require 'spec_helper'

module Matrioska
  describe AppRunner do
    let(:metadata) do
      {:foo => "bar"}
    end
    let(:mock_controller) { mock('Controller', :metadata => metadata) }
    subject { AppRunner.new mock_controller }

    describe "#start" do
      it "should not block" do
        Thread.should_receive(:new).once.and_return mock(:run_loop)
        subject.start
      end

      it 'should not start a second thread if already running' do
        run_loop = mock(:run_loop_thread)
        run_loop.should_receive(:alive?).once.and_return true
        subject.instance_variable_set(:@run_loop, run_loop)

        Thread.should_receive(:new).never
        subject.start
      end
    end

    describe "#wait_for_input" do
      before do
        subject.map_app(3) { p "foo" }
        subject.map_app(5, Object)
      end

      it "should call #wait_for_digit" do
        mock_controller.should_receive(:wait_for_digit).once.with(-1)
        subject.should_receive(:match_and_run).once
        subject.wait_for_input
      end

      it "should invoke #match_and_run" do
        mock_controller.should_receive(:wait_for_digit).with(-1).and_return("5")
        mock_controller.should_receive(:invoke).once.with(subject.app_map["5"], metadata)
        subject.wait_for_input
      end
    end

    describe "#app_loop" do
      it "loops as long as the listener is running" do
        subject.should_receive(:running?).and_return(true, true, false)
        mock_controller.should_receive(:wait_for_digit).with(-1).twice
        subject.should_receive(:match_and_run).twice
        subject.app_loop
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
        subject.map_app(5, Object)
      end
      
      it "does nothing if there is no match" do
        mock_controller.should_receive(:instance_exec).never
        mock_controller.should_receive(:invoke).never
        subject.match_and_run("4")
      end

      it "uses instance_exec if the payload is a Proc" do
        mock_controller.should_receive(:instance_exec).once.with(metadata, &subject.app_map["3"])
        mock_controller.should_receive(:invoke).never
        subject.match_and_run("3")
      end
      it "uses invoke if the payload is a Class" do
        mock_controller.should_receive(:instance_exec).never
        mock_controller.should_receive(:invoke).once.with(subject.app_map["5"], metadata)
        subject.match_and_run("5")
      end
    end
  end
end
