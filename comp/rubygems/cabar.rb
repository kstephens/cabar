
# require 'cabar/command/standard' # Standard command support.
# require 'cabar/facet/standard'   # Standard facets and support.

Cabar::Plugin.new do

  facet :rubygems, :path => [ 'gems' ], :var => :GEM_PATH
  cmd_group [ :rubygems, :gems ] do

    cmd [ :list, :ls ] , <<'DOC' do
[ - <component> ] [ <action> ] 
List gems repositories.
DOC
      select_root cmd_args

      print_header :component
      get_gems_facets.each do | c, facet |
        # puts "f = #{f.to_a.inspect}"
        puts "    #{c.to_s(:short)}: "
        puts "      gems:"
        facet.action.each do | k, v |
          puts "        #{k}: #{v.inspect}"
        end
      end
    end

    class Cabar::Command
      def get_gems_facets match = nil
        result = [ ]
        
        context.
          required_components.each do | c |
          # puts "c.facets = #{c.facets.inspect}"
          c.facets.each do | f |
            if f.key == 'rubygems' &&
              actions << [ c, f ]
            end
          end
        end
        
        result
      end
    end

  end # cmd_group

end # plugin

