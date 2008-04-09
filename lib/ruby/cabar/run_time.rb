require 'cabar'
require 'cabar/base'

require 'cabar/array'
require 'cabar/hash'
require 'cabar/version'


module Cabar
  # Provides a run-time interface to the current Cabar::Context.
  class RunTime < Base
    attr_reader :component_by_name

    def self.current
      @@current ||= Runtime.factory.new
    end
    def self.current= x
      @@current = x
    end

    def initialize opts = EMPTY_HASH
      @component_by_name = { }
      super
    end

    
    # Returns a component by name.
    def component name
      name = name.to_s
      required_components
      @component_by_name[name] || raise(Cabar::Error, "Cannot find component named #{name.inspect}")
    end


    # Returns all the required components for the current environment.
    def required_components
      @required_components ||= 
        begin
          @required_components = [ ]
          ENV['CABAR_REQUIRED_COMPONENTS'].split(/\s+/).each do | c_name |
            c = @component_by_name[c_name] ||= Component.new(:name => c_name).initialize_from_env_var!
            @required_components << c
          end
          @required_components
        end
    end


    # Returns all the top-level component.
    def top_level_components
      @top_level_components ||=
        begin
          required_components
          @top_level_components = [ ]
          ENV['CABAR_TOP_LEVEL_COMPONENTS'].split(/\s+/).each do | c_name |
            c = @component_by_name[c_name] || raise Cabar::Error, "Cannot find component #{c_name.inspect}"
            @top_level_components << c
          end
          @top_level_components
        end
    end

    # Simple lightweight standin for Cabar::Component.
    class Component < Base
      attr_accessor :name
      attr_accessor_type :version, Cabar::Version
      attr_accessor :component_type
      attr_accessor :directory
      attr_accessor :base_directory
      attr_reader :env
      
      def initialize_from_env_vars!
        @env = { }
        ENV.each do | k, v |
          if /^CABAR_(.+)_([A-Z].*)/.match(k) 
            @env[$1] = v
          end
        end
        
        self.version = ENV["CABAR_#{@name}_VERSION"]
        self.directory = ENV["CABAR_#{@name}_DIRECTORY"]
        self.base_directory = ENV["CABAR_#{@name}_BASE_DIRECTORY"]
        
      end
    end
    
  end # class


end # module

