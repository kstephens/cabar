require 'cabar/facet'


module Cabar
  class Facet

    # A facet that represents a directory search path.
    #
    # If env_var is set,
    # it can be compose an environment variable
    # from paths in many components.
    #
    # Used for composing PATH, RUBYLIB, PERL5LIB
    # environment variables to reintegrate modules
    # and programs.
    class Path < self
      # The standard path for instances of this Facet prototype.
      # Defaults to the Facet's key.
      attr_accessor :std_path

      # The array of paths relative to the Component's base_directory.
      attr_accessor :path

      # A Proc that returns an array of paths relative to the Component's
      # base_directory.  This proc is called by #path if path 
      # is not set.
      attr_accessor :path_proc
     
      # The absolute path names for each element in path.
      attr_accessor :abs_path

      # The environment variable associated with this Facet.
      # If set, is_env_var? is true and
      # this Facet is composable in Resolver#compose_facets.
      attr_accessor :env_var

      # If set, the generated abs_path will
      # have [ x, "#{x}/#{arch_dir}" ] for
      # each element x in path.
      attr_accessor :arch_dir

      # If set, the default is used to initialize
      # the default of the environment variable during
      # processing.
      attr_accessor :standard_value

      # If set, the default is used to initialize
      # the default value from a path.
      attr_accessor :standard_path

      # If set, the Proc is called to default the
      # default value during composition.
      attr_accessor :standard_path_proc


      def _reformat_options! opts
        opts = super
        opts = opts.split(Cabar.path_sep) if String === opts
        opts = { :path => opts } if Array === opts
        opts
      end


      COMPONENT_ASSOCIATIONS = [ 'provides' ].freeze
      COMPONENT_ASSOCIATIONS_ENV_VAR = [ 'provides', 'environment' ].freeze
      def component_associations
        if is_env_var?
          COMPONENT_ASSOCIATIONS_ENV_VAR
        else
          COMPONENT_ASSOCIATIONS
        end
      end

      def env_var= x
        @env_var = x && x.to_s
        x
      end

      def is_env_var?
        ! ! @env_var
      end

      def deepen_dup!
        super
        @path = @path.dup rescue @path
        @abs_path = @abs_path.dup rescue @abs_path
        @default_path = @default_path.dup rescue @default_path
        @default_value = @default_value.dup rescue @default_value
      end

      # Returns std_path or the Facet prototype key.
      def default_path
        [ (std_path || key).to_s ]
      end

      # This Facet is inferred if each element in abs_path
      # exists on the file system.
      #
      # FIXME???: make this work if x is a directory.
      #
      def inferred?
        p = abs_path
        p && p.all? { | x | File.exist? x }
      end

      # Returns the path.
      # If not set, path_proc or default_path is used
      # to default.
      def path
        @path ||= 
          (@path_proc && @path_proc.call(self)) || 
          default_path
      end

      # Returns the architecture-specific subdirectory.
      # If arch_dir is a Proc, it is called with self.
      #
      # See cabar/plugin/ruby.rb for an example.
      def arch_dir_value
        case @arch_dir
        when Proc
          @arch_dir.call(self)
        else
          @arch_dir
        end
      end

      def uncache_abs_path!
        @abs_path = nil
      end

      # Calculates the absolute path of each element in path.
      # arch_dir subdirectories are interpolated on each element, if
      # they exist.
      def abs_path
        @abs_path ||= 
        owner &&
        begin
          @abs_path = EMPTY_ARRAY # recursion lock.

          x = path.map { | dir | File.expand_path(expand_string(dir), owner.base_directory) }

          arch_dir = arch_dir_value
          if arch_dir
            # arch_dir = [ arch_dir ] unless Array === arch_dir
            x.map! do | dir |
              if File.directory?(dir_arch = File.join(dir, arch_dir))
                dir = [ dir, dir_arch ]
                # $stderr.puts "  arch_dir: dir = #{dir.inspect}"
              end
              dir
            end
            x.flatten!
            # $stderr.puts "  arch_dir: x = #{x.inspect}"
          end

          @abs_path = x
        end
      end

      # FIXME: This should be refactored to the render as
      # render_Path.
      def render r
        if is_env_var?
          r.setenv(env_var, uniq_lastmost(abs_path).join(r.path_sep))
        end
      end

      # Returns abs_path joined with the standard path separator.
      def value
        uniq_lastmost(abs_path).join(Cabar.path_sep)
      end

      # Returns the standard value for this environment var by
      # expanding default_path 
      def standard_value
        @standard_value ||=
          (x = standard_path) && 
          uniq_lastmost(x.map{|x| File.expand_path(x, base_directory)}).
          join(Cabar.path_sep)
      end

      def standard_path
        @standard_path ||=
          begin
            @standard_path = EMPTY_ARRAY
            x = @standard_path_proc && @standard_path_proc.call(self)
            x = x.split(Cabar.path_sep) if String === x
            x || EMPTY_ARRAY
          end
      end

      # This will append the other Facet's abs_path to this
      # Facet's abs_path uniquely.
      def compose_facet! facet
        # At this time: arch_path usage in abs_path should be resolvable.
        # facet.uncache_abs_path!
        @abs_path = uniq_lastmost(abs_path + facet.abs_path)
=begin
        if @key == 'lib/ruby'
          $stderr.puts "  compose_facet! #{@key.inspect}"
          $stderr.puts "    from = #{facet.owner}\n    abs_path = #{facet.abs_path.inspect}"
          $stderr.puts "    to   = #{@owner}\n    abs_path = #{@abs_path.inspect}"
        end
=end
        self 
      end

      def to_s
        "#<#{self.class} #{key.inspect} #{env_var.inspect} #{path.inspect}>"
      end

      def inspect
        to_s
      end
 
      def to_a
        x = super
        x.push [ :env_var, env_var ] if env_var
        x.push [ :path, path ]
        x.push [ :abs_path, abs_path ]
        x
      end

    end # class

  end # class

end # module


