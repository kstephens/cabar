require 'cabar/base'

require 'cabar/context'


module Cabar
  # Manages a selection of Components based on command line options.
  #
  # Provide default standard cbr Command options.
  class Selection < Base
    # The Context object.
    attr_accessor :context

    # Command option Hash parsed by Command::Runner.
    attr_accessor :cmd_opts

    # Option: "- <<component-constraint>>"
    attr_accessor :select_constraint
    
    # Option: -T
    attr_accessor :select_top_level

    # Option: -A
    attr_accessor :select_available

    # Option: -R
    attr_accessor :select_required

    # Option: -D
    attr_accessor :select_dependencies

    # The required Component from select_constraint.
    attr_accessor :selected_component

    def initialize *args
      @selected_component = nil
      @select_constraint =
        @select_top_level =
        @select_available =
        @select_required =
        @select_dependencies = false
      super
    end


    # Parses command line options to determine how to 
    # select Components.
    def parse_cmd_opts!
#      puts "@cmd_opts = #{@cmd_opts.inspect}"

      if x = cmd_opts[:_]
        cmd_opts.delete(:_)
        @select_constraint = x
      end

      if x = cmd_opts[:T]
        @select_top_level = true
        @select_available = false
        @select_required = false
      end

      if x = cmd_opts[:A]
        @select_available = x
        @select_required = false
        @select_top_level = false
      end

      if x = cmd_opts[:R]
        @select_required = x
        @select_available = false
        @select_top_level = false
      end

      if x = cmd_opts[:D]
        @select_dependencies = x
      end

      self
    end
    
    # Returns a Constraint object for the '- component', --name=<<name>> or --version=<<version>> options.
    def component_constraint
      unless @component_constraint
        name = @select_constraint
        version = @cmd_opts[:version]
        
        component_constraint = { }
        component_constraint[:name] = name if name
        #          component_constraint[:name] ||= default if default
        component_constraint[:version] = version if version
        
        if component_constraint.empty?
          component_constraint = nil
        else
          component_constraint = Cabar::Constraint.create(component_constraint)
        end
        
        @component_constraint = [ component_constraint ]
      end
      @component_constraint.first
    end

    # Returns an Array representation of the selected Components.
    def to_a
      @to_a ||=
        begin
          parse_cmd_opts!
          
          @select_required = true if @select_top_level
          @select_available = true unless @select_required || @select_top_level

          if @verbose # || true
            $stderr.puts "to_a:"
            $stderr.puts "  @select_top_level = #{@select_top_level}"
            $stderr.puts "  @select_available = #{@select_available}"
            $stderr.puts "  @select_required = #{@select_required}"
            $stderr.puts "  @select_constraint = #{@select_constraint}"
            $stderr.puts "  @component_constraint = #{component_constraint}"
          end

          case 
          when @select_required
            s_o = component_constraint

            if s_o
              @selected_component = context.require_component s_o
            else
              context.apply_configuration_requires!
            end

            # Resolve configuration.
            context.resolve_components!
            
            # Validate configuration.
            context.validate_components!
            
            # Get the required components.
            if @select_top_level
              result = context.
                top_level_components.to_a
            else
              result = context.
                component_dependencies(context.required_components.to_a)
            end
          when @select_available
            result = context.available_components
            if component_constraint
              result = result.select(component_constraint)
            end
            result = result.to_a
            
            if @select_dependencies
              result = context.component_dependencies(result)
            else
              result = Component.sort(result)
            end
            
          else
            raise Error, "must be select_required or select_available"
          end
          
          result
        end
    end

  end # class

end # module


