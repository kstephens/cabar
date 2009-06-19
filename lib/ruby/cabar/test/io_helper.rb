require 'cabar'
require 'cabar/main'


module Cabar
  module Test
    module IoHelper
      
      def redirect_io opts, &blk
        save_stdin, save_stdout, save_stderr = $stdin, $stdout, $stderr

        if x = opts.delete(:stdin)
          x = StringIO.new(x) if String === x
          $stdin = x
        end
        if x = opts.delete(:stdout)
          x = StringIO.new(x) if String === x
          $stdout = x
        end
        if x = opts.delete(:stderr)
          x = StringIO.new(x) if String === x
          $stderr = x
        end

        yield

      ensure
        $stdin, $stdout, $stderr = save_stdin, save_stdout, save_stderr
      end
    end # module
  end # module
end # module

