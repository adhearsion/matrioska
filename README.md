[![Build Status](https://secure.travis-ci.org/adhearsion/matrioska.png?branch=develop)](http://travis-ci.org/adhearsion/matrioska)

# Matrioska

Matrioska is an Adhearsion plugin for running in-call apps at the press of a DTMF.

By mapping controllers or blocks to the desired applications, a listener object waits for DTMF and reacts by executing the specified payload.

## Usage Example

```ruby
# inside your controller
runner = Matrioska::AppRunner.new call
runner.map_app 3 do
  logger.info "hi there!"
end
runner.map_app 5, AppController

runner.start
```

### Using local and remote apps with at the same time with a parallel dial
```ruby
# inside your controller
dial_with_apps ['user/userb'] do |dial|
  local do |runner|
    runner.map_app '1' do
      say 'Gosh you sound stunning today leg a'
    end
  end

  remote do |runner|
    runner.map_app '2' do
      say 'Gosh you sound stunning today leg b'
    end
  end
end
```

### Links

* [Adhearsion](http://adhearsion.com)
* [Source](https://github.com/polysics/matrioska)
* [Bug Tracker](https://github.com/polysics/matrioska/issues)

### Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a future version unintentionally.
* Commit, do not mess with Rakefile, version, or history.
  * If you want to have your own version, that is fine but bump version in a commit by itself so I can ignore when I pull
* Send me a pull request. Bonus points for topic branches.

### Credits

Original author: [Luca Pradovera](https://github.com/polysics)

Developed by [Mojo Lingo](http://mojolingo.com) in partnership with [RingPlus](http://ringplus.net).

Thanks to [RingPlus](http://ringplus.net) for ongoing sponsorship of Matrioska.

### Copyright

Copyright (c) 2013 Adhearsion Foundation Inc. MIT license (see LICENSE for details).
