# Docman

Docman made for DOCroot MANagement for Drupal projects. Useful to manage multiple websites in one Drupal multisite installation. We are assuming that there is a git repository with Drupal core and multiple git repositories for each website in multisite environment (think about each repository containing /modules /themes /libraries, etc). This becomes useful, if you can setup a middleware like jenkins which will effectively "build" your multisite environment using this tool. 

Notes: we are speaking about the code only, media files should be managed separately and for now are out of scope of this tool.

Docman requires Linux or OS X.

## Installation

    $ gem install docman

## Usage (in process of documentation)

Init local environment:

    $ docman init <project-dir> <config-repo> # Template: https://github.com/Adyax/docman-config

Build local environment:

    $ docman build local {state}

where state can be: development, staging, stable.


Work on your website!


Bump your production version:

    $ docman bump 

Build the destination docroot using your settings:

    $ docman build <docroot> stable


## Contributing

1. Fork it ( https://github.com/Adyax/docman/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
