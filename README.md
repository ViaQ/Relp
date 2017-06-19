# RELP

This library contains native implementation of [RELP protocol](http://www.rsyslog.com/doc/relp.html) in ruby. At the moment only server-side
is properly implemented and (to some extent) tested.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'relp'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install relp

## Usage

To use this library, require it in your ruby application file, then you can create `Relp::RelpServer`. Arguments are `(bind, port, [log,] callback)`,
where `bind` is :string and specifies address you want to bind to, use "0.0.0.0" to bind to any address. `port` is :integer and sets on which port you want to listen for incoming RELP connections.
`log` is optional and allows you to pass you application's logger into relp library to receive its logs, otherwise the server creates its own standard logger. Finally `callback` is method you want to be
executed upon successfully accepted message, it has only one :string parameter, which is message itself.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dhlavac/RELP.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

