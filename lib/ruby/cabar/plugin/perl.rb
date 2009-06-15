

Cabar::Plugin.new :name => 'cabar/perl', :documentation => <<'DOC' do
Perl support.
DOC

  ##################################################################
  # Perl library facet
  #

  facet 'lib/perl', :env_var => :PERL5LIB, :inferrable => true

end # plugin


