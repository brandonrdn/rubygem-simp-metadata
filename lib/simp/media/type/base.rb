require 'open3'
module Simp
  module Media
    module Type
      class Base
        attr_accessor :engine
        attr_accessor :options
        def initialize(options, engine)
          @options = options
          @engine = engine
        end
        def debug2(output)
          engine.debug2(output)
        end

        def debug1(output)
          engine.debug1(output)
        end

        def info(output)
          engine.info(output)
        end

        def warning(output)
          engine.warning(output)
        end

        def error(output)
          engine.error(output)
        end

        def critical(output)
          engine.critical(output)
        end
        def run(command)
          exitcode = nil
          Open3.popen3(command) do |stdin, stdout, stderr, thread|
            pid = thread.pid
            debug1(stdout.read.chomp)
            debug1(stderr.read.chomp)
            exitcode = thread.value
          end
          exitcode
        end
        def target_directory
          nil
        end
        def cleanup
          true
        end
        def fetch_component(component, options)
          raise '`fetch_component` not implemented'
        end
        def add_component(component, options)
          raise '`add_component` not implemented'
        end
        def finalize()
          raise '`finalize` not implemented'
        end
      end
    end
  end
end
