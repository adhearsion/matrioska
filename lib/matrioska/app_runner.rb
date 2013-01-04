module Matrioska
  class AppRunner
    attr_reader :current_input, :app_map
    def initialize(controller)
      @controller = controller
      @app_map = {}
    end

    def start
      return nil if @run_loop && @run_loop.alive?
      @running = true
      @run_loop = Thread.new { app_loop }
    end

    def app_loop
      while @running do

      end
    end

    def wait_for_input
      result = @controller.wait_for_digit(-1)
    end

    def map_app(digit, controller=nil, &block)
      digit = digit.to_s
      range = "1234567890*#"

      unless range.include?(digit) && digit.size == 1
        raise ArgumentError, "The first argument should be a single digit String or number in the range 1234567890*#" 
      end

      payload = if block_given?
        raise ArgumentError, "You cannot specify both a block and a controller name." if controller.is_a? Class
        block
      else
        raise ArgumentError, "You need to provide a block or a controller name." unless controller.is_a? Class
        controller
      end

      @app_map[digit] = payload
    end

    def match_and_run(digit)
      return unless match = @app_map[digit]
      @controller.instance_exec(@controller.metadata, match) if match.is_a? Proc
      @controller.invoke(match, @controller.metadata) if match.is_a? Class
    end
  end
end
