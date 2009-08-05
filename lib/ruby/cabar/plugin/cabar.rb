

Cabar::Plugin.new :name => 'cabar', :documentation => <<"DOC" do
Cabar standard plugin.

Autoloads all plugins named 'cabar/plugin/auto/*.rb' found along $:.
DOC

  require 'shellwords'

  when_installed do
    # $stderr.puts "*** #{self} plugin_installed! MORE!"

    # Autoload any plugins named cabar/plugin/auto/*.rb
    # in the current $: ruby lib search path.
    $:.map do | dir | 
      x = Dir["#{dir}/cabar/plugin/auto/*.rb"]
      # $stderr.puts "  dir #{dir.inspect} plugins #{x.inspect}"
      x
    end.
    flatten.
    reject { | fn | fn == __FILE__ }.
    compact.
    sort.
    uniq.
    each do | n | 
      # $stderr.puts "loading #{n}"
      manager.load_plugin! n
    end
  end

  doc "Internals and introspection."
  cmd_group [ :cabar, :cbr ] do
    doc '[ - <component> ]
Starts an interactive shell on Cabar::Main.

Examples

  cbr >> f = resolver.available_components["ruby"].first.facets.first
#<Cabar::Facet::Path "lib/ruby" "RUBYLIB" ["lib/ruby"]>
  cbr >> f
#<Cabar::Facet::Path "lib/ruby" "RUBYLIB" ["lib/ruby"]>
  cbr >> f.standard_path_proc
#<Proc:0xb7c83964@/home/kurt/local/src/cabar/lib/ruby/cabar/plugin/ruby.rb:28>
  cbr >> f.standard_path_proc.call(f)
["/usr/local/lib/site_ruby/1.8", "/usr/local/lib/site_ruby/1.8/i486-linux", "/usr/local/lib/site_ruby/1.8/i386-linux", "/usr/local/lib/site_ruby", "/usr/lib/ruby/vendor_ruby/1.8", "/usr/lib/ruby/vendor_ruby/1.8/i486-linux", "/usr/lib/ruby/vendor_ruby", "/usr/lib/ruby/1.8", "/usr/lib/ruby/1.8/i486-linux", "/usr/lib/ruby/1.8/i386-linux", "."]
  cbr >> _options               
{:f=>#<Cabar::Facet::Path "lib/ruby" "RUBYLIB" ["lib/ruby"]>}
'
    cmd :shell do
      selection.select_required = true
      selection.to_a
      
      require 'readline'
      prompt = "  #{File.basename($0)} >> "
      _ = nil
      err = nil
      while line = Readline.readline(prompt, true)
        begin
          _ = main.instance_eval do
            case line
            when /\A\s*_\s+(.*)/
              # Handle running cbr commands from within a shell.
              new_command_runner.parse_args(Shellwords.shellwords($1)).run
            when /\A\s*([a-z_][a-z_0-9]*)\s*=(.*)/i
              # Handle "local" variables assignment via _options Hash.
              # See Cabar::Base#method_missing.
             _options[$1.to_sym] = eval $2
            else
              eval line
            end
          end
          puts _.inspect
        rescue Exception => err
          $stderr.puts "#{err.inspect}\n  #{err.backtrace.join("  \n")}"
        end
      end
    end

  end # cmd_group

end # plugin


