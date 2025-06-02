require 'beaker-rspec'
require 'beaker-rspec/helpers/serverspec'
require 'beaker/puppet_install_helper'
require 'beaker/module_install_helper'


RSpec.configure do |c|
  module_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    rabbitmq_host = hosts_with_role(hosts, "rabbitmq").first

    hosts.each do |host|
      # We only want to touch "agent" nodes, not the dependencies
      if host["roles"].include?("agent")
        run_puppet_install_helper_on(host)

        # on(host, puppet(*%w{module uninstall karolisl-babag}))

        install_module_dependencies_on([host])
        # install_module_on(host)
        copy_module_to(host,
                       module_name: "babag",
                       source: module_root,
                       target_module_path: "/etc/puppetlabs/code/modules")
        # puppet_module_install_on(host, :module_name => "babag",
        #                              :source => module_root,
        #                              :target_path => '/etc/puppetlabs/code/modules')
      end

      if host["roles"].include?("rabbitmq")
        on host, "pgrep rabbitmq || service rabbitmq-server restart || true"
      end
    end
  end
end

def fail_fast msg
  puts "Failing: #{msg}"
  exit 1
end
