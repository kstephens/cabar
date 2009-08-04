require 'cabar'
require 'cabar/main'
require 'cabar/error'

require 'shellwords'
require 'cabar/env'
require 'cabar/test/io_helper'


module Cabar

  CABAR_BASE_DIR = File.expand_path(File.dirname(__FILE__) + '/../../../..')
  
  module Test
    module MainHelper
      include IoHelper
      include Cabar::Env


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
          if filter = opts.delete(:filter_stdout)
            generated = filter.call(generated)
          end
          match_output generated, expected
        end
      end


      def match_output generated, expected
        # HACK!!!
        generated = generated.gsub(/(:|")test\/ruby:/) { $1 }

        if Array === expected and (Regexp === expected[0] or String === expected[0])
          g = generated
          expected.each do | e |
            case e
            when String
              e.split("\n").each do | e |
                e_rx = match_output_rx(e, :eol)
                check_generated_expected(g, e_rx)
              end
            when Regexp
              check_generated_expected(g, e)
            end
          end
        else
          e = match_output_rx expected
          g = generated
          check_generated_expected(g, e) do 
            # show_difference expected, generated
            e = expected.split("\n")
            g = generated.split("\n")
            e = e.map { | el | match_output_rx el, :eol }
            rx_difference(e, g)
          end
        end
      rescue Exception => err
        # check_generated_expected(generated, expected, :no_error)
        raise err.class.new(err.message + "\n#{err.backtrace * "\n"}")
      end


      def check_generated_expected generated, expected, no_error = false
        unless expected === generated
          g = generated
          e =
            case expected
            when Regexp
              expected = DiffableRegexp.new(expected).to_s
            else
              expected
            end
          $stderr.puts "expected:\n#{e}\n----"
          $stderr.puts "generated:\n#{g}\n----"
          if block_given?
            yield generated, expected
          end
          unless no_error
            :generated.should == :expected
          end
        end
      end


      def match_output_rx expected, eol = false
        return expected if Regexp === expected
        e = expected.gsub('<<CABAR_BASE_DIR>>', Cabar::CABAR_BASE_DIR)
        e = Regexp.escape(e)
        e = e.gsub('<<ANY>>', '[^\n]*')
        e = e.gsub('<<ANY-LINES>>', '.*')
        e = eol ? /^#{e}$/ : /\A#{e}\Z/m
      end


      def rx_difference a, b
        require 'rubygems'
        gem 'diff-lcs'
        require 'diff/lcs'
        xform = lambda { | x |
          case x
          when Regexp
            DiffableRegexp.new(x)
          when String
            DiffableString.new(x)
          else
            raise TypeError
          end
        }
        a = a.map(&xform)
        b = b.map(&xform)
        diffs = Diff::LCS.diff(a, b)
        diffs = diffs.flatten
        diffs = diffs.map do | c | 
          case c
          when Diff::LCS::Change
            "#{'%4d' % c.position} #{c.action}#{c.element.to_s}"
          else
            "#{'%4d' % -1} ?#{c.inspect}"
          end
        end
        $stderr.puts "diff:\n#{diffs * "\n"}\n----\n"
        diffs
        "#{diffs.size} diffs".should == "0 diffs"
      end


      class DiffableRegexp
        def initialize rx
          @rx = rx
        end
        
        def to_rx
          @rx
        end
        alias :to_x :to_rx

        def to_s
          str = @rx.to_s
          str = str.sub(/\A\(\?\-[^:]+:/, '')
          str = str.sub(/\)\Z/, '')
          str = str.sub(/\A\^/, '')
          str = str.sub(/\$\Z/, '')
          str = str.gsub("\\A", "")
          str = str.gsub("\\n", "\n")
          str = str.gsub(/\\(.)/) { $1 }
          str
        end
  
        # See Diff::LCS.__inverse_vector
        def hash
          @rx.hash
        end

        # See Diff::LCS.__lcs for a[...] == b[...].
        def == other
          # $stderr.puts "  # #{@rx.inspect} == #{other.inspect}"
          case other
          when self.class
            object_id == other.object_id
          when DiffableString
            @rx === other.to_s
          when String
            @rx === other
          else
            raise TypeError, "Expected ${self.class} or String, given #{other.class}"
          end
        end
      end

      class DiffableString
        def initialize str
          @str = str
        end

        def to_s
          @str
        end
        alias :to_x :to_s

        # See Diff::LCS.__inverse_vector
        def hash
          @str.hash
        end

        # See Diff::LCS.__lcs for a[...] == b[...].
        def == other
          $stderr.puts "  # #{@str.inspect} == #{other.inspect}"
          case other
          when self.class, String
            @str == other.to_s
          when DiffableRegepx
            other == self
          else
            raise TypeError, "Expected ${self.class} or String, given #{other.class}"
          end
        end
      end

    end # module
  end # module
end # module

