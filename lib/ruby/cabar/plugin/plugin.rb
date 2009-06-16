

Cabar::Plugin.new :name => 'cabar/plugin' do

  cmd_group :plugin do
    doc "[ name ]
List plugins."
    cmd :list do
      name = cmd_args.shift

      print_header :plugin
      Cabar::Main.current.plugin_manager.plugins.each do | plugin |
        if name && ! (name === plugin.name)
          next
        end

        puts "    #{plugin.name}: "
        if plugin.documentation
          puts "      documentation: |"
          puts "        #{plugin.documentation}"
          puts "                     |"
        end
        puts "      component: #{plugin.component.to_s.inspect}"
        puts "      file:      #{plugin.file.inspect}"
        puts "      commands:  #{plugin.commands.map{|x| x.name_full}.inspect}"
        puts "      facets:    #{plugin.facets.map{|x| x.key}.inspect}"
        puts ""
      end

    end # cmd

  end # cmd_group

end # plugin


