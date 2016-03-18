module AjaxDatatablesRails
  module ORM
    module ActiveRecord
      def fetch_records
        get_raw_records
      end

      def filter_records(records)
        records = simple_search(records)
        records = composite_search(records)
        records
      end

      def sort_records(records)
        sort_by = []
        params[:order].each_value do |item|
          sort_by << "#{sort_column(item)} #{sort_direction(item)}"
        end
        records.order(sort_by.join(", "))
      end

      def paginate_records(records)
        records.offset(offset).limit(per_page)
      end

      # ----------------- SEARCH HELPER METHODS --------------------

      def simple_search(records)
        return records unless search_query_present?
        conditions = build_conditions_for(params[:search][:value], params[:search][:regex])
        records = records.where(conditions) if conditions
        records
      end

      def composite_search(records)
        conditions = aggregate_query
        records = records.where(conditions) if conditions
        records
      end

      def build_conditions_for(query, regex)
        search_for = query.split(' ')
        criteria = search_for.inject([]) do |criteria, atom|
          criteria << searchable_columns.map { |col| search_condition(col, atom, regex == 'true') }
            .reduce(:or)
        end.reduce(:and)
        criteria
      end

      def aggregate_query
        conditions = view_columns.each_with_index.map do |column, index|
          build_normal_search_condition(column, index)
        end
        conditions << build_date_range_search_condition
        conditions.compact.reduce(:and)
      end

      def build_normal_search_condition(column, index)
        value = params[:columns]["#{index}"][:search][:value] if params[:columns]
        regex = params[:columns]["#{index}"][:search][:regex] == 'true' if params[:columns]
        search_condition(column, value, regex) unless value.blank?
      end

      def build_date_range_search_condition
        if date_range_present?
          date_range_column = view_columns[params[:date_range][:column].to_i]
          model, column = date_range_column.split('.')
          table = get_table(model)

          case
          when only_start_date_present?
            build_date_greater_or_less_query(true, table, column)
          when only_end_date_present?
            build_date_greater_or_less_query(false, table, column)
          when both_start_and_end_date_present?
            build_date_range_query(table, column)
          end

        end
      end

      def search_condition(column, value, regex=false)
        model, column = column.split('.')
        table = get_table(model)
        regex ? regex_search(table, column, value) : non_regex_search(table, column, value)
      end

      def get_table(model)
        model.constantize.arel_table
      rescue
        table_from_downcased(model)
      end

      def table_from_downcased(model)
        model.singularize.titleize.gsub( / /, '' ).constantize.arel_table
      rescue
        ::Arel::Table.new(model.to_sym, ::ActiveRecord::Base)
      end

      def typecast
        case config.db_adapter
        when :mysql, :mysql2 then 'CHAR'
        when :sqlite, :sqlite3 then 'TEXT'
        else
          'VARCHAR'
        end
      end

      def cast_column(table, column)
        ::Arel::Nodes::NamedFunction.new(
          'CAST', [table[column.to_sym].as(typecast)]
        )
      end

      def regex_search(table, column, value)
        ::Arel::Nodes::Regexp.new(table[column.to_sym], ::Arel::Nodes.build_quoted(value))
      end

      def non_regex_search(table, column, value)
        casted_column = cast_column(table, column)
        casted_column.matches("%#{value}%")
      end

      def date_range_present?
        params[:date_range].present?
      end

      def get_date_for_date_range(date, time_zone='GMT', end_date=false)
        if end_date
          Date.strptime(date, '%d/%m/%Y').in_time_zone(Nokogiri::HTML.parse(time_zone).text) + 23.hours + 59.minutes + 59.seconds
        else
          Date.strptime(date, '%d/%m/%Y').in_time_zone(Nokogiri::HTML.parse(time_zone).text)
        end

      rescue
        nil
      end

      def only_start_date_present?
        get_date_for_date_range(params[:date_range][:start], params[:date_range][:time_zone]) && get_date_for_date_range(params[:date_range][:end], params[:date_range][:time_zone], true).nil?
      end

      def only_end_date_present?
        get_date_for_date_range(params[:date_range][:end], params[:date_range][:time_zone], true) && get_date_for_date_range(params[:date_range][:start], params[:date_range][:time_zone]).nil?
      end

      def both_start_and_end_date_present?
        get_date_for_date_range(params[:date_range][:start], params[:date_range][:time_zone]) && get_date_for_date_range(params[:date_range][:end], params[:date_range][:time_zone], true)
      end

      def build_date_greater_or_less_query(greater_than, table, column)
        if greater_than
          greater_than_or_equal_query(table, column, get_date_for_date_range(params[:date_range][:start], params[:date_range][:time_zone]))
        else
          less_than_or_equal_query(table, column, get_date_for_date_range(params[:date_range][:end], params[:date_range][:time_zone], true))
        end
      end

      def build_date_range_query(table, column)
        between_query(table, column, get_date_for_date_range(params[:date_range][:start], params[:date_range][:time_zone]), get_date_for_date_range(params[:date_range][:end], params[:date_range][:time_zone], true))
      end

      def greater_than_or_equal_query(table, column, value)
        casted_column = cast_column(table, column)
        casted_column.gteq(value)
      end

      def less_than_or_equal_query(table, column, value)
        casted_column = cast_column(table, column)
        casted_column.lteq(value)
      end

      def between_query(table, column, start_value, end_value)
        casted_column = cast_column(table, column)
        casted_column.between(start_value..end_value)
      end

      # ----------------- SORT HELPER METHODS --------------------

      def sort_column(item)
        model, column = view_columns[item[:column].to_i].split('.')
        table = get_table(model)
        [table.name, column].join('.')
      end

      def sort_direction(item)
        options = %w(desc asc)
        options.include?(item[:dir]) ? item[:dir].upcase : 'ASC'
      end

      def default_additional_sort(records)
        if config.default_additional_sort
          config.default_additional_sort.split(',').inject(records) do |sorted, column_spec|
            column_name, order = column_spec.split('.')
            order ||= 'ASC'
            if sorted.column_names.include?(column_name)
              sorted.order(column_name.to_sym => order)
            else
              sorted
            end
          end
        else
          records
        end
      end
    end
  end
end
