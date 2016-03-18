require 'spec_helper'

describe AjaxDatatablesRails::Base do
  describe 'an instance' do
    let(:view) { double('view', params: sample_params) }

    it 'requires a view_context' do
      expect { AjaxDatatablesRails::Base.new }.to raise_error
    end

    it 'accepts an options hash' do
      datatable = AjaxDatatablesRails::Base.new(view, :foo => 'bar')
      expect(datatable.options).to eq(:foo => 'bar')
    end
  end

  context 'Public API' do
    let(:view) { double('view', params: sample_params) }
    let(:datatable) { AjaxDatatablesRails::Base.new(view) }

    describe '#view_columns' do
      it 'raises an error if not defined by the user' do
        expect { datatable.view_columns }.to raise_error
      end

      context 'child class implements view_columns' do
        let(:datatable) { SampleDatatable.new(view) }

        it 'expects an array of columns displayed in the html view' do
          expect(datatable.view_columns).to be_a(Array)
        end
      end
    end

    describe '#data' do
      it 'raises an error if not defined by the user' do
        expect { datatable.data }.to raise_error
      end

      context 'child class implements data' do
        let(:datatable) { SampleDatatable.new(view) }

        it 'can return an array of hashes' do
          allow(datatable).to receive(:data) { [{}, {}] }
          expect(datatable.data).to be_a(Array)
          item = datatable.data.first
          expect(item).to be_a(Hash)
        end

        it 'can return an array of arrays' do
          allow(datatable).to receive(:data) { [[], []] }
          expect(datatable.data).to be_a(Array)
          item = datatable.data.first
          expect(item).to be_a(Array)
        end
      end

    end

    describe '#get_raw_records' do
      it 'raises an error if not defined by the user' do
        expect { datatable.get_raw_records }.to raise_error
      end
    end
  end

  context 'Private API' do
    let(:view) { double('view', params: sample_params) }
    let(:datatable) { SampleDatatable.new(view) }

    before(:each) do
      allow_any_instance_of(AjaxDatatablesRails::Configuration).to receive(:orm) { nil }
    end

    describe 'fetch records' do
      it 'raises an error if it does not include an ORM module' do
        expect { datatable.send(:fetch_records) }.to raise_error
      end
    end

    describe 'filter records' do
      it 'raises an error if it does not include an ORM module' do
        expect { datatable.send(:filter_records) }.to raise_error
      end
    end

    describe 'sort records' do
      it 'raises an error if it does not include an ORM module' do
        expect { datatable.send(:sort_records) }.to raise_error
      end
    end

    describe 'default additional sort' do
      it 'raises an error if it does not include an ORM module' do
        expect { datatable.send(:default_additional_sort) }.to raise_error
      end
    end

    describe 'paginate records' do
      it 'raises an error if it does not include an ORM module' do
        expect { datatable.send(:paginate_records) }.to raise_error
      end
    end

    describe 'helper methods' do
      describe '#offset' do
        it 'defaults to 0' do
          default_view = double('view', :params => {})
          datatable = AjaxDatatablesRails::Base.new(default_view)
          expect(datatable.send(:offset)).to eq(0)
        end

        it 'matches the value on view params[:start] minus 1' do
          paginated_view = double('view', :params => { :start => '11' })
          datatable = AjaxDatatablesRails::Base.new(paginated_view)
          expect(datatable.send(:offset)).to eq(10)
        end
      end

      describe '#page' do
        it 'calculates page number from params[:start] and #per_page' do
          paginated_view = double('view', :params => { :start => '11' })
          datatable = AjaxDatatablesRails::Base.new(paginated_view)
          expect(datatable.send(:page)).to eq(2)
        end
      end

      describe '#per_page' do
        it 'defaults to 10' do
          datatable = AjaxDatatablesRails::Base.new(view)
          expect(datatable.send(:per_page)).to eq(10)
        end

        it 'matches the value on view params[:length]' do
          other_view = double('view', :params => { :length => 20 })
          datatable = AjaxDatatablesRails::Base.new(other_view)
          expect(datatable.send(:per_page)).to eq(20)
        end
      end
    end

    context '#default_additional_sort' do
      let(:view) { double('view', params: sample_params) }
      let(:datatable) { ActiveRecordSampleDatatable.new(view) }

      before(:each) do
        create_many_sample_users
      end

      it 'defaults to ascending' do
        # set additional default sort
        datatable.config.default_additional_sort = 'an_int'

        # set to order Users by column_with_single_value in ascending order
        datatable.params[:order]['0'] = { column: '4', dir: 'asc' }
        expect(datatable.records.limit(2).map(&:email)).to match(
          ["johndoe00@example.com", "msmith01@example.com"]
        )
      end

      it "parses the sort order" do
        # set additional default sort
        datatable.config.default_additional_sort = 'an_int.desc'

        # set to order Users by email in descending order
        datatable.params[:order]['0'] = { column: '1', dir: 'desc' }
        expect(datatable.records.limit(2).map(&:email)).to match(
          ["msmith49@example.com", "msmith47@example.com"]
        )
      end

      it 'ignores column sorting when the table does not contain the column' do
        # set additional default sort
        datatable.config.default_additional_sort = 'an_attribute_that_does_not_exist.desc'

        # set to order Users by column_with_single_value in ascending order
        datatable.params[:order]['0'] = { column: '1', dir: 'asc' }
        expect(datatable.records.limit(2).map(&:email)).to match(
          ["johndoe00@example.com", "johndoe02@example.com"]
        )
      end

      it 'uses just the default sort' do
        datatable.config.default_additional_sort = 'an_int'
        datatable.params.delete "order"
        expect(datatable.records.limit(2).map(&:email)).to match(
          ["johndoe00@example.com", "msmith01@example.com"]
        )
      end

      it 'parses multiple defaults' do
        datatable.config.default_additional_sort = 'column_with_single_value.desc,an_int'
        datatable.params.delete "order"
        expect(datatable.records.limit(2).map(&:email)).to match(
          ["johndoe00@example.com", "msmith01@example.com"]
        )
      end
    end
  end
end
