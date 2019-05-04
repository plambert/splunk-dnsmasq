#!/usr/bin/env perl

use Modern::Perl qw/2016/;
use Path::Tiny;
use FindBin;
use JSON::MaybeXS;

my $json=JSON->new->canonical->allow_nonref->allow_blessed->convert_blessed->pretty;
my $props;
my $propsconf=path $FindBin::Bin, "default", "props.conf";

die "${propsconf}: cannot find props.conf" unless -f $propsconf;

my $conf=$propsconf->slurp_raw;

while($conf =~ m{(?:\A|\n)(?<stanza>EXTRACT-\S+)\s*=\s*(?<regexp>(?:.*\\\n)*.*\n)}gx) {
  my ($stanza, $regexp) = ($+{stanza}, $+{regexp});
  $regexp =~ s{(.*?)\s*\\\n}{$1}g;
  $props->{$stanza}=$regexp;
  # printf "\e[34;1m%s\e[0m\n%s\n\n\n", $stanza, $regexp;
}

say STDERR $json->encode($props);exit;

LINE: while(defined(my $line=<>)) {
  chomp $line;
  for my $key (keys %$props) {
    printf STDERR "\r %d %s\e[K\n", $., $key;
    if ($line =~ $props->{$key}) {
      my %fields=( %+, _raw => $line );
      print STDERR "\r\e[K";
      print $json->encode(\%fields);
      # printf "%s\n", $line;
      # printf "\e[1m%s\e[0m=%s ", $_, $+{$_} for sort keys %+;
      # printf "\n";
      next LINE;
    }
  }
  printf STDERR "\r\e[31m%s\e[0m\e[K", $json->encode({_raw => $line, ERROR => 'UNMATCHED' });
  # printf "\e[31m%s\e[0m\e[1mNO MATCHES\e[0m\n", $line;
}
