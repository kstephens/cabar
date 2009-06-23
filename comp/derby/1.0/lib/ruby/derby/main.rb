require 'derby'

require 'derby/scanner'
require 'derby/processor'

require 'fileutils' # mkdir_p


module Derby
  class Main
    include InitializeFromHash

    attr_accessor :args, :src_dir, :dst_dir, :defines
    attr_accessor :errors

    def pre_initialize
      @errors = [ ]
      @src_dir = nil
      @dst_dir = '.'
      @defines = { }
      @defines.extend(DottedHash)
    end


    def parse_args!
      processed_dst = false

      args = self.args.dup
      until args.empty?
        arg = args.shift
        case arg
        when /^--?D([^=]+)=(.*)$/
          define! $1, $2
        when /^--?D$/
          key = args.shift or raise ArgumentError
          val = args.shift or raise ArgumentError
          define! key, val
        when /^--?C$/
          self.src_dir = args.shift
        else
          process_dst! arg
          processed_dst = true
        end
      end

      unless processed_dst
        process_dst! '.'
      end
    end


    def run!
      parse_args!
      @errors ? 1 : 0
    end


    def define! key, val
      path = key.split(/[\.:]/)
      tail = path.pop
      path.inject(@defines) do | h, k |
        h = h[k] ||= { }
        h.extend(DottedHash)
        h
      end[tail] = val
    end


    def process_dst! dst_dir
      Scanner.new(:src_dir => src_dir, :dst_dir => dst_dir).
        process_files!(processor)
    end


    def processor
      @processor ||=
        DerbyProcessor.new(:defines => defines)
    end


    # Main processor generates new files.
    class DerbyProcessor < Processor::Generic
      attr_accessor :preserve_user, :preserve_group, :preserve_mode
      attr_accessor :defines
      
      def pre_initialize
        @preserve_user = true
        @preserve_group = true
        @preserve_mode = true
        super
      end

      def post_initialize
        pp @defines
      end

      def process_file! file
        FileUtils.mkdir_p File.dirname(file[:dst_path])
        File.open(file[:dst_path], "w+") do | fh |
          result = process_erb! file[:src_path]
          fh.write(result)
        end
      end
 
      def get_binding derby
        derby = derby
        binding
      end

      def method_missing sel, *args, &blk
        $stderr.puts "  method_missing #{sel.inspect}, #{args.inspect}: caller #{caller[0]}"
        sel = sel.to_s
        if args.empty? && ! block_given? && @defines.key?(sel)
          @defines[sel]
        else
          super
        end
      end

   end # class

  end # class

end # module
