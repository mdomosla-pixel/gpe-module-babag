class babag::sender (
  $ensure            = 'latest',
  $manage_repo       = true,

  $log_level         = 'info',

  $aws_region,
  $dynamodb_status_table,

  $linkmobility_url,
  $linkmobility_platform_id,
  $linkmobility_platform_partner_id,
  $linkmobility_user,
  $linkmobility_pass,

  $smsapi_com_token,

  $admin_enabled,
  $admin_bind_address,
  $admin_port,

  $rabbitmq_host,
  $rabbitmq_port,
  $rabbitmq_vhost,
  $rabbitmq_user,
  $rabbitmq_pass,

  $postgres_username,
  $postgres_password,
  $postgres_database,
  $postgres_host,

  $rabbitmq_ssl      = false,
  $rabbitmq_ssl_cert = undef,
  $rabbitmq_ssl_key  = undef,
  $rabbitmq_ssl_ca   = undef,

  $nrepl_enabled,
  $nrepl_port,
  $nrepl_bind_address,

  $metrics_enabled   = false,
  $metrics_host      = "localhost",
  $metrics_port      = 8125,

  $noop_sending      = false,
) {

  $component_name = 'babag-sender'

  if $ensure in ['absent', 'present', 'installed'] {
    apt::pin { $component_name:
      ensure => 'absent',
      notify => Exec['apt_update'],
    }
  } else {
    apt::pin { $component_name:
      ensure   => present,
      packages => $component_name,
      version  => $ensure,
      priority => 1000,
      notify   => Exec['apt_update'],
    }
  }

  Package[$component_name] <- [ [ Apt::Source['sfrbintray'], Apt::Pin[$component_name], Class[Apt::Update], Exec['apt_update'] ], ]

  ensure_packages([$component_name],
    {
      ensure  => $ensure,
      require => [
        Apt::Source['sfrbintray'],
        Class['apt::update'],
        Package['apt-transport-https'],
      ],
      notify  => Service[$component_name],
    })

  ensure_resource('file', "/etc/default/${component_name}",
    {
      "content" => epp("${module_name}/default/${component_name}.epp",
        {
          log_level                        => $log_level,

          aws_region                       => $aws_region,
          dynamodb_status_table            => $dynamodb_status_table,

          linkmobility_url                 => $linkmobility_url,
          linkmobility_platform_id         => $linkmobility_platform_id,
          linkmobility_platform_partner_id => $linkmobility_platform_partner_id,
          linkmobility_username            => $linkmobility_user,
          linkmobility_password            => $linkmobility_pass,

          smsapi_com_token                 => $smsapi_com_token,

          admin_enabled                    => $admin_enabled,
          admin_bind_address               => $admin_bind_address,
          admin_port                       => $admin_port,

          postgres_username                => $postgres_username,
          postgres_password                => $postgres_password,
          postgres_database                => $postgres_database,
          postgres_host                    => $postgres_host,

          rabbitmq_host                    => $rabbitmq_host,
          rabbitmq_port                    => $rabbitmq_port,
          rabbitmq_vhost                   => $rabbitmq_vhost,

          rabbitmq_username                => $rabbitmq_user,
          rabbitmq_password                => $rabbitmq_pass,

          rabbitmq_ssl                     => $rabbitmq_ssl,
          rabbitmq_ssl_cert                => $rabbitmq_ssl_cert,
          rabbitmq_ssl_key                 => $rabbitmq_ssl_key,
          rabbitmq_ssl_ca                  => $rabbitmq_ssl_ca,

          nrepl_enabled                    => $nrepl_enabled,
          nrepl_port                       => $nrepl_port,
          nrepl_bind_address               => $nrepl_bind_address,

          metrics_enabled                  => $metrics_enabled,
          metrics_host                     => $metrics_host,
          metrics_port                     => $metrics_port,

          noop_sending                     => $noop_sending,
        }
      ),
      "mode"    => "0600",
      notify    => Service[$component_name],
    })

  service { $component_name:
    provider => systemd,
    ensure   => running,
    enable   => true,
    require  => Package[$component_name],
  }
}
