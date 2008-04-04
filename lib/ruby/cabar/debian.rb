
require 'cabar'


module Cabar

  # Debian support module.
  module Debian
    def self.debian_parse_dpkg_file file = '/var/lib/dpkg/status', array = nil
      array ||= [ ]

      File.open(file, 'r') do | io |
        until io.eof?
          lines = io.readline("\n\n")
          array << debian_parse_package_status(lines)
        end
      end

      array
    end

    def self.debian_parse_package_status lines, hash = nil
      hash ||= { } 

      lines = lines.split("\n")
      lines = lines.inject([ ]) do | a, l |
        if l[0 .. 1] == ' '
          a.last << l
        else
          a << l
        end
        a
      end
      
      # $stderr.puts "lines = #{lines.inspect}"

      until lines.empty?
        line = lines.shift
        if /\A([A-Z][-A-Za-z0-9]+):\s*(.*)/.match(line)
          key = $1
          val = $2

          key.sub!(/[^A-Z0-9_]/i, '_')
          key = key.to_sym
          hash[key] = val

          # $stderr.puts "key = #{key.inspect}"
          # $stderr.puts "val = #{val.inspect}"
          # $stderr.puts "lines = #{lines.inspect}"
        end
      end

      hash
    end

  end # module

end # module

