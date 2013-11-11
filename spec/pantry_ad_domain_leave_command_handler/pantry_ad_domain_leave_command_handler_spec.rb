require 'spec_helper'
require_relative '../../pantry_ad_domain_leave_command_handler/pantry_ad_domain_leave_command_handler'

describe Wonga::Daemon::PantryAdDomainLeaveCommandHandler do
  let(:message) { { "domain"    => "domain" } } 
  let(:config) { 
    {
      "ad" => {
        "username"  => "username",
        "password"  => "passwword"
      },
      "name_server" => "ns.example.com"
    }
  }
  let(:win_rm_runner) { instance_double("Wonga::Daemon::WinRMRunner").as_null_object }
  let(:logger)        { instance_double("Wonga::Daemon::Logger").as_null_object }
  let(:publisher)     { instance_double("Wonga::Daemon::Publisher").as_null_object }

  subject { described_class.new(config, publisher) }

  it_behaves_like 'handler'

  describe "#handle_message" do
    before(:each) do 
      win_rm_runner.stub(:run_commands).and_return("Command completed successfully")
      win_rm_runner.stub(:add_host).and_return(win_rm_runner)
      Wonga::Daemon::WinRMRunner.stub(:new).and_return(win_rm_runner)
    end

    it "Receives a message and removes the machine from the domain" do
      subject.handle_message(message)
      expect(win_rm_runner).to have_received(:run_commands)
      expect(logger).not_to have_received(:error)
    end
  end

  describe "get_name_server" do
    it "should return a name server from config file" do
      resolver = Resolv::DNS.stub(:new).and_return(instance_double('Resolv::DNS').as_null_object)
      subject.get_name_server('a_server', 'aws.example.com').should == 'a_server'
    end
  end
end

