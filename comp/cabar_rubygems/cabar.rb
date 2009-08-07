
Cabar::Plugin.new :documentation => 'Support for rubygems repository components.' do
  ruby_component = lambda {
    @@ruby_component ||=
    Cabar::Main.current.resolver.
    selected_components['ruby'].first
  }

  rubygems_component = lambda {
    @@rubygems_component ||=
    Cabar::Main.current.resolver.
    selected_components['rubygems'].first
  }

  path_proc = lambda { | f | 
    g = rubygems_component.call
    r = ruby_component.call
    "gems-#{g.version}-ruby-#{r.version}-#{r.ruby[:os]}-#{r.ruby[:platform]}-#{r.ruby[:system]}"
  }

  facet :rubygems, 
        :path_proc => path_proc,
        :env_var => :GEM_PATH,
        :standard_path_proc => lambda { | f |
          rg = rubygems_component.call
          rg_prog = "#{rg.facet(:bin).path.first}/gem"
          x = "unset GEM_PATH; unset GEM_HOME; #{rg_prog} environment path 2>/dev/null"
          # $stderr.puts "   cmd = #{x.inspect}"
          x = `#{x}`.chomp.split(Cabar.path_sep) rescue nil
          # $stderr.puts "   rubygems.standard_path_proc = #{x.inspect}"
          x || [ ]
        }

  cmd_group [ :rubygems, :gems ] do

    cmd [ :component ] do
      puts "#{rubygems_component.call.standard_gem_pathinspect}"
    end

    doc "
show the name of the expected gem 'arch' subdirectory.
"
    cmd [ :arch_dir ] do
      puts path_proc.call(nil)
    end

    doc "[ - <component> ]
List gems repositories."
    cmd [ :list ] do
      selection.select_required = true
      selection.to_a

      print_header :component
      get_gems_facets.each do | c, facet |
        # puts "f = #{f.to_a.inspect}"
        puts "    #{c.to_s(:short)}: "
        puts "      gems:"
        facet.abs_path.each do | p |
          puts "        directory: #{p.inspect}"
          puts "          gem:"
          Dir["#{p}/specifications/*-*"].each do | gem_dir |
            puts "          - #{File.basename(gem_dir).inspect}"
          end
        end
      end
    end

    doc '[ - <gems-component> ] <<gem-cmd-args>> 
Run gem using a gems component environment.

Example:

  cbr gems gem - my_gems_component install rails 

Installs "rails" Gem into "my_gems_component/gems",
if my_gems_component has the "rubygems" facet.'
    cmd :gem do
      selection.select_required = true
      selection.to_a

      opts = setup_gem_environment!

      # print_gem_env "After setup_environment!"

      get_gems_facets(root).each do | c, facet |
        begin
          gem_path = facet.abs_path.dup
          ENV['GEM_HOME'] = facet.abs_path.first
          gem_path += [ opts[:gem_path], ENV['GEM_PATH'] ]
          ENV['GEM_PATH'] = Cabar.path_join(gem_path)
          cmd = [ 'gem' ] + cmd_args
          print_gem_env "For #{cmd.join(' ')}"
          system(*cmd)
        ensure
          ENV['GEM_HOME'] = opts[:gem_home]
          ENV['GEM_PATH'] = opts[:gem_path]
        end
      end
    end

    doc "[ - <gems-component> ] <<gem-cmd-args>> 
Print the gem environment.

Example:
  cbr gems env - my_gems_component"
    cmd :env do
      selection.select_required = true
      selection.to_a

      setup_gem_environment!

      print_gem_env nil, :force
    end


    helpers do
      def setup_gem_environment! opts = { }
        selection.to_a

        opts[:gem_home] = ENV['GEM_HOME']
        opts[:gem_path] = ENV['GEM_PATH']
        
        # print_gem_env "Before setup_environment!"

        ENV.delete('GEM_PATH') if ENV['GEM_PATH'] && ENV['GEM_PATH'].empty?
        ENV.delete('GEM_HOME') if ENV['GEM_HOME'] && ENV['GEM_HOME'].empty?

        unless ENV['GEM_PATH'] && ENV['GEM_HOME']
          ENV['GEM_PATH'] ||= 
            begin
              x = `ruby -r rubygems -e 'puts Gem.path.inspect' 2>/dev/null`.chomp
              x = $?.success? ? eval(x) : [ ] # WHAT TO DO IF THIS FAILS? -- kurt 2009/06/15
              # Do we need to do anything?  This means you didn't have a GEM_PATH we could figure out
              # We should either punt entirely (raise) or assume gem will handle it.
              # I'd prefer we assume gem will take care of it. --jwl 2009/06/16
              Cabar.path_join(x)
            end

          ENV['GEM_HOME'] ||= Cabar.path_split(ENV['GEM_PATH']).first
        end

        # print_gem_env "After GEM_PATH, GEM_HOME default."

        # Render environment vars.
        setup_environment!
        
        # print_gem_env "After setup_environment!"
        
        opts
      end

      def print_gem_env header = nil, force = true
        unless force
          return unless cmd_opts[:show_environment]
        end

        puts "\n#{header}:" if header

        [ :RUBYLIB, :GEM_HOME, :GEM_PATH ].each do | v |
          v = v.to_s
          puts "#{v}=#{ENV[v].inspect}" if ENV[v]
        end
      end

      def get_gems_facets match = nil
        result = [ ]

        selection.to_a.each do | c |
          next if match && ! (match === c)
          # puts "c.facets = #{c.facets.inspect}"
          c.facets.each do | f |
            if f.key == 'rubygems' &&
              result << [ c, f ]
            end
          end
        end
        
        result
      end
    end # helpers

  end # cmd_group

end # plugin


