package CStyle::Common ;

BEGIN{
eval("use lib qw($ENV{DOCUMENT_ROOT}home/lib);");
};
use strict;
use CStyle::Configration ;
use Date::Calc qw(:all) ;
use DBI ;
use HTML::Template ;

#=================================================
# サブルーチン
#=================================================


#---------------------------------------------------------------------------------
# ヘッダーを出力
# なし
# なし
sub PrintHeader{
	CStyle::Common::print_log('I',"START") ;
	
	return if ( $CStyle::Configration::is_debug ) ;
	print "Content-Type: text/html; Charset=UTF-8\n\n" ;
}

sub print($){
	my $val = shift ;
	
	if ( $CStyle::Configration::is_debug ) {
		return $val ;
	}else{
		print $val ;
	}
}

#####################################
# データベースに接続
# なし
# データベースハンドル
sub DBConnect{
	return DBI->connect("DBI:Pg:dbname=".$CStyle::Configration::gv_dbname.";host=".$CStyle::Configration::gv_dbhost.";port=5432",$CStyle::Configration::gv_dbuser,$CStyle::Configration::gv_password,{ RaiseError => 1 ,AutoCommit => 0}) || CStyle::Common::OutPutLog('CStyle::Configration->DBConnect\t'.$DBI::errstr);
	
}

sub GetDay{
	# パラメータ
	my $lvi_now = '' ;
	
	# データ宣言
	$lvi_now = sprintf("%04d-%02d-%02d %02d:%02d:%02d",Today_and_Now()) ;
	
	return $lvi_now ;
}

#####################################
# dnsシリアル値を取得
# なし
# シリアル値
sub GetSerial{
	my @lai_localtime = () ;
	my $lvi_serial		= '' ;
	
	@lai_localtime = localtime() ;
	$lvi_serial = sprintf("%04d%02d%02d%02d",$lai_localtime[5] + 1900 , $lai_localtime[4] + 1 , $lai_localtime[3] , $lai_localtime[2]) ;
	return $lvi_serial ;
}	

#####################################
# システムエラー
# ログ内容
# なし
sub print_log{

	# パラメータ
	my $status = shift ;
	my $errortext = shift ;
	my $arg = shift ;
	
	if ( $CStyle::Configration::is_debug && $status eq 'E' ) {
		#return ;
	}
	
	# データ宣言
	my $lvi_now = &GetDay ;
	my @caller = caller(1) ;
	
	utf8::encode($status) if( utf8::is_utf8($status));
	utf8::encode($errortext)  if( utf8::is_utf8($errortext));
	utf8::encode($arg) if( utf8::is_utf8($arg));


	
	# ログ出力
	open(OUT,">> ".$CStyle::Configration::TRACE_PATH);
	print OUT $lvi_now."\t";
	print OUT $status . "\t";
#	print OUT ${'REQUEST_URI'} . "\t";
	print OUT $caller[3]. "\t" ;
	print OUT $errortext. "\t";
	print OUT $arg  . "\n";
	close(OUT);
	
	return 1;
}

#-------------------------------------------------------------------------#
# sql禁止文字の置き換え
# 引数 ： 変換文字列
# 戻り値 : String
#-------------------------------------------------------------------------#
sub escape($$){
	
	my $class	= shift(@_) ;
	my $val		= shift(@_) ;
	
	$val =~ s/\\/\\\\/g;
	$val =~ s/&/&amp;/g; # &
	$val =~ s/\"/&quot;/g; #"
	$val =~ s/\'/&#39;/g; # '
	$val =~ s/</&lt;/g; # <
	$val =~ s/>/&gt;/g; # >

	return($val);

}

#-------------------------------------------------------------------------#
# sql禁止文字の置き換えの逆変換
# 引数 ： 変換文字列
# 戻り値 : String
#-------------------------------------------------------------------------#
sub rvs_escape($$){
	my $class	= shift(@_) ;
	my $val		= shift(@_) ;
	
	$val =~ s/&amp;/&/g; # &
	$val =~ s/&quot;/\"/g; #"
	$val =~ s/&#39;/\'/g; # '
	$val =~ s/&lt;/</g; # <
	$val =~ s/&gt;/>/g; # >

	return($val);

}

#-------------------------------------------------------------------------#
# sql禁止文字の置き換えの逆変換
# 引数 ： 変換文字列
# 戻り値 : String
#-------------------------------------------------------------------------#
sub get_cnt_string($$){
	my $class	= shift(@_) ;
	my $val		= shift(@_) ;
	
	my $cnt_moji = 0 ;	
	my $zenkaku = $val;	
	
	$zenkaku =~ s/[a-z0-9]//gi ;
	$cnt_moji = length($val) - length($zenkaku);
	$cnt_moji = $cnt_moji + (length($zenkaku) / 3) ;
	
	return($cnt_moji);
}


=pod
sub template_output{
	CStyle::Common::print_log('I',"START") ;
		
	my $this = shift;
	my $param = shift;
	my $html = shift;
	
	my $Template = HTML::Template->new(	'filename' => $html ,
																	'path' => [CStyle::Configration::get_temp_path] ,
																	'die_on_bad_params' => 0,
																	'loop_context_vars' => 1,
																	'global_vars' => 1 ,
																	);
	
	if( $param->{DOMAIN} == undef ){
		$param->{DOMAIN} = $CStyle::Configration::DOMAIN;
	}
	
	$Template->param( $param ) ;
	
	my $out = $Template->output;
	
	return $out;
	
}
=cut


sub response_error_page{
	CStyle::Common::print_log('I',"START") ;
	
	my $this = shift;
	my $message = shift ;
	my $html = shift;
	
	my $out = CStyle::Common->template_output({'message' => $message},$html) ;

	#CStyle::Common::PrintHeader;
	return $out ;
}

1;