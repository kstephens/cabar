

Cabar::Plugin.new :name => 'cabar/lib', :documentation => <<'DOC' do
C library support.
DOC

  ##################################################################
  # C lib facet
  #

  facet :lib, :env_var => :LD_LIBRARY_PATH, :inferrable => false

end # plugin


