# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'rspec', cmd: 'bundle exec rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/goliath/(.+)\.rb$})     { |m| "spec/unit/#{m[1]}_spec.rb" }
end

