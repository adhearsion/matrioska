require 'spec_helper'

module Matrioska
  describe AppRunner do
    let(:call_id) { SecureRandom.uuid }
    let(:call)    { Adhearsion::Call.new }

    before do
      double call, write_command: true, id: call_id
    end

    subject { AppRunner.new call }

    class MockController < Adhearsion::CallController
      def run
        call.do_stuff_from_a_class
      end
    end

    describe "#start" do
      let(:grxml) {
        RubySpeech::GRXML.draw mode: 'dtmf', root: 'inputdigits' do
          rule id: 'inputdigits', scope: 'public' do
            one_of do
              0.upto(9) { |d| item { d.to_s } }
              item { "#" }
              item { "*" }
            end
          end
        end
      }

      let(:input_component) {
        Punchblock::Component::Input.new mode: :dtmf, grammar: { value: grxml }
      }

      it "should start the appropriate component" do
        call.should_receive(:write_and_await_response).with(input_component)
        subject.start
        subject.status.should == :started
      end
    end

    describe "#stop!" do
      let(:mock_component) { double Punchblock::Component::Input, register_event_handler: true }

      before do
        Punchblock::Component::Input.stub(:new).and_return mock_component
        call.stub(:write_and_await_response)
        subject.start
      end

      it "stops the runner" do
        mock_component.should_receive(:executing?).and_return true
        mock_component.should_receive :stop!
        subject.stop!
        subject.status.should == :stopped
      end
    end

    describe "#map_app" do
      context "with invalid input" do
        let(:too_long) { "ab" }
        let(:wrong) { "a" }

        it "should raise if the first argument is not a single digit string in the range" do
          expect { subject.map_app(too_long) {} }.to raise_error ArgumentError, "The first argument should be a single digit String or number in the range 1234567890*#"
          expect { subject.map_app(wrong) {} }.to raise_error ArgumentError, "The first argument should be a single digit String or number in the range 1234567890*#"
        end

        it "raises if called without either a class or a block" do
          expect { subject.map_app 1 }.to raise_error ArgumentError, "You need to provide a block or a controller name."
        end

        it "raises if passed both a class and a block" do
          expect { subject.map_app(1, Object) {} }.to raise_error ArgumentError, "You cannot specify both a block and a controller name."
        end
      end
    end

    describe "#handle_input_complete" do
      def mock_event(digit)
        double 'Event', reason: double('Reason', utterance: "dtmf-#{digit}")
      end

      before do
        subject.map_app(3) { call.do_stuff_from_a_block }
        subject.map_app(5, MockController)
      end

      context "if there is no match" do
        it "does nothing, and restarts the launcher" do
          call.should_receive(:execute_controller).never
          subject.should_receive(:start).once
          subject.handle_input_complete mock_event("4")
        end

        context "if the call has been hung up" do
          before { call.should_receive(:write_and_await_response).and_raise Adhearsion::Call::Hangup }

          it "should not raise Hangup but stop cleanly" do
            subject.handle_input_complete mock_event("4")
          end
        end
      end

      it "executes the block if the payload is a Proc" do
        call.should_receive(:do_stuff_from_a_block).once
        subject.should_receive(:start).once
        subject.handle_input_complete mock_event("3")
        sleep 0.1 # Give the controller time to finish and the callback to fire
      end

      it "executes the controller if the payload is a Class" do
        call.should_receive(:do_stuff_from_a_class).once
        subject.should_receive(:start).once
        subject.handle_input_complete mock_event("5")
        sleep 0.1 # Give the controller time to finish and the callback to fire
      end
    end
  end
end
