#####################################################
#
#    Package: SHistory
#
#####################################################
#####################################################

package SHistory;
use strict;
use Carp;
use Class::Std;
use base qw{};

my %messages_of :ATTR( :get<history>);

$Global::Steps_Finished ||= '';
$Global::CurrentRunnableString ||= '';

sub BUILD{
    my ( $self, $id, $opts ) = @_;
    $messages_of{$id} = [ history_string("created") ];
}

sub history_string{
    my ( $msg ) = @_;
    return "[$Global::Steps_Finished]$Global::CurrentRunnableString\t$msg";
}

sub add_history{
    my ( $self, $msg ) = @_;
    push @{$messages_of{ident $self}}, history_string($msg);
}

1; 


