require 'rspec/core/rake_task'
require 'kitchen'

# Style tests. Rubocop and Foodcritic
namespace :style do
  require 'rubocop/rake_task'
  desc 'Run Ruby style checks'
  RuboCop::RakeTask.new(:ruby)

  require 'foodcritic'
  desc 'Run Chef style checks'
  FoodCritic::Rake::LintTask.new(:chef) do |t|
    t.options = {
      fail_tags: ['any']
    }
  end
end

desc 'Run all style checks'
task style: ['style:ruby', 'style:chef']

desc 'Run ChefSpec examples'
RSpec::Core::RakeTask.new(:unit) do |t|
  t.rspec_opts = ['--color --format progress']
  # t.pattern = './spec/unit/filetests/*_spec.rb'
  t.pattern = './spec/unit/recipes/*_spec.rb'
end

desc 'Run Test Kitchen'
task :integration do
  Kitchen.logger = Kitchen.default_file_logger
  Kitchen::Config.new.instances.each do |instance|
    instance.test(:always)
  end
end

require 'stove/rake_task'
Stove::RakeTask.new

# Default
task default: %w(style unit)

task full: %w(style unit integration)
