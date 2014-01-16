package Plack::Middleware::ESI::JSON;
use strict;
use warnings;
use parent qw(Plack::Middleware);
use JSON qw(encode_json decode_json);
use Plack::Request;
use Plack::Util;
use Plack::Util::Accessor qw(depth);

# ABSTRACT: JSON Edge Side Include Middleware

sub prepare_app {
    my ($self) = @_;
    $self->depth(1) unless $self->depth;
}

sub call {
    my($self, $env) = @_;

    # Build Plack::Request
    my $req = Plack::Request->new($env);

    my $res = $self->app->($env);
    Plack::Util::response_cb($res, sub {
        my ($res) = @_;
        
        # Don't do anything if we arent application/json data
        return $res if $res->content_type ne 'application/json';

        my $json_res = eval { decode_json $res->body };
        # If we failed to decode json, return $res as-is
        return $res if $@

        $self->_traverse_json($json_res);
        my $new_json_res = eval { encode_json $json_res };
        # If we failed to encode json, return $res as-is
        return $res if $@;

        # Update the body, and return the new res
        $res->body($new_json_res);
        return $res;
    });
}

sub _traverse_json {
    my ($self, $json, $depth) = @_;
    $depth ||= 0;

    # We don't wanna go too deep!
    return $json if $depth > $self->depth;

    for my $key ( keys %$json ) {
        # If we get a sub-hash, traverse down more
        $self->_traverse_json($json->{$key}, $depth + 1) if ref $key eq 'HASH';
        next unless $key =~ /^__include/;
        $self->_process_include($json, delete $json->{$key});
    }

    return $json;
}

sub _process_include {
    my ($self, $json, $include) = @_;
    # Parse $include object
    
    # Make request to find replacement sub-object

    # Return success or failure
    return 1;
}

1;


=head1 SYNOPSIS

    use Plack::Builder;
    use Plack::Middleware::ESI::JSON;

    my $app = sub { ... } # as usual

    builder {
        enable "Plack::Middleware::ESI::JSON";
        $app;
    };
