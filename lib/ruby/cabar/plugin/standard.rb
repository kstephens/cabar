

Cabar::Plugin.new :name => 'cabar', :documentation => <<"DOC" do
Cabar standard plugin.
Includes all plugins named 'cabar/plugin/*.rb' 
found in $: (#{$:.inspect}).
DOC

  require 'cabar/command/standard' # Standard command support.
  require 'cabar/facet/standard'   # Standard facets and support.

  # Pull any files named cabar/plugin/*.rb
  # in the current $: ruby lib search path.
  $:.map { | dir | Dir["#{dir}/cabar/plugin/*.rb"] }.
    flatten.
    reject { | fn | fn == __FILE__ }.
    map { | fn | %r{/(cabar/plugin/[a-z0-9_-]+)\.rb$}i =~ fn ? $1 : nil }.
    compact.
    sort.
    uniq.
    each do | n |
      # $stderr.puts "loading #{n}"
      require n
    end

  # Internals and introspection.

  cmd_group :cabar do
    cmd :shell, <<'DOC' do
[ - <component> ]
Starts an interactive shell on Cabar::Context.
DOC
      select_root cmd_args 
      
      require 'readline'
      prompt = "  #{File.basename($0)} >> "
      _ = nil
      err = nil
      while line = Readline.readline(prompt, true)
        begin
          _ = context.instance_eval do
            eval line
          end
          puts _.inspect
        rescue Exception => err
          puts err.inspect
        end
      end
    end

  end # cmd_group

end # plugin


