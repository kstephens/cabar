require 'cabar/base'
require 'cabar/error'


require 'cabar/version/requirement'
require 'cabar/command/runner'
require 'yaml'
require 'erb'


module Cabar
  # Configuration file processor.
  #
  # Cabar configuration files are YAML documents that can be overlayed
  # from multiple yaml files.
  #
  # The CABAR_CONFIG environment variable specifies a list of
  # cabar_config.yml documents that are parsed and overlayed.
  # The default is "~/.cabar_conf.yml".
  #
  # /etc/cabar/host-<<hostname>>-conf.yml and /etc/cabar/default.yml are
  # implied at the end of CABAR_CONFIG for host and site-wide configuration.
  #
  # The CABAR_PATH environment variable specifies the list of 
  # component repositories to search for components.
  #
  # Cabar configurations can specify overrides for:
  #
  # * component selection
  # * top-level component requires
  # * component options.
  # * plugin configuration.
  #
  # Use -C config.path.to.element=value,... to override configuration
  # from the command line.
  #
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
      self.config_file_path      = ENV['CABAR_CONFIG'] || '~/.cabar_conf.yml'
      self.component_search_path = ENV['CABAR_PATH']   || '.'

      Cabar::Command::Runner.add_observer(self, :command_parse_args_after)
    end
    
    # Take -C command opts from sender.
    def command_parse_args_after sender, action
      @cmd_line_overlay ||= { }
      opts = sender.state.cmd_opts

      # $stderr.puts "opts = #{opts.inspect}"

      if c_opt = opts[:C]
        opts.delete(:C)

        c_opt.scan(/([^\s=]+)=([^,]+)/) do
          path, value = $1, $2
          path = path.split(/[\.:\/]/)

          key = path.pop
          path.inject(@cmd_line_overlay) { | h, k |
            h = h[k] ||= { } 
            h
          }[key] = str_to_value(value)
        end
      end
      
      if @config
        config.cabar_merge!(@cmd_line_overlay)
      end

      self
    end

    def str_to_value str
      case str
      when 'true'
        str = true
      when 'false'
        str = false
      when '~', 'nil'
        str = nil
      else
        str
      end
    end

    # Applies the component selection configuration to the Context.
    #
    def apply_configuration! context
      by = "config@#{config['config_file_path'].inspect}"
      
      # Apply component selection.
      cfg = nil
      cfg ||= config['component']['select'] rescue nil
      cfg ||= EMPTY_HASH
      
      cfg.each do | name, opts |
        opts = normalize_component_options opts
        opts[:name] = name unless name.nil?
        opts[:_by] = by
        
        context.select_component opts
      end


      # Do plugin configurations.
      # plugin.each do | plugin |
      #  plugin.apply_configuration self
      # end
    end

    # Applies the compnent requires configuration to the Context.
    def apply_configuration_requires! context
      by = "config@#{config['config_file_path'].inspect}"

      # Apply component requires.
      cfg = nil
      cfg ||= config['component']['require'] rescue nil
      cfg ||= EMPTY_HASH
      
      cfg.each do | name, opts |
        opts = normalize_component_options opts
        opts[:name] = name unless name.nil?
        opts[:_by] = by
        
        context.require_component opts
      end
    end

    
    DISABLED_HASH = { :enabled => false }.freeze

    def normalize_component_options opts
      case opts
      when nil, false
        opts = DISABLED_HASH
      when true
        opts = EMPTY_HASH
      when String, Float, Integer
        opts = { :version => opts }
      end
      
      # Convert String keys to Symbols.
      opts = opts.inject({ }) do | h, kv |
        k, v = *kv
        h[k.to_sym] = v
        h
      end

      opts[:version] = Cabar::Version::Requirement.create_cabar(opts[:version]) if opts[:version]
      
      opts
    end

    def component_search_path= x 
      case y = x
      when Array
      when String
        y = Cabar.path_split(x)
      else
        raise ArgumentError, "expected Array or String"
      end

      @component_search_path = Cabar.path_expand(y)

      x
    end

    def config_file_path= x 
      case y = x
      when Array
        y = y.dup
      when String
        y = Cabar.path_split(x)
      else
        raise ArgumentError, "Expected Array or String"
      end
      
      y << "/etc/cabar/host-#{Cabar.hostname}.yml"
      y << "/etc/cabar/default.yml"

      @config_file_path = Cabar.path_expand(y)
      
      # Flush caches:
      @config = nil
      
      x
    end
    
    # Returns the configuration Hash overlayed from all YAML documents
    # listed in config_file_path.
    def config
      @config ||=
        begin
          cfg = nil
          
          config_file_path.reverse.select { | file | File.exists? file }.each do | file |
            cfg = read_config_file_with_includes file, cfg
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
          x['config_file_path'] ||= config_file_path
          
          # Overlay command line -C=opt=value
          x.cabar_merge!(@cmd_line_overlay || EMPTY_HASH)

          if x['component_search_path']
            self.component_search_path = x['component_search_path']
          end

          x['component_search_path'] ||= component_search_path
          
          x
        end
    end
    
    # Validates a cabar configuration hash.
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


    def read_config_file_with_includes file, cfg = nil, visited = { }
      cfg ||= { }

      file = File.expand_path(file)
      return cfg if visited[file]
      visited[file] = 1

      _logger.info "config: loading #{file.inspect}"

      y = read_config_file file
      validate_config_hash y

      # Check to see if this config is enabled.
      conf = y['cabar']['configuration'] 
      return cfg if conf['enabled'] == false

      # Handle deprecated formats.
      if old_format = ((x = conf['select']) && x['component'])
        _logger.warn "config: in #{file}: use component: select: ..., instead of select: component: ..."
        (conf['component'] ||= { })['select'] = old_format
        x.delete('component')
      end
      
      # Handle deprecated formats.
      if old_format = ((x = conf['require']) && x['component'])
        _logger.warn "config: in #{file}: use component: require: ..., instead of require: component: ..."
        (conf['component'] ||= { })['require'] = old_format
        x.delete('component')
      end

      # Handle includes first.
      include = y['cabar']['configuration']['include']
      include = [ include ] unless Array === include
      include.compact.each do | inc_file |
        # Include files are relative to source.
        inc_file = File.expand_path(inc_file, File.dirname(file))
        cfg = read_config_file_with_includes inc_file, cfg, visited
      end

      # Overlay file.
      cfg.cabar_merge!(y)
      
      # Handle environment variables.
      env = y['cabar']['configuration']['env_var'] || EMPTY_HASH
      env.each do | k, v |
        ENV[k] = v
      end

      _logger.info "config: loading #{file.inspect}: DONE"

      cfg
    rescue Exception => err
      raise Error, "Problem reading config file #{file.inspect}: #{err.inspect}"
    end

    # Read a YAML file after processing it as a ERB template.
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


    # Validate a cabar Hash.
    def validate_yaml_hash cfg, supported_version = nil
      supported_version ||= Cabar.version
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
      unless v <= supported_version
        raise Error, "version #{v} is not supported, expected #{supported_version}"
      end

      cfg
    end

  end # class
end # module

