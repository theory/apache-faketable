package Apache::FakeTable;
use strict;
use vars qw($VERSION);
$VERSION = '0.01';

=head1 NAME

Apache::FakeTable - Pure Perl implementation of the Apache::Table interface.

=head1 SYNOPSIS

  use Apache::FakeTable;

  my $table = Apache::FakeTable->new(@vals);
  $table->set(From => 'david@kineticode.com');

  $table->add(Cookie => 'One Cookie');
  $table->add(Cookie => 'Another Cookie');

  $table->do( sub {
      my ($k, $v) = @_;
      print "$k: $v\n";
  });

=head1 DESCRIPTION

This class emulates the behavior of the L<Apache::Table|Apache::Table> class.

Apache::FakeTable is designed to behave exactly like Apache::Table, and
differs in only one respect. When a given key has multiple values in an
C<Apache::Table> object, one can fetch each of the values for that key using
Perl's C<each> operator:

  while (my ($k, $v) = each %$table) {
      push @cookies, $v if lc $k eq 'set-cookie';
  }

If anyone knows how Apache::Table does this, let us know! In the meantime, use
C<get()> or C<do()> to get at all of the values for a given key (they're much
more efficient, anyway).

=head1 INTERFACE

=head3 new()

  my $table = Apache::FakeTable->new(@values);

Returns a new C<Apache::FakeTable> object. Any parameters passed
to C<new()> will be added to the table as initial values using C<set()>.

=cut

sub new {
    my $class = shift;
    my $self = {};
    tie %{$self}, 'Apache::FakeTableHash';
    %$self = @_ if @_;
    return bless $self, ref $class || $class;
}

=head3 get()

  my $value = $table->get($key);
  my $value = $table->{$key};

Gets the value stored for a given key in the table. If a key has multiple
values, all will be returned when C<get()> is called in an array context, and
only the first value when it is called in a scalar context.

=cut

sub get {
    tied(%{shift()})->get(@_);
}

=head3 set()

  $table->set($key, $value);
  $table->{$key} = $value;

Takes key and value arguments and sets the value for that key. Previous values
for that key will be discarded. The value must be a string, or C<set()> will
turn it into one. A value of C<undef> will have the same behavior as
C<unset()>.

=cut

sub set {
    my ($self, $header, $value) = @_;
    defined $value ? $self->{$header} = $value : delete $self->{$header};
}

=head3 unset()

  $table->unset($key);
  delete $table->{$key};

Takes a single key argument and deletes that key from the table, so that none
of its values will be in the table any longer.

=cut

sub unset {
    my $self = shift;
    delete $self->{shift()};
}

=head3 clear()

  $table->clear;
  %$table = ();

Clears the table of all values.

=cut

sub clear {
    %{shift()} = ();
}

=head3 add()

  $table->add($key, $value);

Adds a new value to the table. If the value did not previously exist under the
given key, it will be created. Otherwise, it will be added as a new value to
the key.

=cut

sub add {
    tied(%{shift()})->add(@_);
}

=head3 merge()

  $table->merge($key, $value);

Merges a new value with an existing value by concatenating the new value onto
the existing. The result is a comma-separated list of all of the values merged
for a given key.

=cut

sub merge {
    my ($self, $key, $value) = @_;
    if (defined $self->{$key}) {
        $self->{$key} .= ',' . $value;
    } else {
        $self->{$key} = "$value";
    }
}

=head3 do()

  $table->do($coderef);

Pass a code reference to this method to have it iterate over all of the
key/value pairs in the table. Keys will multiple values will trigger the
execution of the code reference multiple times for each value. The code
reference should expect two arguments: a key and a value. Iteration terminates
when the code reference returns false, to be sure to have it return a true
value if you wan it to iterate over every value in the table.

=cut

sub do {
    my ($self, $code) = @_;
    while (my ($k, $val) = each %$self) {
        for my $v (ref $val ? @$val : $val) {
            return unless $code->($k => $v);
        }
    }
}

1;

##############################################################################
# This is the implementation of the case-insensitive hash that each table
# object is based on.
package Apache::FakeTableHash;
use strict;

sub TIEHASH {
    my $class = shift;
    return bless {}, ref $class || $class;
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self->{lc $key} = [ $key => ref $value ? "$value" : $value ];
}

sub add {
    my ($self, $key) = (shift, shift);
    return unless defined $_[0];
    # Stringify value.
    my $value = ref $_[0] ? "$_[0]" : $_[0];
    my $ckey = lc $key;
    if (exists $self->{$ckey}) {
        # Add it to the array or create the array.
        if (ref $self->{$ckey}[1]) {
            push @{$self->{$ckey}[1]}, $value;
        } else {
            $self->{$ckey}[1] = [ $self->{$ckey}[1], $value ];
        }
    } else {
        # It's a simple assignment.
        $self->{$ckey} = [ $key => $value ];
    }
}

sub DELETE {
    my ($self, $key) = @_;
    my $ret = delete $self->{lc $key};
    return $ret->[1];
}

sub FETCH {
    my ($self, $key) = @_;
    # Grab the values first so that we don't autovivicate the key.
    my $val = $self->{lc $key} or return;
    if (my $ref = ref $val->[1]) {
        return unless $val->[1][0];
        # Return the first value only.
        return $val->[1][0];
    }
    return $val->[1];
}

sub get {
    my ($self, $key) = @_;
    my $ckey = lc $key;
    # Prevent autovivication.
    return unless exists $self->{$ckey};
    return $self->{$ckey}[1] unless ref $self->{$ckey}[1];
    return wantarray ? @{$self->{$ckey}[1]} : $self->{$ckey}[1][0];
}

sub CLEAR {
    %{shift()} = ();
}

sub EXISTS {
    my ($self, $key)= @_;
    return exists $self->{lc $key};
}

sub FIRSTKEY {
    my $self = shift;
    # Reset perl's iterator.
    keys %$self;
    # Get the first key via perl's iterator.
    my $first_key = each %$self;
    return undef unless defined $first_key;
    return $self->{$first_key}[0];
}

sub NEXTKEY {
    my ($self, $nextkey) = @_;
    # Get the next key via perl's iterator.
    my $next_key = each %$self;
    return undef unless defined $next_key;
    return $self->{$next_key}[0];
}

1;
__END__

=head1 BUGS

Report all bugs via the CPAN Request Tracker at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache-FakeTable>.

=head1 AUTHOR

David Wheeler <david@kineticode.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003, David Wheeler. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut
