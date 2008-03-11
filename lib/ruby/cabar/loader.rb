require 'cabar/base'

require 'cabar/configuration'
require 'cabar/component'


module Cabar
  class Loader < Base
    attr_accessor :context

    attr_reader :component_search_path
    attr_reader :component_directories
  
    attr_reader :available_components

    def initialize opts = EMPTY_HASH
      @component_search_path = [ ]
      @component_search_path_pending = [ ]
      @component_directories = [ ]
      @component_directories_pending = [ ]
      @component_parse_pending = [ ]
      super
    end

    def add_component_search_path! path
      if Array === path
        path.each { | x | add_component_search_path! x }
        return self
      end
      path = File.expand_path(path)
      return self if @component_search_path.include? path
      return self if @component_search_path_pending.include? path
      @component_search_path_pending << path
      self
    end

    def add_component_directory! path
      path = File.expand_path(path)
      return self if @component_directories.include? path
      return self if @component_directories_pending.include? path
      @component_directories_pending << path
      self
    end

    def load_components!
      # While there are still component paths to search.
      @component_search_path_pending.cabar_each! do | path |
        # $stderr.puts "search path #{path.inspect}"
        @component_search_path << path
        
        search_for_component_directories(path).each do | dir |
          add_component_directory! dir
        end

        # While there are still components to load.
        @component_directories_pending.cabar_each! do | dir |
          @component_directories << dir
          # $stderr.puts "  component dir #{dir.inspect}"
          
          comp = parse_component dir
        end

      end

      # Now that all components (and any plugins have been loaded),
      # the components can be fully configured.
      @component_parse_pending.cabar_each! do | c |
        c.parse_configuration!
        # $stderr.puts "component #{c.inspect}"
      end
      
      self
    end

    # Returns a list of all component directories.
    def search_for_component_directories *path
      # Find all */*/cabar.yml or */cabar.yml files.
      x = path.map do | p |
        [ "#{p}/*/*/cabar.yml", "#{p}/*/cabar.yml" ]
      end.cabar_flatten_return!
      
      # Glob matching.
      x.map! do | f |
        Dir[f]
      end.cabar_flatten_return!
      
      # Take the directories.
      x.map! do | f |
        File.dirname(f)
      end
      
      # Unique.
      x.cabar_uniq_return!
    end


    ##################################################################

    #
    # Returns a set of all availabe components
    # found through the component_directories search path.
    #
    def available_components
      unless @available_components
        @available_components = Cabar::Version::Set.new
        load_components!
      end

      @available_components
    end


    # Called when a component has been added.
    def add_available_component! c
      @available_components << c
      @component_parse_pending << c
    end


    # Helper method to create a Component.
    def create_component(opts)
      c = Component.factory.new opts
      c.context = @context
      c
    end

private

    def parse_component directory, conf_file = nil 
      conf_file ||= 
        File.join(directory, "cabar.yml")
      
      # $stderr.puts "loading #{conf_file}"

      conf = @context.configuration.read_config_file conf_file
      conf = conf['cabar']
      
      # Handle plugins.
      if plugin = conf['plugin']
        plugin = [ plugin ] unless Array === plugin
        plugin.each do | file |
          file = File.expand_path(file, directory) 
          # $stderr.puts "#{$0}: using plugin #{plugin}"
          require file
        end
      end
      
      # Handle components.
      unless comps = conf['component']
        raise Error, "does not have a component definition"
      end
      unless Hash === comps
        comps = { }
      end
      
      # Infer component name/version from directory.
      infer_component_name comps, directory

      if comps.size >= 2 && comps['name'] && comps['version']
        name = comps['name']
        comps.delete 'name'
        comps = { name => comps }
      end
      
      comps.each do | name, opts |
        # Overlay configuration.
        comp_config = @context.config['configure'] || EMPTY_HASH
        comp_config = comp_config[name] || EMPTY_HASH
        opts.cabar_merge! comp_config
        
        opts[:name] = name
        opts[:directory] = directory
        opts[:context] = self
        opts[:_config_file] = conf_file
        
        comp = create_component opts
        
        unless valid_string? comp.name
          raise Error, "component in #{directory.inspect} has no name" 
        end
        unless Version === comp.version
          raise Error, "component #{name.inspect} has no version #{comp.version.inspect}"
        end
        
        # Save config hash for later.
        comp._config = conf

        # Register component, if it's enabled.
        if comp.enabled?
          # $stderr.puts "enabled #{conf_file}"
          comp.parse_configuration_early!

          add_available_component! comp
        end

        comp
      end
    rescue Exception => err
      raise Error, "in #{conf_file.inspect}:\n  in #{self.class}:\n  #{err.inspect}\n  #{err.backtrace.join("\n  ")}"
      
    end
    
    def infer_component_name comps, directory
      # Infer component name/version from directory name.
      unless comps['name'] && comps['version']
        case directory
          # name/version
        when /\/([a-z_][^\/]*)[\/-]([0-9]+(\.[0-9])*)$/i
          comps['name'] ||= $1
          comps['version'] ||= $2
          # name
        when /\/([a-z_][^\/]*)$/i
          comps['name'] ||= $1
          comps['version'] ||= '0.1'
        else
          raise Error, "Cannot infer component name/version from directory"
        end
      end

    end


    def valid_string? str
      String === str && ! str.empty?
    end

    
  end # class

end # module

