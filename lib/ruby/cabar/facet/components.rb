require 'cabar/facet'

module Cabar
  class Facet

    # Represents a component that recursively contains other components.
    #
    # Cabar itself uses this Facet, to provide standard
    # software platform components, e.g.: Ruby, Perl and Rubygems.
    #
    # See cabar/comp in the source distribution.
    class Components < Path
      def component_associations
        @@component_associations ||=
          [ :provides ].freeze
      end

      # This Facet must be configured early, because
      # it affects the component search path and
      # loading of other components.
      def configure_early?
        true
      end

      # Addes its subcomponent directories to
      # the current Cabar::Loader.component_search_path,
      # thus forcing its components to become visible.
      # 
      # Cabar itself uses this Facet, to provide standard
      # software platform components, e.g.: Ruby, Perl and Rubygems.
      #
      # See cabar/comp in the source distribution.
      def attach_component! c
        super
        # $stderr.puts "adding component search path #{abs_path.inspect}"
        _loader.add_component_search_path! abs_path, :priority => :before
      end
    end # class

  end # class

end # module


require 'cabar/facet/required_component'


