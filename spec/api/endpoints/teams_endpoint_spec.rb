require 'spec_helper'

describe Api::Endpoints::TeamsEndpoint do
  include Api::Test::EndpointTest

  context 'team' do
    it 'requires code' do
      expect { client.teams._post }.to raise_error Faraday::ClientError do |e|
        json = JSON.parse(e.response[:body])
        expect(json['message']).to eq 'Invalid parameters.'
        expect(json['type']).to eq 'param_error'
      end
    end

    context 'register' do
      before do
        oauth_access = {
          'bot' => {
            'bot_access_token' => 'token',
            'bot_user_id' => 'bot_user_id'
          },
          'user_id' => 'activated_user_id',
          'team_id' => 'team_id',
          'team_name' => 'team_name'
        }
        ENV['SLACK_CLIENT_ID'] = 'client_id'
        ENV['SLACK_CLIENT_SECRET'] = 'client_secret'
        allow_any_instance_of(Slack::Web::Client).to receive(:im_open).with(
          user: 'activated_user_id'
        ).and_return(
          'channel' => {
            'id' => 'C1'
          }
        )
        allow_any_instance_of(Slack::Web::Client).to receive(:oauth_access).with(
          hash_including(
            code: 'code',
            client_id: 'client_id',
            client_secret: 'client_secret'
          )
        ).and_return(oauth_access)
      end
      after do
        ENV.delete('SLACK_CLIENT_ID')
        ENV.delete('SLACK_CLIENT_SECRET')
      end
      it 'creates a team' do
        expect(SlackStrava::Service.instance).to receive(:start!)
        expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
          text: "Welcome to Slava!\nInvite <@bot_user_id> to a channel to publish activities to it.\nType \"*connect*\" to connect your Strava account.\"\n",
          channel: 'C1',
          as_user: true
        )
        expect {
          team = client.teams._post(code: 'code')
          expect(team.team_id).to eq 'team_id'
          expect(team.name).to eq 'team_name'
          team = Team.find(team.id)
          expect(team.token).to eq 'token'
          expect(team.bot_user_id).to eq 'bot_user_id'
          expect(team.activated_user_id).to eq 'activated_user_id'
        }.to change(Team, :count).by(1)
      end
      it 'reactivates a deactivated team' do
        expect(SlackStrava::Service.instance).to receive(:start!)
        expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
          text: "Welcome to Slava!\nInvite <@bot_user_id> to a channel to publish activities to it.\nType \"*connect*\" to connect your Strava account.\"\n",
          channel: 'C1',
          as_user: true
        )
        existing_team = Fabricate(:team, token: 'token', active: false)
        expect {
          team = client.teams._post(code: 'code')
          expect(team.team_id).to eq existing_team.team_id
          expect(team.name).to eq existing_team.name
          expect(team.active).to be true
          team = Team.find(team.id)
          expect(team.token).to eq 'token'
          expect(team.active).to be true
          expect(team.bot_user_id).to eq 'bot_user_id'
          expect(team.activated_user_id).to eq 'activated_user_id'
        }.to_not change(Team, :count)
      end
      it 'returns a useful error when team already exists' do
        existing_team = Fabricate(:team, token: 'token')
        expect { client.teams._post(code: 'code') }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['message']).to eq "Team #{existing_team.name} is already registered."
        end
      end
      it 'reactivates a deactivated team with a different code' do
        expect(SlackStrava::Service.instance).to receive(:start!)
        expect_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
          text: "Welcome to Slava!\nInvite <@bot_user_id> to a channel to publish activities to it.\nType \"*connect*\" to connect your Strava account.\"\n",
          channel: 'C1',
          as_user: true
        )
        existing_team = Fabricate(:team, api: true, token: 'old', team_id: 'team_id', active: false)
        expect {
          team = client.teams._post(code: 'code')
          expect(team.team_id).to eq existing_team.team_id
          expect(team.name).to eq existing_team.name
          expect(team.active).to be true
          team = Team.find(team.id)
          expect(team.token).to eq 'token'
          expect(team.active).to be true
          expect(team.bot_user_id).to eq 'bot_user_id'
          expect(team.activated_user_id).to eq 'activated_user_id'
        }.to_not change(Team, :count)
      end
    end
  end
end
