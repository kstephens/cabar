

Cabar::Plugin.new :name => 'cabar/lib', :documentation => 'C library support.' do

  facet :lib, :env_var => :LD_LIBRARY_PATH, :inferrable => false

end # plugin


