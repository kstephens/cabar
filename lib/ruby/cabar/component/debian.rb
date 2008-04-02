require 'cabar/component'

require 'cabar/base'
require 'cabar/version'


module Cabar
  class Component

    # Debian Package as a Cabar Component.
    class Debian < Component
      # register_component_type :deb

      attr_accessor :name
      attr_accessor_type :version, Cabar::Version

      attr_accessor :dependencies

      def self.all
        unless @all
          @all = [ ]
          lines = `dpkg -l`
          lines = lines.split("\n")
          lines = lines[5 .. -1]
          lines.each do | line |
            # $stderr.puts "line = #{line.inspect}"
            status, name, version, description = line.split(/\s+/, 4)
            # $stderr.puts "status = #{status.inspect}"
            # $stderr.puts "name = #{name.inspect}"
            # $stderr.puts "version = #{version.inspect}"
            # $stderr.puts "description = #{description.inspect}"
            @all << self.new(:name => name, :version => version)
          end
        end
        @all
      end
      
      def initialize *args
        super 
      end

      def detail_raw
        unless @detail_raw
          @detail_raw = { }

          lines = `dpkg -s #{name.inspect}`
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
            @detail_raw[key] = val
            $stderr.puts "key = #{key.inspect}"
            $stderr.puts "val = #{val.inspect}"
            $stderr.puts "lines = #{lines.inspect}"
          end
        end
        @detail_raw
      end

      def dependencies
        @dependencies ||=
        begin
          d = detail_raw['Depends'].dup.gsub("\n", ' ')
        end
      end

      def to_s
        inspect
      end

      def inspect
        "#<#{self.class} #{name.inspect}>"
      end

    end
  end
end
