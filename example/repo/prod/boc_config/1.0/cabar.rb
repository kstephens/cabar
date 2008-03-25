Cabar::Plugin.new do
  facet :boc_config_path, 
      :env_var => :BOC_CONFIG_PATH,
      :std_path => :etc
end

