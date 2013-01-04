module Matrioska
  class AppRunner

    def initialize(controller)
      @controller = controller
      @app_map = {}
    end

    def start
      return nil if @run_loop && @run_loop.alive?
      @running = true
      @run_loop = Thread.new { app_loop }
    end

    def stop
      @running = false
    end

    def running?
      @running
    end

    def app_map
      @app_map
    end

    def app_loop
      while running? do
        wait_for_input
      end
    end

    def wait_for_input
      result = @controller.wait_for_digit(-1)
      match_and_run result.to_s
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
      Adhearsion.logger.info "#match_and_run called with #{digit}"
      Adhearsion.logger.info "app_map is #{@app_map}"
      Adhearsion.logger.info "It seems to be a block" if match.is_a? Proc
      @controller.instance_exec(@controller.metadata, &match) if match.is_a? Proc
      @controller.invoke(match, @controller.metadata) if match.is_a? Class
    end
  end
end
