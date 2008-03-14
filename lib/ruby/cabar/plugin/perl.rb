

Cabar::Plugin.new :name => 'cabar/perl', :documentation => <<'DOC' do
Perl support.
DOC

  require 'cabar/command/standard' # Standard command support.
  require 'cabar/facet/standard'   # Standard facets and support.


  ##################################################################
  # Perl library facet
  #

  facet 'lib/perl', :var => :PERL5LIB, :inferrable => true

end # plugin


