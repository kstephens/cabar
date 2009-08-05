require 'cabar'
require 'cabar/main'


module Cabar
  module Test
    module IoHelper
      
      # Redirect standard IO streams.
      def redirect_io opts, &blk
        error = nil
        @@uid ||= 0
        uid = @@uid += 1
        base_file = "/tmp/#{$$}.#{uid}"

        save_stdin, save_stdout, save_stderr = $stdin, $stdout, $stderr
        old_stdout_file, old_stderr_file = nil, nil
        old_stdout, old_stderr = nil, nil
        tmp_stdout, tmp_stderr = nil, nil

        if stdin = opts.delete(:stdin)
          $stdin = x
        end

        if stdout = opts.delete(:stdout)
          $stdout.flush
          old_stdout = $stdout.clone
          tmp_stdout_file = "#{base_file}.out"
          tmp_stdout = File.open(tmp_stdout_file, "w+")
          $stdout.reopen(tmp_stdout)
          $stdout = tmp_stdout
        end

        if stderr = opts.delete(:stderr)
          $stderr.flush
          old_stderr = $stderr.clone
          tmp_stderr_file = "#{base_file}.err"
          tmp_stderr = File.open(tmp_stderr_file, "w+")
          $stderr.reopen(tmp_stderr)
          $stderr = tmp_stderr
        end

        yield

      rescue Object => err
        error = err

      ensure
        tmp_stdout.flush if tmp_stdout
        tmp_stdout.close if tmp_stdout
        if tmp_stdout_file
          if String === stdout
            stdout << File.read(tmp_stdout_file)
          end
          File.unlink(tmp_stdout_file)
        end

        tmp_stderr.flush if tmp_stderr
        tmp_stderr.close if tmp_stderr
        if tmp_stderr_file
          if String === stderr
            stderr << File.read(tmp_stderr_file)
          end
          File.unlink(tmp_stderr_file)
        end

        $stdin, $stdout, $stderr = save_stdin, save_stdout, save_stderr

        $stdout.reopen(old_stdout) if old_stdout
        $stderr.reopen(old_stderr) if old_stderr

        if error
          $stderr.puts "ERROR: #{error.inspect}\n#{error.backtrace * "\n"}"
          if String == stderr
            $stderr.puts "STDERR:\n#{stderr}\n----"
          end
          raise error
        end
      end
    end # module
  end # module
end # module

