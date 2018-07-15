#!/usr/bin/perl -w
use Data::Dumper;

sub canon {
    my $foo = shift;
    $foo =~ s/-/ /go;
    return join '', map { ucfirst lc } split /(\s+)/, $foo;
}

sub listdir {
    my $d = shift;
    opendir(D, $d) || die "opendir: $d: $!\n";
    my @foo = sort(grep(!/^\./o, readdir(D)));
    closedir(D);
    return @foo;
}

sub first {
    my $f = shift;
    my $line;
    open(F, $f) || die "open: $f: $!\n";
    chomp($line = <F>);
    close(F);
    return $line;
}

sub lines {
    my $f = shift;
    my @results;
    open(F, $f) || die "open: $f: $!\n";
    chomp(@results = <F>);
    close(F);
    return \@results; # REF!
}

sub doonion {
    my ($path, $onion) = @_;
    my $odir = "$path/$onion";
    my %result = ();

    foreach $x (qw(title)) {
        $result{$x} = &first("$odir/$x");
    }

    foreach $x (qw(urls)) {
        $result{$x} = &lines("$odir/$x");
    }

    @optional = qw(
                   comment
                   proof
                   status
                   check-date
                   check-status
                   check-date-1
                   check-status-1
                   check-date-2
                   check-status-2
                   check-date-3
                   check-status-3
                   check-date-4
                   check-status-4
    );

    foreach $x (@optional) {
        $result{$x} = &lines("$odir/$x") if (-f "$odir/$x"); # OPTIONAL
    }

    $result{'sortkey'} = "$result{title}::$onion";
    return \%result;
}

sub docat {
    my ($path, $category) = @_;
    my $catdir = "$path/$category";
    my @onions = &listdir($catdir);
    my %result = ();
    foreach $onion (@onions) {
        my $foo = &doonion($catdir, $onion);
        my $key = $$foo{'sortkey'};
        $result{$key} = $foo;
    }
    return \%result;
}

# load

@categories = &listdir('directory');

foreach $catname (@categories) {
    $tree{$catname} = &docat('directory', $catname);
}

print "\n";
print "----\n\n";

$last_check = &first('directory/.check-date');

print <<"EOF";
# Index

This index is sorted alphabetically; the main text is sorted by size of each category.

Connectivity was last checked at: **$last_check**
EOF

print "\n";
foreach $catname (sort keys %tree) {
    my $catprint = &canon($catname);
    print "* [$catprint](#$catname)\n"
}
print "\n";


foreach $catname (sort {
    ((scalar keys %{$tree{$a}}) <=>
     (scalar keys %{$tree{$b}})) or
     ($a cmp $b)
                  } keys %tree) {
    print "----\n\n";
    my $catprint = &canon($catname);
    print "# $catprint\n\n";
    $catcontents = $tree{$catname};
    foreach $catsortkey (sort { lc($a) cmp lc($b) } keys %{$catcontents}) {
        my $onion = $catcontents->{$catsortkey};
        my @foo = keys(%{$onion});

        print "## $onion->{title}\n\n";

        foreach my $line (@{$onion->{urls}}) {
            print "* $line";
            print " :lock:" if ($line =~ m!https://!);
            print "\n";
        }

        foreach $suffix ('', '-1', '-2', '-3', '-4') {
            $cd = "check-date$suffix";
            $cs = "check-status$suffix";
            if ($onion->{$cd}) {
                print "  * ";
                print "`@{$onion->{$cd}}`";
                if ($onion->{$cs}) {
                    print " ";
                    print "@{$onion->{$cs}}";
                }
                print "\n";
            }
        }

        foreach my $line (@{$onion->{proof}}) {
            print "  * $line";
            print " :no_entry_sign: Not HTTPS" if ($line =~ m!http://!);
            print "\n";
        }

        print "\n";
    }
    print "\n";
}
print "----\n\n";
