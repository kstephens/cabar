

Cabar::Plugin.new :name => 'cabar/perl', :documentation => 'Perl support.' do

  facet 'lib/perl', :env_var => :PERL5LIB, :inferrable => true

end # plugin


