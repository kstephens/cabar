module Cabar
  unless defined?(Facet::Rakefile)
    class Facet::Rakefile < Facet::Path
      attr_accessor :rakefiles
      def _normalize_options! opts, new_opts={}
        new_opts=super
        if Hash===opts and opts.invert[nil] and opts[:path].nil?
          x=opts.invert[nil]
          new_opts[:path]=x.to_s
          new_opts.delete(x)
        end
        new_opts
      end
      def inferred?
        File.exist? File.join(component.base_directory,'Rakefile')
      end
      def abs_path
        @abs_path ||=
        owner &&
        begin
          @abs_path = EMPTY_ARRAY # recursion lock.

          x = path.map { | dir | File.expand_path(expand_string(dir), owner.base_directory) }

          arch_dir = arch_dir_value
          if arch_dir
            # arch_dir = [ arch_dir ] unless Array === arch_dir
            x.map! do | dir |
              if File.directory?(dir_arch = File.join(dir, arch_dir))
                dir = [ dir, dir_arch ]
                # $stderr.puts "  arch_dir: dir = #{dir.inspect}"
              end
              dir
            end
            x.flatten!
            # $stderr.puts "  arch_dir: x = #{x.inspect}"
          end

          @abs_path = x.map{|p|[p,component.name].join('!')}
        end
      end
    end
  end
end
Cabar::Plugin.new do
  facet :rakefile, 
      :env_var => :CABAR_RAKE_FILE,
      :std_path => :Rakefile,
      :file_list => true,
      :inferrable => true,
      :class => Cabar::Facet::Rakefile
end

