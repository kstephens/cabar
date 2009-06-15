

Cabar::Plugin.new :name => 'cabar/config', :documentation => <<'DOC' do
Configuration support.
DOC

  ##################################################################
  # Configuration
  #

  cmd_group [ :config, :conf, :cfg ] do
    cmd [ :show, :list ], <<'DOC' do

Show current configuration.
DOC
      puts context.configuration.config_raw.to_yaml
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


