
Cabar::Plugin.new :documentation => <<'DOC' do
Support for rubygems repository components.
DOC

  facet :rubygems, 
        :path => [ 'gems' ], 
        :env_var => :GEM_PATH

  cmd_group [ :rubygems, :gems ] do

    cmd [ :list ] , <<'DOC' do
[ - <component> ]
List gems repositories.
DOC
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

    cmd :gem , <<'DOC' do
[ - <gems-component> ] <<gem-cmd-args>> 
Run gem using a gems component environment.

Example:

  cbr gems gem - my_gems_component install rails 

Installs "rails" gem into "my_gems_component/gems",
if my_gems_component has the 'rubygems' facet.

DOC
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

    cmd :env , <<'DOC' do
[ - <gems-component> ] <<gem-cmd-args>> 
Print the gem environment.

Example:
  cbr gems env - my_gems_component

DOC
      selection.select_required = true
      selection.to_a

      setup_gem_environment!

      print_gem_env nil, :force
    end


    class Cabar::Command
      def setup_gem_environment! opts = { }
        selection.to_a

        opts[:gem_home] = ENV['GEM_HOME']
        opts[:gem_path] = ENV['GEM_PATH']
        
        # print_gem_env "Before setup_environment!"

        ENV.delete('GEM_PATH') if ENV['GEM_PATH'] && ENV['GEM_PATH'].empty?
        ENV.delete('GEM_HOME') if ENV['GEM_HOME'] && ENV['GEM_HOME'].empty?

        unless ENV['GEM_PATH'] && ENV['GEM_HOME']
          require 'rubygems'
          ENV['GEM_PATH'] ||= Cabar.path_join(Gem.path)
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
    end

  end # cmd_group

end # plugin


