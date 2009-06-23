require 'derby'

require 'pp'


module Derby
  # Scans src_dir for pattern[0] and calls processor to process each input ERB file.
  class Scanner
    include InitializeFromHash

    attr_accessor :src_dir, :dst_dir, :glob, :patterns

    attr_accessor :verbose

    def pre_initialize
      @verbose = 0
    end


    def glob
      @glob ||= '**/*'
    end


    # A list of patterns to try.
    def patterns
      @patterns ||=
        [
         {
           :type => :erb,
           :rx   => /\.erb\Z/,
           :rep  => '',
         },
         {
           :type => :none,
           :rx   => /\Z/,
           :rep  => '',
         },
        ]
    end


    def files
      @files ||= 
        begin
          files = [ ]

          raise ArgumentError, "src_dir" unless String === src_dir && ! src_dir.empty?
          src_dir_rx = /\A#{src_dir}\//
          src_pattern = "#{src_dir}/#{glob}"

          Dir[src_pattern].sort.each do | src_path |
            src_file = src_path.sub(src_dir_rx, '')
            patterns.each do | p |
              dst_file = src_file.dup
              file = nil

              case
              when File.symlink?(src_path)
                file = {
                  :pattern => { :type => :symlink },
                  :linkname => File.readlink(src_path),
                }

              when File.directory?(src_path)
                # SKIP

              when dst_file.sub!(p[:rx], p[:rep])
                file = {
                  :pattern => p,
                }

              else
                # SKIP
              end

              if file
                file.update({
                  :src_path => src_path, 
                  :src_dir  => src_dir,
                  :src_file => src_file,
                  :dst_dir  => dst_dir,
                  :dst_file => dst_file,
                  :dst_path => "#{dst_dir}/#{dst_file}",
                  :src_stat => File.lstat(src_path),
                            })
                pp file if @verbose > 1 # || true
                files << file
                break
              end
            end
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


