module Matrioska
  class AppRunner
    include Adhearsion::CallController::Utility

    def initialize(call)
      @call = call
      @app_map = {}
    end

    def start
      component = Punchblock::Component::Input.new({ :mode => :dtmf,
          :grammar => {
            :value => grammar_accept
          }
      })
      component.register_event_handler Punchblock::Event::Complete do |event|
        handle_input_complete event
      end
      @call.write_and_await_response component
    end

    def app_map
      @app_map
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
      if match = @app_map[digit]
        Adhearsion.logger.info "#match_and_run called with #{digit}"
        callback = lambda do |call|
          Adhearsion.logger.info "MATRIOSKA CALLBACK RESTARTING LISTENER"
          start
        end
        
        @call.execute_controller(nil, callback, &match) if match.is_a? Proc
        if match.is_a? Class
          payload = match.new(@call)
          Adhearsion.logger.info "MATRIOSKA EXECUTING #{payload.to_s}"
          @call.execute_controller(payload, callback)
        end
      end
      start
    end

    def handle_input_complete(event)
      result = event.reason.respond_to?(:utterance) ? event.reason.utterance : nil
      digit = parse_dtmf result
      match_and_run digit
    end
  end
end
