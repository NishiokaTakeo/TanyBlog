#!/usr/bin/perl

use strict;
use JSON qw/encode_json decode_json/ ;


my $ret =[];

my $row = {
	'id'    => '1',
	'domain' => 'tany1.com',
	'type' => 'WP',
};

push @$ret ,$row ;

$row = {
	'id'    => '2',
	'domain' => 'tany2.com',
	'type' => 'WP',
};

push @$ret ,$row ;
my $json = encode_json($ret);

print "Content-Type: text/plain; charset=UTF-8\n" ;
print "\n";
print $json;



