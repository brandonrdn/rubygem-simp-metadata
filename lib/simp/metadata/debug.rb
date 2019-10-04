module Simp
  module Metadata
    # Debug class for SIMP
    class Debug
      attr_accessor :disable_debug_output, :debug_level, :levels_hash

      def self.level?(level)
        set_level = convert_level(@debug_level)
        check_level = convert_level(level)
        check_level <= set_level
      end

      def self.debug_level(level)
        @debug_level = level
      end

      def self.disable_debug_output(setting)
        @disable_debug_output = setting
      end

      def self.levels_hash
        { 'disabled' => 0, 'critical' => 1, 'error' => 2, 'warning' => 3, 'info' => 4, 'debug1' => 5, 'debug2' => 6 }
      end

      def self.convert_level(level)
        levels_hash[level] || 3
      end

      def self.red(text)
        "\e[41m#{text}\e[0m"
      end

      def self.yellow(text)
        "\e[30;43m#{text}\e[0m"
      end

      def self.blue(text)
        "\e[44m#{text}\e[0m"
      end

      def self.green(text)
        "\e[32m#{text}\e[0m"
      end

      def self.print_message(pre, message)
        prefix = color(pre)
        spaces = pre.length + 1
        if message.class.to_s == 'Array'
          message.each do |line|
            if message.index(line) == 0
              warn("#{prefix}: #{line}")
            else
              warn("#{' ' * spaces} #{line}")
            end
          end
        else
          message.split("\n").each do |line|
          warn("#{prefix}: #{line}") unless @disable_debug_output
          end
        end
      end

      def self.color(text)
        case text
        when /DEBUG/, 'INFO'
          blue(text)
        when 'WARN', 'BACKTRACE'
          yellow(text)
        when 'ERROR', 'CRITICAL', 'ABORT'
          red(text)
        else
          text
        end
      end

      def self.debug1(message)
        print_message('DEBUG1', message) if level?('debug1')
      end

      def self.debug2(message)
        print_message('DEBUG2', message) if level?('debug2')
      end

      def self.info(message)
        print_message('INFO', message) if level?('info')
      end

      def self.warning(message)
        print_message('WARN', message) if level?('warning')
      end

      def self.error(message)
        print_message('ERROR', message) if level?('error')
      end

      def self.critical(message)
        print_message('CRITICAL', message) if level?('critical')
      end

      def self.abort(message)
        print_message('ABORT', message)
        exit 8
      end

      def self.backtrace(backtrace)
        backtrace.reverse.each { |message| print_message('BACKTRACE', message) } if level?('debug1')
      end
    end
  end
end
