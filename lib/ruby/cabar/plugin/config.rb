

Cabar::Plugin.new :name => 'cabar/config', :documentation => <<'DOC' do
Configuration support.
DOC

  require 'cabar/command/standard' # Standard command support.
  require 'cabar/facet/standard'   # Standard facets and support.

  ##################################################################
  # Configuration
  #

  cmd_group [ :config, :conf, :cf ] do
    cmd [ :show, :list, :ls ], <<'DOC' do

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


