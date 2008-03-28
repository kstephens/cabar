

Cabar::Plugin.new :name => 'cabar/ruby', :documentation => <<'DOC' do
Support for Ruby.
DOC

  require 'cabar/command/standard' # Standard command support.
  require 'cabar/facet/standard'   # Standard facets and support.


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

end # plugin


