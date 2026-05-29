# frozen_string_literal: true

RSpec.describe 'connector', :vcr do
  let(:connector) { Workato::Connector::Sdk::Connector.from_file('connector.rb', settings) }
  let(:settings) { Workato::Connector::Sdk::Settings.from_default_file }

  it 'loads successfully' do
    expect(connector).to be_present
  end

  describe 'test' do
    it 'connects and loads the OpenAPI schema from GCP without raising' do
      expect { connector.test(settings) }.not_to raise_error
    end
  end

  describe 'pick_lists' do
    describe 'object_for_get' do
      subject(:list) { connector.pick_lists.object_for_get(settings) }

      it 'returns available objects derived from the OpenAPI schema' do
        expect(list).to be_an(Array)
        expect(list).not_to be_empty
      end

      it 'includes Invoice' do
        labels = list.map(&:first)
        expect(labels).to include('Invoice')
      end
    end
  end

  describe 'actions' do
    describe 'get_record' do
      describe 'input_fields' do
        subject(:fields) { connector.actions.get_record.input_fields(settings, {}) }

        it 'exposes the object picker' do
          expect(fields).to include(hash_including('name' => 'object_for_get'))
        end
      end

      describe 'execute' do
        context 'with an Invoice' do
          subject(:output) do
            input = JSON.parse(File.read('fixtures/actions/get_record/input_invoice.json'))
            connector.actions.get_record.execute(settings, input)
          end

          it 'returns the invoice record' do
            expect(output).to include('id' => 'in_Jwn_FnGf9Ae4UEo8iLF04NwTecNpWlOh')
          end

          it 'includes core invoice fields' do
            expect(output).to include('customer', 'subscription', 'product_id', 'due_date')
          end
        end

        context 'with a Customer' do
          subject(:output) do
            input = JSON.parse(File.read('fixtures/actions/get_record/input_customer.json'))
            connector.actions.get_record.execute(settings, input)
          end

          it 'returns the customer record' do
            expect(output).to include('id')
          end
        end

        context 'with a Subscription' do
          subject(:output) do
            input = JSON.parse(File.read('fixtures/actions/get_record/input_subscription.json'))
            connector.actions.get_record.execute(settings, input)
          end

          it 'returns the subscription record' do
            expect(output).to include('id', 'product_id', 'customer')
          end
        end

        context 'with a Webhook endpoint' do
          subject(:output) do
            input = JSON.parse(File.read('fixtures/actions/get_record/input_webhook_endpoint.json'))
            connector.actions.get_record.execute(settings, input)
          end

          it 'returns the webhook endpoint record' do
            expect(output).to include('id', 'url', 'enabled_events')
          end
        end
      end
    end

    describe 'search_records' do
      describe 'input_fields' do
        subject(:fields) { connector.actions.search_records.input_fields(settings, {}) }

        it 'exposes the object picker' do
          expect(fields).to include(hash_including('name' => 'object_for_search'))
        end
      end
    end

    describe 'create_record' do
      describe 'input_fields' do
        subject(:fields) { connector.actions.create_record.input_fields(settings, {}) }

        it 'exposes the object picker' do
          expect(fields).to include(hash_including('name' => 'object_for_create'))
        end
      end
    end

    describe 'update_record' do
      describe 'input_fields' do
        subject(:fields) { connector.actions.update_record.input_fields(settings, {}) }

        it 'exposes the object picker' do
          expect(fields).to include(hash_including('name' => 'object_for_update'))
        end
      end
    end

    describe 'delete_record' do
      describe 'input_fields' do
        subject(:fields) { connector.actions.delete_record.input_fields(settings, {}) }

        it 'exposes the object picker' do
          expect(fields).to include(hash_including('name' => 'object_for_delete'))
        end
      end
    end
  end
end
