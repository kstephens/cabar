require 'cabar/facet'


module Cabar
  class Facet

    # This represents group of commands that can be run on a component.
    #
    # action:
    #   name_1: cmd_1
    #   name_2: cmd_2
    #
    # run "cbr action list".
    class Action < self
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

      def execute_action! action, args
        expr = @action[action.to_s] || raise("cannot find action #{action.inspect}")
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
           [ :action, action ],
          ]
      end
    end # class


    # This represents a set of environment variables.
    #
    #   facet:
    #     env_var:
    #       NAME1: v1
    #       NAME2: v2
    class EnvVarGroup < self
      attr_accessor :vars

      def _reformat_options! opts
        opts = { :vars => opts }
        opts
      end

      def compose_facet! facet
        self
      end

      # Creates individual EnvVar facets for each
      # key/value pair in the option Hash.
      def attach_component! c
        vars.each do | n, v |
          c.create_facet(:env_var, :var => n, :value => v)
        end
      end
    end # class

    def is_env_var?
      false
    end


    # A basic environment variable facet.
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
      end

      def to_a
        super +
          [
           [ :var, var ],
           [ :value, value ],
          ]
      end
    end


    # A facet that represents a directory search path.
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

      def inferred?
        # result = 
          abs_path.all? { | x | File.exist? x }
        # $stderr.puts "inferred? #{abs_path.inspect} => #{result}"
        # result
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


    # Represents a component that recursively contains other components.
    #
    # Cabar itself uses this Facet, to provide standard
    # software platform components, e.g.: Ruby, Perl and Rubygems.
    #
    # See cabar/comp in the source distribution.
    class Components < Path
      def component_associations
        [ 'provides' ]
      end

      def configure_early?
        true
      end

      # Addes its subcomponent directories to
      # the current Cabar::Loader.component_search_path,
      # thus forcing its components to become visible.
      # 
      # Cabar itself uses this Facet, to provide standard
      # software platform components, e.g.: Ruby, Perl and Rubygems.
      #
      # See cabar/comp in the source distribution.
      def attach_component! c
        super
        # $stderr.puts "adding component search path #{abs_path.inspect}"
        c.context.loader.add_component_search_path! abs_path
      end
    end # class


    # A Facet that can compose an environment variable
    # from paths in many components.
    # Used for composing PATH, RUBYLIB, PERL5LIB
    # environment variables to reintegrate modules
    # and programs.
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
        x = super
        x[2, 0] = [ [ :var, var ] ]
        x
      end
    end

  end # class

end # module



require 'cabar/facet/required_component'


