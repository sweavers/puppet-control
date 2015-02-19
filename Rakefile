require 'rake'
require 'puppet-syntax/tasks/puppet-syntax'
require 'puppet-lint/tasks/puppet-lint'
require 'colorize'

# Ignore these directories in tests
exclude_paths = [ 'modules/**/*.pp' ]

# Puppet lint task (:lint)
# You can troubleshoot errors and warnings @ http://puppet-lint.com/checks/
desc "Run lint tasks against module"
#Rake::Task[:lint].clear # https://github.com/rodjek/puppet-lint/issues/331
PuppetLint::RakeTask.new :lint do |config|
config.fail_on_warnings = true
config.ignore_paths = exclude_paths
config.disable_checks = [
'80chars',
]
config.log_format = "%{path}:%{linenumber}:%{check}:%{KIND}:%{message}"
end

# Puppet syntax task (:syntax)
PuppetSyntax.exclude_paths = exclude_paths

# YAML syntax task (:yaml)
desc "Test YAML files"
task :yaml do
  require 'yaml'

  d = Dir["**/*.yaml", "**/*.yml"]
  d.each do |file|
    begin
      puts "YAML syntax - Checking #{file}"
      YAML.load_file(file)
    rescue Exception
      puts "YAML syntax - Failed to read #{file}: #{$!}".red
      exit 1
    end
  end
end

# Shell syntax task (:shell)
desc "Test shell scripts"
task :shell do
  require 'open4'

  d = Dir["**/*.sh"]
  d.each do |file|
    puts "Shell syntax - Checking #{file}"
    pid, stdin, stdout, stderr = Open4.popen4("bash -n #{file}")
    ignored, status = Process::waitpid2 pid
    if status.to_i != 0 # Check if script exits with non-zero
      begin
        result = stderr.gets.chomp.sub(" syntax error:",'')
        puts "Shell syntax - #{result}".red
      rescue
        puts "Shell syntax - Error reading output of #{file}".red
      end
      exit 1
    end
  end
end


task :test => [:syntax, :lint, :yaml, :shell]
task :default => :test