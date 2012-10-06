#!/usr/bin/perl
package ListBlog;

BEGIN{
eval("use lib qw($ENV{DOCUMENT_ROOT}home/lib);");
};
use strict;
use CStyle::Configration;
use JSON qw/encode_json decode_json/ ;

#=================================================
#-- ここから主処理
#=================================================
my $ret =[];
my $i = 1 ;

my $dirname = $CStyle::Configration::DOCUMENT_ROOT;
opendir DH, $dirname ;
while (my $dir = readdir DH) {

	next if( $dir eq 'home') ;
	next if (! -d $dirname.$dir ) ;
	next if( $dir =~ /(\.){1,2}/ );

	my $row = {
		'id'    => $i,
		'domain' => $dir,
		'type' => 'WP',
	};

	$i ++ ;

	push @$ret ,$row ;
}

my $json = encode_json($ret);

print "Content-Type: text/plain; charset=UTF-8\n" ;
print "\n";
print $json;



