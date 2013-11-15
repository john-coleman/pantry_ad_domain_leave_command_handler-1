require 'wonga/daemon/win_rm_runner'

module Wonga
  module Daemon
    class PantryAdDomainLeaveCommandHandler
      def initialize(config, publisher)
        @publisher    = publisher        
        @config       = config
        @ad_domain    = config["ad"]["domain"]
        @ad_user      = config["ad"]["username"]
        @ad_password  = config["ad"]["password"]      
      end

      def handle_message(message)
        leave_domain(message)
        @publisher.publish(message)              
      end

      def get_name_server(name_server, domain)
        if name_server.nil?  || name_server.empty?
          resolver  = Resolv::DNS.new
          resolver.getresource(
            domain, 
            Resolv::DNS::Resource::IN::NS
          ).name
        else
          name_server
        end
      end

      def leave_domain(message)
        runner  = WinRMRunner.new
        name_server = get_name_server(@config["name_server"], message["domain"])
        runner.add_host(
          name_server, 
          @config['ad']['username'], 
          @config['ad']['password']
        )
        if message.has_key?('ad_ou')
          ad_ou = message['ad_ou']
          command = "NETDOM REMOVE /Domain:#{message["domain"]} #{message["hostname"]}.#{message["domain"]} /OU:'#{ad_ou}' /UserD:#{@ad_domain}\\#{@ad_user} /PasswordD:\"#{@ad_password}\" & echo ERRORLEVEL: %ERRORLEVEL%"
        else
          command = "NETDOM REMOVE /Domain:#{message["domain"]} #{message["hostname"]}.#{message["domain"]} /UserD:#{@ad_domain}\\#{@ad_user} /PasswordD:\"#{@ad_password}\" & echo ERRORLEVEL: %ERRORLEVEL%"
        end        
        runner.run_commands(command) do |cmd, ret_val|
          unless ret_val.includes? "Command completed successfully" 
            logger.error(ret_val)
          end
        end
      end
    end
  end
end
