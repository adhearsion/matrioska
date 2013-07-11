# Matrioska

Matrioska is an Adhearsion plugin for running in-call apps at the press of a DTMF.

By mapping controllers or blocks to the desired applications, a listener object waits for DTMF and reacts by executing the specified payload.

## Usage Example

```ruby
#inside your controller
runner = Matrioska::AppRunner.new(call)
runner.map_app 3 do
  logger.info "hi there!"
end
runner.map_app 5, AppController

call.on_end do
  runner.stop
end

runner.start
```

### Author

Original author: [Luca Pradovera](https://github.com/polysics)

### Links

* [Adhearsion](http://adhearsion.com)
* [Source](https://github.com/polysics/matrioska)
* [Bug Tracker](https://github.com/polysics/matrioska/issues)

### Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  * If you want to have your own version, that is fine but bump version in a commit by itself so I can ignore when I pull
* Send me a pull request. Bonus points for topic branches.

### Copyright

Copyright (c) 2013 Adhearsion Foundation Inc. MIT license (see LICENSE for details).
