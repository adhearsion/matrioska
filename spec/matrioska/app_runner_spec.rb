require 'spec_helper'

module Matrioska
  describe AppRunner do
    let(:mock_call) { double 'Call' }
    subject { AppRunner.new mock_call }
    class MockController < Adhearsion::CallController; end

    describe "#start" do
      let(:grxml) {
          RubySpeech::GRXML.draw :mode => 'dtmf', :root => 'inputdigits' do
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
        Punchblock::Component::Input.new(
          { :mode => :dtmf,
            :grammar => {
              :value => grxml.to_s
            }
          }
        )
      }

      it "should start the appropriate component" do
        mock_call.should_receive(:write_and_await_response).with(input_component)
        subject.start
      end
    end

    describe "#map_app" do
      context "with invalid input" do
        let(:too_long) { "ab" }
        let(:wrong) { "a" }
        it "should raise if the first argument is not a single digit string in the range" do
          expect { subject.map_app(too_long){} }.to raise_error ArgumentError, "The first argument should be a single digit String or number in the range 1234567890*#"
          expect { subject.map_app(wrong){} }.to raise_error ArgumentError, "The first argument should be a single digit String or number in the range 1234567890*#"
        end

        it "raises if called without either a class or a block" do
           expect { subject.map_app 1 }.to raise_error ArgumentError, "You need to provide a block or a controller name."
        end

        it "raises if passed both a class and a block" do
           expect { subject.map_app(1, Object){} }.to raise_error ArgumentError, "You cannot specify both a block and a controller name."
        end
      end

      context "with valid input" do
        it "properly sets the map for a block" do
          subject.map_app(3) { p "foo" }
          subject.app_map["3"].should be_a Proc
        end
        it "properly sets the map for a class" do
          subject.map_app(3, Object)
          subject.app_map["3"].should be_a Class
        end
      end
    end

    describe "#match_and_run" do
      before do
        subject.map_app(3) { p "foo" }
        subject.map_app(5, MockController)
      end

      it "does nothing if there is no match, and restarts the launcher" do
        mock_call.should_receive(:execute_controller).never
        subject.should_receive(:start).once
        subject.match_and_run("4")
      end

      it "executes the block if the payload is a Proc" do
        mock_call.should_receive(:execute_controller).once.with(&subject.app_map["3"])
        subject.should_receive(:start).once
        subject.match_and_run("3")
      end
      it "executes the controller if the payload is a Class" do
        mock_call.should_receive(:execute_controller).once.with(kind_of(MockController), kind_of(Proc))
        subject.should_receive(:start).once
        subject.match_and_run("5")
      end
    end

    describe "#handle_input_complete" do
      let(:mock_event) { double('Event', :reason => double('Reason', :utterance => "dtmf-5")) }
      it "runs #match_and_run" do
        subject.should_receive(:match_and_run).with("5").once
        subject.handle_input_complete(mock_event)
      end
    end
  end
end
