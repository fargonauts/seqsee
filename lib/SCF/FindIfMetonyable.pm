#####################################################
#
#    Package: SCF::FindIfMetonyable
#
# CF: FindIfMetonyable
#
# Options:
# 
# How It Works:
#
# Thought/Codelets Scheduled: 
#####################################################
#   
#####################################################

package SCF::FindIfMetonyable;
use strict;
use Carp;
use Class::Std;

use base qw{};

{
    my ($logger, $is_debug, $is_info);
    BEGIN{ $logger   = Log::Log4perl->get_logger("SCF::FindIfMetonyable"); 
           $is_debug = $logger->is_debug();
           $is_info  = $logger->is_info();
         }
    sub LOGGING_DEBUG() { $is_debug; }
    sub LOGGING_INFO()  { $is_info;  }
}

my $logger = Log::Log4perl->get_logger("SCF::FindIfMetonyable"); 


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
    my $object = $opts_ref->{object} or confess "Need Object";
    my $category = $opts_ref->{category} or confess "Need category";

    my @meto_types = $category->get_meto_types;
    my $meto_type = $meto_types[0]; #XXX
    $object->annotate_with_metonym($category, $meto_type);
    $object->set_metonym_activeness(1);


}
1;
