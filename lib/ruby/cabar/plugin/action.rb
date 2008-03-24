

Cabar::Plugin.new :name => 'cabar/action' do

  require 'cabar/command/standard' # Standard command support.
  require 'cabar/facet/standard'   # Standard facets and support.

  ##################################################################
  # action facet
  #

  # This represents group of commands that can be run on a component.
  #
  # action:
  #   name_1: cmd_1
  #   name_2: cmd_2
  #
  # See "cbr action list".
  class Cabar::Facet::Action < Cabar::Facet
    attr_accessor :action
    
    def component_associations
      [ 'provides' ]
    end
    
    def is_composable?
      false
    end
    
    def _reformat_options! opts
      opts = { :action => opts }
      opts
    end
    
    def compose_facet! f
      @action.cabar_merge! f.action
    end
    
    def can_do_action? action
      @action.key? action.to_s
    end
    
    def execute_action! action, args, opts = EMPTY_HASH
      expr = @action[action.to_s] || raise("cannot find action #{action.inspect}")
      puts "component #{component}:"
      puts "action: #{action.inspect}: #{expr.inspect}"
      
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
        error_ok = str.sub!(/^\s*-/, '')
        # puts "error_ok: #{error_ok.inspect}"
        
        Dir.chdir(component.directory) do 
          # FIXME.
          str = '"' + str + '"'
          str = component.instance_eval do
            eval str 
          end
          
          puts "+ #{str}"
          unless opts[:dry_run]
            result = system(str)
          end
        end
        
        puts "result: #{result.inspect}"
        puts "\n"
        
        unless error_ok
          raise "action: failed #{result.inspect}" unless result
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
  
  facet :action, 
        :class => Cabar::Facet::Action

  ##################################################################
  # action facet
  #

  cmd_group :action, <<'DOC' do
Actions are commands that can be run on a component:

Defined by:

  facet:
    action:
      name_1: cmd_1
      name_2: cmd_2
DOC

    cmd :list, <<'DOC' do
[ <action> ] 
List actions available on all components.

DOC
      selection.select_available = true
      selection.to_a

      action = cmd_args.shift

      print_header :component
      get_actions(action).each do | c, facet |
        # puts "f = #{f.to_a.inspect}"
        puts "    #{c.to_s(:short)}: "
        puts "      action:"
        facet.action.each do | k, v |
          next if action && ! (action === k)
          puts "        #{k}: #{v.inspect}"
        end
      end
    end # cmd

    cmd [ :run, :exec, 'do' ], <<'DOC' do
[ --dry-run ] <action> <args> ...
Executes an action on all required components.
DOC
      selection.select_required = true
      selection.to_a

      action = cmd_args.shift || raise(ArgumentError, "expected action name")
      # puts "comp = #{comp}"
       
      # Render environment vars.
      setup_environment!
      # puts ENV['RUBYLIB']

      get_actions(action).each do | c, f |
        f.execute_action! action, cmd_args.dup, cmd_opts
      end

    end # cmd

    class Cabar::Command
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

    end # cmd

  end # cmd_group

end # plugin


