
Cabar::Plugin.new do
  facet :boc_locale_path, 
      :env_var => :BOC_LOCALE_PATH,
      :std_path => :locale
end
