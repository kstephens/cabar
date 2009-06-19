require 'cabar'
require 'cabar/main'
require 'shellwords'

require 'cabar/environment'
require 'cabar/test/io_helper'


module Cabar

  CABAR_BASE_DIR = File.expand_path(File.dirname(__FILE__) + '/../../../..')
  
  module Test
    module MainHelper
      include IoHelper
      include Cabar::Environment

      def main opts, &blk
        if cwd = opts.delete(:cd)
          cwd = cwd.to_s.gsub('CABAR_BASE_DIR', CABAR_BASE_DIR)
          return Dir.chdir(cwd) do
            main(opts, &blk)
          end
        end

        if opts[:stdin] || opts[:stdout] || opts[:stderr]
          return redirect_io(opts) do 
            main(opts, &blk)
          end
        end

        if env = opts.delete(:env)
          return with_env(env) do 
            main(opts, &blk)
          end
        end


        @main =    
          Cabar::Main.new

        result = @main

        if args = opts[:args]
          args = Shellwords.shellwords(args) unless Array === args
          @main.args = args
          @main.parse_args
          result = @main.run
        end

        yield @main if block_given?

        result
      end
    end # module
  end # module
end # module

