# install fonts requied for PDF geneation
class profiles::fonts {
  file { '/usr/share/fonts/':
    ensure  => directory,
    source  => 'puppet:///modules/profiles/fonts',
    recurse => true,
  }
}
