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

    local $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0; # suppress certificate verify failed
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

WWW::Google::C2DM - Google C2DM Client

=head1 SYNOPSIS

  use WWW::Google::C2DM;
  use WWW::Google::ClientLogin;

  my $auth_token = WWW::Google::ClientLogin->new(...)->authentication->auth_token;
  my $c2dm = WWW::Google::C2DM->new(auth_token => $auth_token);
  my $res  = $c2dm->send(
      registration_id => $registration_id,
      collapse_key    => $collapse_key,
      'data.message'  => $message,
  );
  die $res->error_code if $res->has_error;
  my $id = $res->id;

=head1 DESCRIPTION

WWW::Google::C2DM is HTTP Client for Google C2DM service.

SEE ALSO L<< http://code.google.com/intl/ja/android/c2dm/ >>

=head1 METHODS

=over 4

=item new()

Create a WWW::Google::C2DM instance.

  my $c2dm = WWW::Google::C2DM->new(auth_token => $auth_token);

C<< auth_token >> parameter is required.

=item send()

Send to C2DM. Returned values is L<< WWW::Google::C2DM::Response >> object.

  my $res = $c2dm->send(
      registration_id  => $registration_id,
      collapse_key     => $collapse_key,
      'data.message'   => $message,
      delay_while_idle => $bool,
  );

  say $res->error_code if $res->has_error;

send() arguments are:

=over 4

=item registration_id : Str

Required. The registration ID retrieved from the Android application on the phone.

  registration_id => $registration_id,

=item collapse_key : Str

Required. An arbitrary string that is used to collapse a group of like messages when the device is offline,
so that only the last message gets sent to the client.

  collapse_key => $collapse_key,

=item delay_while_idle : (1|0)

Optional. If included, indicates that the message should not be sent immediately if the device is idle.

=item data.<key> : Str || data : HASHREF

Optional. Payload data, expressed as key-value pairs.

  my $res = $c2dm->send(
      ....
      'data.message' => $message,
      'data.name'    => $name,
  );

Or you can specify C<< data >>. Value is must be HASHREF.

  data => {
      message => $message,
      name    => $name,
  },
  # Equals:
  # 'data.message' => $message,
  # 'data.name'    => $name,

Or you can specify both option.

=back

SEE ALSO L<< http://code.google.com/intl/ja/android/c2dm/#push >>

=back

=head1 AUTHOR

xaicron E<lt>xaicron@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2011 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
