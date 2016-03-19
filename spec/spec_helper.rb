require 'pry'
require 'rails'
require 'active_record'
require 'ajax-datatables-rails'

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

load File.dirname(__FILE__) + '/schema.rb'
load File.dirname(__FILE__) + '/test_helpers.rb'
require File.dirname(__FILE__) + '/test_models.rb'

RSpec.configure do |config|
  config.before(:each) do |_|
    AjaxDatatablesRails.configure do |config|
      config.db_adapter = :sqlite
      config.orm = :active_record
      config.default_additional_sort = nil
    end
  end

  config.after(:each) do |_|
    User.destroy_all
  end
end
