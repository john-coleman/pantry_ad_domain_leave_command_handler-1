require 'spec_helper'
require_relative '../../pantry_ad_domain_leave_command_handler/pantry_ad_domain_leave_command_handler'

RSpec.describe Wonga::Daemon::PantryAdDomainLeaveCommandHandler do
  let(:message) do
    {
      'domain'    => 'a.b.c',
      'hostname'  => 'hostname'
    }
  end

  let(:config) do
    {
      'ad' => {
        'domain'      => 'domain',
        'username'    => 'username',
        'password'    => 'passwword',
        'name_server' => 'ns.example.com'
      }
    }
  end

  let(:win_rm_runner) { instance_double('Wonga::Daemon::WinRMRunner').as_null_object }
  let(:logger)        { instance_double('Wonga::Daemon::Logger').as_null_object }
  let(:publisher)     { instance_double('Wonga::Daemon::Publisher').as_null_object }

  subject { described_class.new(config, publisher, logger) }

  it_behaves_like 'handler'

  describe '#dc_from_domain' do
    it 'takes a domain and returns the appropriate dc string' do
      expect(subject.dc_from_domain('example.com')).to eq('DC=aws,DC=wonga,DC=com')
    end
  end

  describe '#handle_message' do
    before(:each) do
      allow(win_rm_runner).to receive(:run_commands).and_return('Command completed successfully')
      allow(win_rm_runner).to receive(:add_host).and_return(win_rm_runner)
      allow(Wonga::Daemon::WinRMRunner).to receive(:new).and_return(win_rm_runner)
    end

    it 'Receives a message and removes the machine from the domain' do
      subject.handle_message(message)
      expect(win_rm_runner).to have_received(:run_commands).with(
        "dsrm -noprompt \"CN=hostname,CN=Computers,DC=a,DC=b,DC=c\""
      )
      expect(logger).not_to have_received(:error)
    end

    context 'when machine name is longer than 15 symbols' do
      let(:message) do
        {
          'domain'    => 'a.b.c',
          'hostname'  => '12345678901234567890'
        }
      end

      it 'uses first 15 symbols to remove the machine from the domain' do
        subject.handle_message(message)
        expect(win_rm_runner).to have_received(:run_commands).with(
          "dsrm -noprompt \"CN=123456789012345,CN=Computers,DC=a,DC=b,DC=c\""
        )
        expect(logger).not_to have_received(:error)
      end
    end
  end

  describe 'get_name_server' do
    it 'should return a name server from config file' do
      allow(Resolv::DNS).to receive(:new).and_return(instance_double('Resolv::DNS').as_null_object)
      expect(subject.get_name_server('a_server', 'example.com')).to eq('a_server')
    end
  end
end
