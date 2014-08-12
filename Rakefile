require 'rake/testtask'
require 'rubocop/rake_task'

task default: [:test, :rubocop]

task :test do
  Rake::TestTask.new do |t|
    t.pattern = 'tests/*_test.rb'
  end
end

task :rubocop do
  RuboCop::RakeTask.new
end
