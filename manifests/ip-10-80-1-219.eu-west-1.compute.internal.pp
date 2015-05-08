node 'ip-10-80-1-219.eu-west-1.compute.internal' {

	include '::profiles::nginx'

	$ssl             =  hiera('nginx::ssl')
    $ssl_protocols   =  hiera('nginx::ssl_protocols')
    $ssl_ciphers     =  hiera('nginx::ssl_ciphers')
    $ssl_cache       =  hiera('nginx::ssl_cache')
    $ssl_cert        =  hiera('nginx::ssl_cert')
    $ssl_key         =  hiera('nginx::ssl_key')
    $proxy           =  hiera('nginx::proxy')
    $proxy_set_header=  ['Host $host', 'X-Forward-For $proxy_add_x_forwarded_for', 'X-Real_IP $remote_addr', 'Client_IP $remote_addr']


	nginx::resource::vhost { 'digital.integration.beta.landregistryconcept.co.uk':
      
      proxy            =>  $proxy,
      ssl              =>  $ssl,
      ssl_protocols    =>  $ssl_protocols,
      ssl_ciphers      =>  $ssl_ciphers,
      ssl_cache        =>  $ssl_cache,
      ssl_cert         =>  $ssl_cert,
      ssl_key          =>  $ssl_key,
      proxy_set_header =>  $proxy_set_header,
      rewrite_to_https =>  { 'rewrite' => '^ https://$server_name$request_uri? permanent' },
    }
}