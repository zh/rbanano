require 'rspec'
require 'webmock/rspec'
require 'pry'
require 'stringio'
require 'banano'

WebMock.disable_net_connect!

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.warnings = true
  config.disable_monkey_patching!
  config.default_formatter = 'doc' if config.files_to_run.one?
  config.order = :random
  Kernel.srand config.seed
end

def headers
  {
    Accept: '*/*',
    'Accept-Encoding': 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
    'Content-Type': 'application/json',
    'User-Agent': 'Banano RPC Client'
  }
end

# From http://www.virtuouscode.com/2011/08/25/temporarily-disabling-warnings-in-ruby/
def silent_warnings
  old_stderr = $stderr
  $stderr = StringIO.new
  yield
ensure
  $stderr = old_stderr
end
