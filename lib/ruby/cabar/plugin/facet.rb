

Cabar::Plugin.new :name => 'cabar/facet' do

  require 'cabar/command/standard' # Standard command support.
  require 'cabar/facet/standard'   # Standard facets and support.
  
  ##################################################################
  # Facet
  #

  cmd_group :facet do
    cmd :list, <<'DOC' do
[ --verbose ] [ name ]
List avaliable facets.
DOC
      facets = Cabar::Facet.prototypes
      yaml_renderer.render(facets.to_a, :prototype => true)
    end
  end # cmd_group

end # plugin


