#!/usr/bin/perl
package CreateBlog;

BEGIN{
	eval("use lib qw($ENV{DOCUMENT_ROOT}home/lib);");
};

use strict;
use CStyle::Configration;
use CStyle::Common ;
use JSON qw/encode_json decode_json/ ;

#=================================================
#-- ここから主処理
#=================================================
&main;

sub main{
CStyle::Common::print_log('I',"START") ;

my %URL_PARAM = CStyle::Configration::get_request_param ;
my $blog_type = $URL_PARAM{'blog_type'} ;
my $domain = $URL_PARAM{'domain'} ;

if( $blog_type != undef && $blog_type ne ''
    && $domain != undef && $domain ne ''
){
	CStyle::Common->PrintHeader;
	print "" ;
}

my $rc = '';

my $blog_conf = &create_blog_conf($blog_type,$domain);

#Blogの設定
$rc = &create_blog($blog_type,$domain,$blog_conf);

if( !$rc ){
	#&rollback;
	
	#ログを出力
	CStyle::Common::print_log('E','処理失敗', "\$blog_type = $blog_type , \$domain = $domain");
	CStyle::Common->PrintHeader;
	print "" ;
	exit;
}

#DB情報を作製
$rc = &create_db($blog_conf,$blog_type,$domain);

if( !$rc ){

	#&rollback;
	
	#ログを出力
	CStyle::Common::print_log('E','処理失敗', "\$blog_type = $blog_type , \$domain = $domain");
	CStyle::Common->PrintHeader;
	print "" ;
	exit;
}
=pod 作成されるブログはサブドメイン形式からサブディレクトリ形式になったため不要
#DNSの設定
&create_dns;

if( !$rc ){
	&rollback;
	
	#ログを出力
	CStyle::Common::print_log('E','処理失敗', "\$blog_type = $blog_type , \$domain = $domain");
	CStyle::Common->PrintHeader;
	print "" ;
	exit;
}

#apacheの設定
&create_www;

if( !$rc ){
	&rollback;
	
	#ログを出力
	CStyle::Common::print_log('E','処理失敗', "\$blog_type = $blog_type , \$domain = $domain");
	CStyle::Common->PrintHeader;
	print "" ;
	exit;
}
=cut

my %res=();
$res{'id'} = $domain;
$res{'domain'} = $domain;
$res{'type'} = $blog_type;
my $json = encode_json(\%res);

#CStyle::Common->PrintHeader;
print "Content-Type: text/plain; charset=UTF-8\n" ;
print "\n";
print $json ;


CStyle::Common::print_log('I',"END") ;
exit;
}




#=================================================
#-- ここから関数
#=================================================

sub create_blog_conf{
CStyle::Common::print_log('I',"START") ;

	my $blog_type = shift;
	my $domain = shift;

	my %conf = ();
	my $dbname = $CStyle::Configration::BLOG_PREFIX .  $blog_type . "_" . $domain ;
	$dbname =~ s/\-/_/gi ;
	$conf{'db_name'} = $dbname ;
	$conf{'db_user'} =  $CStyle::Configration::BLOG_DB_USER ;
	$conf{'db_pass'} = $CStyle::Configration::BLOG_DB_PASS;
	$conf{'new_blog_dir'} = $CStyle::Configration::DOCUMENT_ROOT. $domain;
	$conf{'new_blog_dir_path'} = $CStyle::Configration::DOCUMENT_ROOT. $domain. '/';
	$conf{'data_dir'} =  $CStyle::Configration::USER_PATH . '/data' ;

	CStyle::Common::print_log('I',"END") ;

	return \%conf ;
}


sub create_blog{
	CStyle::Common::print_log('I',"START") ;

	my $blog_type = shift;
	my $domain = shift;
	my $blog_conf = shift;
	
	my $new_blog_dir = $blog_conf->{'new_blog_dir'};
	my $new_blog_dir_path = $blog_conf->{'new_blog_dir_path'};
	my $data_dir = $blog_conf->{'data_dir'} ;

	#blogtype毎に処理を判断
	if( $blog_type eq 'WP' ){
	
		#存在するフォルダは無理
		if(-d $CStyle::Configration::DOCUMENT_ROOT. $domain
		  || $domain eq $CStyle::Configration::HOME_DIR_NAME){
			CStyle::Common::print_log('E',"already exist dir = $blog_type,$domain") ;
			return undef;
		}

		#domains下にdirの作成
		`mkdir -p -m 777  $new_blog_dir` ;

		#data/mt.tar.gz を上記dir上にcp
		`cp $data_dir/wp.zip $new_blog_dir_path` ;

		#domains/mt.tar.gzを解凍
		my $unzip_path = $CStyle::Configration::DOCUMENT_ROOT. $domain .'/wp.zip';
		`unzip $unzip_path -d $new_blog_dir_path`;

		#解凍したファイルを移動し、今回作成したブログdirの直下に移動
		my $move_from = $new_blog_dir_path . 'wordpress/*' ;
		my $move_to = $new_blog_dir ;
		`mv $move_from $move_to` ;

		#mtの設定ファイルを書き換え
		open FH," < ".$data_dir."/wp-config.php" ;
		my @new_conf_file=() ;
		while( my $row = <FH>){
		
			#DB名
			$row =~ s/\$database_name\$/$blog_conf->{'db_name'}/g;
			$row =~ s/\$username\$/$blog_conf->{'db_user'}/g;
			$row =~ s/\$password\$/$blog_conf->{'db_pass'}/g;
			
			push @new_conf_file ,$row;
		}
		close FH;
		
		my $new_conf_file2 = join('',@new_conf_file);
		open FH , "> " .$new_blog_dir_path."wp-config.php"  ;
		print FH $new_conf_file2;
		close FH;
	}

	#念のため出来ているかチェック
	if(! -d $new_blog_dir_path
	  || ! -f $new_blog_dir_path."wp-config.php"
	){
	  CStyle::Common::print_log('E',"ディレクトリ作成エラー") ;
	  return undef;
	}

CStyle::Common::print_log('I',"END") ;	
	
	return 1;
}


sub create_db{
CStyle::Common::print_log('I',"START") ;
	my $blog_conf = shift;
	my $blog_type = shift;
	my $domain = shift;

	if( $blog_type  eq 'WP'  ){

		my $db_name = $blog_conf->{'db_name'} ;
		my $user_name = $blog_conf->{'db_user'} ;
		my $dbpass =  $blog_conf->{'db_pass'} ;

		my $mysql_root_pass = $CStyle::Configration::MYSQL_ROOT_PASS;

		open CMD, "| mysql -u root -p" . $mysql_root_pass;
		print CMD "CREATE DATABASE ".$db_name." ;" , "\n" ;
		print CMD "GRANT select,insert,delete,update,create,drop,file,alter,index ON *.* TO ".$user_name ."@\'localhost\' IDENTIFIED BY '".$dbpass."';","\n" ;
		print CMD "FLUSH PRIVILEGES;" , "\n";
		close CMD;

		#念のためチェックが出来なかったので、諦める
		#my @checkrc = ();
		#open CHECK , sprintf("mysql -u %s -p%s %s |",$user_name,$dbpass,$db_name) ;
		#@checkrc = <CHECK>;
		#close(CHECK);
		#CStyle::Common::print_log('I',@checkrc) ;
	}

	
CStyle::Common::print_log('I',"END") ;
	return 1;
}


sub create_dns{

	#/var/named/chroot/var/confに追記


	#/var/named/chroot/var/named/に追記
	


	#named restart
	
	return 1;
}


sub create_www{
=pod
	#Todo:
		tanyblog用のvirtualconf設定	
		
		apacheの再起動

=cut
	return 1;
}

sub rollback{

CStyle::Common::print_log('I',"START") ;
	my $blog_conf = shift;
	my $blog_type = shift;
	my $domain = shift;
	
	`rm -rf $blog_conf->{'new_blog_dir'}` ;

	return 1;
CStyle::Common::print_log('I',"END") ;
}