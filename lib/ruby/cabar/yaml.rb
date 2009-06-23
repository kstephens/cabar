require 'cabar/base'

require 'cabar/file' # File.cabar_expand_softlink
require 'yaml'
require 'ostruct'
require 'erb'


module Cabar
  module Yaml
    class Loader < Base
      # Directory search path.
      attr_accessor :path

      def initialize opts = EMPTY_HASH
        @visited = { }
        @path = [ ]
        @current_path = EMPTY_ARRAY
        super
      end


      # Parse a yaml file after processing it as an ERB template.
      # The following are available as ERB bindings:
      #
      #   <% cabar.current_file %>
      #   <% cabar.current_file_points_to %>
      #   <% cabar.current_directory %>
      #   <% cabar.current_directory_points_to %>
      # 
      # Includes can be done using:
      #
      #   <% cabar.include file %>
      #
      def read_erb_yaml file, opts = EMPTY_HASH
        # Handle relative includes.
        current_path_save = @current_path

        file = find_file_in_path(file)

        if data = @visited[file]
          return data
        end

        # Recursion lock.
        @visited[file] = data = { }

        # Jeremy likes softlinks and so to I.
        file_readlink = File.cabar_expand_symlink(file)
        
        File.open(file) do | fh |
          # ERb Interface.
          cabar = {
            'current_file'                => file,
            'current_file_points_to'      => file_readlink,
            'current_directory'           => File.dirname(file),
            'current_directory_points_to' => File.dirname(file_readlink),
            '_yaml_loader'                => self,
          }

          cabar = OpenStruct.new(cabar.merge(opts))

          # Handle relative includes.
          @current_path = [ cabar.current_directory ]

          def cabar.include file
            data.cabar_merge!(read_erb_yaml(file))
          end

          template = ERB.new fh.read
          yaml = template.result binding
          data = YAML::load yaml

          @visited[file] = data
        end
        
        data
      rescue Exception => err
        raise Error, "Problem reading file #{file.inspect}: #{err.inspect}" # + ":\n#{err.backtrace * "\n"}"

      ensure
        @current_path = current_path_save
      end


      CURRENT_DIRECTORY_PATH = [ '.' ].freeze

      # Find the file in path.
      #
      def find_file_in_path file, path = self.path
        (@current_path + path + CURRENT_DIRECTORY_PATH).
          map { | dir | File.expand_path(file, dir) }.
          uniq.
          find { | f | File.exist?(f) && File.readable?(f) }
      end

    end # class
  end # module
end # module


