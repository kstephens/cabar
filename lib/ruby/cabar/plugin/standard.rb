
Cabar::Plugin.new :name => 'cabar' do
  # Defaults to Facet::EnvVarPath
  facet :dummy, :var => :CABAR_DUMMY, :path => [ 'dummy' ]

  cmd_group :plugin do
    cmd :list, <<'DOC' do
NO-ARGS
Lists all plugins.
DOC
      print_header :plugin
      Cabar::Main.current.plugin_manager.plugins.each do | plugin |
        puts "    #{plugin.name}: "
        puts "      file:     #{plugin.file.inspect}"
        puts "      commands: #{plugin.commands.map{|x| x.name_full}.inspect}"
        puts "      facets:   #{plugin.facets.map{|x| x.key}.inspect}"
      end
    end
  end

  
end # plugin


