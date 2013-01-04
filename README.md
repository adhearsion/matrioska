# Matrioska

Matrioska is an Adhearsion plugin for running in-call apps at the press of a DTMF.

By mapping controllers or blocks to the desired applications, a listener object waits for DTMF and reacts by executing the specified payload.

## Usage Example

```ruby
#inside your controller
runner = Matrioska::AppRunner.new self
runner.map_app 3 do
  logger.info "hi there!"
end
runner.map_app 5, AppController

call.on_end do
  runner.stop
end

runner.start
```

