# RELP

This library contains native implementation of [RELP protocol](http://www.rsyslog.com/doc/relp.html) in ruby with TLS support. At the moment only server-side
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

To run server just create instance of `Relp::RelpServer.new(port, callback, host, tls_context, logger)`
and then call method run on instance of server e.g. `server.run`

`port` 

  * This is a required setting.
  * Value type is number
  * There is no default value for this setting.
  * Sets on which port you want to listen for incoming RELP connections

`callback`
  * This is a required setting.
  * Method you want to be executed upon successfully accepted message, it has only one :string parameter, which is message itself.
  
`host` 
  * This is a required setting.
  * Value type is string
  * Default value is "0.0.0.0' to bind any address
  * Specifies address you want to bind to, use "0.0.0.0" to bind to any address
 
`tls_context` 
  * Value type is SSL_context_object = OpenSSL::SSL::SSLContext.new See -> OpenSSL <a href="http://ruby-doc.org/stdlib-2.0.0/libdoc/openssl/rdoc/OpenSSL/SSL/SSLContext.html">homepage</a>
  * If is not set - server runs without TLS or SSL encryption
  * Example of TLS/SSL context object:
  ```ruby
      sslContext = OpenSSL::SSL::SSLContext.new
      sslContext.cert = OpenSSL::X509::Certificate.new(File.open("path/to/certificate/cert.pem"))
      sslContext.key = OpenSSL::PKey::RSA.new(File.open("path/to/key/key.pem"))
      sslContext.ca_file = 'path/to/certificate/authority/ca.pem'
      sslContext.verify_mode = OpenSSL::SSL::VERIFY_PEER #only if you want verify peer
  ```
 
`logger`
  
  * This is optional setting
  * Value type is logger object
  * If is not set - default is `Logger.new(STDOUT)` with all levels of logging
 

#### Important Methods
  * `run` Start connecting clients
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

