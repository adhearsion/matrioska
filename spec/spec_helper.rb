require 'adhearsion'
require 'matrioska'

RSpec.configure do |config|
  config.color_enabled = true
  config.tty = true

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.before :suite do
    Adhearsion::Logging.start :trace, Adhearsion.config.core.logging.formatter
  end

  config.before do
    @uuid = SecureRandom.uuid
    Adhearsion.stub new_request_id: @uuid
  end
end
