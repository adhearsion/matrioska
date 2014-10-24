require 'adhearsion'
require 'matrioska'

describe Adhearsion::Call do
  let(:call) { Adhearsion::Call.new }


  it 'should track all runners launched with it' do
    runner = Matrioska::AppRunner.new call
    call.runners.should include(runner)
  end

  it 'should be possible to stop all runners on a call' do
    r1 = Matrioska::AppRunner.new call
    r2 = Matrioska::AppRunner.new call
    r3 = Matrioska::AppRunner.new call

    r1.should_receive(:stop!).once
    r2.should_receive(:stop!).once
    r3.should_receive(:stop!).once

    call.stop_all_runners!
  end


end
