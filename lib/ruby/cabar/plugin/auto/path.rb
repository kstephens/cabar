

Cabar::Plugin.new :name => 'cabar/path' do

  doc <<"DOC"
Path facet tools.
DOC
  # 'emacs

  cmd_group :path do
    doc '[ -f=<facet> ] [ <file-glob> ... ]
List all files found under the paths.

Example:

  cbr path list -f=lib/ruby "**/*.rb"

Lists all ruby *.rb files that would be found under RUBYLIB as
defined by cbr env.

'
    cmd [ :list, :ls ] do
      selection.select_required = true
      selection.to_a

      globs = cmd_args
      path_facets = cmd_opts[:f] || [ ]
      #$stderr.puts "path_facets = #{path_facets.inspect}"
      path_facets = [ path_facets ] unless Array === path_facets
      #$stderr.puts "path_facets = #{path_facets.inspect}"
      path_facets = path_facets.map { | x | Cabar::Facet.proto_by_key x }
      #$stderr.puts "path_facets = #{path_facets.inspect}"
      path_facets = Cabar::Facet.prototypes if path_facets.empty?
      #$stderr.puts "path_facets = #{path_facets.inspect}"
      path_facets = path_facets.select { | x | Cabar::Facet::Path === x }
      #$stderr.puts "path_facets = #{path_facets.inspect}"
      path_facets = path_facets.sort_by{ | x | x.key }
      #$stderr.puts "path_facets = #{path_facets.inspect}"
      #exit 1

      facet_paths = { }

      path_facets.each do | facet |
        comp_facet = selection.resolver.collect_facet facet
        abs_path = (comp_facet.abs_path || [ ])
        facet_paths[facet] = abs_path
      end

      print_header :path
      path_facets.each do | facet |
        puts "    #{facet.key}: # #{facet.env_var} "
        puts "      path: "
        abs_path = facet_paths[facet]
        abs_path.each do | p |
          puts "        - #{p.inspect}  "
        end 

        # Scan for files in each directory
        files = { }
        globs.each do | g |
          abs_path.each do | p |
            Dir["#{p}/#{g}"].each do | df |
              f = df.sub(/^#{p}\//, '')
              (files[f] ||= [ ]) << [ df, p, g ]
            end
          end
        end

        unless files.empty?
          puts "      files: "
          files.keys.sort.each do | f |
            puts "        #{f.inspect}: "
            files[f].each do | (df, p, g) |
              puts "          - #{df} # #{p.inspect} #{g.inspect} "
            end
          end
        end
      end
    end # cmd

  end # cmd_group

end # plugin


