require 'nyet_helpers'

describe NyetHelpers do
  include NyetHelpers

  describe 'logged_in_client' do
    it 'can log in successfully' do
      logged_in_client.should be_logged_in
    end
  end

  describe 'with_model' do
    it 'calls create, yields, then calls delete' do
      yielded = false
      model = double
      model.should_receive(:create!)
      with_model(model) do
        yielded = true
        model.should_receive(:delete!)
      end

      expect(yielded).to eq(true)
    end
  end

  describe 'clean_up_previous_run' do
    it 'deletes the app and the route matching the given name' do
      app = double
      app.should_receive(:delete!)

      route = double
      route.should_receive(:delete!)

      client = double
      client.should_receive(:app_by_name).with('name').and_return(app)
      client.should_receive(:route_by_host).with('name').and_return(route)

      clean_up_previous_run(client, 'name')
    end

    it 'can handle when there is no app or route with that name' do
      client = double
      client.should_receive(:app_by_name).with('name').and_return(nil)
      client.should_receive(:route_by_host).with('name').and_return(nil)

      expect { clean_up_previous_run(client, 'name') }.not_to raise_error
    end
  end
end
