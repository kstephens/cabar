

Cabar::Plugin.new :name => 'cabar/env', :documentation => 'Environment variable support.' do

  facet :env,     :class => Cabar::Facet::EnvVarGroup
  facet :env_var, :class => Cabar::Facet::EnvVar

  doc "[ --verbose | --selected ]
Lists the environment variables for required components
as a sourceable /bin/sh script.

Options:
  --verbose
  --selected - renders only the selected objects

Examples
  cbr env - ruby 
  cbr env - ruby --selected
  cbr env --selected -T
"
  cmd :env do
    selection.select_required = true
    selection.to_a
    
    r = Cabar::Renderer::ShellScript.new cmd_opts
    
    selection.render r
  end # cmd

end # plugin


