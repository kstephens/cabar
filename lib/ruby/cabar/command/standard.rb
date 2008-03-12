require 'cabar/command'

require 'cabar/error'
require 'cabar/renderer'


# Define helpers for built-in commands.

class Cabar::Command

  def print_header str = nil
    puts "cabar:"
    puts "  version: #{Cabar.version.to_s.inspect}"
    puts "  #{str}:" if str
  end
  

  def setup_environment!
    context.render Cabar::Renderer::InMemory.new
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


