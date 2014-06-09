# Docman

Docman made for DOCroot MANagement for Drupal projects. Useful to manage multiple websites in one Drupal multisite installation.

## Installation

Add this line to your application's Gemfile:

    gem 'docman'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install docman

## Usage (in process of documentation)

Build local environment:

    $ docman build local environment

Build the destination docroot using your settings:

    $ docman build <docroot> stable

Deploy built docroot (Drupal core with multiple websites in multisite) to your environment:

    $ docman deploy <docroot>

## Contributing

1. Fork it ( https://github.com/Adyax/docman/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request