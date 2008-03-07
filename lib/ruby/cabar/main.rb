require 'cabar/base'

require 'cabar/error'
require 'cabar/context'
require 'cabar/renderer'


module Cabar

  # Main command line driver.
  class Main < Base
    attr_accessor :args, :cmd, :cmd_opts, :cmd_args, :exit_code

    @@cmd_help = { }


    def initialize *args
      super
      self.exit_code = -1
    end


    def parse_args args = self.args
      args = args.dup

      self.cmd = nil
      self.cmd_args = [ ]
      self.cmd_opts = { }
      
      until args.empty?
        arg = args.shift

        case arg
        when /^--?([^\s=]+)=(.+)$/
          _options[$1.sub(/[^A-Z0-9]/i, '_').to_sym] = $2.dup
        when /^--?([^\s=]+)=$/
          _options[$1.sub(/[^A-Z0-9]/i, '_').to_sym] = args.shift
        when /^--?([^\s=]+)$/
          _options[$1.sub(/[^A-Z0-9]/i, '_').to_sym] = true
        else
          self.cmd = arg.to_sym
          
          until args.empty?
            arg = args.shift

            case arg
            when '--'
              self.cmd_args = args
              args = EMPTY_HASH
            when /^--?([^\s=]+)=(.+)$/
              cmd_opts[$1.sub(/[^A-Z0-9]/i, '_').to_sym] = $2.dup
            when /^--?([^\s=]+)=$/
              cmd_opts[$1.sub(/[^A-Z0-9]/i, '_').to_sym] = args.shift
            when /--?([^\s+=]+)$/
              cmd_opts[$1.sub(/[^A-Z0-9]/i, '_').to_sym] = true
            else
              args.unshift arg
              self.cmd_args = args
              args = EMPTY_ARRAY
            end
          end
        end
      end

      self
    end


    def run
      begin
        self.exit_code = 0
        unless self.class.cmd_names.include?(cmd)
          raise Cabar::Error, "invalid command: #{cmd.inspect}"
        end
        send "cmd_#{cmd}"
      rescue SystemExit => err
        raise err
      rescue Exception => err
        $stderr.puts "#{File.basename($0)}: #{err.inspect}\n  #{err.backtrace.join("\n  ")}"
        self.exit_code = 10
      end

      self.exit_code
    end

    ##################################################################

    # Return the Context object.
    def context
      @context ||=
      begin
        Context.new(:directory => File.expand_path('.')).make_current!
      end
    end


    ##################################################################
    # Command methods.
    #

    def self.cmd_names
      @@cmd_names ||= [ ]
    end


    def self.cmd_help
      @@cmd_help ||= { }
    end


    # Define a command.
    def self.cmd name, doc = nil, &blk
      if Enumerable === name
        name.each { | x | cmd x, doc, &blk }
        return
      end

      name = name.to_sym
      self.cmd_names << name
      self.cmd_help[name] = doc if doc
      self.class_eval do 
        send(:define_method, "cmd_#{name}", &blk)
      end
    end


    ##################################################################


    cmd :help, <<"END" do
help [ <command> ]
Shows help on a command.
END
      if cmd_args.empty?
        puts "Commands:"
        self.class.cmd_names.each do | cmd |
          help = self.class.cmd_help[cmd]
          puts "  #{cmd} - #{help.split("\n")[1]}"
        end
      else
        cmd = cmd_args.first.to_sym
        msg = self.class.cmd_help[cmd]
        raise ArgumentError, "unknown command #{cmd.inspect}" unless msg
        puts "#{msg}"
      end
    end

    cmd :config, <<"END" do
config 
Shows current configuration.
END
      puts "#{context.config_raw.to_yaml}"
    end


    cmd :list, <<"END" do
list [ <cmd-opts> ] [ <component> ]
Lists all available components.
END
      yaml_renderer.
        render_components(context.
                          available_components.
                          select(search_opts(cmd_args))
                          )
    end

    cmd :show, <<"END" do
show [ <cmd-opts> ] <component>
Lists the current settings for a selected component.
END
      select_root cmd_args

      yaml_renderer.
        render_components(context.
                          required_components
                          )
      yaml_renderer.
        render_facets(
                      context.
                      facets.
                      values)
    end

    cmd :env, <<"END" do
env [ <cmd-opts> ] <component>
Lists the environment variables for a selected component.
END
      raise ArgumentError if cmd_args.empty?
      select_root cmd_args

      r = Renderer::ShellScript.new cmd_opts

      context.render r
    end


    cmd :run, <<"END" do
run [ cmd-opts ] <component> <prog> <prog-args> ....
Runs <prog> in the environment of the top-level component.
END
      select_root cmd_args

      r = Renderer::InMemory.new cmd_opts

      context.render r

      exec_program *cmd_args
    end
    alias :cmd_exec :cmd_run

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
          /#!.*ruby/ === File.open(cmd) { |fh| fh.readline }
        # $stderr.puts "Running ruby in-place #{cmd.inspect} #{args.inspect}"

        ARGV.clear
        ARGV << args
        $0 = cmd

        load cmd
        exit 0
      else
        Kernel::exec [ cmd ] + args
      end
    end


    cmd :facet, <<"END" do
facet [ <cmd-opts> ] <component>
Show the facets for the top-level component.
END
      select_root cmd_args

      yaml_renderer.
        render_facets(context.
                      facets.
                      values
                      )
    end


    cmd :dot, <<"END" do
dot [ <cmd-opts> ] <component>
Render the components as a dot graph on STDOUT.
END
      select_root cmd_args

      r = Renderer::DotGraph.new cmd_opts

      r.render(context)
    end


    cmd :action, <<"END" do
action [ <cmd-opts> ] <component> <action> <args> ...
Executes an action on a facet.
END

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


    cmd :shell, <<"END" do
shell [ <cmd-opts> ] [ <component> ]
Starts an interactive shell on Cabar::Context.
END
      unless cmd_args.empty?
        select_root cmd_args 
      end

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

    private

    # Return a YAML renderer.
    def yaml_renderer
      @yaml_renderer ||=
        Cabar::Renderer::Yaml.new cmd_opts
    end

    #####################################################

    
    # Selects the root component.
    def select_root args
      # Find the root component.
      root_component = context.require_component search_opts(args)

      # Resolve configuration.
      context.resolve_components!

      # Validate configuration.
      context.validate_components!

      # Return the root component.
      root_component
    end


    # Get a Constraint object for the cmd_arguments and options.
    def search_opts args
      # Get options.
      name = args.shift
      version = cmd_opts[:version]

      search_opts = { }
      search_opts[:name] = name if name
      search_opts[:version] = version if version

      search_opts = Cabar::Constraint.create(search_opts)
      
      search_opts
    end
    
  end # class

end # module

