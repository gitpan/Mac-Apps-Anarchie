#!perl -w
#-----------------------------------------------------------------#
#  Anarchie.pm
#  pudge
#  Interface to Anarchie 2.01+
#
#  Created:       Chris Nandor (pudge@pobox.com)         18-Mar-97
#  Last Modified: Chris Nandor (pudge@pobox.com)         04-May-97
#-----------------------------------------------------------------#
package Mac::Apps::Anarchie;
require 5.00201;
use Exporter;
use Carp;
#-----------------------------------------------------------------
@ISA = qw(Exporter);
@Anarchie::ISA = qw(Mac::Apps::Anarchie);
@EXPORT = ();
#-----------------------------------------------------------------
$Mac::Apps::Anarchie::revision = '$Id: Anarchie.pm,v 1.1 1997/05/04 19:02 EST cnandor Exp $';
$Mac::Apps::Anarchie::VERSION  = '1.1';
local($be) = '';
#-----------------------------------------------------------------
use Mac::AppleEvents;
use Mac::Processes;
use Mac::MoreFiles(%Application);
#=================================================================
# Stuff
#=================================================================
sub new {
	my %fields1 = (
		showabout			=> ['abou','core'],
#		help				=> ['help','core'], #???
		quit				=> ['quit','aevt'],
		close				=> ['clos','core'],
		closeall			=> ['Clos','core'],
		undo				=> ['undo','core'],
		cut					=> ['cut ','core'],
		copyclip			=> ['copy','core'],
		paste				=> ['past','core'],
		clear				=> ['delo','core'],
		selectall			=> ['slct','core'],
#		frontwindowrecord	=> ['Afwr','Arch'], #???
		showtranscript		=> ['STrn','Arch'],
		showarchie			=> ['SArI','Arch'],
		showget				=> ['SFcI','Arch'],
		updateserverlist	=> ['UpSL','Arch'],
		showlog				=> ['SLog','Arch'],
		showmacsearch		=> ['SMSI','Arch'],
		showtips			=> ['STip','Arch'],
	);
	my %fields2 = (
		host	=> undef,
		path	=> undef,
		user	=> undef,
		pass	=> undef,
		fire	=> undef,
		socks	=> undef,
	);
	my %fields3 = (
		remove			=> 'Rmve',
		removeURL		=> 'Rmve',
		mkdir			=> 'MkDr',
		mkdirURL		=> 'MkDr',
		sendcommand		=> 'SCmd',
		sendcommandURL	=> 'SCmd',
		index			=> 'Indx',
		indexURL		=> 'Indx',
	);
	my %fields4 = (
		list			=> 'List',
		listURL			=> 'List',
		nlist			=> 'NLst',
		nlistURL		=> 'NLst',
	);
	my $self = {
		_p1 => \%fields1,
		%fields1,
		_p2 => \%fields2,
		%fields2,
		_p3 => \%fields3,
		%fields3,
		_p4 => \%fields4,
		%fields4,
	};
	my $that = shift;
	my $class = ref($that) || $that;
	bless $self, $class;
	$self->{ArchAgent} = shift || 'Arch';
	&_ArchLaunchApp($self);
	return $self;
}
#-----------------------------------------------------------------
sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self) || croak "$self is not an object\n";
	my $name = $AUTOLOAD;
	$name =~ s/.*://;
	if (exists $self->{_p1}->{$name}) {
		$be	= &_ArchAeBuild($self,$self->{$name}[0],$self->{$name}[1]);
		return &_ArchAeProcess($self)
	} elsif (exists $self->{_p2}->{$name}) {
		if (@_) {
			return $self->{$name} = shift;
		} else {
			return $self->{$name};
		}
	} elsif (exists $self->{_p3}->{$name}) {
		if ($name =~ /URL$/) {&_doArchFuncURL($self,$self->{$name},@_)}
		else {&_doArchFunc($self,$self->{$name},@_)}
	} elsif (exists $self->{_p4}->{$name}) {
		if ($name =~ /URL$/) {&_doListFuncURL($self,$self->{$name},@_)}
		else {&_doListFunc($self,$self->{$name},@_)}
	} else {
		croak "Can't access '$name' field in object of class $type\n";
	}
}
#-----------------------------------------------------------------
sub DESTROY {
	my $self = shift;
	&_ArchFrontApp($self,$self->{ArchMainApp}) if ($self->{ArchSwitchApps} == 1 && $self->{ArchMainApp});
}
#-----------------------------------------------------------------
sub revision {
	return $revision;
}
#-----------------------------------------------------------------
sub version {
	return $VERSION;
}
#-----------------------------------------------------------------
sub getresults {
	my($self,$res) = @_;
	$res = 'result' if (!$res);
	return $self->{results}->{$res};
}
#-----------------------------------------------------------------
sub getresultsall {
	my($self) = shift;
	my($results) = $self->{results};
	return %{$results};
}
#-----------------------------------------------------------------
sub switchapp {
	my($self,$do,$app) = @_;
	if (defined $do) {
		$self->{ArchSwitchApps} = $do;
	}
	if ($app) {
		$self->{ArchMainApp} = $app;
	}
	&_ArchFrontApp($self) if ($self->{ArchSwitchApps} == 1);
}
#-----------------------------------------------------------------
sub useagent {
	my($self,$agent) = @_;
	if ($agent) {
		$self->{ArchAgent} = $agent;
	}
	&_ArchFrontApp($self) if ($self->{ArchSwitchApps} == 1);
}
#-----------------------------------------------------------------
sub quit {
	my($self) = shift;
	my($be) = AEBuildAppleEvent('aevt','quit',typeApplSignature,$self->{ArchAgent},0,0,'') || croak $^E;
	AESend($be, kAEWaitReply) || croak $^E;
}
#=================================================================
# Main subroutines
#=================================================================
sub find {
	my(@p)	= @_;
	$be		= &_ArchAeBuild($p[0],'Find');
	if ($p[1])			{&_ArchBText($p[1],'----')	} else {&_ArchError('m','dObj')}
	if ($p[2])			{&_ArchBText($p[2],'ArFS')	}
	if ($p[3] ne '')	{&_ArchBShor($p[3],'ArFM')	}
	if ($p[4] ne '')	{&_ArchBBool($p[4],'ArFC')	}
	if ($p[5] ne '')	{&_ArchBKeyw($p[5],'ArFR',[0,1,2])}
	if ($p[6])			{&_ArchBText($p[6],'ArUR')	}
#	if (defined $p[7])	{&_ArchBBool($p[7],'ArFW')	}
	&_ArchBBool(1,'ArFW');
	return &_ArchAeProcess($p[0])
}
#-----------------------------------------------------------------
sub macsearch {
	my(@p)	= @_;
	$be		= &_ArchAeBuild($p[0],'PQry');
	if ($p[1])			{&_ArchBText($p[1],'----')	} else {&_ArchError('m','dObj')}
	return &_ArchAeProcess($p[0])
}
#-----------------------------------------------------------------
sub fetch {
	my(@p)	= @_;
	$be		= &_ArchAeBuild($p[0],'Ftch');
	my($host) = $p[5] || $p[0]->{host};
	my($user) = $p[6] || $p[0]->{user};
	my($pass) = $p[7] || $p[0]->{pass};
	my($fire) = $p[8] || $p[0]->{fire};
	my($socks) = $p[9] || $p[0]->{socks};
	if ($p[1])			{&_ArchBFile($p[1],'----')	} else {&_ArchError('m','dObj')}
	if ($p[2])			{&_ArchBText($p[2],'FTPc')	}
	if (defined $p[3])	{&_ArchBBool($p[3],'ArGB')	}
	if ($p[4])			{&_ArchBText($p[4],'ArGE')	}
	if ($host)			{&_ArchBText($host,'FTPh')	}
	if ($user)			{&_ArchBText($user,'ArGU')	}
	if ($pass)			{&_ArchBText($pass,'ArGp')	}
	if ($fire)			{&_ArchBText($fire,'ArGF')	}
	if ($socks)			{&_ArchBText($socks,'ArGS')	}
	return &_ArchAeProcess($p[0])
}
#-----------------------------------------------------------------
sub fetchURL {
	my(@p)	= @_;
	$be		= &_ArchAeBuild($p[0],'Ftch');
	my($fire) = $p[5] || $p[0]->{fire};
	my($socks) = $p[6] || $p[0]->{socks};
	if ($p[1])			{&_ArchBFile($p[1],'----')	} else {&_ArchError('m','dObj')}
	if ($p[2])			{&_ArchBText($p[2],'ArUR')	}
	if (defined $p[3])	{&_ArchBBool($p[3],'ArGB')	}
	if ($p[4])			{&_ArchBText($p[4],'ArGE')	}
	if ($fire)			{&_ArchBText($fire,'ArGF')	}
	if ($socks)			{&_ArchBText($socks,'ArGS')	}
	return &_ArchAeProcess($p[0])
}
#-----------------------------------------------------------------
sub store {
	my(@p)	= @_;
	$be		= &_ArchAeBuild($p[0],'Stor');
	my($host) = $p[4] || $p[0]->{host};
	my($user) = $p[5] || $p[0]->{user};
	my($pass) = $p[6] || $p[0]->{pass};
	my($fire) = $p[7] || $p[0]->{fire};
	my($socks) = $p[8] || $p[0]->{socks};
	if ($p[1])			{&_ArchBFile($p[1],'----')	} else {&_ArchError('m','dObj')}
	if ($p[2])			{&_ArchBText($p[2],'FTPc')	}
	if (defined $p[3])	{&_ArchBBool($p[3],'ArGB')	}
	if ($host)			{&_ArchBText($host,'FTPh')	}
	if ($user)			{&_ArchBText($user,'ArGU')	}
	if ($pass)			{&_ArchBText($pass,'ArGp')	}
	if ($fire)			{&_ArchBText($fire,'ArGF')	}
	if ($socks)			{&_ArchBText($socks,'ArGS')	}
	return &_ArchAeProcess($p[0])
}
#-----------------------------------------------------------------
sub storeURL {
	my(@p)	= @_;
	$be		= &_ArchAeBuild($p[0],'Stor');
	my($fire) = $p[4] || $p[0]->{fire};
	my($socks) = $p[5] || $p[0]->{socks};
	if ($p[1])			{&_ArchBFile($p[1],'----')	} else {&_ArchError('m','dObj')}
	if ($p[2])			{&_ArchBText($p[2],'ArUR')	}
	if (defined $p[3])	{&_ArchBBool($p[3],'ArGB')	}
	if ($fire)			{&_ArchBText($fire,'ArGF')	}
	if ($socks)			{&_ArchBText($socks,'ArGS')	}
	return &_ArchAeProcess($p[0])
}
#-----------------------------------------------------------------
sub rename {
	my(@p)	= @_;
	$be		= &_ArchAeBuild($p[0],'Rena');
	my($host) = $p[3] || $p[0]->{host};
	my($user) = $p[4] || $p[0]->{user};
	my($pass) = $p[5] || $p[0]->{pass};
	my($fire) = $p[6] || $p[0]->{fire};
	my($socks) = $p[7] || $p[0]->{socks};
	if ($p[1])			{&_ArchBText($p[1],'NewN')	} else {&_ArchError('m','NewN')}
	if ($p[2])			{&_ArchBText($p[2],'FTPc')	}
	if ($host)			{&_ArchBText($host,'FTPh')	}
	if ($user)			{&_ArchBText($user,'ArGU')	}
	if ($pass)			{&_ArchBText($pass,'ArGp')	}
	if ($fire)			{&_ArchBText($fire,'ArGF')	}
	if ($socks)			{&_ArchBText($socks,'ArGS')	}
	return &_ArchAeProcess($p[0])
}
#-----------------------------------------------------------------
sub renameURL {
	my(@p)	= @_;
	$be		= &_ArchAeBuild($p[0],'Rena');
	my($fire) = $p[3] || $p[0]->{fire};
	my($socks) = $p[4] || $p[0]->{socks};
	if ($p[1])			{&_ArchBText($p[1],'NewN')	} else {&_ArchError('m','NewN')}
	if ($p[2])			{&_ArchBText($p[2],'ArUR')	}
	if ($fire)			{&_ArchBText($fire,'ArGF')	}
	if ($socks)			{&_ArchBText($socks,'ArGS')	}
	return &_ArchAeProcess($p[0])
}
#-----------------------------------------------------------------
sub _doArchFunc {
	my(@p)	= @_;
	$be		= &_ArchAeBuild($p[0],$p[1]);
	my($host) = $p[3] || $p[0]->{host};
	my($user) = $p[4] || $p[0]->{user};
	my($pass) = $p[5] || $p[0]->{pass};
	my($fire) = $p[6] || $p[0]->{fire};
	my($socks) = $p[7] || $p[0]->{socks};
	if ($p[2])			{&_ArchBText($p[2],'FTPc')	}
	if ($host)			{&_ArchBText($host,'FTPh')	}
	if ($user)			{&_ArchBText($user,'ArGU')	}
	if ($pass)			{&_ArchBText($pass,'ArGp')	}
	if ($fire)			{&_ArchBText($fire,'ArGF')	}
	if ($socks)			{&_ArchBText($socks,'ArGS')	}
	return &_ArchAeProcess($p[0])
}
#-----------------------------------------------------------------
sub _doArchFuncURL {
	my(@p)	= @_;
	$be		= &_ArchAeBuild($p[0],$p[1]);
	my($fire) = $p[3] || $p[0]->{fire};
	my($socks) = $p[4] || $p[0]->{socks};
	if ($p[2])			{&_ArchBText($p[2],'ArUR')	}
	if ($fire)			{&_ArchBText($fire,'ArGF')	}
	if ($socks)			{&_ArchBText($socks,'ArGS')	}
	return &_ArchAeProcess($p[0])
}
#-----------------------------------------------------------------
sub _doListFunc {
	my(@p)	= @_;
	$be		= &_ArchAeBuild($p[0],$p[1]);
	my($host) = $p[5] || $p[0]->{host};
	my($user) = $p[6] || $p[0]->{user};
	my($pass) = $p[7] || $p[0]->{pass};
	my($fire) = $p[8] || $p[0]->{fire};
	my($socks) = $p[9] || $p[0]->{socks};
	if ($p[2])			{&_ArchBFile($p[2],'----')	} #else {&_ArchError('m','dObj')}
	if ($p[3])			{&_ArchBText($p[3],'FTPc')	}
	if (defined $p[4])	{&_ArchBBool($p[4],'ArFW')	}
	if ($host)			{&_ArchBText($host,'FTPh')	}
	if ($user)			{&_ArchBText($user,'ArGU')	}
	if ($pass)			{&_ArchBText($pass,'ArGp')	}
	if ($fire)			{&_ArchBText($fire,'ArGF')	}
	if ($socks)			{&_ArchBText($socks,'ArGS')	}
	return &_ArchAeProcess($p[0])
}
#-----------------------------------------------------------------
sub _doListFuncURL {
	my(@p)	= @_;
	$be		= &_ArchAeBuild($p[0],$p[1]);
	my($fire) = $p[5] || $p[0]->{fire};
	my($socks) = $p[6] || $p[0]->{socks};
	if ($p[2])			{&_ArchBFile($p[2],'----')	} #else {&_ArchError('m','dObj')}
	if ($p[3])			{&_ArchBText($p[3],'ArUR')	}
	if (defined $p[4])	{&_ArchBBool($p[4],'ArFW')	}
	if ($fire)			{&_ArchBText($fire,'ArGF')	}
	if ($socks)			{&_ArchBText($socks,'ArGS')	}
	return &_ArchAeProcess($p[0])
}
#-----------------------------------------------------------------
sub open {
	my(@p)	= @_;
	$be		= &_ArchAeBuild($p[0],'odoc','aevt');
	if ($p[1])			{&_ArchBFile($p[1],'----')	} else {&_ArchError('m','dObj')}
	return &_ArchAeProcess($p[0])
}
#-----------------------------------------------------------------
sub geturl {
	my(@p)	= @_;
	$be		= &_ArchAeBuild($p[0],'GURL','GURL');
	if ($p[1])			{&_ArchBText($p[1],'----')	} else {&_ArchError('m','dObj')}
	if ($p[2])			{&_ArchBFile($p[2],'dest')	}
	return &_ArchAeProcess($p[0])
}
#=================================================================
# Error checking of data
#=================================================================
sub _twixtOf {
	my($type,$one,$of) = @_;
	&_ArchError('d',$type) unless 
		(($one !~ /\D/ && $one >= $$of[0] && $one <= $$of[1]) || ($one == 0));
	return 1;
}
#-----------------------------------------------------------------
sub _oneOf {
	my($type,$one,$of,$yes) = @_;
	foreach (@{$of}) {
		$yes = 1 if ($one eq $_);
	}
	if (!$yes) {
		&_ArchError('t',$type);
	}
	return 1;
}
#=================================================================
# Add AE descriptor records to event
#=================================================================
sub _ArchBKeyw {
	my($data,$type,$keys) = @_;
	AEPutParamDesc($be,$type,(AEBuild($data))) if (&_oneOf($type,$data,$keys));
}
#-----------------------------------------------------------------
sub _ArchBShor {
	my($data,$type) = @_;
	my(@datas) = ('0', eval(2**31));
	AEPutParamDesc($be,$type,(AEBuild($data))) if (&_twixtOf($type,$data,\@datas));
}
#-----------------------------------------------------------------
sub _ArchBBool {
	my($data,$type) = @_;
	if ($data eq '1') {
		$data = 'true';
	} elsif ($data eq '0') {
		$data = 'fals';
	} else {
		&_ArchError('b',$type);
	}
	AEPutParamDesc($be,$type,(AEBuild($data)));
}
#-----------------------------------------------------------------
sub _ArchBText {
	my($data,$type) = @_;
	AEPutParamDesc($be,$type,(AEBuild('TEXT(@)',$data)));
}
#-----------------------------------------------------------------
sub _ArchBFile {
	my($data,$type) = @_;
	my($file)	= AECreateList('', 1);
	AEPutParam($file, 'want', 'type', 'file');
	AEPutParam($file, 'from', 'null', '');
	AEPutParam($file, 'form', 'enum', 'name');
	AEPutParam($file, 'seld', 'TEXT', $data);
	my($obj)	= AECoerceDesc($file, 'obj ');	
	AEPutParamDesc($be,$type,$obj);
}
#=================================================================
# Main processing
#=================================================================
sub _ArchLaunchApp {
	my($self) = shift;
	my($app) = shift || $self->{ArchAgent};
	my(%Launch);
	tie %Launch, LaunchParam;
	$Launch{launchControlFlags} = launchContinue+launchNoFileFlags+launchDontSwitch;
	$Launch{launchAppSpec}		= $Application{$app};
	LaunchApplication(\%Launch) or croak $^E;
}
#-----------------------------------------------------------------
sub _ArchFrontApp {
	my($self) = shift;
	my($app) = shift || $self->{ArchAgent};
	my(%Launch);
	tie %Launch, LaunchParam;
	$Launch{launchControlFlags} = launchContinue+launchNoFileFlags;
	$Launch{launchAppSpec}		= $Application{$app};
	LaunchApplication(\%Launch) or croak $^E;
}
#-----------------------------------------------------------------
sub _ArchError {
	my($type,$info) = @_;
	if ($type eq 'm') {
		croak "Missing required element of type: $info.\n";
	} elsif ($type eq 'd') {
		croak "Value of $info does not fall within acceptable bounds.\n";
	} elsif ($type eq 't') {
		croak "Value of $info does not match acceptable parameters.\n";
	} elsif ($type eq 'b') {
		croak "Value of $info must be either 1 or 0 (boolean).\n";
	} elsif ($type eq 's') {
		croak "Cannot include signature in self-decrypting files.\n";
	} else {
		croak "Unknown error ($type, $info).\n";
	}
}
#-----------------------------------------------------------------
sub _ArchAeBuild {
	my($self,$ev,$st) = @_;
	$st = 'Arch' if (!$st);
	my($be) = AEBuildAppleEvent($st,$ev,typeApplSignature,$self->{ArchAgent},0,0,'') || croak $^E;
	return $be;
}
#-----------------------------------------------------------------
sub _ArchAePrint {
	my($self,$rp) = @_;
	my(@ar,%ar,$ar,$at);
	@ar = ('----','errn','errs','outp');
	foreach $ar(@ar) {
		if ($at = AEGetParamDesc($rp,$ar)) {
			$ar{$ar} = AEPrint($at);
		}
	}
	if (exists $ar{'----'}) {
		$ar{'----'} =~ s/^Ò(.*)Ó$/$1/s;
		$ar{'result'} = $ar{'----'};
	}
	if ($ar{'errn'}) {
		$ar{'errs'} =~ s/^Ò(.*)Ó$/$1/ if (exists $ar{'errs'});
		carp "Anarchie error $ar{'errn'}: $ar{'errs'}\n";
	}
	if (exists $ar{'outp'}) {
		$ar{'outp'} =~ s/^\[alis\(\Ç(.*?)\È\)\]/$1/;
#		$ar{'outp'} = (pack("H*",$ar{'outp'}));
	}
	$self->{results} = \%ar;
	return $ar{result};
}
#-----------------------------------------------------------------
sub _ArchAeProcess {
	my($self) = shift;
	my($rp) = AESend($be, kAEWaitReply) || croak $^E;
	return &_ArchAePrint($self,$rp);
}
#-----------------------------------------------------------------#

__END__

=head1 NAME

Mac::Apps::Anarchie - Interface to Anarchie 2.01+

=head1 SYNOPSIS

	use Mac::Apps::Anarchie;
	$ftp = new Anarchie;

=head1 DESCRIPTION

This is a MacPerl interface to the popular MacOS shareware FTP/archie client, Anarchie.  For more info, see the Anarchie documentation.

=head1 USAGE

NOTE: for some explanations of methods, drop Anarchie on Script Editor, and check the Anarchie docs.

=head2 Standard Suite

	$ftp->open(ALIAS);
	$ftp->quit;
	$ftp->showabout;
	$ftp->close;
	$ftp->closeall;
	$ftp->undo;
	$ftp->cut;
	$ftp->copyclip;
	$ftp->paste;
	$ftp->clear;
	$ftp->selectall;

=head2 Anarchie Suite

NOTE: * denotes compatability with Fetch.  Fetch does not use the variables SOCKS, FIRE, BINARY, or TYPE.  Fetch implements some of these methods differently than Anarchie.  To use Fetch instead of Anarchie for these methods, call the method:

	$ftp->useagent('FTCh');

There are two forms of each of the following methods: "method" and "methodURL".
The methodURL version takes the user name, password, host and path in 
the URL instead of separately.  URLs are usually in the form:

	ftp://user:password@host.com/path/to/file
	ftp://user:password@host.com//absolute/path/to/file

See Anarchie docs for more info on URLs.

Also, the host, username, password, proxy firewall and socks firewall can be preset and then omitted during the method call.  This saves a lot of code writing if you are going to make multiple calls to the same host.  If a method explicitly names any of those strings, it overrides presets.  If username and password are not specified anywhere, FTP is done anonymously.

	$ftp->host(HOST);
	$ftp->user(USER);
	$ftp->pass(PASS);
	$ftp->fire(FIRE);
	$ftp->socks(SOCKS);

=over

=item fetch *

	$ftp->fetch(FILENAME [, PATH, BINARY, TYPE, HOST, USER, PASS, FIRE, SOCKS]);
	$ftp->fetchURL(FILENAME [, URL, BINARY, TYPE, FIRE, SOCKS]);

Fetches file and saves to FILENAME on local drive.  BINARY is boolean for whether file is binary or ascii.  TYPE is the creator code to link file to.  NOTE: for Fetch, FILENAME must be an existing directory name, NOT a filename.  For Anarchie, FILENAME must be a file if the fetched item is a file or a directory if the fetched item is a directory.  Anarchie will create FILENAME on the local drive if it does not exist.  

=item store *

	$ftp->store(FILENAME [, PATH, BINARY, HOST, USER, PASS, FIRE, SOCKS]);
	$ftp->storeURL(FILENAME [, URL, BINARY, FIRE, SOCKS]);

Stores file FIELNAME from local drive to remote location specified.

=item rename *

	$ftp->rename(NEWNAME [, PATH, HOST, USER, PASS, FIRE, SOCKS]);
	$ftp->renameURL(NEWNAME [, URL, FIRE, SOCKS]);

Renames file NEWNAME to value in PATH or URL.

=item remove *

$ftp->remove([PATH, HOST, USER, PASS, FIRE, SOCKS]);
$ftp->removeURL([URL, FIRE, SOCKS]);

Removes file/directory specified in PATH or URL.

=item mkdir *

	$ftp->mkdir([PATH, HOST, USER, PASS, FIRE, SOCKS]);
	$ftp->mkdirURL([URL, FIRE, SOCKS]);

Make directory specified in PATH or URL.

=item sendcommand *

	$ftp->sendcommand([PATH, HOST, USER, PASS, FIRE, SOCKS]);
	$ftp->sendcommandURL([URL, FIRE, SOCKS]);

Send raw FTP command.

=item index *

	$ftp->index([PATH, HOST, USER, PASS, FIRE, SOCKS]);
	$ftp->indexURL([URL, FIRE, SOCKS]);

Display index listing.  SITE INDEX command must be implemented on host.

=item list *

	$ftp->list(FILENAME, [PATH, HOST, USER, PASS, FIRE, SOCKS]);
	$ftp->listURL(FILENAME, [URL, FIRE, SOCKS]);

List files in a directory, put into file FILENAME.  Fetch apparently only lists to the screen, while Anarchie lists to a file.  For Fetch, just put any old text in place of FILENAME and it should work just fine.

=item nlist

	$ftp->nlist(FILENAME, [PATH, HOST, USER, PASS, FIRE, SOCKS]);
	$ftp->nlistURL(FILENAME, [URL, FIRE, SOCKS]);

List names of files in a directory, put into file FILENAME.

=head2 Anarchie Suite, Part Deux

NOTE: These methods are NOT supported at all by Fetch.

=item find

	$ftp->find(FILENAME [, SERVER, MAX, CASE, REGEX, URL]);

Find file containing text FILENAME in Archie SERVER with maximum matches MAX.  CASE is boolean (0 or 1) for case sensitive.  REGEX is 0, 1 or 2 for denoting that FILENAME is a substring, pattern, or regular expression.

=item macsearch

	$ftp->macsearch(FILENAME);

Find Mac file containing text FILENAME on Ambrosia's Mac server.

=item others

	$ftp->showtranscript;
	$ftp->showarchie;
	$ftp->showget;
	$ftp->updateserverlist;
	$ftp->showlog;
	$ftp->showmacsearch;
	$ftp->showtips;

=item geturl

$ftp->geturl(URL [, FILENAME]);

=back

=head1 VERSION NOTES

=over

=item v.1.1 May 4, 1997

Whoops, fixed something I broke in the AEPutParamDesc stuff.

=item v.1.0 May 4, 1997

Finally got around to cleaning it up.  Only minor changes.

=item v.0.2 March 20, 1997

First 'public' beta.

=back

=head1 BUGS / TO DO

=over

=item regex find

Still having problems with the substring/pattern/regex option on L<"find">.  I am not sure what the problem is.

=back

=head1 SEE ALSO

=over

=item Anarchie Home Page

http://www.stairways.com/anarchie/index.html

=back

=head1 AUTHOR / COPYRIGHT

Chris Nandor, 04-May-1997

	mailto:pudge@pobox.com
	http://pudge.net/

Copyright (c) 1997 Chris Nandor.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.  Please see the Perl Artistic License.

=cut
