

Cabar::Plugin.new :name => 'cabar/config', :documentation => 'Configuration support.' do

  cmd_group [ :config, :conf, :cfg ] do
    doc "
Show current configuration.
"
    cmd [ :show, :list ] do
      puts main.configuration.config_raw.to_yaml
    end

  end # cmd_group


  class Cabar::Version
    # MOVE ME!
    def to_yaml( opts = {} )
      YAML.quick_emit( nil, opts ) do |out|
        out.scalar(nil, self.to_s, :quote2)
      end
    end
  end # class

  class Cabar::Version::Requirement
    # MOVE ME!
    def to_yaml( opts = {} )
      YAML.quick_emit( nil, opts ) do |out|
        out.scalar(nil, self.to_s, :quote2)
      end
    end
  end # class

end # plugin


