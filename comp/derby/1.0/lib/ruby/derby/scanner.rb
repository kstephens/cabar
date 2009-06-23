require 'derby'

require 'pp'

module Derby
  # Scans src_dir for pattern[0] and calls processor to process each input ERB file.
  class Scanner
    include InitializeFromHash

    attr_accessor :src_dir, :dst_dir, :pattern

    def pattern
      @pattern ||= [ '**/*.erb', /\.erb$/, '' ]
    end

    def files
      @files ||= 
        begin
          files = [ ]
          glob, rx, repl = pattern
          raise ArgumentError, "src_dir" unless String === src_dir && ! src_dir.empty?

          src_dir_rx = /\A#{src_dir}\//
          src_pattern = "#{src_dir}/#{glob}"
          $stderr.puts "src_pattern = #{src_pattern.inspect}"
          # exit 0

          Dir[src_pattern].each do | src_path |
            src_file = src_path.sub(src_dir_rx, '')
            dst_file = src_file.sub(rx, repl)
            file = {
              :src_path => src_path, 
              :src_dir => src_dir,
              :src_file => src_file,
              :dst_dir => dst_dir,
              :dst_file => dst_file,
              :dst_path => "#{dst_dir}/#{dst_file}",
            }
            pp file
            files << file
          end
          files
        end
    end

    def process_files! processor
      files.each do | file |
        processor.process_file! file
      end
    end


  end # class

end # module


