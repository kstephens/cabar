

Cabar::Plugin.new :name => 'cabar/ruby', :documentation => <<'DOC' do
Support for Ruby.
DOC

  require 'fileutils'

  ##################################################################
  # Ruby library facet
  #

  facet 'lib/ruby', 
    :env_var => :RUBYLIB, 
    :inferrable => true,
    :arch_dir => lambda { | facet |
      # Get the arch_dir 
      ruby_comp =
        facet.
        context.
        required_components['ruby']
      ruby_comp &&= ruby_comp.size == 1 && ruby_comp.first
      # $stderr.puts "ruby_comp = #{ruby_comp}"
      arch = ruby_comp && ruby_comp.ruby['arch']
      # $stderr.puts "arch = #{arch.inspect}"
      arch
    },
    :standard_path_proc => lambda { | facet |
      # Get the standard ruby load_path. 
      ruby_comp =
        facet.
        context.
        required_components['ruby']
      ruby_comp &&= ruby_comp.size == 1 && ruby_comp.first
      # $stderr.puts "ruby_comp = #{ruby_comp}"
      path = ruby_comp && ruby_comp.ruby['load_path']
      # $stderr.puts "path = #{path.inspect}"
      path &&= path.map{|x| x =~ /^\./ ? x : File.expand_path(x) } 
      # $stderr.puts "  path = #{path.inspect}"
      path
   }


  cmd_group :ruby do
    cmd :rdoc, <<"DOC" do
[ --rdoc-directory=<dir> ]
Generate rdoc documentation for components with lib/ruby facet.

Facet/command options:

* rdoc_directory: defaults to "gen/rdoc".
* rdoc_generate: if false, rdoc is not run on the component's lib/ruby paths.
DOC
      #'emacs

      selection.select_required = true
      selection.to_a.each do | c |
        next unless f = c.facet('lib/ruby')
        next if f.rdoc_generate == false

        # Options
        rdoc_dest = cmd_opts[:rdoc_directory] || f.rdoc_directory || "gen/rdoc"
        rdoc_dest = File.expand_path(rdoc_dest, c.directory)
        cmd = cmd_opts[:rdoc_command] || f.rdoc_command || "rdoc --all --show-hash --inline-source --line-numbers "

        # Command line.
        cmd = "#{cmd}--title '#{c.name} #{c.version}' #{cmd_opts.map{|x| x.inspect}.join(' ')} -o #{rdoc_dest.inspect} #{f.abs_path.map{|x| x.inspect}.join(' ')}"

        # Output.
        puts "component #{c}:"
        puts "  rdoc_directory: #{rdoc_dest.inspect}"
        puts "  rdoc_command: #{cmd.inspect}"

        # Execute.
        system cmd
      end
    end
  end

end # plugin


