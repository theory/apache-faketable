#!perl -w

use strict;
use Test::More tests => 27;

BEGIN { use_ok('Apache::FakeTable') }

# Create a table object.
ok( my $table = Apache::FakeTable->new, "Create new FakeTable" );

# Test direct hash access.
ok( $table->{Location} = 'foo', "Assing to Location" );
is( $table->{Location}, 'foo', "Location if 'foo'" );

# Test case-insensitivity.
is( $table->{location}, 'foo', "location if 'foo'" );
is( delete $table->{Location}, 'foo', "Delete location" );

# Test add().
ok( $table->{Hey} = 1, "Set 'Hey' to 1" );
ok( $table->add('Hey', 2), "Add another value to 'Hey'" );

# Fetch both values at once.
is_deeply( [$table->get('Hey')], [1,2], "Get array for 'Hey'" );
is( scalar $table->get('Hey'), 1, "Get first 'Hey' value only" );
is( $table->{Hey}, 1, "Get first 'Hey' value via direct hash access" );

# Try do(). The code ref should be executed twice, once for each value
# in the 'Hey' array reference.
my $i;
$table->do( sub {
    my ($k, $v) = @_;
    is( $k, 'Hey', "Check key in 'do'" );
    is( $v, ++$i, "Check value in 'do'" );
});

# Try short-circutiting do(). The code ref should be executed only once,
# because it returns a false value.
$table->do( sub {
    my ($k, $v) = @_;
    is( $k, 'Hey', "Check key in short 'do'" );
    is( $v, 1, "Check value in short 'do'" );
    return;
});

# Test set() and get().
ok( $table->set('Hey', 'bar'), "Set 'Hey' to 'bar'" );
is( $table->{Hey}, 'bar', "Get 'Hey'" );
is( $table->get('Hey'), 'bar', "Get 'Hey' with get()" );

# Try merge().
ok( $table->merge(Hey => 'you'), "Add 'you' to 'Hey'" );
is( $table->{Hey}, 'bar,you', "Get 'Hey'" );
is( $table->get('Hey'), 'bar,you', "Get 'Hey' with get()" );

# Try unset().
ok( $table->unset('Hey'), "Unset 'Hey'" );
ok( ! exists $table->{Hey}, "Hey doesn't exist" );
is( $table->{Hey}, undef, 'Hey is undef' );

# Try clear().
ok( $table->{Foo} = 'bar', "Add Foo value" );
$table->clear;
ok( ! exists $table->{Foo}, "Hey doesn't exist" );
is( $table->{Foo}, undef, 'Hey is undef' );

__END__
