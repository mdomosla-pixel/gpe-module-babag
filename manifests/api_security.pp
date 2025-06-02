class babag::api_security (
    $htpasswd_dir = "/etc/nginx/babag",
    $htpasswd_file = "${htpasswd_dir}/users.htpasswd",
    $php_dir = "/var/www/php",
    $location_url = "https://nginx.org/packages/mainline/ubuntu/",
    $release = "xenial",
    $repos = "nginx",
    $key = "573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62",
    $source = "https://nginx.org/keys/nginx_signing.key",
    $nginx_ssl_cert,
    $nginx_ssl_key,
    $api_port,
    $nginx_users,
    $nginx_server = "babag",
    $php_version = "7.0",

) {
  ensure_packages(['apt-transport-https'], { ensure => "present" })

  apt::source { "${release}-mainline-nginx":
    location => "${location_url}",
    release  => "${release}",
    repos    => "${repos}",
    key      => {
      'id'     => "${key}",
      'source' => "${source}"
    },
    require  => Package['apt-transport-https'],
  }

  include ::nginx
  nginx::resource::location { "php":
    location             => "~ \.php$",
    location_custom_cfg  => { 'set $php_root'  => '/var/www/' },
    auth_basic           => "off",
    ssl_only             => true,
    ssl                  => true,
    server               => $nginx_server,
    fastcgi              => "127.0.0.1:9000",
    fastcgi_param        => {
      'SCRIPT_FILENAME' => '$php_root$fastcgi_script_name',
    },
  }
  nginx::resource::location { "root":
    location             => "/",
    ssl_only             => true,
    ssl                  => true,
    proxy                => "http://localhost:${api_port}",
    server               => $nginx_server,
  }
  nginx::resource::server { $nginx_server:
    # ssl_port == listen_port means that only SSL port will be listening
    server_name          => ["_", "babag"],
    listen_port          => 443,
    ssl_port             => 443,
    ssl                  => true,
    ssl_cert             => $nginx_ssl_cert,
    ssl_key              => $nginx_ssl_key,

    auth_basic           => "BabaG SMS Gateway API",
    auth_basic_user_file => "${htpasswd_file}",
    use_default_location => false,
    require              => File[$htpasswd_file],
    raw_append           => "location /_health { return 200; }",
  }

  #ensure_resource('file', '/etc/nginx/conf.d/default.conf', {'ensure' => 'absent' })

  ## This is mant to be a workaround for Fortigate MFA Authenticator
  ## Remove when this will be implemented in the code

  ensure_resource('file', "${php_dir}", {
    ensure  => directory,
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0755',
    recurse => true,
  })

  ensure_resource('file', "/var/www/php/gateway.php", {
    mode => "0755",
    owner => 'www-data',
    group => 'www-data',
    content => epp("${module_name}/default/babag-php-gateway.epp",
       {
          api_port              => $api_port,
       },
    ),
  })

  ensure_resource('file', "${htpasswd_dir}", {
    ensure => directory,
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0440',
  })

  ensure_resource('file', "${htpasswd_file}", {
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0440',
    require => File[$htpasswd_dir],
  })

  $nginx_users.each |$username, $password_hash| {
    htpasswd { $username:
      cryptpasswd => $password_hash,
      target      => $htpasswd_file,
      before      => File[$htpasswd_file],
      require     => File[$htpasswd_dir],
      notify      => Service['nginx'],
    }
  }
  ensure_packages(['php7.0-curl'], { ensure => "present" })
  class { '::php::globals':
    php_version => $php_version,
  }->
  class { '::php':
    fpm          => true,
    dev          => false,
    composer     => false,
    pear         => false,
    phpunit      => false,
  }
}
