

Cabar::Plugin.new :name => 'cabar/lib', :documentation => <<'DOC' do
C library support.
DOC

  require 'cabar/command/standard' # Standard command support.
  require 'cabar/facet/standard'   # Standard facets and support.

  ##################################################################
  # C lib facet
  #

  facet :lib, :env_var => :LD_LIBRARY_PATH, :inferrable => false

end # plugin


