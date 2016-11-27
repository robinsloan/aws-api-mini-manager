# AWS API Gateway Mini Manager

This is a simple tool to manage a few API keys from the command line.

```
bundle install
ruby api-mini-manager.rb
```

Running the script without arguments will display usage info.

At its most basic, the script takes a name and a memo (most likely an email address) and returns an API key for delivery to an API user via chat, email, whatever. If you're using macOS, it copies the key to the clipboard.

That's it!