require 'cabar/command'

require 'cabar/error'
require 'cabar/renderer'


# Define helpers for built-in commands.

class Cabar::Command
  def print_header str = nil
    puts Cabar.yaml_header(str)
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
    
    if ENV['CABAR_ALWAYS_EXEC']
      args.unshfit cmd
      Kernel::exec *args
      raise Error, "cannot execute #{args.inspect}"
    end

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
  
end # class


