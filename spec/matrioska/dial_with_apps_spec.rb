require 'spec_helper'

require 'matrioska/dial_with_apps'

describe Matrioska::DialWithApps do
  let(:call_id)           { SecureRandom.uuid }
  let(:call)              { Adhearsion::Call.new }
  let(:controller_class)  { Class.new Adhearsion::CallController }
  let(:controller)        { controller_class.new call }

  let(:to)              { 'sip:foo@bar.com' }
  let(:other_call_id)   { SecureRandom.uuid }
  let(:other_mock_call) { Adhearsion::OutboundCall.new }

  let(:mock_answered) { Punchblock::Event::Answered.new }

  before do
    controller_class.mixin described_class
    call.wrapped_object.stub id: call_id, write_command: true
    other_mock_call.wrapped_object.stub id: other_call_id, write_command: true
  end

  def mock_end(reason = :hangup_command)
    Punchblock::Event::End.new.tap { |event| event.stub reason: reason }
  end

  describe "#dial_with_local_apps" do
    it "starts an app listener on the originating call using the passed block, dials the call to the correct endpoint, and returns a dial status object" do
      mock_app_runner = Matrioska::AppRunner.new call
      Matrioska::AppRunner.should_receive(:new).once.with(call).and_return mock_app_runner
      mock_app_runner.should_receive(:foo).once.with(instance_of(Adhearsion::CallController::Dial::ParallelConfirmationDial))
      mock_app_runner.should_receive(:start).once

      Adhearsion::OutboundCall.should_receive(:new).and_return other_mock_call
      other_mock_call.should_receive(:dial).with(to, :from => 'foo').once

      dial_thread = Thread.new do
        status = controller.dial_with_local_apps(to, :from => 'foo') do |runner, dial|
          runner.foo dial
        end

        status.should be_a Adhearsion::CallController::Dial::DialStatus
        joined_status = status.joins[status.calls.first]
        joined_status.duration.should == 0.0
        joined_status.result.should == :no_answer
      end

      sleep 0.1
      other_mock_call << mock_end
      dial_thread.join.should be_true
    end
  end
end
