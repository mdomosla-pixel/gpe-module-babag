require 'spec_helper_acceptance'

describe 'babag::sender class' do

  context 'sender' do
    # Using puppet_apply as a helper
    it 'should install sender' do
      bintray_user = ENV['BINTRAY_USER']
      bintray_key = ENV['BINTRAY_KEY']

      fail_fast "You must specify BINTRAY_USER environment var" if bintray_user.nil?
      fail_fast "You must specify BINTRAY_KEY environment var" if bintray_key.nil?

      pp = <<-EOS
        ensure_packages(['apt-transport-https'], {
          ensure => "present",
          before => Apt::Source['sfrbintray'],
        })

        $repo_url = "https://#{bintray_user}:#{bintray_key}@statoilfuelretail.bintray.com/deb"

        apt::source { 'sfrbintray':
          location => "${repo_url}",
          release  => "${lsbdistcodename}",
          repos    => 'main 3rd-party',
          key      => {
            'id'     => '8756C4F765C9AC3CB6B85D62379CE192D401AB61',
            'server' => 'pgp.key-server.io',
          },
          require  => Package['apt-transport-https'],
        }

        class { 'babag::sender':
          log_level => "trace",

          aws_region => "http://localhost:1234",
          dynamodb_status_table => "acctest-babag-statuses",

          smsapi_com_token => "ebXAXyll63tHtg5WUmuT5OUmpqBMFuzVP0CMe66F",

          linkmobility_url => "http://example.com/send",
          linkmobility_platform_id => "123",
          linkmobility_platform_partner_id => "321",
          linkmobility_user => "someUser",
          linkmobility_pass => "somePass",

          rabbitmq_host => "rabbitmq",
          rabbitmq_port => "5672",
          rabbitmq_vhost => "/",
          rabbitmq_user => "guest",
          rabbitmq_pass => "guest",

          postgres_username => "postgres",
          postgres_password =>"postgres_p",
          postgres_database => "postgres",
          postgres_host => "postgres",

          admin_enabled => true,
          admin_bind_address => "0.0.0.0",
          admin_port => "9091",

          nrepl_enabled => true,
          nrepl_port => "7999",
          nrepl_bind_address => "0.0.0.0",

          metrics_enabled => true,
          metrics_host => "localhost",
          metrics_port => "8125",

          noop_sending => true,
        }
      EOS

      # Run it twice and test for idempotency
      result = apply_manifest(pp, :catch_failures => true)
      expect(result.exit_code).to_not eq(1)
      # Check that second puppet run doesn't produce any changes
      expect(apply_manifest(pp, :catch_changes => true).exit_code).to eq(0)
    end

    describe service('babag-sender') do
      it {should be_enabled}
      it {should be_running}
    end

    describe package('babag-sender') do
      it {should be_installed}
    end

    describe file('/etc/default/babag-sender') do
      its(:content) {should match /^LINKMOBILITY__URL="http:\/\/example.com\/send"$/}
      its(:content) {should match /^LINKMOBILITY__PLATFORM_ID="123"$/}
      its(:content) {should match /^LINKMOBILITY__PLATFORM_PARTNER_ID="321"$/}
      its(:content) {should match /^LINKMOBILITY__USERNAME="someUser"$/}
      its(:content) {should match /^LINKMOBILITY__PASSWORD="somePass"$/}

      its(:content) {should match /^RABBITMQ__USERNAME="guest"$/}
      its(:content) {should match /^RABBITMQ__PASSWORD="guest"$/}
      its(:content) {should match /^RABBITMQ__HOST="rabbitmq"$/}
      its(:content) {should match /^RABBITMQ__PORT="5672"$/}
      its(:content) {should match /^RABBITMQ__VHOST="\/"$/}

      its(:content) {should match /^POSTGRES__USERNAME="postgres"/}
      its(:content) {should match /^POSTGRES__PASSWORD="postgres_p"/}
      its(:content) {should match /^POSTGRES__DATABASE="postgres"/}
      its(:content) {should match /^POSTGRES__HOST="postgres"/}

      its(:content) {should match /^RABBITMQ__SSL="false"$/}

      its(:content) {should match /^NREPL__ENABLED="true"/}
      its(:content) {should match /^NREPL__PORT="7999"/}
      its(:content) {should match /^NREPL__BIND_ADDRESS="0.0.0.0"/}


      its(:content) {should match /^ADMIN__ENABLED="true"/}
      its(:content) {should match /^ADMIN__BIND_ADDRESS="0.0.0.0"/}
      its(:content) {should match /^ADMIN__PORT="9091"/}

      its(:content) {should match /^METRICS__ENABLED="true"/}
      its(:content) {should match /^METRICS__HOST="localhost"/}
      its(:content) {should match /^METRICS__PORT="8125"/}

      its(:content) {should match /^NOOP_SENDING="true"/}

      its(:content) {should match /^LOG_LEVEL="trace"/}
    end

    describe port(9091) do
      it {should be_listening.on('0.0.0.0').with('tcp')}
    end

  end
end
