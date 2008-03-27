

Cabar::Plugin.new :name => 'cabar/env', :documentation => <<'DOC' do
Environment variable support.
DOC

  require 'cabar/command/standard' # Standard command support.
  require 'cabar/facet/standard'   # Standard facets and support.

  ##################################################################
  # env facet
  #

  facet :env,     :class => Cabar::Facet::EnvVarGroup
  cmd :env, <<'DOC' do

Lists the environment variables for required components
as a sourceable /bin/sh script.
DOC
    selection.select_required = true
    selection.to_a
    
    r = Cabar::Renderer::ShellScript.new cmd_opts
    
    context.render r
  end # cmd

end # plugin


