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

    foreach $x (qw(comment proof status check-date check-status)) {
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
print "# Index\n\n";

print "This index is sorted alphabetically; the main text is sorted by size of each category.\n\n";

foreach $catname (sort keys %tree) {
    my $catprint = &canon($catname);
    print "* [$catprint](#$catname)\n"
}
print "\n";


foreach $catname (sort { (scalar keys %{$tree{$a}}) <=> (scalar keys %{$tree{$b}}) } keys %tree) {
    print "----\n\n";
    my $catprint = &canon($catname);
    print "# $catprint\n\n";
    $catcontents = $tree{$catname};
    foreach $catsortkey (sort keys %{$catcontents}) {
        my $onion = $catcontents->{$catsortkey};
        my @foo = keys(%{$onion});
        print "## $onion->{title}\n\n";
        foreach my $line (@{$onion->{urls}}) {
            print "* $line";
            print " :lock:" if ($line =~ m!https://!);
            print "\n";
        }
        if ($onion->{'check-status'}) {
            print "  * ";
            print "@{$onion->{'check-status'}}";
            if ($onion->{'check-date'}) {
                print " ";
                print "@{$onion->{'check-date'}}";
            }
            print "\n";
        }
        foreach my $line (@{$onion->{proof}}) {
            print "  * $line";
            print " :no_entry_sign: Not HTTPS" if ($line !~ m!https://!);
            print "\n";
        }
        print "\n";
    }
    print "\n";
}
print "----\n\n";
