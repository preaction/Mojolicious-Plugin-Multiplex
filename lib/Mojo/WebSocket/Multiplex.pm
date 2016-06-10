package Mojo::WebSocket::Multiplex;

use Mojo::Base 'Mojo::EventEmitter';

use Scalar::Util ();

has 'tx';

my %map = (
  sub => 'subscribe',
  msg => 'message',
  uns => 'unsubscribe',
);

sub new {
  my ($class, $c) = @_;
  my $tx = $c->tx;
  return undef unless $tx->is_websocket;
  my $self  = $class->SUPER::new(tx => $tx);
  Scalar::Util::weaken $self->{tx};

  $c->on(text => sub {
    my ($c, $bytes) = @_;
    my ($type, $channel, $payload) = split /,/, $bytes, 3;

    my $e = $map{$type};
    $self->emit($e ? $e : (unknown => $type), $channel, $payload);
  });

  $tx->on(finish => sub { shift; $self->emit(finish => @_) });

  return $self;
}

sub send {
  my ($self, $chan, $payload, $cb) = @_;
  return unless my $tx = $self->tx;
  $tx->send("msg,$chan,$payload", $cb ? sub { $self->$cb() } : ());
}

