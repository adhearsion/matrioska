require 'adhearsion'

class Adhearsion::Call
  def stop_all_runners!
    return unless variables[:matrioska_runners]

    variables[:matrioska_runners].each do |runner|
      runner.stop!
    end
  end

  def runners
    Array(variables[:matrioska_runners])
  end
end
