


Cabar::Plugin.new :name => 'cabar/debian', 
  :enabled => false, 
  :documentation => <<'DOC' do
Debian package support.
DOC

  require 'cabar/command/standard' # Standard command support.
  require 'cabar/facet/standard'   # Standard facets and support.

  require 'cabar/debian'

  DEB_STR = 'deb'.freeze

  def debian_available_components(loader = nil)
    unless @debian_components
      @debian_components = [ ]

      $stderr.write "Parsing Debian packages: "; $stderr.flush
      dpkgs = Cabar::Debian.debian_parse_dpkg_file

      dpkgs.each do | dpkg |
        name = dpkg[:Package] || raise("Cannot get debian name")
        opts = {
          :name => "#{DEB_STR}:#{name}",
          :debian_name => name,
          :version => dpkg[:Version],
          :component_type => DEB_STR,
          :debian_detail => dpkg,
        }
        # $stderr.write "."; $stderr.flush

        c = opts
        c = loader.create_component(opts)
        c.debian_dependencies

        @debian_components << c
      end

      $stderr.puts ": #{@debian_components.size}"
    end

    @debian_components
  end


  # Provide Debian components.
  def after_load_components! loader, args
    # $stderr.puts "loader = #{loader}, args = #{args.inspect}"
    debs = debian_available_components(loader)
    debs.each do | c |
      loader.add_available_component! c
      # $stderr.write '.'; $stderr.flush
    end
    # $stderr.puts "added #{debs.size}"
  end
  
  # Callback after other components have been loaded.
  Cabar::Loader.add_observer(self, :after_load_components!, :after_load_components!)

  class Cabar::Component
    attr_accessor :debian_detail

    def debian_dependencies
      unless @debian_dependencies
        @debian_dependencies = [ ]

        # $stderr.puts "  debian_dependencies #{self.name}:" 

        if deps = @debian_detail[:Depends]
          deps.scan(/(\S+)\s+[(]([^\)]+)[)],?/) do
            name, version = $1, $2
            $stderr.puts "    #{name.inspect} #{version.inspect}"
            
            f = create_facet :required_component, 
              :name => "#{DEB_STR}:#{name}",
              :debian_name => name,
              :component_type => DEB_STR,
              :version => version
            
            @debian_dependencies << f
          end
        end
      end

      @debian_dependencies
    end

  end

end
