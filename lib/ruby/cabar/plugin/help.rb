

Cabar::Plugin.new :name => 'cabar/help' do

  require 'cabar/command/standard' # Standard command support.
  require 'cabar/facet/standard'   # Standard facets and support.

  ##################################################################
  # help
  #

  cmd :help, <<'DOC' do
[ --verbose ] [ <command> ]
Lists all commands or help for a specific command.
DOC
    # puts "cmd_args = #{cmd_args.inspect}"
    opts = cmd_opts.dup
    opts[:path] = cmd_args.empty? ? nil : cmd_args.dup

    print_header
    if error = opts[:error]
      puts "  error: #{error.to_s.inspect}"
    end
    puts "  command:"

    main.commands.visit_commands(opts) do | cmd, opts |
      if opts[:path]
        next unless cmd === opts[:path]
      end
      
      x = opts[:indent]
      if opts[:verbose]
        puts "#{x}#{cmd.name}:"
        x = opts[:indent] << '  '
        puts "#{x}aliases:    #{cmd.aliases.inspect}" unless cmd.aliases.empty?
        puts "#{x}synopsis:   #{cmd.synopsis.inspect}"
        puts "#{x}documentation: |"
        puts "#{x}  #{cmd.documentation_lines[1 .. -1].join("\n#{x}  ")}"
        puts "#{x}               |"
        puts "#{x}defined_in: #{cmd._defined_in.to_s.inspect}"
        puts "#{x}subcommands:" unless cmd.subcommands.empty?
      else
        key = "#{x}#{'%-10s' % (cmd.name + ':')}"
        if cmd.subcommands.empty?
          puts "#{key} #{cmd.description.inspect}"
        else
          puts "#{key}"
          puts "  #{x}#{'%-10s' % ':desc:'}   #{cmd.description.inspect}"
        end
        
        unless cmd.aliases.empty?
          puts "  #{x}#{'%-10s' % ':alias:'}  #{cmd.aliases.sort.inspect}"
        end
      end

    end # cmd

  end # cmd_group
  
end # plugin


