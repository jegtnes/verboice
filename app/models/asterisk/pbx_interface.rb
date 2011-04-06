module Asterisk
  class PbxInterface < MagicObjectProtocol::Server
    Port = Rails.configuration.verboice_configuration[:pbx_interface_port].to_i
    ConfigDir = Rails.configuration.asterisk_configuration[:config_dir]
    SipConf = "#{ConfigDir}/sip.conf"

    attr_accessor :pbx

    def call(address, application_id, call_log_id)
      raise "PBX is not available" if pbx.error?
      result = pbx.originate :channel => address,
        :application => 'AGI',
        :data => "agi://localhost:#{Asterisk::FastAGIServer::Port},#{application_id},#{call_log_id}",
        :async => true,
        :actionid => call_log_id
      raise result[:message] if result[:response] == 'Error'
      nil
    end

    def update_channel(channel_id)
      channel = Channel.find channel_id
      send "update_#{channel.kind}_channel", channel
    rescue Exception => ex
      puts "#{ex}, #{ex.backtrace}"
    end

    def update_sip2sip_channel(channel)
      section = "verboice_#{channel.id}"
      user = channel.config['username']
      password = channel.config['password']

      Asterisk::Conf.change SipConf do
        add section, :template => '!',
          :type => :peer,
          :canreinvite => :no,
          :nat => :yes,
          :qualify => :yes,
          :domain => 'sip2sip.info',
          :fromdomain => 'sip2sip.info',
          :outboundproxy => 'proxy.sipthor.net',
          :fromuser => user,
          :defaultuser => user,
          :secret => password,
          :insecure => :invite,
          :context => :verboice

        ['sip2sip.info', '81.23.228.129', '81.23.228.150', '85.17.186.7'].each_with_index do |host, i|
          add "#{section}-#{i}", :template => section, :host => host
        end

        add_action :general, :register, "#{user}:#{password}@sip2sip.info/#{channel.application_id}"
      end
    end

    def delete_channel(channel_id)
      channel = Channel.find_by_id channel_id
      send "delete_#{channel.kind}_channel", channel
    end

    def delete_sip2sip_channel(channel)
      section = "verboice_#{channel.id}"
      user = channel.config['username']
      password = channel.config['password']

      Asterisk::Conf.change SipConf do
        remove section

        4.times { |i| remove "#{section}-#{i}" }

        remove_action :general, :register, "#{user}:#{password}@sip2sip.info/#{channel.application_id}"
      end
    end
  end
end
