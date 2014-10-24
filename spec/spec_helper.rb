require 'adhearsion'
require 'matrioska'

RSpec.configure do |config|
  config.color_enabled = true
  config.tty = true

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.before :suite do
    Adhearsion::Logging.start Adhearsion::Logging.default_appenders, :trace, Adhearsion.config.platform.logging.formatter
  end

  config.before do
    @uuid = SecureRandom.uuid
    Punchblock.stub new_request_id: @uuid
  end
end
