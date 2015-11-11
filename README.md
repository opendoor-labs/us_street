# UsStreet

Parses and normalizes the street part of an address for US streets into its parts.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'us_street'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install us_street

## Usage

Can make sense of most streets

    street = UsStreet.parse('123 north Fake street south 2034 #12')

    # component accessors
    street.street_number == '123'
    street.dir_prefix == 'N'
    street.street_name == 'Fake'
    street.street_suffix == 'St'
    street.dir_suffix == 'S'
    street.road_number == '2034'
    street.unit == '12'

    street.street == 'N Fake St S 2034'
    street.full_street == '123 N Fake St S 2034'
    street.display == '123 N Fake St S 2034 #12'

It also works on simple streets

    street = UsStreet.parse('12 st')
    street.full_street = '12th St'

    street = UsStreet.parse('123 north 12 st')
    street.full_street == '123 N 12th St'

    street = UsStreet.parse('123 something road')
    street.full_street == '123 Something Rd'

## Contributing

1. Fork it ( https://github.com/[my-github-username]/us_street/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
