# Class profiles::digitalregister_app
#
# This class will manage api server installations
#
# Requires:
# - puppetlabs/stdlib
#
# Sample Usage:
#   class { 'profiles::digitalregister_app': }
#
class profiles::digital_java_apps(){

    package { 'leptonica':
      ensure   => 'installed',
      source   => 'https://s3-eu-west-1.amazonaws.com/rpm.landregistryconcept.co.uk/landregistry/x86_64/leptonica_1.72_x86_64.rpm',
      provider => 'rpm'
    }

    package { 'tesseract':
      ensure   => 'installed',
      source   => 'https://s3-eu-west-1.amazonaws.com/rpm.landregistryconcept.co.uk/landregistry/x86_64/tesseract_3.03_x86_64.rpm',
      provider => 'rpm'
    }

}
