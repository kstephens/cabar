require 'derby'

require 'derby/scanner'
require 'derby/processor'

require 'fileutils' # mkdir_p
require 'pp'


module Derby
  class Main
    include InitializeFromHash

    attr_accessor :args, :src_dir, :dst_dir, :defines
    attr_accessor :verbose

    attr_accessor :errors

    def pre_initialize
      @verbose = 0
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
        when /^--?u$/
          options[:preserve_user] = true
        when /^--?g$/
          options[:preserve_group] = true
        when /^--?p$/
          options[:preserve_perms] = true
        when /^--?D([^=]+)=(.*)$/
          define! $1, $2
        when /^--?D$/
          key = args.shift or raise ArgumentError
          val = args.shift or raise ArgumentError
          define! key, val
        when /^--?v$/
          self.verbose += 1
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
      @errors.empty? ? 0 : 1
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
      if @verbose > 0
        $stderr.puts "#{File.basename($0)}: binding:"
        pp @defines
      end
      Scanner.new(:src_dir => src_dir, :dst_dir => dst_dir, :verbose => verbose).
        process_files!(processor)
    end


    def processor
      @processor ||=
        DerbyProcessor.new(
                           options.merge(
                                         :defines => defines, 
                                         :verbose => verbose
                                         ))
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
        # pp @defines
      end

      
      def process_file! file
        src_path, dst_path = file[:src_path], file[:dst_path]

        result = process_erb! src_path

        FileUtils.mkdir_p(File.dirname(dst_path))
        File.open(dst_path, "w+") do | fh |
          $stderr.puts "#{File.basename($0)}: generating #{dst_path.inspect}" if @verbose > 0
          fh.write(result)
        end
      
        src_stat = File.stat(src_path)
        File.chown(src_stat.uid, nil, dst_path)  if @preserve_user && Process.euid == 0
        File.chown(nil, src_stat.gid, dst_path)  if @preserve_group
        File.chmod(src_stat.mode, dst_path) if @preserve_mode
      end
 

      def get_binding derby
        derby = derby
        binding
      end


      def method_missing sel, *args, &blk
        # $stderr.puts "  method_missing #{sel.inspect}, #{args.inspect}: caller #{caller[0]}"
        if args.empty? && ! block_given? && @defines.key?(sel = sel.to_s)
          @defines[sel]
        else
          super
        end
      end

   end # class

  end # class

end # module
