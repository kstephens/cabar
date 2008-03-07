require 'cabar/base'
require 'cabar/error'


require 'cabar/version/requirement'
require 'yaml'
require 'erb'


module Cabar
  class Configuration < Base
    class Error < Cabar::Error; end

    # Path to search for component directories.
    attr_accessor :component_search_path

    # Path to search for configuration files.
    attr_accessor :config_file_path

    # The Context object.
    attr_accessor :context

    def initialize opts = EMPTY_HASH
      super
      self.config_file_path      = ENV['CABAR_CONFIG'] || '~/.cabar.yml'
      self.component_search_path = ENV['CABAR_PATH']   || '.'
    end
    
    # Applies this configuration to the Context.
    def apply_configuration! context
      by = "config@#{config['config_file_path'].inspect}"
      
      # Apply component selection.
      cfg = config
      cfg &&= cfg['select']
      cfg &&= cfg['component']
      cfg ||= EMPTY_HASH
      
      cfg.each do | name, opts |
        opts = normalize_component_options opts
        opts[:name] = name unless name.nil?
        opts[:_by] = by
        
        context.select_component opts
      end

      # Apply component requires.
      cfg = config
      cfg &&= cfg['require']
      cfg &&= cfg['component']
      cfg ||= EMPTY_HASH
      
      cfg.each do | name, opts |
        opts = normalize_component_options opts
        opts[:name] = name unless name.nil?
        opts[:_by] = by
        
        context.require_component opts
      end

      # Do plugin configurations.
      # plugin.each do | plugin |
      #  plugin.apply_context_configuration self
      # end
    end
    

    def normalize_component_options opts
      opts = opts.inject({ }) do | h, kv |
        k, v = *kv
        h[k.to_sym] = v
        h
      end
      case opts
      when nil, false
        opts = { :enabled => false }
      when true
        opts = { }
      when String, Float, Integer
        opts = { :version => opts }
      end
      
      opts[:version] = Cabar::Version::Requirement.create_cabar(opts[:version]) if opts[:version]
      
      opts
    end

    def component_search_path= x 
      case y = x
      when Array
      when String
        y = x.split(Cabar.path_sep)
      else
        raise ArgumentError, "expected Array or String"
      end

      @component_search_path = y.map { | p | File.expand_path(p) }.cabar_uniq_return!

      x
    end

    def config_file_path= x 
      case y = x
      when Array
      when String
        y = x.split(Cabar.path_sep)
      else
        raise ArgumentError, "Expected Array or String"
      end
      
      @config_file_path = y.map { | p | File.expand_path(p) }.cabar_uniq_return!
      
      # Flush caches:
      @config = nil
      
      x
    end
    
    # Returns the configuration Hash loaded from config_file_path.
    def config
      @config ||=
        begin
          cfg = nil
          
          config_file_path.reverse.select { | file | File.exists? file }.each do | file |
            begin
              y = read_config_file file
              validate_config_hash y
              cfg ||= { }
              cfg.cabar_merge!(y)
            rescue Exception => err
              pp err.backtrace
              raise Error, "Problem reading config file #{file.inspect}: #{err.inspect}"
            end
          end
          

          cfg ||= {
            'cabar' => {
              'version' => Cabar.version,
              'configuration' => {
              },
            },
          }

          validate_config_hash cfg
          @config_raw = cfg
          
          # pp cfg

          x = cfg['cabar']['configuration']      
          x['config_file_path'] = config_file_path
          x['component_search_path'] = component_search_path
          
          x
        end
    end
    
    def validate_config_hash cfg
      unless cfg['cabar']['configuration']
        raise Error, "configuration is not a Cabar configuration file"
      end
      cfg
    end


    # Returns the raw configuration hash.
    # See Cabar::Main.
    def config_raw
      config
      @config_raw
    end


    def read_config_file file
      cfg = nil
      File.open(file) do | fh |
        template = ERB.new fh.read
        fh = template.result binding
        cfg = YAML::load fh
        validate_yaml_hash cfg
      end
      cfg
    rescue Exception => err
      raise Error, "Problem reading config file #{file.inspect}: #{err.inspect}"
    end


    def validate_yaml_hash cfg
      unless Hash === cfg
        raise Error, "is not a Hash"
      end
      unless cfg = cfg['cabar']
        raise Error, "is not a Cabar file"
      end
      unless v = cfg['version']
        raise Error, "does not have a version"
      end
      v = cfg['version'] = Cabar::Version.create_cabar(v)
      unless v <= Cabar.version
        raise Error, "version #{v} is not supported, expected #{Cabar.version}"
      end

      cfg
    end

  end # class
end # module
