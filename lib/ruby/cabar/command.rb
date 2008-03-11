require 'cabar/base'

require 'cabar/error'
require 'cabar/renderer'


module Cabar
  # Manages a list of commands.
  class CommandManager < Base
    # A list of all commands.
    attr_reader :commands

    # A Hash that maps command names (and aliases) to Command objects.
    attr_reader :command_by_name

    def initialize *args
      @commands = [ ]
      @command_by_name = { }
      super
    end

    def command_names
      @command_by_name.keys.sort
    end

    def commands
      @commands
    end

    def empty?
      @commands.empty?
    end

    def deepen_dup!
      super
      @commands = @commands.dup
      @command_by_name = @command_by_name.dup
    end

    def register_command! cmd
      return nil if @commands.include? cmd
      @commands << cmd
      (cmd.aliases + [ cmd.name ]).each do | name |
        name = name.to_s
        if @command_by_name[name]
          raise InvalidCommand, "A command named #{name.inspect} is already registered"
        end
        @command_by_name[name] = cmd
        # $stderr.puts "  register_command! #{cmd.inspect} as #{name.inspect}"
      end

      cmd
    end

    def create_command! name, opts, blk
      opts = { :documentation => opts } unless Hash === opts
 
      opts[:aliases] = EMPTY_ARRAY
      if Array === name
        opts[:aliases] = name[1 .. -1]
        name = name.first
      end

      cls = opts[:class] || Command
      opts.delete(:class)

      opts[:name] = name.to_s.freeze
      opts[:aliases] = opts[:aliases].map{|x| x.to_s.freeze}.freeze
      opts[:proc] = blk

      # $stderr.puts "opts = #{opts.inspect}"

      cmd = cls.factory.new opts

      cmd
    end

    # Define a command.
    def define_command name, opts = nil, &blk
      cmd = create_command! name, opts, blk
      register_command! cmd
      cmd
    end
    alias :cmd :define_command
    
    # Define a command group.
    def define_command_group name, opts = nil, &blk
      opts ||= { }
      cmd = create_command! name, opts, nil
      cmd.instance_eval &blk if block_given?
      cmd.documentation = <<"DOC"
[ #{cmd.subcommands.commands.map{|x| x.name}.sort.join(' | ')} ] ...
* '#{cmd.name_full}' command group.
DOC
      register_command! cmd
      cmd
    end
    alias :cmd_group :define_command_group

    
    # Visits a command.
    def visit_commands opts = { }, &blk
      opts[:indent] ||= '    '
      opts[:cmd_path] ||= [ ]

      commands.sort { |a, b| a.name <=> b.name }.each do | cmd | 
        opts[:cmd_path].push cmd.name
        
        indent_old = opts[:indent].dup

        # yield cmd and opts to the block.
        yield cmd, opts
        
        opts[:indent] << '  '

        cmd.subcommands.visit_commands opts, &blk
 
        opts[:indent] = indent_old
        opts[:cmd_path].pop
      end
    end

    def inspect
      "#<#{self.class} #{commands.inspect}>"
    end

  end # class


  class CommandState < Base
    # The full ARGV.
    attr_accessor :args
    
    # The parsed command path.
    attr_accessor :cmd_path
    
    # The parsed arguments for the command.
    attr_accessor :cmd_opts
    
    # The arguments for the command
    attr_accessor :cmd_args

    # Exit code of command.
    attr_accessor :exit_code

    def initialize *args
      @args = [ ]
      @cmd_path = [ ]
      @cmd_args = [ ]
      @cmd_opts = { }
      @exit_code = 0
     super
    end

    def deepen_dup!
      super
      @args = @args.dup
      @cmd_path = @cmd_path.dup
      @cmd_args = @cmd_args.dup
      @cmd_opts = @cmd_opts.dup
    end

    def merge! state
      # @args = state.args
      # @cmd_path = state.cmd_path
      @cmd_opts = state.cmd_opts.dup.cabar_merge! @cmd_opts
      # @cmd_args = state.cmd_args
      # @exit_code = state.exit_code
    end

    def inspect
      "#<#{self.class} #{object_id} #{cmd_path.inspect} #{cmd_opts.inspect} #{cmd_args.inspect}>"
    end

  end


  # Starts and executes a command.
  class CommandRunner < Base
    # Cabar::Main object.
    attr_accessor :context

    # Cabar::CommandState
    attr_accessor :state

    # Cabar::Command.
    attr_accessor :cmd

    attr_accessor :manager
   
    def manager
      @manager ||= 
        context.commands
    end

    # Parses arguments from command line.
    def parse_args args

      state = self.state = CommandState.factory.new
      state.args = args.dup

      options = state.cmd_opts
      manager = self.manager

      until args.empty?
        arg = args.shift

        case arg
        when '--'
          self.cmd_args = args
          args = EMPTY_HASH
        when /^--?([^\s=]+)=(.+)$/
          options[$1.sub(/[^A-Z0-9]/i, '_').to_sym] = $2.dup
        when /^--?([^\s=]+)=$/
          options[$1.sub(/[^A-Z0-9]/i, '_').to_sym] = args.shift
        when /--?([^\s+=]+)$/
          options[$1.sub(/[^A-Z0-9]/i, '_').to_sym] = true
        else
          # Check for command.
          # puts "cmd_path = #{state.cmd_path.inspect}"
          # puts "manager = #{manager.inspect}"
          if ! manager.empty?
            cmd_name = arg.to_s
            state.cmd_path << cmd_name
            if self.cmd = manager.command_by_name[cmd_name]
              manager = self.cmd.subcommands
            else
              raise Cabar::Error, "Invalid command path #{state.cmd_path.inspect}"
            end
          else
            args.unshift arg
            state.cmd_args = args
            args = EMPTY_ARRAY
          end
        end
      end

      if state.cmd_path.empty?
        $stderr.puts "#{File.basename($0)}: command not specified"
        parse_args [ "help" ]
      end

      # $stderr.puts "state = #{state.inspect}"
    
      self
    end


    def run
      begin
        cmd = self.cmd

        unless cmd
          raise Cabar::Error, "Invalid command name #{state.cmd_path.inspect}"
        end

        # Clone the Command object.
        # $stderr.puts "original cmd = #{cmd.inspect}"
        cmd = cmd.dup

        # Attach to the context.
        cmd.main = @context

        # Merge the current state.
        state.merge! cmd.state

        # Attach to this cmd state.
        state_save = cmd.state
        cmd.state = state

        # We need to define the singleton methods here
        # because singleton methods do not survive
        # dup.
        (class << cmd; self; end).class_eval do 
          define_method :execute_command!, cmd.proc
        end

        # $stderr.puts "state = #{cmd.state.inspect}"
        # $stderr.puts "cmd = #{cmd.inspect}"
        # $stderr.puts "cmd.methods = #{cmd.methods.sort.inspect}"

        # Execute the command.
        cmd.execute_command!
      rescue SystemExit => err
        raise err
      rescue Exception => err
        $stderr.puts "#{File.basename($0)}: #{err.inspect}\n  #{err.backtrace.join("\n  ")}"
        state.exit_code = 10
      ensure 
        cmd.state = state_save
      end

      state.exit_code
    end
  end # class


  # Represents commands that can be run from Cabar::Main.
  class Command < Base

    # Attributes during invokation.
    attr_accessor :state
    # The full ARGV.
    def args     ; @state.args;     end
    # The actual command path given.
    def cmd_path ; @state.cmd_path; end
    # The command arguments.
    def cmd_args ; @state.cmd_args; end
    # The command options.
    def cmd_opts ; @state.cmd_opts; end

    # The Command name.
    attr_accessor :name

    # Alternate names for this command.
    attr_accessor :aliases

    # The documentation for the command.
    attr_accessor :documentation

    # The Proc to be executed.
    attr_accessor :proc

    # The Command that holds this as a subcommand.
    attr_accessor :supercommand

    # A CommandManager for subcommands.
    attr_accessor :subcommands

    # The context that undefined methods will delegate to.
    attr_accessor :main

    def initialize *args, &blk
      @state = CommandState.factory.new
      @subcommands = CommandManager.factory.new
      super
      instance_eval if block_given?
    end

    def deepen_dup!
      super
      @state = @state.dup
      self
    end


    def names
      @aliases.dup << @name
    end

    # Returns true if matches by name or alias.
    def === x
      case x
      when String
        x === @name || @aliases.any?{|x| n === x} 
      when Array
        path = names_path.dup
        x.all? do | x |
          p = path.shift
          p.nil? || p.any?{|p| x === p }
        end
      when
        false
      end
    end

    # Returns the lines of documentation.
    def documentation_lines
      @documentation_lines ||= @documentation.split("\n")
    end

    # Return the full path to this command.
    def name_path
      @name_path ||=
        begin
          path = @supercommand ? @supercommand.name_path.dup : [ ] 
          path.push name
        end
    end

    def names_path
      @names_path ||=
        begin
          path = @supercommand ? @supercommand.names_path.dup : [ ] 
          path.push names
        end
    end

    def name_full
      name_path.join(' ')
    end


    # Returns the synopsis of this command from
    # the first line of documentation.
    def synopsis
      "#{name_full} " + documentation_lines[0]
    end

    # Returns the description of this command from
    # the second line of documentation.
    def description
      documentation_lines[1]
    end

    # Returns true if this command is a top-level command.
    def top_level_command?
      ! @supercommand
    end

    # Defer to @main.
    def method_missing sel, *args, &blk
      @main.send(sel, *args, &blk)
    end

    def execute_command!
      raise Error, "Command instance #{self.inspect} must define execute_command!"
    end

    ##################################################################

    def define_command name, opts = nil, &blk
      opts = { :documentation => opts } unless Hash === opts
      opts[:supercommand] = self
      cmd = @subcommands.define_command name, opts, &blk
      cmd
    end
    alias :cmd :define_command

    def cmd_group name, opts = nil, &blk
      opts = { :documentation => opts } unless Hash === opts
      opts[:supercommand] = self
      cmd = @subcommands.cmd_group name, opts, &blk
      cmd
    end
  
    def inspect
      "#<#{self.class} #{object_id} #{name.inspect} #{aliases.inspect} #{description.inspect}>"
    end

  end # class

  
  class CommandManager

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
        
      end

      
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

    
  # Define helpers for commands

  class Command

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

end # module

