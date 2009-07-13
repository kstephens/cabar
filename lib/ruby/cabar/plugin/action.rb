

Cabar::Plugin.new :name => 'cabar/action' do

  require 'shellwords'

  ##################################################################
  # action facet
  #

  module Cabar
  class Facet
  # This represents group of commands that can be run on a component.
  #
  # action:
  #   name_1: cmd_1
  #   name_2: cmd_2
  #
  # See "cbr action list".
  class Action < self
    # The Hash of action names to action commands.
    attr_accessor :action
    
    def component_associations
      [ 'provides' ]
    end
    
    def is_composable?
      false
    end
    
    def _reformat_options! opts
      opts = { :action => opts || { } }
      opts
    end
    
    def compose_facet! f
      @action.cabar_merge! f.action
    end
    
    def can_do_action? action
      @action.key? action.to_s
    end
    
    # Runs action with arguments.
    #
    # If action expression is a String,
    # args are quoted using Shellwords and appended.
    # then substituted via Ruby #{...} expansion.
    #
    def execute_action! action, args, opts = EMPTY_HASH
      expr = @action[action.to_s] or raise ArgumentError, "cannot find action #{action.inspect}"

      out =
        case
        when opts[:out]
          opts[:out]
        when opts[:quiet]
          StringIO.new
        else
          $stdout
        end
 
      out.puts "component:"
      out.puts "  #{component.to_s(:short)}:"
      out.puts "    action: "
      out.puts "      #{action.inspect}:"
      out.puts "        expr: #{expr.inspect}"
      unless args.empty?
        out.puts "        args: #{args.inspect}"
      end
      
      result = nil
      if opts[:dry_run]
        result = true
      end
      
      case expr
      when Proc
        unless opts[:dry_run]
          result = expr.call(*args)
        end
        
      when String
        str = expr.dup
        unless args.empty?
          str += ' ' + Shellwords.shellwords(args.join(' ')).join(' ')
        end
        error_ok = str.sub!(/^\s*-/, '')
        # puts "error_ok: #{error_ok.inspect}"
        
        Dir.chdir(component.directory) do
          # Interpolate #{...} in String.
          str = expand_string(str)          
          out.puts "        command: #{str.inspect}"
          out.puts "        output: |"
          unless opts[:dry_run]
            if str =~ /^\s*!exec\s+(\S+.*)/
              exec_args = Shellwords.shellwords($1)
              exec_args = exec_args + args
              exec *exec_args
              raise Error, "exec failed: #{exec_args.inspect}"
            end
            result = system(str)
          end
          out.puts "                |"
        end
        
        out.puts "        result: #{result.inspect}"
        out.puts "\n"
        
        unless error_ok
          raise Error, "action: failed #{result.inspect}" unless result
        end
      end

      result
    end
    
    def to_a
      super +
        [
         [ :action, action ],
        ]
    end
  end # class
  end # class
  end # module
  

  facet :action, 
        :class => Cabar::Facet::Action

  ##################################################################
  # action facet
  #

  doc <<"DOC"
Actions are commands that can be run on a component:

Defined by:

  facet:
    action:
      name_1: cmd_1
      name_2: cmd_2

If an action command begins with '-' it's error code is ignored.

DOC
  # 'emacs

  cmd_group :action do
    doc '[ <action> ] 
List actions available on all components.
'
    cmd [ :list, :ls ] do
      selection.select_available = true
      selection.to_a

      action = cmd_args.shift

      print_header :action
      sorted_actions={}
      get_actions(action).each do | c, facet |
        facet.action.each do | k, v |
          next if action && ! (action === k)
          sorted_actions[k]=(sorted_actions[k] || []) << c
        end
      end
      sorted_actions.keys.sort.each { |action_name|
        puts "    #{action_name}:  "
        sorted_actions[action_name].sort_by {|c| c.name }.each {|comp| 
          puts "      - #{comp.to_s(:short)} "
        }
      }
    end # cmd

    doc '[ --dry-run, --quiet ] <action> <args> ...
Executes an action on all required components.'
    cmd [ :run, :exec, 'do' ] do
      selection.select_required = true
      selection.to_a

      action = cmd_args.shift || raise(ArgumentError, "expected action name")
      # puts "comp = #{comp}"
       
      # Render environment vars.
      setup_environment!
      # puts ENV['RUBYLIB']
      raise "No components responded to action!" unless get_actions(action).size > 0
      get_actions(action).each do | c, f |
        f.execute_action! action, cmd_args.dup, cmd_opts
      end

    end # cmd


    helpers do
      def get_actions action = nil
        actions = [ ]
        
        # puts "selection = #{selection.to_a.inspect}"
        selection.to_a.each do | c |
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

    end # helpers

  end # cmd_group

end # plugin


