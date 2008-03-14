

Cabar::Plugin.new :name => 'cabar/ruby', :documentation => <<'DOC' do
Support for Ruby.
DOC

  require 'cabar/command/standard' # Standard command support.
  require 'cabar/facet/standard'   # Standard facets and support.


  ##################################################################
  # Ruby library facet
  #

  facet 'lib/ruby', :var => :RUBYLIB, :inferrable => true

end # plugin


