module Matrioska
  module DialWithApps
    def dial_with_local_apps(to, options = {}, &block)
      dial = Adhearsion::CallController::Dial::Dial.new to, options, call

      runner = Matrioska::AppRunner.new call
      yield runner, dial
      runner.start

      dial.track_originating_call
      dial.prep_calls
      dial.place_calls
      dial.await_completion
      dial.cleanup_calls
      dial.status
    end

    def dial_with_remote_apps(to, options = {}, &block)
      dial = Adhearsion::CallController::Dial::Dial.new to, options, call

      dial.track_originating_call

      dial.prep_calls do |new_call|
        new_call.on_joined call do
          runner = Matrioska::AppRunner.new new_call
          yield runner, dial
          runner.start
        end
      end

      dial.place_calls
      dial.await_completion
      dial.cleanup_calls
      dial.status
    end

    def dial_with_apps(to, options = {}, &block)
      dial = Adhearsion::CallController::Dial::Dial.new to, options, call
      yield dial

      if @local_runner_block
        local_runner = Matrioska::AppRunner.new call
        @local_runner_block.call local_runner
        local_runner.start
      end

      dial.prep_calls do |new_call|
        new_call.on_joined call do
          if @remote_runner_block
            remote_runner = Matrioska::AppRunner.new new_call
            @remote_runner_block.call remote_runner
            remote_runner.start
          end
        end
      end

      dial.track_originating_call
      dial.place_calls
      dial.await_completion
      dial.cleanup_calls
      dial.status
    end

  private

    def local(&block)
      @local_runner_block = block
    end

    def remote(&block)
      @remote_runner_block = block
    end
  end
end
