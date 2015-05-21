require 'spec_helper'

describe Matrioska::DialWithApps do
  let(:call_id)           { SecureRandom.uuid }
  let(:call)              { Adhearsion::Call.new }
  let(:controller_class)  { Class.new Adhearsion::CallController }
  let(:controller)        { controller_class.new call }

  let(:to)              { 'sip:foo@bar.com' }
  let(:other_call_id)   { SecureRandom.uuid }
  let(:other_mock_call) { Adhearsion::OutboundCall.new }

  let(:second_to)               { 'sip:baz@bar.com' }
  let(:second_other_call_id)    { SecureRandom.uuid }
  let(:second_other_mock_call)  { Adhearsion::OutboundCall.new }

  let(:mock_answered) { Punchblock::Event::Answered.new }

  before do
    controller_class.mixin described_class
    call.wrapped_object.stub id: call_id, write_command: true
    other_mock_call.wrapped_object.stub id: other_call_id, write_command: true
    second_other_mock_call.wrapped_object.stub id: second_other_call_id, write_command: true
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

  describe "#dial_with_remote_apps" do
    it "starts an app listener on the joined call using the passed block, dials the call to the correct endpoint, and returns a dial status object" do
      call.should_receive(:answer).once

      mock_app_runner = Matrioska::AppRunner.new other_mock_call

      Matrioska::AppRunner.should_receive(:new).once.with(second_other_mock_call).and_return mock_app_runner
      mock_app_runner.should_receive(:foo).once.with(instance_of(Adhearsion::CallController::Dial::ParallelConfirmationDial))
      mock_app_runner.should_receive(:start).once

      Adhearsion::OutboundCall.should_receive(:new).and_return other_mock_call, second_other_mock_call

      other_mock_call.should_receive(:dial).with(to, :from => 'foo').once
      other_mock_call.should_receive(:hangup).once.and_return do
        other_mock_call << mock_end
      end

      second_other_mock_call.should_receive(:dial).with(second_to, :from => 'foo').once
      second_other_mock_call.should_receive(:join).once.and_return do
        second_other_mock_call << Punchblock::Event::Joined.new(call_uri: call_id)
      end

      dial_thread = Thread.new do
        status = controller.dial_with_remote_apps([to, second_to], :from => 'foo') do |runner, dial|
          runner.foo dial
        end

        status.should be_a Adhearsion::CallController::Dial::DialStatus
        joined_status = status.joins[status.calls.first]
        joined_status.duration.should == 0.0
        joined_status.result.should == :no_answer
      end

      sleep 0.1
      second_other_mock_call << Punchblock::Event::Answered.new
      second_other_mock_call << mock_end
      dial_thread.join.should be_true
    end
  end

  describe "#dial_with_apps" do
    let(:mock_local_runner)  { Matrioska::AppRunner.new call }
    let(:mock_remote_runner) { Matrioska::AppRunner.new second_other_mock_call }

    before do
      Matrioska::AppRunner.stub(:new).with(call).and_return mock_local_runner
      Matrioska::AppRunner.stub(:new).with(second_other_mock_call).and_return mock_remote_runner

      Adhearsion::OutboundCall.should_receive(:new).and_return other_mock_call, second_other_mock_call
    end

    it "starts an app listener on both ends of the call" do
      call.should_receive(:answer).once

      mock_local_runner.should_receive(:foo).once
      mock_local_runner.should_receive(:start).once

      mock_remote_runner.should_receive(:bar).once
      mock_remote_runner.should_receive(:start).once

      other_mock_call.should_receive(:dial).with(to, from: 'foo').once
      other_mock_call.should_receive(:hangup).once.and_return do
        other_mock_call << mock_end
      end

      second_other_mock_call.should_receive(:dial).with(second_to, from: 'foo').once
      second_other_mock_call.should_receive(:join).once.and_return do
        second_other_mock_call << Punchblock::Event::Joined.new(call_uri: call_id)
      end

      dial_thread = Thread.new do
        controller.instance_exec(to,second_to) do |to, second_to|
            dial_with_apps([to, second_to], from: 'foo') do |dial|
            local do |runner|
              runner.foo
            end

            remote do |runner|
              runner.bar
            end
          end
        end
      end

      sleep 0.1
      second_other_mock_call << mock_answered
      second_other_mock_call << mock_end
      dial_thread.join.should be_true
    end

    it "allows specifying only a local listener" do
      call.should_receive(:answer).once

      mock_local_runner.should_receive(:bar).once
      mock_local_runner.should_receive(:start).once

      mock_remote_runner = nil

      other_mock_call.should_receive(:dial).with(to, from: 'foo').once
      other_mock_call.should_receive(:hangup).once.and_return do
        other_mock_call << mock_end
      end

      second_other_mock_call.should_receive(:dial).with(second_to, from: 'foo').once
      second_other_mock_call.should_receive(:join).once.and_return do
        second_other_mock_call << Punchblock::Event::Joined.new(call_uri: call_id)
      end

      dial_thread = Thread.new do
        controller.instance_exec(to,second_to) do |to, second_to|
            dial_with_apps([to, second_to], from: 'foo') do |dial|

            local do |runner|
              runner.bar
            end
          end
        end
      end

      sleep 0.1
      second_other_mock_call << mock_answered
      second_other_mock_call << mock_end
      dial_thread.join.should be_true
    end

    it "allows specifying only a remote listener" do
      call.should_receive(:answer).once

      mock_local_runner = nil

      mock_remote_runner.should_receive(:bar).once
      mock_remote_runner.should_receive(:start).once

      other_mock_call.should_receive(:dial).with(to, from: 'foo').once
      other_mock_call.should_receive(:hangup).once.and_return do
        other_mock_call << mock_end
      end

      second_other_mock_call.should_receive(:dial).with(second_to, from: 'foo').once
      second_other_mock_call.should_receive(:join).once.and_return do
        second_other_mock_call << Punchblock::Event::Joined.new(call_uri: call_id)
      end

      dial_thread = Thread.new do
        controller.instance_exec(to,second_to) do |to, second_to|
            dial_with_apps([to, second_to], from: 'foo') do |dial|

            remote do |runner|
              runner.bar
            end
          end
        end
      end

      sleep 0.1
      second_other_mock_call << mock_answered
      second_other_mock_call << mock_end
      dial_thread.join.should be_true
    end
  end
end
