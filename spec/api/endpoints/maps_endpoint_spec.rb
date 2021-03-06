require 'spec_helper'

describe Api::Endpoints::MapsEndpoint do
  include Api::Test::EndpointTest

  context 'maps' do
    context 'without an activity' do
      it '404s' do
        get '/api/maps/5abd07019b0b58f119c1bbaa.png'
        expect(last_response.status).to eq 404
        expect(JSON.parse(last_response.body)).to eq('error' => 'Not Found')
      end
    end
    context 'with an activity' do
      let(:user) { Fabricate(:user) }
      let(:activity) { Fabricate(:user_activity, user: user) }
      it 'returns map', vcr: { cassette_name: 'strava/map' } do
        get "/api/maps/#{activity.map.id}.png"
        expect(last_response.status).to eq 200
        expect(last_response.headers['Content-Type']).to eq 'image/png'
      end
    end
  end
end
