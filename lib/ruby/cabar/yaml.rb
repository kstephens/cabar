require 'cabar'

# It's too early to simply wait for cabar to depend on itself
# and its dependency on derby.
cabar_comp_require 'derby', '1.0'

require 'derby/processor'


module Cabar
  module Yaml
    class Loader < Derby::Processor::Yaml
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
        process_erb! file, opts
      end
      
      # Also bind "cabar" to the derby context object. 
      def get_binding derby
        cabar = derby = derby
        binding
      end
    end # class
  end # module
end # module


