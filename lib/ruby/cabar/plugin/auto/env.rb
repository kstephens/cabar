

Cabar::Plugin.new :name => 'cabar/env', :documentation => 'Environment variable support.' do

  facet :env_var, :class => Cabar::Facet::EnvVarGroup
  facet :env_var_instance, :class => Cabar::Facet::EnvVar

  doc "[ --verbose, --selected, --ruby, --shell ]
Lists the environment variables for required components
as a sourceable /bin/sh script.

Options:
  --verbose
  --selected - renders only the selected objects
  --ruby     - renders result as a Ruby script on ENV.
  --shell    - renders result as a /bin/sh script.

Examples
  cbr env - cabar 
  cbr env - cabar --selected
  cbr env --selected -T
  cbr env - cabar --ruby
"
  cmd :env do
    selection.select_required = true
    selection.to_a
    
    case 
    when cmd_opts[:ruby]
      r = Cabar::Renderer::RubyScript
    else
      r = Cabar::Renderer::ShellScript
    end
    r = r.new cmd_opts
    
    selection.render r
  end # cmd

end # plugin


