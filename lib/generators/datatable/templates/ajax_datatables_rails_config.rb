AjaxDatatablesRails.configure do |config|
  # available options for db_adapter are: :pg, :mysql2, :sqlite3
  # config.db_adapter = :pg

  # available options for paginator are: :simple_paginator, :kaminari, :will_paginate
  # config.paginator = :simple_paginator

  # available options depend on your database and tables, if the column doesn't exist
  # on a specified table, this option will be ignored; specify this option as a string
  # in the form of 'column_name.direction' -- if the direction is left off, 'asc' is
  # assumed
  # config.default_additional_sort = 'id.asc'
end
