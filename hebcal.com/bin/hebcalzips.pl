#!/usr/local/bin/perl5 -w

# $Id$

use DB_File;

%city_zips = 
    (
     'Atlanta', '30334',
     'Austin', '78701',
     'Baltimore', '21201',
     'Boston', '02108',
     'Buffalo', '14201',
     'Chicago', '60608',
     'Cincinnati', '45202',
     'Cleveland', '44102',
     'Dallas', '75201',
     'Denver', '80202',
     'Detroit', '48201',
     'Hawaii', '96813',
     'Houston', '77002',
     'Los+Angeles', '90071',
     'Los Angeles', '90071',
     'Los%20Angeles', '90071',
     'Miami', '33128',
     'New+York', '10007',
     'New York', '10007',
     'New%20York', '10007',
     'Omaha', '68102',
     'Philadelphia', '19102',
     'Phoenix', '85003',
     'Pittsburgh', '15240',
     'Saint+Louis', '63101',
     'Saint%20Louis', '63101',
     'Saint Louis', '63101',
     'San+Francisco', '94102',
     'San%20Francisco', '94102',
     'San Francisco', '94102',
     'Seattle', '98101',
     'Washington+DC', '20301',
     'Washington%20DC', '20301',
     'Washington DC', '20301',
     );

$dbmfile = '/home/web/hebcal.com/docs/hebcal/zips.db';
tie(%DB, 'DB_File', $dbmfile, O_RDONLY, 0444, $DB_File::DB_HASH)
    || die "Can't tie $dbmfile: $!\n";
die unless defined $DB{"95051"};

$total = 0;
$filename = defined $ARGV[0] ? $ARGV[0] : 
    '/var/log/httpd/hebcal.com-access_log';
open(A,$filename) || die "$filename: $!\n";
while(<A>)
{
    next unless m,/hebcal/, || m,/shabbat/,;
    next if /cfg=r/;
    next if /cfg=/;
    next if /^208\.46\.162\.254/;
    next if /^24\.130\.2\.|24\.167\.142\./;
    next if /^207\.55\.191\.4|205\.216\.162\.|198\.144\.204\.|198\.144\.193\.150|206\.251\.16\./;

    if (/zip=(\d\d\d\d\d)/) {
	if (defined $zips{$1}) {
	    $zips{$1}++;
	} else {
	    $zips{$1} = 1;
	}
	$total++;
    } elsif (/city=([^\s\&]+)/) {
	if (defined $city_zips{$1})
	{
	    if (defined $zips{$city_zips{$1}}) {
		$zips{$city_zips{$1}}++;
	    } else {
		$zips{$city_zips{$1}} = 1;
	    }
	    $total++;
	}
    }
}
close(A);

$unk = 0;
while(($key,$val) = each(%zips))
{
    if (defined $DB{$key}) {
	if (defined $valbycity{substr($DB{$key},6)}) {
	    $valbycity{substr($DB{$key},6)} += $val;
	    $zipbycity{substr($DB{$key},6)} .= "\001" . $key;
	} else {
	    $valbycity{substr($DB{$key},6)}  = $val;
	    $zipbycity{substr($DB{$key},6)}  = $key;
	}
    } else {
	if (defined $valbycity{'***UNKNOWN***'}) {
	    $valbycity{'***UNKNOWN***'} += $val;
	    $zipbycity{'***UNKNOWN***'} .= "\001" . $key;
	} else {
	    $valbycity{'***UNKNOWN***'}  = $val;
	    $zipbycity{'***UNKNOWN***'}  = $key;
	}
	$unk += $val;
    }
}
untie(%DB);


foreach (sort keys %valbycity) {
    if (defined($byvalue{$valbycity{$_}})) {
	$byvalue{$valbycity{$_}} .= "\001" . $_;
    } else {
	$byvalue{$valbycity{$_}} = $_;
    }
}

print "Hebcal Interactive Jewish Calendar - http://www.hebcal.com/\n";
print "Most Often Used Zip Codes\n";
print "------------------------------------------------------------\n";
print scalar(localtime), "\n";
printf "%d pageviews (%5.1f%% from unknown zip codes)\n",
    $total, (($unk * 100.0) / $total);
print "------------------------------------------------------------\n";

$a = $b = 0;			# avoid warning
foreach $cityval (sort {$b <=> $a} keys %byvalue) {
    @c=split(/\001/, $byvalue{$cityval});
    foreach $c (@c) { 
	die unless defined $zipbycity{$c};
	if ($c =~ /\0/) {
	    ($city,$state) = split(/\0/, $c);

	    @city = split(/([- ])/, $city);
	    $city = '';
	    foreach (@city)
	    {
		$_ = "\L$_\E";
		$_ = "\u$_";
		$city .= $_;
	    }
	    undef(@city);
	    $c2 = "$city, $state";
	    
	    &display_city();
	}
    }
}

if (defined $valbycity{'***UNKNOWN***'}) {
    $c2 = $c = '***UNKNOWN***';
    $cityval = $valbycity{'***UNKNOWN***'};
    &display_city();
}

exit(0);



sub display_city {
    printf "%6d  %s", $cityval, $c2;

    $cnt = 0;
    %z = ();
    foreach (split(/\001/, $zipbycity{$c}))
    {
	$cnt++;
	if (defined $z{$zips{$_}}) {
	    $z{$zips{$_}} .= "," . $_;
	} else {
	    $z{$zips{$_}} = $_;
	}
    }

    if ($cnt == 1)
    {
	print '  ', $zipbycity{$c}, "\n";
    }
    else
    {
	print "\n";
	foreach (sort {$b <=> $a} keys %z) {
	    @z=split(/,/, $z{$_});
	    foreach $z (sort @z) { 
		printf "       %6d - %s\n", $_, $z;
	    }
	}
	print "\n";
    }

    1;
}
