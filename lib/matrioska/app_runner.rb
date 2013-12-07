module Matrioska
  class AppRunner
    include Adhearsion::CallController::Utility

    VALID_DIGITS = /[^0-9*#]/

    def initialize(call)
      @call = call
      @app_map = {}
      @running = false
    end

    def start
      @state = :started
      logger.debug "MATRIOSKA START CALLED"
      unless @running
        @component = Punchblock::Component::Input.new mode: :dtmf, inter_digit_timeout: Adhearsion.config[:matrioska].timeout * 1_000, grammar: { value: build_grammar }
        logger.debug "MATRIOSKA STARTING LISTENER"
        @component.register_event_handler Punchblock::Event::Complete do |event|
          handle_input_complete event
        end
        @call.write_and_await_response @component if @call.active?
      end
    end

    def stop!
      @state = :stopped
      @component.stop! if @component && @component.executing?
    end

    def status
      @state
    end

    def started?
      @state == :started
    end

    def stopped?
      @state == :stopped
    end

    def map_app(pattern, controller = nil, &block)
      pattern = pattern.to_s
      range = "1234567890*#"

      if VALID_DIGITS.match(pattern)
        raise ArgumentError, "The first argument should be a String or number containing only 1234567890*#"
      end

      payload = if block_given?
        raise ArgumentError, "You cannot specify both a block and a controller name." if controller.is_a? Class
        block
      else
        raise ArgumentError, "You need to provide a block or a controller name." unless controller.is_a? Class
        controller
      end

      @app_map[pattern] = payload
    end

    def handle_input_complete(event)
      if @state == :stopped
        logger.warn "Stopped runner #{self} received event."
        return
      end
      logger.debug "MATRIOSKA HANDLING INPUT"
      result = event.reason.respond_to?(:utterance) ? event.reason.utterance : nil
      digit = parse_dtmf result
      match_and_run digit unless @running
    end

    private

    def app_map
      @app_map
    end

    def match_and_run(digit)
      if match = @app_map[digit]
        logger.debug "MATRIOSKA #match_and_run called with #{digit}"
        @running = true
        callback = lambda do |call|
          @running = false
          logger.debug "MATRIOSKA CALLBACK RESTARTING LISTENER"
          if call.active?
            start unless stopped?
          else
            logger.debug "MATRIOSKA CALLBACK NOT DOING ANYTHING BECAUSE CALL IS DEAD"
          end
        end

        if match.is_a? Proc
          logger.debug "MATRIOSKA EXECUTING #{match} AS BLOCK"
          @call.execute_controller(nil, callback, &match)
        end

        if match.is_a? Class
          payload = match.new(@call)
          logger.debug "MATRIOSKA EXECUTING #{payload.to_s} AS CONTROLLER"
          @call.execute_controller(payload, callback)
        end
      else
        start
      end
    rescue Adhearsion::Call::Hangup
      logger.debug "Matrioska terminated because the call was disconnected"
    end

    def build_grammar
      current_app_map = app_map
      RubySpeech::GRXML.draw mode: :dtmf, root: 'options' do
        rule id: 'options', scope: 'public' do
          item do
            one_of do
              current_app_map.keys.each do |index|
                item do
                  index
                end
              end
            end
          end
        end
      end
    end
  end
end
