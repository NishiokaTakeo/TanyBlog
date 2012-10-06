package CStyle::Configration ;

BEGIN{
eval("use lib qw($ENV{DOCUMENT_ROOT}home/lib);");
};
#use CStyle::Common;
use strict;

#=================================================
# データ宣言
#=================================================
our $USER_PATH      = &get_user_path($ENV{DOCUMENT_ROOT}) ;
our $DOCUMENT_ROOT	= $USER_PATH. '/domains/' ;
our $LOGS_ROOT		= $USER_PATH. '/logs/' ;
our $DOMAIN		= $ENV{HTTP_HOST} ;
our $TRACE_PATH	= $LOGS_ROOT . 'trace.log' ;
our %URL_PARAM = &get_request_param ;
our $HOME_DIR_NAME = 'home' ;
our $BLOG_PREFIX = 'tanyblog_' ;
our $BLOG_DB_USER = 'tany';
our $BLOG_DB_PASS = 'tanytany!';
our $MYSQL_ROOT_PASS = '4444#Gamk3b' ;

#=================================================
# 関数宣言
#=================================================
sub get_request_param{

	my %ret = ();

	my @p = split('&' , $ENV{'QUERY_STRING'}) ;

	foreach my $row (@p){
		my @kv =  split('=',$row);
		$ret{$kv[0]} = $kv[1];
	}

	return %ret ;
}

sub get_user_path {   
    my $doc_root = shift ;

    my @dirs = split('/',$doc_root) ;
    pop(@dirs);

    return join('/',@dirs) ;
}

1;