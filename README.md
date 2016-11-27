# AWS API Gateway Mini Manager

This is a simple tool to manage a few API keys from the command line.

```
bundle install
ruby api-mini-manager.rb --help
```

In its most basic usage, the script takes a name and a memo (most likely an email address) and returns an API key for delivery to end-user via chat, email, whatever. If you're using macOS, it copies the key to the clipboard.

That's it!