require 'derby'

require 'cabar/file' # File.cabar_expand_softlink
require 'cabar/hash' # Hash.cabar_merge!
require 'ostruct'
require 'erb'



module Derby
  class Processor
    include InitializeFromHash

    # A Processor Error.
    class Error < ::Exception; end

    # Directory search path.
    attr_accessor :path

    # A Proc to call to compute the ERB Binding.
    attr_accessor :binding_proc

    
    def pre_initialize
      @visited = { }
      @path = [ ]
      @current_path = EMPTY_ARRAY
    end


    # Processing a file as an ERB template.
    #
    # The following are available as ERB bindings:
    #
    #   <% derby.current_file %>
    #   <% derby.current_file_points_to %>
    #   <% derby.current_directory %>
    #   <% derby.current_directory_points_to %>
    # 
    # Includes can be done using:
    #
    #   <% derby.include file %>
    #
    def process_erb! file, opts = EMPTY_HASH
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
        derby = {
          'current_file'                => file,
          'current_file_points_to'      => file_readlink,
          'current_directory'           => File.dirname(file),
          'current_directory_points_to' => File.dirname(file_readlink),
          '_yaml_loader'                => self,
        }
        
        derby = OpenStruct.new(derby.merge(opts))
        
        # Handle relative includes.
        @current_path = [ derby.current_directory ]
        
        def derby.include file
          process_include!(file, process_erb!(file), data)
        end
        
        template = ERB.new fh.read
        data = template.result(get_binding(derby))
        data = process_data! file, data

        @visited[file] = data
      end
      
      data
    rescue Exception => err
      raise Error, "Problem reading file #{file.inspect}:\n#{err.inspect}" + ":\n#{err.backtrace * "\n"}"
      
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
    

    ##################################################

    # Returns the Binding object for ERB#result.
    # Subclasses may override this method.
    def get_binding derby
      binding_proc.call(derby)
    end


    # Subclasses may override this methods.
    def process_data! file, data
      data
    end


    # Subclasses may override this method.
    def process_include! file, data, target_data
      data
    end




    class Generic < self
    end


    class Yaml < self
      # The merged Hash from all processing
      attr_accessor :result

      def initialize
        require 'yaml'
        super
        @result ||= { }
      end

      def process_file! file, data
        @result.cabar_merge!(YAML::load(data))
      end

      def process_include! file, data, target_data
        target_data.cabar_merge!(data)
      end
    end
  end # class
end # module

