

Cabar::Plugin.new :name => 'cabar/bin', :documentation => 'Support for bin/ and $PATH' do

  ##################################################################
  # bin facet
  #

  facet :bin, :env_var => :PATH, :inferrable => true

  cmd_group :bin do
    doc "<prog> <prog-args> ....
Runs <prog> in the environment of the top-level component."
    cmd [ :run, :exec ] do
      selection.select_required = true
      selection.to_a
      
      setup_environment!
      
      exec_program *cmd_args
    end # cmd
    
    doc "[ <prog> ] 
Lists all bin programs.

<prog> defaults to '*'"
    cmd [ :list, :ls ] do
      prog = cmd_args.shift || '*'
      selection.select_required = true

      print_header :bin
      selection.to_a.each do | c |
        if f = c.facet(:bin)
          list_only = f.list_only
          list_only &&= list_only.map{|x| x.to_s}
          cmds = f.abs_path.
            map { |x| "#{x}/#{prog}"}.
            map { |x| Dir[x]}.flatten.sort.
            select { |x| ! list_only  or list_only.include?(File.basename(x)) }.
            select { |x| File.executable? x}
          unless cmds.empty?
            puts "    #{c.to_s}: "
            cmds.each do | f |
              file = `file #{f.inspect}`.chomp
              file = file.split(': ', 2)
              puts "      #{file[0]}: #{file[1].inspect}"
            end
          end
          
        end
      end
    end # cmd

  end # cmd_group

end # plugin

