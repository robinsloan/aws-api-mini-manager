require "rubygems"
require "bundler/setup"

require "slop"
require "archieml"
require "aws-sdk"

opts = Slop.parse do |args|
  args.string "-a", "--config", "Config filename, if not aws_config.aml", default: "aws_config.aml"
  args.bool "-l", "--list", "Flag to list all current keys and exit immediately", default: false
  args.bool "-g", "--generate", "Generate a new key", default: false
  args.string "-n", "--name", "Name of new API key holder"
  args.string "-m", "--memo", "Memo (probably email)"
  args.bool "-d", "--disable", "Disable the specified key", default: false
  args.bool "-x", "--delete", "Delete the specified key", default: false
  args.string "-k", "--key", "API key to be disabled or deleted"
  args.on "--help" do
    puts args
    exit
  end
end

puts ""

if not ( opts[:list] || opts[:generate] || opts[:disable] || opts[:delete])
  puts "Use the --help flag to see the available options. Exiting."
  puts ""
  exit
end

# note: the config file is AML, not YAML
# why? because i think archieml is the coolest

# config.aml should contain:
# aws_id: foo
# aws_secret: bar
# api_id: blee

if File.exist?(opts[:config])
  config = Archieml.load_file(opts[:config])
else
  puts "No file found at #{opts[:config]}! Exiting."
  puts ""
  exit
end

# https://us-west-2.console.aws.amazon.com/apigateway/home

region = config["region"] || "us-west-2"
aws_id = config["aws_id"]
aws_secret = config["aws_secret"]
api_id = config["api_id"]
stage_name = config["stage_name"] || "prod"

api = Aws::APIGateway::Client.new(region: region, credentials: Aws::Credentials.new(aws_id, aws_secret))

if opts[:list]
  puts "Listing all keys..."
  puts ""
  begin
    enabled = api.get_api_keys.items.select do |key| key.enabled end
    disabled = api.get_api_keys.items.select do |key| !key.enabled end

    {ENABLED: enabled, DISABLED: disabled}.each_pair do |name, list|
      puts name
      puts ""
      list.each do |key|
        puts key.name
        puts key.description
        puts key.id
        puts "Enabled? #{key.enabled ? "Yes" : "No"}"
        puts ""
      end
    end


  rescue Aws::APIGateway::Errors::NotFoundException => e
    puts "Error: can't list keys."
    puts ""
  end

  puts ""
  exit
end

if opts[:disable]
  unless opts[:key]
    puts "Need to specify an API key to disable. Exiting."
    puts ""
    exit
  end

  puts "Attempting to disable API key #{opts[:key]}..."
  begin
    key = api.get_api_key({api_key: opts[:key]})
    api.update_api_key({api_key: opts[:key], patch_operations: [{op: "replace", path: "/enabled", value: "false"}]})
    puts "Disabled."
  rescue Aws::APIGateway::Errors::NotFoundException => e
    puts "Error: that key doesn't seem to exist."
    puts ""
  end

  puts ""
  exit
end

if opts[:delete]
  unless opts[:key]
    puts "Need to specify an API key to delete. Exiting."
    puts ""
    exit
  end

  puts "Attempting to delete API key #{opts[:key]}..."
  begin
    key = api.get_api_key({api_key: opts[:key]})
    api.delete_api_key({api_key: opts[:key]})
    puts "Deleted."
  rescue Aws::APIGateway::Errors::NotFoundException => e
    puts "Error: that key doesn't seem to exist."
    puts ""
  end

  puts ""
  exit
end

# http://docs.aws.amazon.com/sdkforruby/api/Aws/APIGateway/Client.html#create_api_key-instance_method

unless opts[:name] and opts[:memo]
  puts "Must specify name and memo field. Exiting."
  puts ""
  exit
end

key = api.create_api_key({
  name: opts[:name],
  description: opts[:memo],
  enabled: true,
  stage_keys: [
    {
    rest_api_id: api_id,
    stage_name: stage_name
    },
  ],
})

puts "Key created:"
puts key.id

if (/darwin/ =~ RUBY_PLATFORM) != nil
  `echo #{key.id} | pbcopy`
  puts "(It's been copied to the clipboard)"
end

puts ""
