package Miniqlo::Web;
use Miniqlo::Base;
use Miniqlo::Web::Dispatcher;
use parent qw(Miniqlo Amon2::Web);

sub dispatch {
    return (Miniqlo::Web::Dispatcher->dispatch($_[0]) or die "response is not generated");
}

__PACKAGE__->load_plugin('Web::JSON', {canonical => 1});
__PACKAGE__->add_trigger(
    AFTER_DISPATCH => sub ($c, $res, @) {
        $res->header( 'X-Content-Type-Options' => 'nosniff' );
        $res->header( 'X-Frame-Options' => 'DENY' );
        $res->header( 'Cache-Control' => 'private' );
    },
);

use Plack::Middleware::Static;
sub to_app ($self) {
    Plack::Middleware::Static->wrap(
        $self->SUPER::to_app,
        path => sub { s{^/cron-log/}{} }, root => $self->log_dir . "/",
    );
}

1;