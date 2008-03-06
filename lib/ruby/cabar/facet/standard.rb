require 'cabar/facet'


module Cabar
  class Facet

    # This represents group of action commands to run on a component.
    #
    # actions:
    #   name_1: cmd_1
    #   name_2: cmd_2
    class ActionGroup < self
      attr_accessor :actions

      def component_associations
        [ 'provides' ]
      end

      def is_composable?
        false
      end

      def _reformat_options! opts
        opts = { :actions => opts }
        opts
      end

      def compose_facet! f
        actions.merge! f.actions
      end

      def can_do_action? action
        actions.key? action.to_s
      end

      def execute_action! action, args
        expr = actions[action.to_s] || raise("cannot find action #{action.inspect}")
        puts "component #{component}:"
        puts "action: #{action.inspect}: #{expr.inspect}"

        case expr
        when Proc
          result = expr.call(*args)

        when String
          str = expr.dup
          error_ok = str.sub!(/^\s*-/, '')
          # puts "error_ok: #{error_ok.inspect}"
          
          result =
            Dir.chdir(component.directory) do 
            # FIXME.
            str = '"' + str + '"'
            str = component.instance_eval do
              eval str 
            end
            
            puts "+ #{str}"
            system(str)
          end
          
          puts "result: #{result.inspect}"

          unless error_ok
            raise "action: failed #{result.inspect}" unless result
          end
        end

        result
      end

      def to_a
        super +
          [
           [ :actions, actions ],
          ]
      end
    end # class

    ActionGroup.new(:key => :actions).register_prototype!
 

    # This represents a list of environment variables.
    class EnvVarGroup < self
      attr_accessor :vars

      def _reformat_options! opts
        opts = { :vars => opts }
        opts
      end

      def compose_facet! facet
        self
      end

      # env_var:
      #   NAME1: v1
      #   NAME2: v2
      def attach_component! c
        vars.each do | n, v |
          c.create_facet(:env_var, :var => n, :value => v)
        end
      end
    end
    EnvVarGroup.new(:key => :env).register_prototype!


    def is_env_var?
      false
    end

    class EnvVar < self
      attr_accessor :var
      attr_accessor :value

      def var= x
        @var = x && x.to_s
        x
      end

      def is_env_var?
        true
      end

      def component_associations
        [ 'environment' ]
      end

      def compose_facet! facet
        value = facet.value 
        if @value == nil || @value == value
          @value = value 
        else
          raise "EnvVar #{var.inspect} already set #{@value.inspect}"
        end
        self
      end

      def render r
        r.setenv(var, value)
        case var
        when 'RUBYLIB'
          $: = value.split(':') # FIXME: ':'
        end
      end

      def to_a
        super +
          [
           [ :var, var ],
           [ :value, value ],
          ]
      end
    end


    class Path < self
      attr_accessor :std_path
      attr_accessor :path
      attr_accessor :abs_path

      def deepen_dup!
        super
        @path = @path.dup rescue @path
        @abs_path = @abs_path.dup rescue @abs_path
      end

      def default_path
        [ (std_path || key).to_s ]
      end

      def path
        @path ||= default_path
      end

      def abs_path
        @abs_path ||= path.map { | x | File.expand_path(x, component.base_directory) }
      end

      def compose_facet! facet
        @abs_path = (abs_path + facet.abs_path).uniq
        self
      end

      def to_s
        "#<#{self.class} #{key.inspect} #{abs_path.inspect}>"
      end

      def inspect
        to_s
      end
 
      def to_a
        x = super
        x.push [ :path, path ]
        x.push [ :abs_path, abs_path ]
        x
      end
    end


    class EnvVarPath < Path
      attr_accessor :var

      def var= x
        @var = x && x.to_s
        x
      end

      def is_env_var?
        true
      end

      def component_associations
        [ 'provides', 'environment' ]
      end

      def value
        abs_path.uniq.join(', ')
      end

      def render r
        r.setenv(var, abs_path.uniq.join(r.path_sep))
      end

      def to_a
        super +
          [
           [ :var, var ],
          ]
      end
    end


    register_prototype EnvVarPath.new(:key => :bin,       :var => :PATH)
    register_prototype EnvVarPath.new(:key => :lib,       :var => :LD_LIBRARY_PATH)
    register_prototype EnvVarPath.new(:key => :include,   :var => :INCLUDE_PATH)
    register_prototype EnvVarPath.new(:key => 'lib/ruby', :var => :RUBYLIB)
    register_prototype EnvVarPath.new(:key => 'lib/perl', :var => :PERL5LIB)

  end # class

end # module


