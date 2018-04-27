require 'spec_helper'

describe Api::Endpoints::SlackEndpoint do
  include Api::Test::EndpointTest

  context 'with a SLACK_VERIFICATION_TOKEN' do
    let(:token) { 'slack-verification-token' }
    let(:team) { Fabricate(:team) }
    before do
      ENV['SLACK_VERIFICATION_TOKEN'] = token
    end
    context 'interactive buttons' do
      let(:user) { Fabricate(:user, team: team, access_token: 'token') }
      context 'without a club' do
        let(:club) do
          Club.new(
            name: 'Orchard Street Runners',
            description: 'www.orchardstreetrunners.com',
            url: 'OrchardStreetRunners',
            city: 'New York',
            state: 'New York',
            country: 'United States',
            member_count: 146,
            logo: 'https://dgalywyr863hv.cloudfront.net/pictures/clubs/43749/1121181/4/medium.jpg'
          )
        end
        it 'connects club', vcr: { cassette_name: 'strava/retrieve_a_club' } do
          expect {
            expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
              club.to_slack.merge(
                as_user: true,
                channel: 'C12345',
                text: "A club has been connected by #{user.slack_mention}."
              )
            )
            expect_any_instance_of(Strava::Api::V3::Client).to receive(:paginate)
            expect_any_instance_of(Club).to receive(:sync_last_strava_activity!)
            post '/api/slack/action', payload: {
              actions: [{ name: 'strava_id', value: '43749' }],
              channel: { id: 'C12345', name: 'runs' },
              user: { id: user.user_id },
              team: { id: team.team_id },
              token: token,
              callback_id: 'club-connect-channel'
            }.to_json
            expect(last_response.status).to eq 201
            response = JSON.parse(last_response.body)
            expect(response['attachments'][0]['actions'][0]['text']).to eq 'Disconnect'
          }.to change(Club, :count).by(1)
        end
      end
      context 'with a club' do
        let!(:club) { Fabricate(:club, team: team) }
        it 'disconnects club' do
          expect {
            expect_any_instance_of(Strava::Api::V3::Client).to receive(:paginate)
            expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
              club.to_slack.merge(
                as_user: true,
                channel: club.channel_id,
                text: "A club has been disconnected by #{user.slack_mention}."
              )
            )
            post '/api/slack/action', payload: {
              actions: [{ name: 'strava_id', value: club.strava_id }],
              channel: { id: club.channel_id, name: 'runs' },
              user: { id: user.user_id },
              team: { id: team.team_id },
              token: token,
              callback_id: 'club-disconnect-channel'
            }.to_json
            expect(last_response.status).to eq 201
            response = JSON.parse(last_response.body)
            expect(response['text']).to eq('Not connected to any clubs.')
            expect(response['attachments']).to eq([])
          }.to change(Club, :count).by(-1)
        end
      end
      it 'returns an error with a non-matching verification token' do
        post '/api/slack/action', payload: {
          actions: [{ name: 'strava_id', value: '43749' }],
          channel: { id: 'C1', name: 'runs' },
          user: { id: user.user_id },
          team: { id: team.team_id },
          callback_id: 'invalid-callback',
          token: 'invalid-token'
        }.to_json
        expect(last_response.status).to eq 401
        response = JSON.parse(last_response.body)
        expect(response['error']).to eq 'Message token is not coming from Slack.'
      end
      it 'returns invalid callback id' do
        post '/api/slack/action', payload: {
          actions: [{ name: 'strava_id', value: 'id' }],
          channel: { id: 'C1', name: 'runs' },
          user: { id: user.user_id },
          team: { id: team.team_id },
          callback_id: 'invalid-callback',
          token: token
        }.to_json
        expect(last_response.status).to eq 404
        response = JSON.parse(last_response.body)
        expect(response['error']).to eq 'Callback invalid-callback is not supported.'
      end
    end
    context 'slash commands' do
      context 'disconnected user' do
        let(:user) { Fabricate(:user, team: team) }
        let!(:club_in_another_channel) { Fabricate(:club, team: team, channel_id: 'another') }
        let!(:club) { Fabricate(:club, team: team, channel_id: 'channel') }
        it 'lists clubs connected to this channel' do
          post '/api/slack/command',
               command: '/slava',
               text: 'clubs',
               channel_id: 'channel',
               user_id: user.user_id,
               team_id: team.team_id,
               token: token
          expect(last_response.status).to eq 201
          expect(JSON.parse(last_response.body)).to eq(
            JSON.parse(club.connect_to_slack.merge(
              text: '', user: user.user_id, channel: 'channel'
            ).to_json)
          )
        end
      end
      context 'connected user' do
        let(:user) { Fabricate(:user, team: team, access_token: 'token') }
        let(:nyrr_club) do
          Club.new(
            strava_id: '108605',
            name: 'New York Road Runners',
            url: 'nyrr',
            city: 'New York',
            state: 'New York',
            country: 'United States',
            member_count: 9131,
            logo: 'https://dgalywyr863hv.cloudfront.net/pictures/clubs/108605/8433029/1/medium.jpg'
          )
        end
        it 'lists clubs a user is a member of', vcr: { cassette_name: 'strava/list_athlete_clubs' } do
          post '/api/slack/command',
               command: '/slava',
               text: 'clubs',
               channel_id: 'channel',
               user_id: user.user_id,
               team_id: team.team_id,
               token: token
          expect(last_response.status).to eq 201
          response = JSON.parse(last_response.body)
          expect(response['attachments'].count).to eq 5
          expect(response['attachments'][0]['title']).to eq nyrr_club.name
        end
        context 'with another connected club in the channel' do
          let!(:club_in_another_channel) { Fabricate(:club, team: team, channel_id: 'another') }
          let!(:club) { Fabricate(:club, team: team, channel_id: 'channel') }
          it 'lists both clubs a user is a member of and the connected club', vcr: { cassette_name: 'strava/list_athlete_clubs' } do
            post '/api/slack/command',
                 command: '/slava',
                 text: 'clubs',
                 channel_id: 'channel',
                 user_id: user.user_id,
                 team_id: team.team_id,
                 token: token
            response = JSON.parse(last_response.body)
            expect(response['attachments'].count).to eq 6
            expect(response['attachments'][0]['title']).to eq nyrr_club.name
            expect(response['attachments'][5]['title']).to eq club.name
          end
        end
        context 'DMs' do
          it 'says no clubs are connected in a DM' do
            post '/api/slack/command',
                 command: '/slava',
                 text: 'clubs',
                 channel_id: 'D1234',
                 user_id: user.user_id,
                 team_id: team.team_id,
                 token: token

            expect(last_response.status).to eq 201
            expect(JSON.parse(last_response.body)).to eq(
              'attachments' => [],
              'channel' => 'D1234',
              'text' => 'No clubs connected.',
              'user' => user.user_id
            )
          end
          context 'with a connected club' do
            let!(:club) { Fabricate(:club, team: team) }
            it 'lists connected clubs in a DM' do
              post '/api/slack/command',
                   command: '/slava',
                   text: 'clubs',
                   channel_id: 'D1234',
                   user_id: user.user_id,
                   team_id: team.team_id,
                   token: token

              expect(last_response.status).to eq 201
              expect(JSON.parse(last_response.body)).to eq(
                JSON.parse(club.to_slack.merge(
                  text: '', user: user.user_id, channel: 'D1234'
                ).to_json)
              )
            end
          end
        end
      end
      it 'returns an error with a non-matching verification token' do
        post '/api/slack/command',
             command: '/slava',
             text: 'clubs',
             channel_id: 'C1',
             user_id: 'user_id',
             team_id: 'team_id',
             token: 'invalid-token'
        expect(last_response.status).to eq 401
        response = JSON.parse(last_response.body)
        expect(response['error']).to eq 'Message token is not coming from Slack.'
      end
    end
    after do
      ENV.delete('SLACK_VERIFICATION_TOKEN')
    end
  end
end
