require 'wonga/daemon/win_rm_runner'

module Wonga
  module Daemon
    class PantryAdDomainLeaveCommandHandler
      def initialize(config, publisher, logger)
        @logger       = logger
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

      def dc_from_domain(domain)
        domain.split(".").map {
          |x| "DC=" + x
        }.join(",")
      end

      def leave_domain(message)
        runner  = WinRMRunner.new
        name_server = get_name_server(@config["name_server"], message["domain"])
        runner.add_host(
          name_server, 
          @config['ad']['username'], 
          @config['ad']['password']
        )
        dc_string = dc_from_domain(message["domain"])
        command = "dsrm -noprompt \"CN=#{message["hostname"]},CN=Computers,#{dc_string}\""
        @logger.info("Executing command: #{command}")
        runner.run_commands(command) do |cmd, ret_val|
          unless ret_val.includes? "dsrm succeeded" 
            @logger.error(ret_val)
          end
        end
      end
    end
  end
end
