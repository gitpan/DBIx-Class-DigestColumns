package DBIx::Class::DigestColumns;

use strict;
use warnings;

use vars qw($VERSION);
use base qw/DBIx::Class/;
use Digest;

__PACKAGE__->mk_classdata( 'digest_auto_columns' => [] );
__PACKAGE__->mk_classdata( 'digest_auto' => 1 );
__PACKAGE__->mk_classdata( 'digest_maker' );
__PACKAGE__->mk_classdata( 'encoding' );

__PACKAGE__->digest_algorithm('MD5');
__PACKAGE__->digest_encoding('hex');

# Always remember to do all digits for the version even if they're 0
# i.e. first release of 0.XX *must* be 0.XX000. This avoids fBSD ports
# brain damage and presumably various other packaging systems too

$VERSION = '0.01000';

=head1 NAME

DBIx::Class::DigestColumns - Automatic digest columns

=head1 SYNOPSIS

In your L<DBIx::Class> table class:

  __PACKAGE__->load_components(qw/DigestColumns .../);

  __PACKAGE__->digestcolumns(
      columns   => [qw/ password /],
      algorithm => 'MD5',
      encoding  => 'base64',
      auto      => 1,
  );

Alternatively you could call each method individually  

  __PACKAGE__->digest_columns(qw/ password /);
  __PACKAGE__->digest_algorithm('MD5');
  __PACKAGE__->digest_encoding('base64');
  __PACKAGE__->digest_auto(1);

Note that the component needs to be loaded before Core.

=head1 DESCRIPTION

This L<DBIx::Class> component can be used to automatically insert a message
digest of selected columns. By default DigestColumns will use
L<Digest::MD5> to insert a 128-bit hexadecimal message digest of the column
value.

The length of the inserted string will be 32 and it will only contain characters
from this set: '0'..'9' and 'a'..'f'.

If you would like to use a specific digest module to create your message
digest, you can set L</digest_algorithm>:

  __PACKAGE__->digest_algorithm('SHA-1');

=head1 METHODS

=head2 digestcolumns

  __PACKAGE__->digestcolumns(
      columns   => [qw/ password /],
      algorithm => $algorithm',
      encoding  => $encoding,
      auto      => 1,
  );

Calls L</digest_columns>, L</digest_algorithm>, and L</digest_encoding> and L</digest_auto> if the corresponding argument is defined.

=cut

sub digestcolumns {
    my $self = shift;
    my %args = @_;
    
    $self->digest_columns( $args{columns} ) if exists $args{columns};
    $self->digest_algorithm( $args{algorithm} ) if exists $args{algorithm};
    $self->digest_encoding( $args{encoding} ) if exists $args{encoding};
    $self->digest_auto( $args{auto} ) if exists $args{auto};
}

=head2 digest_columns

Takes a list of columns to be convert to a message digest during insert.

  __PACKAGE__->digest_columns(qw/ password /);

=cut

sub digest_columns {
    my $self = shift;
    for (@_) {
        $self->throw_exception("column $_ doesn't exist") unless $self->has_column($_);
    }
    $self->digest_auto_columns(\@_);
}

=head2 digest_algorithm

Takes the name of a digest algorithm to be used to calculate the message digest.

  __PACKAGE__->digest_algorithm('SHA-1');

If a suitible digest module could not be loaded an exception will be thrown.

Supported digest algorithms are:

  MD5
  MD4
  MD2
  SHA-1
  SHA-256
  SHA-384
  SHA-512
  CRC-16
  CRC-32
  CRC-CCITT
  HMAC-SHA-1
  HMAC-MD5
  Whirlpool
  Adler-32

digest_algorithm defaults to C<MD5>.

=cut

sub digest_algorithm {
    my ($self, $class) = @_;

    if ($class) {
        if (!eval { Digest->new($class) }) {
        	$self->throw_exception("$class could not be used as a digest algorithm: $@");       	
        } else {
            $self->digest_maker(Digest->new($class));
        };
    };
    return ref $self->digest_maker;
}

=head2 digest_encoding

Selects the encoding to use for the message digest.

  __PACKAGE__->digest_encoding('base64');

Possilbe encoding schemes are:

  binary
  hex
  base64

digest_encoding defaults to C<hex>.

=cut

sub digest_encoding {
    my ($self, $encoding) = @_;
    if ($encoding) {
    	if ($encoding =~ /^(binary)|(hex)|(base64)$/) {
			$self->encoding($encoding);	
		} else {
			$self->throw_exception("$encoding is not a supported encoding scheme");
		};
	};
	return $self->encoding;
}

sub _get_digest_string {
	my ($self, $value) = @_;
	my $digest_string;
	
	$self->digest_maker->add($value);

	if ($self->encoding eq 'binary') {
		$digest_string = eval { $self->digest_maker->digest };
	
	} elsif ($self->encoding eq 'hex') {
		$digest_string = eval { $self->digest_maker->hexdigest };
	
	} else {
		$digest_string = eval { $self->digest_maker->b64digest }
								|| eval { $self->digest_maker->base64digest };
	};
	
	$self->throw_exception("could not get a digest string: $@") unless defined( $digest_string );
	return $digest_string;
}

=head2 digest_auto

  __PACKAGE__->digest_auto(1);

Turns on and off automatic digest columns.  When on, this feature makes all
UPDATEs and INSERTs automatically insert a message digest of selected columns.

The default is for digest_auto is to be on.

=head1 EXTENDED METHODS

The following L<DBIx::Class::Row> methods are extended by this module:-

=over 4

=item insert

=cut

sub insert {
    my $self = shift;
    if ($self->digest_auto) {
        for my $column (@{$self->digest_auto_columns}) {
            $self->set_column( $column, $self->_get_digest_string($self->get_column( $column )) )
                if defined $self->get_column( $column );
        }
    }
    $self->next::method(@_);
}

=item update

=cut

sub update {
    my $self = shift;
    if ($self->digest_auto) {
		for my $column (@{$self->digest_auto_columns}) {
			$self->set_column( $column, $self->_get_digest_string($self->get_column( $column )) )
				if defined $self->get_column( $column );
		}
	}
    $self->next::method(@_);
}

1;
__END__

=back

=head1 SEE ALSO

L<DBIx::Class>,
L<Digest>

=head1 AUTHOR

Tom Kirkpatrick (tkp) <tkp@cpan.org>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.
