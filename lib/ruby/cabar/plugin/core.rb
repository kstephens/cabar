

Cabar::Plugin.new :name => 'cabar/core', :documentation => 'Cabar Core Plugin.' do

  facet :required_component, 
    :class => Cabar::Facet::RequiredComponent
  
  facet :components, 
    :class => Cabar::Facet::Components,
    :path => [ 'comp' ],
    :inferrable => true

end # plugin

