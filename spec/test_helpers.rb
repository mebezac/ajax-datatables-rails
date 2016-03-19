def sample_params
  ActiveSupport::HashWithIndifferentAccess.new(
    {
      "draw"=>"1",
      "columns"=> {
        "0"=> {
          "data"=>"0", "name"=>"", "searchable"=>"true", "orderable"=>"true",
          "search"=> {
            "value"=>"", "regex"=>"false"
          }
        },
        "1"=> {
          "data"=>"1", "name"=>"", "searchable"=>"true", "orderable"=>"true",
          "search"=> {
            "value"=>"", "regex"=>"false"
          }
        },
        "2"=> {
          "data"=>"2", "name"=>"", "searchable"=>"false", "orderable"=>"false",
          "search"=> {
            "value"=>"", "regex"=>"false"
          }
        },
        "3"=> {
          "data"=>"3", "name"=>"", "searchable"=>"false", "orderable"=>"true",
          "search"=> {
            "value"=>"", "regex"=>"false"
          }
        },
        "4"=> {
          "data"=>"4", "name"=>"", "searchable"=>"false", "orderable"=>"true",
          "search"=> {
            "value"=>"", "regex"=>"false"
          }
        }
      },
      "order"=> {
        "0"=> {"column"=>"0", "dir"=>"asc"}
      },
      "start"=>"0", "length"=>"10", "search"=>{
        "value"=>"", "regex"=>"false"
      },
      "_"=>"1423364387185"
    }
  )
end

def create_many_sample_users
  50.times.map do |n|
    username = n % 2 == 0         \
      ? "johndoe#{ "%02d" % n }"  \
      : "msmith#{ "%02d" % n }"
    email = "#{username}@example.com"
    User.new(username: username, email: email, column_with_single_value: '000000|TBD', an_int: n)
  end.shuffle.each(&:save!)
end

class SampleDatatable < AjaxDatatablesRails::Base
  def view_columns
    @view_columns ||= [
      'User.username', 'User.email', 'User.first_name', 'User.last_name', 'User.column_with_single_value'
    ]
  end

  def data
    [{}, {}]
  end

  def get_raw_records
    User.all
  end
end

class ActiveRecordSampleDatatable < SampleDatatable
  include AjaxDatatablesRails::ORM::ActiveRecord
end
