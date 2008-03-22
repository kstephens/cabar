

Cabar::Plugin.new :name => 'cabar/bin' do

  require 'cabar/command/standard' # Standard command support.
  require 'cabar/facet/standard'   # Standard facets and support.

  ##################################################################
  # bin facet
  #

  facet :bin,     :var => :PATH, :inferrable => true

  cmd_group :bin do
    cmd [ :run, :exec ], <<'DOC' do
[ - <component> ] <prog> <prog-args> ....
Runs <prog> in the environment of the top-level component.
DOC
      select_root cmd_args
      
      r = Cabar::Renderer::InMemory.new cmd_opts
      
      context.render r
      
      exec_program *cmd_args
    end # cmd
    
    cmd [ :list, :ls ], <<'DOC' do
[ <options> ] [ - <component> ] [ <prog> ] 
Lists all bin programs.

Options:

  -r  Selects required components
  -a  Selects available components
  Defaults to selecting the default top-level component.
DOC
      root_component = select_root cmd_args
      prog = cmd_args.shift || '*'
      
      components = 
        case
        when cmd_opts[:r]
          $stderr.puts "required_components"
          context.required_components
        when cmd_opts[:a]
          $stderr.puts "available_components"
          context.available_components
        when root_component
          $stderr.puts "root_component => #{root_component}"
          [ root_component ]
        end
      
      print_header :bin
      components.to_a.each do | c |
        if f = c.facet('bin')
          list_only = f.list_only
          list_only &&= list_only.map{|x| x.to_s}
          cmds = f.abs_path.
            map { |x| "#{x}/#{prog}"}.
            map { |x| Dir[x]}.flatten.sort.
            select { |x| ! list_only  or list_only.include?(File.basename(x)) }.
            select { |x| File.executable? x}
          unless cmds.empty?
            puts "    #{c.to_s}: "
            cmds.each do | f |
              file = `file #{f.inspect}`.chomp
              file = file.split(': ', 2)
              puts "      #{file[0]}: #{file[1].inspect}"
            end
          end
          
        end
      end
    end # cmd

  end # cmd_group

end # plugin


