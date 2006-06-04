use strict;
use warnings;
use Test::More;

BEGIN {
    plan eval "require Digest"
        ? ( tests => 5 )
        : ( skip_all => 'needs Digest for testing' );
}

use lib qw(t/lib);

use DigestTest;
my $schema = DigestTest->init_schema;
my $row;


$row = $schema->resultset('Test')->create({ password => 'testvalue' });
is $row->password, 'e9de89b0a5e9ad6efd5e5ab543ec617c', 'got hex MD5 from Digest (default) on insert';

$row->password('testvalue2');
$row->update;
is $row->password, '91c04cd25d9cc5fc44b7e4086e022d4d', 'got hex MD5 from Digest (default) on update';

eval { DigestTest::Schema::Test->digest_encoding('Dummy') };
like $@, qr/is not a supported encoding scheme/, 'Unsupported encoding scheme';

eval { DigestTest::Schema::Test->digest_algorithm('Dummy') };
like $@, qr/could not be used as a digest algorithm/, 'Unsupported algorithm';

DigestTest::Schema::Test->digest_auto(0);
Class::C3->reinitialize();
$row->password('testvalue2');
$row->update;
is $row->password, 'testvalue2', 'digest_auto off';

1;