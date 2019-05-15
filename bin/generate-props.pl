#!/usr/bin/env perl

use strict;
use warnings;
use 5.016;

use FindBin;

my $file=sprintf "%s/../default/props.conf", $FindBin::Bin;

my $props={
  '[dnsmasq]' => {
    SHOULD_LINEMERGE => 'false',
    LINE_BREAKER => '[\r\n]+',
    TZ => 'America/Los_Angeles',
    'EXTRACT-' => {

      "dnsmasq-dns" => qr{ ^
        ... \s .. \s ..:..:.. \s
        dnsmasq\[(?<pid>\d+)\]: \s
        (?:
          (?<request_id>\d+) \s
          (?<peer>[^\s/]+) / (?<peer_port>\d+) \s
          (?:
            (?<type> [a-z]+ )
            (?:
              (?<= query ) \[ (?<record_type> [^\]]+ ) \]
            )? \s
          )?
        |
          (?<type>reply) \s
        )
        (?<query> [\s\S]+? ) \s
        (?:
            from  \s (?<client_address> \S+ )
          | to    \s (?<server>         \S+ )
          | is    \s (?<result>         \S+ )
        )
      $ }ix,

      "dnsmasq-dhcp" => qr{ ^
        ... \s .. \s ..:..:.. \s
        dnsmasq-dhcp\[(?<pid>\d+)\]: \s
        (?:
          (?<request_id> \d+ ) \s
          (?:
            available \s DHCP \s range: \s (?<dhcp_range_start> \S+ ) \s -- \s (?<dhcp_range_end> \S+ )
          | vendor \s class: \s (?<dhcp_vendor_class> .*? )
          | client \s provides \s name: \s (?<dhcp_client_name> .*? )
          | (?<dhcp_eventype> DHCPREQUEST ) \( (?<dhcp_interface> [a-z0-9:_]+ ) \) \s (?<dhcp_ip> \S+ ) \s (?<dhcp_mac_address> \S+ )
          | (?<dhcp_eventype> DHCPACK ) \( (?<dhcp_interface> [a-z0-9:_]+ ) \) \s (?<dhcp_ip> \S+ ) \s (?<dhcp_mac_address> \S+ ) \s (?<dhcp_client_name> [^\n]*? )
          | (?<dhcp_eventype> DHCPDISCOVER ) \( (?<dhcp_interface> [a-z0-9:_]+ ) \) \s (?: (?<dhcp_ip> \S+ ) \s )? (?<dhcp_mac_address> \S+ )
          | (?<dhcp_eventype> DHCPOFFER ) \( (?<dhcp_interface> [a-z0-9:_]+ ) \) \s (?<dhcp_ip> \S+ ) \s (?<dhcp_mac_address> \S+ )
          | (?<dhcp_eventype> DHCPINFORM ) \( (?<dhcp_interface> [a-z0-9:_]+ ) \) \s (?<dhcp_ip> \S+ ) \s (?<dhcp_mac_address> \S+ )
          | (?<dhcp_action> [A-Z]+ ) \( (?<dhcp_interface> \S+ ) \) 
          | tags: \s (?<dhcp_tags> .*? )
          | requested \s options: \s (?<dhcp_requested_options> .*? )
          | next \s server: \s (?<dhcp_next_server> \S+ )
          | (?<dhcp_eventtype> broadcast \s response )
          | (?<dhcp_eventtype> sent \s size ) : \s+ (?<dhcp_option_size> \d+ ) \s+ option: \s+ (?<dhcp_option_id> \d+ ) \s+ (?<dhcp_option_name> \S .*? ) \s\s (?<dhcp_option_value> .*? )
          )

        | (?<dhcp_eventtype> Ignoring \s domain ) \s (?<dhcp_domain> \S+ ) \s for \s DHCP \s host \s name \s (?<dhcp_host> \S+ )

        ) \s*
      $ }ix,
    },
  }
};

for my $sourcetype (sort keys %$props) {
  my $sourcetype_definition=$props->{$sourcetype};
  printf "%s\n", $sourcetype;
  for my $key (sort grep { !m{-$} } keys %$sourcetype_definition) {
    printf "%s=%s\n", $key, $sourcetype_definition->{$key};
  }
  for my $directive (sort grep { m{-$} } keys %$sourcetype_definition) {
    for my $key (sort keys %{$sourcetype_definition->{$directive}}) {
      my $value=$sourcetype_definition->{$directive}->{$key};
      $value =~ s{\s*\n\s*}{ }g;
      $value =~ s{(\s)(\1)+}{ }g;
      printf "%s%s = %s\n", $directive, $key, $value;
    }
  }
  print "\n";
}
