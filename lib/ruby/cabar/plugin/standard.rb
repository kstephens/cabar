
require 'cabar/command/standard' # Standard command support.
require 'cabar/facet/standard'   # Standard facets and support.

Cabar::Plugin.new :name => 'cabar' do

  ##################################################################
  # help
  #

  cmd :help, <<'DOC' do
[ --verbose ] [ <command> ]
Lists all commands or help for a specific command.
DOC
    # puts "cmd_args = #{cmd_args.inspect}"
    opts = cmd_opts.dup
    opts[:path] = cmd_args.empty? ? nil : cmd_args.dup

    print_header
    if error = opts[:error]
      puts "  error: #{error.to_s.inspect}"
    end
    puts "  command:"

    main.commands.visit_commands(opts) do | cmd, opts |
      if opts[:path]
        next unless cmd === opts[:path]
      end
      
      x = opts[:indent]
      if opts[:verbose]
        puts "#{x}#{cmd.name}:"
        x = opts[:indent] << '  '
        puts "#{x}aliases:    #{cmd.aliases.inspect}" unless cmd.aliases.empty?
        puts "#{x}synopsis:   #{cmd.synopsis.inspect}"
        puts "#{x}documentation: |"
        puts "#{x}  #{cmd.documentation_lines[1 .. -1].join("\n#{x}  ")}"
        puts "#{x}               |"
        puts "#{x}defined_in: #{cmd._defined_in.to_s.inspect}"
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
  

  ##################################################################
  # action facet
  #

  facet :action, :class => Cabar::Facet::Action
  cmd_group :action do

    cmd [ :list, :ls ] , <<'DOC' do
[ - <component> ] [ <action> ] 
List actions available on all required components
DOC
      select_root cmd_args
      action = cmd_args.shift

      print_header :component
      get_actions(action).each do | c, facet |
        # puts "f = #{f.to_a.inspect}"
        puts "    #{c.to_s(:short)}: "
        puts "      action:"
        facet.action.each do | k, v |
          puts "        #{k}: #{v.inspect}"
        end
      end
    end

    cmd [ :run, :exec, 'do' ], <<'DOC' do
<action> [ - <component> ] <args> ...
Executes an action on all required components.
DOC
      action = cmd_args.shift || raise(ArgumentError, "expected action name")
      comp = select_root cmd_args
      puts "comp = #{comp}"
       
      # Render environment vars.
      setup_environment!
      # puts ENV['RUBYLIB']

      get_actions(action).each do | c, f |
        if comp && comp != c
          next
        end
        f.execute_action! action, cmd_args.dup
      end
    end

    class Cabar::Command
      def get_actions action = nil
        actions = [ ]
        
        context.
          required_components.each do | c |
          # puts "c.facets = #{c.facets.inspect}"
          c.facets.each do | f |
            if f.key == 'action' &&
              (! action || f.can_do_action?(action))
              actions << [ c, f ]
            end
          end
        end
        
        actions
      end
    end
  end # cmd_group


  ##################################################################
  # env facet
  #

  facet :env,     :class => Cabar::Facet::EnvVarGroup
  cmd :env, <<'DOC' do
[ - <component> ]
Lists the environment variables for a selected component.
DOC
    select_root cmd_args
    
    r = Cabar::Renderer::ShellScript.new cmd_opts
    
    context.render r
  end

    
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

  ##################################################################
  # C lib facet
  #

  facet :lib,     :var => :LD_LIBRARY_PATH, :inferrable => false

  ##################################################################
  # C include facet
  #

  facet :include, :var => :INCLUDE_PATH

  ##################################################################
  # Ruby library facet
  #

  facet 'lib/ruby', :var => :RUBYLIB, :inferrable => true


  ##################################################################
  # Perl library facet
  #

  facet 'lib/perl', :var => :PERL5LIB, :inferrable => true


  ##################################################################
  # Component commands
  #

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
    
    cmd :dot, <<'DOC' do
[ - <component> ]
Render the components as a dot graph on STDOUT.
DOC
      select_root cmd_args
      
      r = Cabar::Renderer::DotGraph.new cmd_opts
      
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
  

  ##################################################################
  # Recursive subcomponents.
  #

  facet :components, 
    :class => Cabar::Facet::Components,
    :path => [ 'comp' ],
    :inferrable => true


  cmd_group :plugin do
    cmd :list, <<'DOC' do
[ name ]
Lists plugins.
DOC
      name = cmd_args.shift

      print_header :plugin
      Cabar::Main.current.plugin_manager.plugins.each do | plugin |
        if name && ! (name === plugin.name)
          next
        end

        puts "    #{plugin.name}: "
        puts "      file:     #{plugin.file.inspect}"
        puts "      commands: #{plugin.commands.map{|x| x.name_full}.inspect}"
        puts "      facets:   #{plugin.facets.map{|x| x.key}.inspect}"
      end
    end
  end

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


