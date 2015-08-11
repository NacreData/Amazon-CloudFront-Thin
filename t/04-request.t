use strict;
use warnings;

package MyAgent;
use Test::More;
sub new { bless {}, shift }
sub request {
    my ($self, $req) = @_;
    isa_ok $self, 'MyAgent';
    isa_ok $req, 'HTTP::Request';
    like $req->content, qr{\Q<?xml version="1.0" encoding="UTF-8"?><InvalidationBatch xmlns="http://cloudfront.amazonaws.com/doc/2015-04-17/"><Paths><Quantity>1</Quantity><Items><Path><![CDATA[/some/path]]></Path></Items></Paths><CallerReference>\E\d+\Q</CallerReference></InvalidationBatch>\E}, 'comparing payload';
    my $headers = $req->headers->as_string;
    like $headers, qr{Date:}, 'headers contain date';
    like $headers, qr{Authorization: AWS 321:AWS4-HMAC-SHA256}, 'headers contain auth';
    like $headers, qr{Host: cloudfront.amazonaws.com}, 'headers contain host';
    like $headers, qr{Content-Length: 265}, 'headers contain content-length';
    like $headers, qr{Content-Type: text/xml}, 'headers contain content-type';
    return 42;
}

package main;
use Test::More;
use Amazon::CloudFront::Thin;

my $cloudfront = Amazon::CloudFront::Thin->new(
    aws_access_key_id     => 123,
    aws_secret_access_key => 321,
    distribution_id       => 1,
    ua                    => MyAgent->new,
);

ok my $res = $cloudfront->create_invalidation('/some/path'), 'create_invalidation returns';
is $res, 42, 'create_invalidation forwards whatever is returned from user agent';

done_testing;
