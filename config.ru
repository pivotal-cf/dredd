require 'octokit'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')
require 'dredd'

config = Dredd::Config.from_file('config/config.yml')
template = File.read('config/template.md.erb')

github_client = Octokit::Client.new(login: config.username,
    oauth_token: config.token)

bootstrapper = Dredd::HookBootstrapper.new(github_client,
                                           config.callback_url,
                                           config.callback_secret)
config.repositories.each do |repo|
  bootstrapper.bootstrap_repository(repo)
end

email_filter = Dredd::EmailFilter.new(github_client, config.allowed_emails)
username_filter = Dredd::UsernameFilter.new(config.allowed_usernames)
composite_filter = Dredd::CompositeFilter.new([email_filter, username_filter])

commenter = Dredd::PullRequestCommenter.new(github_client, template)
filtered_commenter = Dredd::FilteredCommenter.new(commenter, composite_filter)

Dredd::DreddApp.set :commenter, filtered_commenter
Dredd::DreddApp.set :secret, config.callback_secret

run Dredd::DreddApp
