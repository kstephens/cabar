

Cabar::Plugin.new :name => 'cabar/include', :documentation => <<'DOC' do
C includes support.
DOC

  require 'cabar/command/standard' # Standard command support.
  require 'cabar/facet/standard'   # Standard facets and support.

  ##################################################################
  # C include facet
  #

  facet :include, :env_var => :INCLUDE_PATH

end # plugin


