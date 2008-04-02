

Cabar::Plugin.new :name => 'cabar/ruby', :documentation => <<'DOC' do
Support for Ruby.
DOC

  require 'cabar/command/standard' # Standard command support.
  require 'cabar/facet/standard'   # Standard facets and support.
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
    }

  cmd_group :ruby do
    cmd :rdoc, <<'DOC' do
Generate rdoc documentation for any components containing 'lib/ruby' facets.
DOC

      selection.select_required = true
      selection.to_a.each do | c |
        next unless f = c.facet('lib/ruby')
        next if f.rdoc_generate == false
        puts "component #{c}:"

        rdoc_dest = f.rdoc_directory || "gen/rdoc"
        rdoc_dest = File.expand_path(rdoc_dest, c.directory)

        cmd = "rdoc --all --show-hash --inline-source --line-numbers --title '#{c.name} #{c.version}' #{cmd_opts.map{|x| x.inspect}.join(' ')} -o #{rdoc_dest.inspect} #{f.abs_path.map{|x| x.inspect}.join(' ')}"

        puts "  rdoc_directory: #{rdoc_dest.inspect}"
        puts "  rdoc_command: #{cmd.inspect}"

        system cmd
      end
    end
  end

end # plugin


