module SlackStrava
  module Commands
    class Help < SlackRubyBot::Commands::Base
      HELP = <<~EOS.freeze
        ```
        I am your friendly bot powered by Strava.

        DM
        -------
        connect                  - connect your Strava account
        disconnect               - disconnect your Strava account

        Clubs
        --------
        /slava clubs             - connect/disconnect clubs

        Settings
        --------
        set units mi|km          - use miles or kilometers
        set maps off|full|thumb  - change the way maps are displayed
        set private true|false   - sync private activities (default is false)

        General
        -------
        help                     - get this helpful message
        subscription             - show subscription info
        info                     - bot info
        ```
EOS
      def self.call(client, data, _match)
        client.say(channel: data.channel, text: [
          HELP,
          client.owner.reload.subscribed? ? nil : client.owner.subscribe_text
        ].compact.join("\n"))
        logger.info "HELP: #{client.owner}, user=#{data.user}"
      end
    end
  end
end
