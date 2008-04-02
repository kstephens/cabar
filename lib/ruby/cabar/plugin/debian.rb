


Cabar::Plugin.new :name => 'cabar/debian', :enabled => false, :documentation => <<'DOC' do
Debian package support.
DOC

  require 'cabar/command/standard' # Standard command support.
  require 'cabar/facet/standard'   # Standard facets and support.

  DEB_STR = 'deb'.freeze

  def debian_available_components(loader = nil)
    unless @debian_components
      @debian_components = [ ]
      lines = `dpkg -l`
      lines = lines.split("\n")
      lines = lines[5 .. -1]
      lines.each do | line |
        # $stderr.puts "line = #{line.inspect}"
        status, name, version, description = line.split(/\s+/, 4)
        opts = {
          :name => "#{DEB_STR}:#{name}",
          :debian_name => name,
          :version => version,
          :component_type => DEB_STR,
        }
        $stderr.puts "  deb opts = #{opts.inspect}"

        c = opts
        # c = loader.create_component(opts)
        # c.debian_dependencies

        @debian_components << c
      end
      $stderr.puts "debian components found: #{@debian_components.size}"
    end
    @debian_components
  end


  # Provide Debian components.
  def after_load_components! loader, args
    $stderr.puts "loader = #{loader}, args = #{args.inspect}"
    debian_available_components(loader).each do | c |
      return 
      loader.add_available_component! c
    end
  end
  
  # Callback after other components have been loaded.
  Cabar::Loader.add_observer(self, :after_load_components!, :after_load_components!)

  class Cabar::Component
    def debian_detail
      return nil unless component_type == DEB_STR

      unless @debian_detail
        @debian_detail = { }

        lines = `dpkg -s #{debian_name.inspect}`
        lines = lines.split("\n")
        lines = lines.inject([ ]) do | a, l |
          if l[0 .. 1] == ' '
            a.last << l
          else
            a << l
          end
          a
        end
        
        until lines.empty?
          line = lines.shift
          /\A([A-Z][-A-Za-z0-9]+):\s*(.*)/.match(line)
          key = $1
          val = $2
          @debian_detail[key] = val
          # $stderr.puts "key = #{key.inspect}"
          # $stderr.puts "val = #{val.inspect}"
          # $stderr.puts "lines = #{lines.inspect}"
        end

        # $stderr.puts "debian_detail #{self.name} => #{@debian_detail.inspect}"
      end

      @debian_detail
    end

    def debian_dependencies
      unless @debian_dependencies
        @debian_dependencies = [ ]

        # $stderr.puts "  debian_dependencies #{self.name}:" 

        deps = debian_detail['Depends']
        # $stderr.puts "    deps = #{deps.inspect}"

        if deps
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
