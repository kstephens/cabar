require 'cabar'
require 'cabar/main'
require 'cabar/error'

require 'shellwords'
require 'cabar/environment'
require 'cabar/test/io_helper'


module Cabar

  CABAR_BASE_DIR = File.expand_path(File.dirname(__FILE__) + '/../../../..')
  
  module Test
    module MainHelper
      include IoHelper
      include Cabar::Environment


      # Runs commands under the cabar/example/ directory using the repo/ and cabar_config.yml
      def example_main opts = { }, &blk
        opts = {
          :cd => "CABAR_BASE_DIR/example", 
          :env => {
            :CABAR_PATH   => "repo/dev:repo/prod:repo/plat:@repo/..",
            :CABAR_CONFIG => "cabar_conf.yml",
          },
        }.merge(opts)
        
        main(opts, &blk)
      end


      def main opts, &blk
        generated = expected = nil

        if cwd = opts.delete(:cd)
          cwd = cwd.to_s.gsub('CABAR_BASE_DIR', CABAR_BASE_DIR)
          return Dir.chdir(cwd) do
            main(opts, &blk)
          end
        end

        if expected = opts.delete(:match_stdout)
          opts[:stdout] = generated = ''
        end

        if env = opts.delete(:env)
          return with_env(env) do 
            main(opts, &blk)
          end
        end


        if opts[:stdin] || opts[:stdout] || opts[:stderr]
          return redirect_io(opts) do 
            main(opts, &blk)
          end
        end

        @main =    
          Cabar::Main.new

        result = @main

        if args = opts[:args]
          args = Shellwords.shellwords(args) unless Array === args
          result = Cabar::Error.cabar_error_handler(:rethrow => true) do
            @main.as_current do
              @main.args = args
              @main.parse_args
              @main.run
            end
          end
        end

        yield @main if block_given?

        result
      ensure
        # $stderr.puts "expected:\n#{expected}\n----"
        if generated and expected
          match_output generated, expected
        end
      end


      def match_output generated, expected
#        require 'rubygems'
#        gem 'diff-lcs'
#        require 'diff-lcs'

        e = match_output_rx expected
        g = generated
        g = g.gsub(/(:|")test\/ruby:/) { $1 }

        unless e === g
          e = expected.split("\n")
          g = generated.split("\n")
          e.zip(g) do | (el, gl) |
            el_rx = match_output_rx el, :eol
            unless el_rx === gl
              $stderr.puts "- #{el_rx.inspect}"
              $stderr.puts "+  #{gl.inspect}"
            end
          end
        end

        g.should match(e)

      rescue Exception => err
        $stderr.puts "generated:\n#{generated}\n----"
        raise err.class.new(err.message + "\n#{err.backtrace * "\n"}")
      end

      def match_output_rx expected, eol = false
        e = expected.gsub('<<CABAR_BASE_DIR>>', Cabar::CABAR_BASE_DIR)
        e = Regexp.escape(e)
        e = e.gsub('<<ANY>>', '[^\n]*')
        e = e.gsub('<<ANY-LINES>>', '.*')
        e = eol ? /^#{e}$/ : /\A#{e}\Z/m
      end

    end # module

  end # module
end # module

