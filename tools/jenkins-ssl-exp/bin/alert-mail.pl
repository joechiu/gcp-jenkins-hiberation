#!/usr/bin/perl
#
use strict;
use lib '.';
use open ':std', ':encoding(UTF-8)';
use File::Copy;
use POSIX qw/difftime mktime strftime/;
use Text::CSV;
use constant TEST => 0;
use constant EXP => 30;
use Data::Dumper;

sub day;
sub hh;
sub mm;
sub ss;
sub icons;

my $csv = Text::CSV->new({ sep_char => ',' });

my $env = shift || 'prod';
my $csvdir = $env.'csv';
my $env = $csvdir =~ /non/g ? 'non prod' : 'prod';
my $cfile = '*';
my $now = now();
my $NOW = strftime('%Y-%m-%d %H:%M:%S', localtime($now));
my $mth = strftime('%m', localtime($now));
my $dst = ($mth > 3 and $mth < 11) ? 1 : 0; # day saving time
my $offset = 10 + $dst; # hours diff from system
my $skips = "DaysUntilExpired|End Date";
my $diff;
my $html = qq(<style>td { border-right: 1px solid white; }</style>\n);
my @rec;
my $text;
my $to;
my $NN = 0;
my $X = 0;
# update the recipient list here
if (TEST) {
	$to = 'Joe.Chiu@treasury.nsw.gov.au';
} else {
	$to = 'Indu.Neelakandan@treasury.nsw.gov.au,Joe.Chiu@treasury.nsw.gov.au';
}
my $from = 'Joe.Chiu@treasury.nsw.gov.au';
my $subject = "Just another certificate expiration alert - $NOW";
my @th = ( "CERTIFICATE", "ENV", "CN", "SERVER", "IP", "EXP DATE", "DAY LEFT", "STATUS" );
my $c = {
	s0 => "#ffffff",
	s1 => "#eeeeee",
	today => "#AED6F1",
	week => "#F9E79F",
	week2 => "#AED6F1",
	expired => "#E6B0AA",
	invalid => "#A9DFBF",
};

$html .= "<b>LICENSE EXPIRATION REPORT</b>\n";
$text .= "License Expiration Report: generated at $NOW\n";
$html .= "<table border=1 cellspacing=0 cellpadding=0>\n<tr><td>\n";
$html .= "<table border=0 cellspacing=0 cellpadding=6 width=100%>\n";
$html .= qq(<tr style="border:1px solid gray;color:white" bgcolor=black><td><b>).join('</b></td><td><b>',@th)."</b></td></tr>\n";

my $nn;
foreach my $cfile (glob "$csvdir/*.csv") {
open my $fh, "<:encoding(utf8)", $cfile or die "$cfile: $!";
R: 
    while ( my $r = $csv->getline( $fh ) ) {

	my ($path, $host, $ip) = $cfile =~ /(.*?\/)+(.*?)_(.*?)\.csv/g;
	my $err = "".$csv->error_diag();
	if ($err) {
		my @err = $csv->error_diag();
		$html .= sprintf qq(<tr bgcolor=red style="color:white"><td colspan=%d>%s</td></tr>), scalar @th, join(", ",@err);
		next R;
	}
	my ($app, $iss, $sub, $sel, $sta, $exp, $tot, $day) = @$r;
	my $un = "$iss$sub,";
	my (@cn) = $un =~ /CN\=(.*?)[\,|\/]/g;
	my $cn = join(",",@cn);
	$cn =~ s/,$//;
        $exp =~ /$skips/ig && next;
	$diff = $day;
	my $note ||= 'N/A';
	$day .= ' day'.snos($day);

        my $msg = sprintf "%-72s%-40s%16s%16s", "$app($env)", "$host($ip)", $exp, $day;
	my @td = ($app, $env, $cn, $host, $ip, $exp, $day);
	my $bg = $nn % 2 ? $c->{s1} : $c->{s0};
	my $stat;
	my $msgtemp = "Expires in %s days!";
	
        if ($diff > 0) {
                if ($diff < EXP/3) {
			$bg = $c->{today};
                        $stat = sprintf $msgtemp, EXP/3;
                } elsif ($diff < EXP/2) {
			$bg = $c->{week};
                        $stat = sprintf $msgtemp, EXP/2;
                } elsif ($diff < EXP) {
			$bg = $c->{week2};
                        $stat = sprintf $msgtemp, EXP;
                } else {
                        $stat = "OK!";
                }
        } else {
		$bg = $c->{expired};
		$stat = "Expired!";
        }

	$X++ if $diff < EXP;

	$text .= "$msg - $stat\n";
	push @td, $stat;
	my $h = {
		'stat' => $stat,
		'html' => sprintf qq(<tr bgcolor="$bg"><td nowrap=1>%s</td></tr>\n), join('</td><td nowrap=1>',@td)
	};
	push @rec, $h;
	$nn++;
    }
close $fh;
}
my $total = @rec;
if (!$total) {
	$html .= sprintf qq(<tr><td colspan=%d>%s</td></tr>), scalar @th, "None of the licenses is expired!";
} else {
	foreach my $r (@rec) {
		$html .= $r->{html} if $r->{'stat'} !~ /ok/gi;
	}
}
my $icons = join(" ", map {icon()} (1..36));
$html .= sprintf qq(<tr><td colspan=%d align=right>%s $X item%s found</td></tr>), (scalar @th), $icons, snos($X);
$html .= "</table>\n</td></tr>\n</table>";

exit mailer("Error: invalid format in the CSV file\n".system("cat $cfile")) unless $text;

if ($X) {
	eval { mailer($html) };
} else {
	print "[$NOW]\tNo expiry certificates found in $env!\n";
}

if ($@) {
	print "[$NOW]\t$@\n";
} else {
	print "[$NOW]\tmail sent\n$text\n" if $X;
}

sub mailer { 
	my $c = shift;
	my $git = 'https://github.com/NSWDAC/Platform/blob/master/Operations/Certificate%20Expiry%20Check/jenkins-ssl-exp';
	$c .= "<ul style='margin-left:-20;'>Script's available in GitHub: <a href='$git'>$git</a></ul>";
	open MAIL, '|/usr/sbin/sendmail -t' || die "Can't sendmail - $!"; 
	print MAIL "To: $to\n"; 
	print MAIL "From: $from\n"; 
	print MAIL "Subject: $subject\n"; 
	print MAIL qq(Content-Type: text/html; charset=UTF-8\n\n);
	print MAIL $c; 
	close MAIL; 
}

# s or no s for plural num
sub snos {
	my $n = shift;
	return 's' if $n > 1;
}
sub now {
        time + int($offset%86400)*3600
}
sub day {
        my $dd = sprintf "%d", int($diff/86400);
	$dd." day".snos($dd)
}
sub hh {
        my $hh = strftime('%H', localtime($diff));
	$hh." hour".snos($hh)
}
sub mm {
        my $mm = strftime('%M', localtime($diff));
	$mm." minute".snos($mm)
}
sub ss {
        my $ss = strftime('%S', localtime($diff));
	$ss." second".snos($ss)
}

sub icon {
        my @icons = qw/ &#9731 &#9788 &#9786 /;
	$NN++;
        srand (time ^ rand($NN*10));
        # zodiac constellations
        my @z = icons 9800, 12;
        # planets
        my @p = icons 9795, 5;
        # yi icons
        my @y = icons 9775, 9;
	# star symbols
	my @x = icons 10018, 52;
	# Chess Symbols
	my @c = icons 9812, 12;
	# Heart Symbols
	my @h = icons 10084, 4;
        push @icons, @z, @p, @x, @c, @y, @h;
        return $icons[rand @icons];
}
sub icons {
        my $s = shift;
        my $e = shift;
        return map { '&#'.($s+$_).';' }(0..$e-1);
}

