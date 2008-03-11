require 'cabar/command/manager'


require 'cabar/error'
require 'cabar/renderer'


# Standard built-in commands.

class Cabar::Command::Manager
  
  # See Cabar::Main.
  def define_top_level_commands!  
    cmd :help, <<'DOC' do
[ --verbose ] [ <command> ]
Lists all commands or help for a specific command.
DOC
      # puts "cmd_args = #{cmd_args.inspect}"
      opts = cmd_opts.dup
      opts[:path] = cmd_args.empty? ? nil : cmd_args.dup
      print_header :command
      main.commands.visit_commands(opts) do | cmd, opts |
        if opts[:path]
          next unless cmd === opts[:path]
        end
        
        x = opts[:indent]
        if opts[:verbose]
          puts "#{x}#{cmd.name}:"
          x = opts[:indent] << '  '
          puts "#{x}aliases: #{cmd.aliases.inspect}" unless cmd.aliases.empty?
          puts "#{x}synopsis: #{cmd.synopsis.inspect}"
          puts "#{x}documentation: |"
          puts "#{x}  #{cmd.documentation_lines[1 .. -1].join("\n#{x}  ")}"
          puts "#{x}               |"
          puts "#{x}subcommands:" unless cmd.subcommands.empty?
        else
          key = "#{x}#{'%-10s' % (cmd.name + ':')}"
          if cmd.subcommands.empty?
            puts "#{key} #{cmd.description.inspect}"
          else
            puts "#{key}"
            puts "  #{x}#{'%-10s' % (':desc:')} #{cmd.description.inspect}"
          end
          
          unless cmd.aliases.empty?
            puts "##{x}#{'%-10s' % ''} aka: #{cmd.aliases.sort.join(', ')}"
          end
        end
      end
    end
    
    cmd_group [ :component, :comp, :c ] do
      cmd [ :list, :ls ], <<'DOC' do
[ --verbose ] [ - <component> ]
Lists all available components.
DOC
        yaml_renderer.
          render_components(context.
                            available_components.
                            select(search_opts(cmd_args))
                            )
      end
      
      cmd :dot, <<'DOC' do
[ - <component> ]
Render the components as a dot graph on STDOUT.
DOC
        select_root cmd_args
        
        r = Renderer::DotGraph.new cmd_opts
        
        r.render(context)
      end
      
      cmd :show, <<'DOC' do
[ <cmd-opts???> ] [ - <component> ]
Lists the current settings for a selected component.
DOC
        select_root cmd_args
        
        yaml_renderer.
          render_components(context.required_components)
        yaml_renderer.
          render_facets(context.facets.values)
      end
      
    end # cmd_group
    
    
    cmd :env, <<'DOC' do
[ - <component> ]
Lists the environment variables for a selected component.
DOC
      raise ArgumentError if cmd_args.empty?
      select_root cmd_args
      
      r = Renderer::ShellScript.new cmd_opts
      
      context.render r
    end
    
    
    cmd [ :run, :exec ], <<'DOC' do
[ - <component> ] <prog> <prog-args> ...
Runs <prog> in the environment of the top-level component.
DOC
      select_root cmd_args
      
      r = Renderer::InMemory.new cmd_opts
      
      context.render r
      
      exec_program *cmd_args
    end
    
    ################################################################
    # bin facet command
    #
    
    cmd_group :bin do
      cmd [ :run, :exec ], <<'DOC' do
[ - <component> ] <prog> <prog-args> ....
Runs <prog> in the environment of the top-level component.
DOC
        select_root cmd_args
        
        r = Renderer::InMemory.new cmd_opts
        
        context.render r
        
        exec_program *cmd_args
      end # cmd
      
      cmd [ :list, :ls ], <<'DOC' do
[ - <component> ] [ <prog> ] 
Lists all bin programs.
DOC
        select_root cmd_args
        prog = cmd_args.shift || '*'
        
        components = 
          case 
          when cmd_opts[:R]
            context.required_components
          else
            context.selected_components
          end
        
        print_header :bin
        components.to_a.each do | c |
          if f = c.facet('bin')
            cmds = f.abs_path.map{|x| "#{x}/#{prog}"}.map{|x| Dir[x]}.flatten.sort.select{|x| File.executable? x}
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
    

    cmd :facet, <<'DOC' do
[ - <component> ]
Show the facets for the top-level component.
DOC
      select_root cmd_args
      
      yaml_renderer.
        render_facets(context.
                      facets.
                      values
                      )
    end
    
    
    cmd :action, <<'DOC' do
[ - <component> ] <action> <args> ...
Executes an action on all required components.
DOC
      select_root cmd_args
      action = cmd_args.shift
      
      context.
        required_components.each do | c |
        # puts "c.facets = #{c.facets.inspect}"
        c.facets.select do | f |
          f.key == 'actions' &&
            f.can_do_action?(action)
        end.each do | f |
          # puts "f = #{f.to_a.inspect}"
          f.execute_action! action, cmd_args.dup
        end
      end
      
    end
    
    
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
    
  end # class
end # class

    
# Define helpers for built-in commands.

class Cabar::Command

  def print_header str = nil
    puts "cabar:"
    puts "  version: #{Cabar.version}"
    puts "  #{str}:" if str
  end
  
  
  # Return a YAML renderer.
  def yaml_renderer
    @yaml_renderer ||=
      Cabar::Renderer::Yaml.new cmd_opts
  end
  
  #####################################################
  
  # Locates an executable using PATH.
  # 
  # If the script starts with:
  #
  #   #!/usr/bin/env cbr-run
  #   #!ruby
  #
  # the script is run directly inside cabar's ruby interpreter after
  # appropriately replacing ARGV and $0.
  #
  # If the script starts with:
  #
  #   #!/usr/bin/env cbr-run
  #   #!/some-exe -arg1 -arg2
  #
  # some-exe is executed with [ "-arg1", "-arg2", script ].
  #
  # Otherwise the executable is simple exec'ed.
  def exec_program cmd, *args
    # $stderr.puts "exec_program #{cmd.inspect} #{args.inspect}"
    
    unless /\// === cmd 
      ENV['PATH'].split(Cabar.path_sep).each do | x |
        x = File.expand_path(File.join(x, cmd))
        if File.executable?(x)
          cmd = x
          break
        end
      end
    end
    
    if File.readable?(cmd) && 
        File.executable?(cmd) && 
        (lines = File.open(cmd) { |fh| 
           lines = [ ]
           lines << fh.readline 
           lines << fh.readline
           lines
         })
      
      case
      when (/^\s*#!.*ruby/ === lines[0] || /^\s*#!.*ruby/ === lines[1])
        # $stderr.puts "Running ruby in-place #{cmd.inspect} #{args.inspect}"
        
        ARGV.clear
        ARGV.push *args
        $0 = cmd
        
        load cmd
        exit 0
      when (/^\s*#!.*cbr-run/ === lines[0] && /^\s*#!\s*(.*)/ === lines[1])
        require 'shellwords'
        words = Shellwords.shellwords($1)
        words << cmd
        args.unshift *words
        # $stderr.puts "Running #{args.inspect}"
        Kernel::exec *args
        raise Error, "cannot execute #{args.inspect}"
      end
    end
    
    args.unshift cmd
    Kernel::exec *args
    raise Error, "cannot execute #{args.inspect}"
  end
  
  
  # Selects the root component.
  def select_root args
    # Require the root component.
    root_component = context.require_component search_opts(args, ENV['CABAR_TOP_LEVEL'])
    
    # Resolve configuration.
    context.resolve_components!
    
    # Validate configuration.
    context.validate_components!
    
    # Return the root component.
    root_component
  end
  
  
  # Get a Constraint object for the cmd_arguments and options.
  def search_opts args, default = nil
    name = nil
    if args.first == '-'
      args.shift
      # Get options.
      name = args.shift
    end
    version = cmd_opts[:version]
    
    search_opts = { }
    search_opts[:name] = name if name
    search_opts[:name] ||= default if default
    
    search_opts[:version] = version if version
    
    search_opts = Cabar::Constraint.create(search_opts)
    
    search_opts
  end
  
end # class


