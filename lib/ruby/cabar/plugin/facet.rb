

Cabar::Plugin.new :name => 'cabar/facet' do

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


