package WWW::Google::C2DM;

use strict;
use warnings;
use Carp qw(croak);
use HTTP::Request;
use LWP::UserAgent;
use LWP::protocol::https;

use WWW::Google::C2DM::Response;

use 5.008_001;
our $VERSION = '0.01';

our $URL = 'https://android.apis.google.com/c2dm/send';
$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0; # suppress certificate verify failed

sub new {
    my ($class, %args) = @_;
    croak "Usage: $class->new(auth_token => \$auth_token)" unless $args{auth_token};
    $args{ua} ||= LWP::UserAgent->new(agent => __PACKAGE__.' / '.$VERSION);
    bless { %args }, $class;
}

sub send {
    my ($self, %args) = @_;
    croak 'Usage: $self->send(registration_id => $reg_id, collapse_key => $collapse_key)'
        unless $args{registration_id} && $args{collapse_key};

    if (my $data = delete $args{data}) {
        croak 'data parameter must be HASHREF' unless ref $data eq 'HASH';
        map { $args{"data.$_"} = $data->{$_} } keys %$data;
    }

    my $req = HTTP::Request->new(POST => $URL);
    $req->header('Content-Type' => 'application/x-www-form-urlencoded');
    $req->header(Authorization  => 'GoogleLogin auth='.$self->{auth_token});
    $req->content(join '&', map { $_.'='.$args{$_} } keys %args);

    my $http_response = $self->{ua}->request($req);

    my $result;
    if ($http_response->code == 200) {
        my $content = $http_response->content;
        my $params = { map { split '=', $_, 2 } split /\n/, $content };
        if ($params->{Error}) {
            $result = WWW::Google::C2DM::Response->new(
                is_success    => 0,
                error_code    => $params->{Error},
                http_response => $http_response,
            );
        }
        else {
            $result = WWW::Google::C2DM::Response->new(
                is_success    => 1,
                http_response => $http_response,
                params        => $params,
            );
        }
    }
    else {
        $result = WWW::Google::C2DM::Response->new(
            is_success    => 0,
            http_response => $http_response,
        );
    }

    return $result;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

WWW::Google::C2DM -

=head1 SYNOPSIS

  use WWW::Google::C2DM;

=head1 DESCRIPTION

WWW::Google::C2DM is

=head1 AUTHOR

xaicron E<lt>xaicron@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2011 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
