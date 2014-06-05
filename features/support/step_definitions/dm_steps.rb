# Given(/^I have deployed "(.*?)" state to "(.*?)" from scratch$/) do |state, target|
#   in_current_dir do
#     clean_current_dir
#     run "build.rb #{target} #{state}"
#   end
# end
#

Then(/^I store in "(.*?)" value "(.*?)"$/) do |name, value|
  @name = value
end

Then(/^I check stored value of "(.*?)" should contain "(.*?)"$/) do |name, value|
  expect(@name).to eq(value)
end

Then(/^I create file with random name and content and store its name in "(.*?)"$/) do |name|
# random_file_name = ('a'..'z').to_a.shuffle[0,8].join
#   self.instance_variable_set(:@name, random_file_name)
#   self.instance_variable_set(:@name, random_file_name)
#   @random_file_content = ('a'..'z').to_a.shuffle[0,8].join
end

When(/^I store bump version from file "(.*?)"$/) do |file|
  ENV['DM_BUMPED_VERSION'] = IO.read(file)
end

When(/^I change repo state to last bumped tag for "(.*?)" version$/) do |state|
  version = ENV['DM_BUMPED_VERSION']
  run "state.sh tag #{version} #{state}"
end

Then(/^the file "(.*?)" should contain last bumped tag$/) do |file|
  version = ENV['DM_BUMPED_VERSION']
  puts "Last bumped tag: #{version}"
  prep_for_fs_check { expect(IO.read(file)).to eq version }
end
