Fwissr
======

A simple configuration registry tool by Fotonauts.


Install
=======

```bash
$ [sudo] gem install fwissr
```

Or add it to your `Gemfile`.


Usage
=====

Create the main `fwissr.json` configuration file in either `/etc/fwissr/` or `~/.fwissr/` directory:

```json
{ "foo" : "bar", "horn" : { "loud" : true, "sounds": [ "TUuuUuuuu", "tiiiiiiIIiii" ] } }
```

In your application, you can access `fwissr`'s global registry that way:

```ruby
require 'fwissr'

Fwissr['/foo']
# => "bar"

Fwissr['/horn']
# => { "loud" => true, "sounds" => [ "TUuuUuuuu", "tiiiiiiIIiii" ] }

Fwissr['/horn/loud']
# => true

Fwissr['/horn/sounds']
# => [ "TUuuUuuuu", "tiiiiiiIIiii" ]
```

In bash you can call the `fwissr` tool:

```bash
$ fwissr /foo
bar

# json output
$ fwissr -j /horn
{ "loud" : true, "sounds": [ "TUuuUuuuu", "tiiiiiiIIiii" ] }

# pretty print json output
$ fwissr -j -p /horn
{
  "loud": true,
  "sound": [
    "TUuuUuuuu",
    "tiiiiiiIIiii"
  ]
}

# dump all registry with pretty print json output
# NOTE: yes, that's the same as 'fwissr -jp /'
$ fwissr --dump -jp
{
  "horn": {
    "loud": true,
    "sound": [
      "TUuuUuuuu",
      "tiiiiiiIIiii"
    ]
  }
}
```


Additional configuration file
=============================

Provide additional configuration files with the `fwissr_sources` setting in `fwissr.json`:

```json
{
   "fwissr_sources": [
     { "filepath": "/etc/my_app.json" },
   ],
}
```

The settings for that configuration will be prefixed with the file name.

For example, with that `/etc/my_app.json`:

```json
{ "foo": "bar", "bar": "baz" }
```

the settings can be accessed that way:

```ruby
require 'fwissr'

Fwissr['/my_app']
# => { "foo" => "bar", "bar" => "baz" }

Fwissr['/my_app/foo']
# => "bar"

Fwissr['/my_app/bar']
# => "baz"
```

You can bypass that behaviour with the `top_level` setting:

```json
{
   "fwissr_sources": [
     { "filepath": "/etc/my_app.json", "top_level": true },
   ],
}
```

With the `top_level` setting activated the configuration settings are added to registry root:

```ruby
require 'fwissr'

Fwissr['/']
# => { "foo" => "bar", "bar" => "baz" }

Fwissr['/foo']
# => "bar"

Fwissr['/bar']
# => "baz"
```

Note that you can provide `.json` and `.yaml` configuration files.


Directory of configuration files
================================

If the `filepath` setting is a directory, then all `.json` and `.yaml` files in that directory (but NOT in subdirectories) will be imported in global registry:

```json
{
   "fwissr_sources": [
     { "filepath": "/mnt/my_app/conf/" },
   ],
}
```

With `/mnt/my_app/conf/database.yaml`:

```yaml
production:
  adapter: mysql2
  encoding: utf8
  database: my_app_db
  username: my_app_user
  password: my_app_pass
  host: db.my_app.com
```

and `/mnt/my_app/conf/credentials.json`:

```json
{ "key": "i5qw64816c", "code": "448e4wef161" }
```

the settings can be accessed that way:

```ruby
require 'fwissr'

Fwissr['/database']
# => { "production" => { "adapter" => "mysql2", "encoding" => "utf8", "database" => "my_app_db", "username" => "my_app_user", "password" => "my_app_pass", "host" => "db.my_app.com" } }

Fwissr['/database/production/host']
# => "db.my_app.com"

Fwissr['/credentials']
# => { "key" => "i5qw64816c", "code" => "448e4wef161" }

Fwissr['/credentials/key']
# => "i5qw64816c"
```


File name mapping to setting path
=================================

Use dots in file name to define a path for configuration settings.

For example:

```json
{
   "fwissr_sources": [
     { "filepath": "/etc/my_app.database.slave.json" },
   ],
}
```

with that `/etc/my_app.database.slave.json`:

```json
{ "host": "db.my_app.com", "port": "1337" }
```

the settings can be accessed that way:

```ruby
require 'fwissr'

Fwissr['/my_app/database/slave/host']
# => "db.my_app.com"

Fwissr['/my_app/database/slave/port']
# => "1337"
```


Mongodb source
==============

You can define a mongob collection as a configuration source:

```json
{
   "fwissr_sources": [
        { "mongodb": "mongodb://db1.example.net/my_app", "collection": "config" },
   ],
}
```

Each document in the collection is a setting for that configuration.

The `_id` document field is the setting key, and the `value` document field is the setting value.

For example:

```
> db["my_app.stuff"].find()
{ "_id" : "foo", "value" : "bar" }
{ "_id" : "database", "value" : { "host": "db.my_app.com", "port": "1337" } }
```

```ruby
require 'fwissr'

Fwissr['/my_app/stuff/foo']
# => "bar"

Fwissr['/my_app/stuff/database']
# => { "host": "db.my_app.com", "port": "1337" }

Fwissr['/my_app/stuff/database/port']
# => "1337"
```

As with configuration files you can use dots in collection name to define a path for configuration settings. The `top_level` setting is also supported to bypass that behaviour. Note too that the `fwissr` collection is by default a `top_level` configuration (as the `/etc/fwissr/fwissr.json` configuration file).


Refreshing registry
===================

Enable registry auto-update with the `refresh` source setting.

For example:

```json
{
   "fwissr_sources": [
        { "filepath": "/etc/my_app/my_app.json" },
        { "filepath": "/etc/my_app/stuff.json", "refresh": true },
        { "mongodb": "mongodb://db1.example.net/my_app", "collection": "production" },
        { "mongodb": "mongodb://db1.example.net/my_app", "collection": "config", "refresh": true },
   ],
}
```

The `/etc/my_app/my_app.json` configuration file and the `production` mongodb collection are read only once when global registry is accessed for the first time, whereas the settings holded by the `/etc/my_app/stuff.json` configuration file and the `config` mongodb collection are expired periodically and re-fetched.

The default freshness is 15 seconds, but you can change it with the `fwissr_refresh_period` setting:

```json
{
   "fwissr_sources": [
        { "filepath": "/etc/my_app/my_app.json" },
        { "filepath": "/etc/my_app/stuff.json", "refresh": true },
        { "mongodb": "mongodb://db1.example.net/my_app", "collection": "production" },
        { "mongodb": "mongodb://db1.example.net/my_app", "collection": "config", "refresh": true },
   ],
   "fwissr_refresh_period": 60,
}
```

The refresh is triggered when accessing the global registry, and it is done asynchronously in a thread:

```ruby
require 'fwissr'

Fwissr['/stuff/foo']
# => "bar"

# > Change '/etc/my_app/stuff.json' file by setting: {"foo":"baz"}

# Wait 2 minutes
sleep(120)

# This following registry access triggers an async refresh in a thread, and the old value is still returned for now
Fwissr['/stuff/foo']
# => "bar"

# > Async refresh is over

# The new value is now in the registry
Fwissr['/stuff/foo']
# => "baz"
```


Create a custom registry
========================

`fwissr` is intended to be easy to setup: just create a configuration file and that configuration is accessible via the global registry. But if you need to, you can create your own custom registry.

```ruby
require 'fwissr'

# create a custom registry
registry = Fwissr::Registry.new('refresh_period' => 20)

# add configuration sources to registry
registry.add_source(Fwissr::Source.from_settings({ 'filepath': '/etc/my_app/my_app.json' }))
registry.add_source(Fwissr::Source.from_settings({ 'filepath': '/etc/my_app/stuff.json', 'refresh': true }))
registry.add_source(Fwissr::Source.from_settings({ 'mongodb': 'mongodb://db1.example.net/my_app', 'collection': 'production' }))
registry.add_source(Fwissr::Source.from_settings({ 'mongodb': 'mongodb://db1.example.net/my_app', 'collection': 'config', 'refresh': true }))

registry['/stuff/foo']
# => 'bar'
```


Credits
=======

The Fotonauts team: http://www.fotopedia.com

Copyright (c) 2013 Fotonauts released under the MIT license.
