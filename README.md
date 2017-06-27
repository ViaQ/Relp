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

### Server

To run server just creat instance of `Relp::RelpServer.new(host, port, logger = nil, callback)`
and than call method run on instance of server e.g. `server.run`

`host` 
  * This is a required setting.
  * Value type is string
  * There is no default value for this setting.
  * Specifies address you want to bind to, use "0.0.0.0" to bind to any address



`port` 

  * This is a required setting.
  * Value type is number
  * There is no default value for this setting.
  * Sets on which port you want to listen for incoming RELP connections


`logger`
  
  * This is optional setting
  * Value type is logger object
  * If is not set - default is `Logger.new(STDOUT)` with all levels of logging
 
`callback`
  * This is a required setting.
  * Method you want to be executed upon successfully accepted message, it has only one :Hash parameter, which is message itself.
  
####Important Methods
  * `run` Start connceting clients
  *  `server_shutdown` Close connection to all clients and shutdown server

### Client

Coming soon.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. 
## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ViaQ/Relp.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

