

Cabar::Plugin.new :name => 'cabar/include', :documentation => <<'DOC' do
C includes support.
DOC

  ##################################################################
  # C include facet
  #

  facet :include, :env_var => :INCLUDE_PATH

end # plugin


