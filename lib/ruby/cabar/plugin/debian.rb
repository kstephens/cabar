


Cabar::Plugin.new :name => 'cabar/debian', 
  :enabled => false, 
  :documentation => <<'DOC' do
Debian package support.
DOC

  require 'cabar/debian'

  DEB_STR = 'deb'.freeze

  def debian_available_components(loader = nil)
    unless @debian_components
      @debian_components = [ ]

      _logger.info "Parsing Debian packages: ", :write => true
      dpkgs = Cabar::Debian.debian_parse_dpkg_file

      dpkgs.each do | dpkg |
        name = dpkg[:Package] || raise("Cannot get debian name")
        opts = {
          :name => name,
          :version => dpkg[:Version],
          :component_type => DEB_STR,
          :debian_detail => dpkg,
        }

        c = loader.create_component(opts)
        c.debian_dependencies

        @debian_components << c
      end

      _logger.info "#{@debian_components.size}", :prefix => false
    end

    @debian_components
  end


  # Provide Debian components.
  def after_load_components! loader, args
    debs = debian_available_components(loader)

    _logger.info "Adding available Debian packages to context: ", :write => true

    debs.each do | c |
      loader.add_available_component! c
      _logger.debug :".", :write => true, :prefix => false
    end

    _logger.info " #{debs.size}", :prefix => false
  end
  
  # Callback after other components have been loaded.
  Cabar::Loader.add_observer(self, :after_load_components!, :after_load_components!)

  class Cabar::Component
    # Hash containing the raw detail about the Debian package.
    attr_accessor :debian_detail

    def debian_dependencies
      unless @debian_dependencies
        @debian_dependencies = [ ]

        _logger.debug2 do
          "  debian_dependencies #{name}/#{version} =>"
        end

        if deps = @debian_detail[:Depends]
          deps.scan(/(\S+)\s+[(]([^\)]+)[)],?/) do
            name, version = $1, $2

            _logger.debug2 do
              "   #{name.inspect} #{version.inspect}"
            end

            f = create_facet :required_component, 
              :name => name,
              :component_type => DEB_STR,
              :version => version
            
            @debian_dependencies << f
          end
        end

        _logger.debug2 :" ", :prefix => false
      end

      @debian_dependencies
    end

  end

end
