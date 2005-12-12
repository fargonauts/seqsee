#####################################################
#
#    Package: SCF::Reader
#
# CF: Reader
#
# Options:
#
# How It Works:
#
# Thought/Codelets Scheduled:
#
#####################################################
#   
#####################################################

package SCF::Reader;
use strict;
use Carp;
use Class::Std;
use base qw{};

{
    my ($logger, $is_debug, $is_info);
    BEGIN{ $logger   = Log::Log4perl->get_logger("SCF::Reader"); 
           $is_debug = $logger->is_debug();
           $is_info  = $logger->is_info();
         }
    sub LOGGING_DEBUG() { $is_debug; }
    sub LOGGING_INFO()  { $is_info;  }
}

my $logger = Log::Log4perl->get_logger("SCF::Reader"); 


# method: run
# 
#
sub run{
    my ( $action_object, $opts_ref ) = @_;
        if (LOGGING_INFO()) {
        my $msg = $action_object->generate_log_msg();

        $logger->info( $msg );
    }
    ################################
    ## Code above autogenerated.
    ## Insert Code Below

    my $object = SWorkspace->read_object();
    if (LOGGING_INFO() and $object) {
        my ($l, $r, $s) = ($object->get_left_edge,
                           $object->get_right_edge,
                           $object->get_structure,
                               );
        my $msg = "* Read Object: \t[$l,$r] $s\n";
        $logger->info( $msg );
    }


    if ($object) {
        SThought->create($object)->schedule();
    }

}
1;
