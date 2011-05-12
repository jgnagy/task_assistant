#!/usr/bin/env jruby

require 'rubygems'
require 'irb'
require "yaml"
require "active_record"

def consolize &block
  
  yield

  IRB.setup(nil)
  irb = IRB::Irb.new
  IRB.conf[:MAIN_CONTEXT] = irb.context

  irb.context.evaluate("require 'irb/completion'", 0)
  
  conf.prompt_c = "* "
  conf.prompt_i = "> "
  conf.prompt_s = "%l "

  trap("SIGINT") do
    irb.signal_handle
  end
  catch(:IRB_EXIT) do
    irb.eval_input
  end
end

consolize do

  # require whatever you need
  #require 'redcloth'
  config = YAML::load_file('config.yaml')
  ActiveRecord::Base.establish_connection(
    config[:db]
  )
  
  # Load models and libs *after* establishing ActiveRecord connection
  require 'models/task'
  require 'models/tag'
  
  require 'lib/console_helpers'
end

