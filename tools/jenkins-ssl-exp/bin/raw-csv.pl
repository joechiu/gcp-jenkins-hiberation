#!/usr/bin/perl

use POSIX qw/difftime mktime/;

sub diff;
sub chk;
sub cdt;

@a = ();
$h = {};
$nn = 0;
@h = (
	"Certificate",	
	"Issuer",
	"Subject",	
	"Self Signed",	
	"Start Date",	
	"End Date",	
	"Total Days",	
	"DaysUntilExpired",	
);

while (<>) {
        chomp;
        if (not $_) {
                $nn++;
                push @a, $h;
                $h = {};
                next;
        }
        chk $_;
}
# print "Total: $nn items\n";
print join(",", @h),"\n";

$i = 0;
foreach $c (@a) {
        ($c->{name}, $c->{url}) = split ':', $c->{app}, 2;
        ($c->{proto}, $c->{addr}, $c->{port}) = split ':', $c->{url};
        ($c->{ip}) = $c->{addr} =~ /(\d+\.\d+\.\d+\.\d+)/g;
        if (not $c->{ip}) {
                $c->{addr} =~ s/\///g;
        } else {
                undef $c->{addr}
        }
        $c->{sel} = $c->{iss} eq $c->{'sub'};
        $c->{sel} = 'Yes' if $c->{sel};
        $a[$i] = $c;
        $c->{sta} = cdt $c->{sta};
        $c->{end} = cdt $c->{end};
	$c->{day} = diff $c->{sta}, $c->{end};
	$c->{now} = diff $c->{end};
        $res = sprintf "%s,%s,%s,%s,%s,%s,%s,%s\n",
               		map {$c->{$_}} qw(app iss sub sel sta end day now);
	print $res if $res !~ /Yes\,\-\-/g
}
# print Dumper \@a;

sub mkt {
	my $dd = shift;
	my ($y, $m, $d) = split '-', $dd;
	mktime(0, 0, 0, $d, $m-1, $y-1900);
}

sub diff {
	my $d1 = shift;
	my $d2 = shift;
	if ($d2) {
		$d2 = mkt $d2;
	} else {
		$d2 = time();
	}
	$d1 = mkt $d1;
	if ($d2 > $d1) {
		$diff = difftime($d2, $d1);
	} else {
		$diff = difftime($d1, $d2);
	}
	sprintf "%.2f", $diff/86400;
}

sub cdt { # convert date Jan 23 23:43:24 2024 GMT to yyyy-mm-dd
        $dd = shift;
        @d = qw(jan feb mar apr may jun jul aug sep oct nov dec);
        $nn = 0;
        %d = map { $_ => sprintf "%02d", ++$nn } @d;
        ($m, $d, $t, $y, @foo) = split /\s+/, $dd;
        $m = $d{lc $m};
        "$y-$m-$d"
}

sub app {
        $s = shift;
        $s =~ /-+\s(.*?)\s-+/g;
        $h->{app} = $1;
}
sub iss {
        $s = shift;
        $s =~ /issuer= (.*)/g;
        $h->{iss} = $1;
}
sub jet {
        $s = shift;
        $s =~ /subject= (.*)/g;
        $h->{'sub'} = $1;
}
sub sta {
        $s = shift;
        $s =~ /notBefore=(.*)/g;
        $h->{sta} = $1;
}
sub end {
        $s = shift;
        $s =~ /notAfter=(.*)/g;
        $h->{end} = $1;
}

sub chk {
        $str = shift;
        app $str if $str =~ /------/;
        iss $str if $str =~ /issuer/;
        jet $str if $str =~ /subjec/;
        sta $str if $str =~ /notBef/;
        end $str if $str =~ /notAft/;
}
__END__
Service/Application     IP      Address Port    URL     Issuer  Subject Self signed Y/N Cert start date Cert Expiry date
name ip addr port url iss sub sel sta end

log=./server-raw-crt-list.txt; rm $log; for i in `find / -name '*.crt' | grep -v mozi | grep -v example`; do echo "------ $i ------" >> $log; openssl x509 -noout -issuer -subject -dates -in $i >> $log; echo >> $log; done

