require "./test/test_helper"

def run_suite(wildcard)
  #simple way to make sure requires are isolated
  result = Dir[wildcard].collect{|test_file| system("ruby #{test_file}") }.uniq == [true]
  puts "suite " + (result ? "passed" : "FAILED")
  exit(result ? 0 : 1)
end

run_suite("test/**/*_test.rb")