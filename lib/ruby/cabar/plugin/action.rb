

Cabar::Plugin.new :name => 'cabar/action' do

  require 'cabar/command/standard' # Standard command support.
  require 'cabar/facet/standard'   # Standard facets and support.

  ##################################################################
  # action facet
  #

  facet :action, :class => Cabar::Facet::Action
  cmd_group :action do

    cmd [ :list, :ls ] , <<'DOC' do
[ - <component> ] [ <action> ] 
List actions available on all required components
DOC
      select_root cmd_args
      action = cmd_args.shift

      print_header :component
      get_actions(action).each do | c, facet |
        # puts "f = #{f.to_a.inspect}"
        puts "    #{c.to_s(:short)}: "
        puts "      action:"
        facet.action.each do | k, v |
          puts "        #{k}: #{v.inspect}"
        end
      end
    end # cmd

    cmd [ :run, :exec, 'do' ], <<'DOC' do
<action> [ - <component> ] <args> ...
Executes an action on all required components.
DOC
      action = cmd_args.shift || raise(ArgumentError, "expected action name")
      comp = select_root cmd_args
      puts "comp = #{comp}"
       
      # Render environment vars.
      setup_environment!
      # puts ENV['RUBYLIB']

      get_actions(action).each do | c, f |
        if comp && comp != c
          next
        end
        f.execute_action! action, cmd_args.dup
      end

    end # cmd

    class Cabar::Command
      def get_actions action = nil
        actions = [ ]
        
        context.
          required_components.each do | c |
          # puts "c.facets = #{c.facets.inspect}"
          c.facets.each do | f |
            if f.key == 'action' &&
              (! action || f.can_do_action?(action))
              actions << [ c, f ]
            end
          end
        end
        
        actions
      end

    end # cmd

  end # cmd_group

end # plugin


