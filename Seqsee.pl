use strict;

#use blib;
use lib 'lib/';

use Config::Std;
use Getopt::Long;

use S;
use SUtil;
use Seqsee;

use Carp;
use Tk::Carp qw{tkdie};
use Smart::Comments;
use List::Util qw(min);
use UNIVERSAL::require;
use Sub::Installer;
use IO::Prompt 0.99.4;
use English qw(-no_match_vars );

use Perl6::Form;
use Sort::Key;
use Memoize;
use Exception::Class;
use Class::Multimethods;
use Log::Log4perl;
use Log::Log4perl::Layout::PatternLayout;
use PerlIO;
use File::Slurp;
use Tk::ROText;
use attributes;

use Tk;
use SGUI;

# variable: $OPTIONS_ref
#    final configuration hash
#
#    This is the result after passing through all the three stages 
#  (config, command line, default)
#
#     This is passed on to initialize several others, and is thus very important
#
#  seed - the random number seed
#  log  - whether logging should be on or off
#  tk   - to tk or not
#  seq  - the sequence seqsee will deal with: an arrayref
#  update_interval - force redisplay after so many steps
#  interactive - for non-tk, this specifies interactivity

my $OPTIONS_ref = $Global::Options_ref =
  Seqsee::_read_config( Seqsee::_read_commandline() );
INITIALIZE();
GET_GOING();    # Potentially "infinite" loop

# method: INITIALIZE
# pulls all the pieces(logging, display etc) in, initializes
#   them
#
#context of call:
#   should get called only once, at the beginning

sub INITIALIZE {

    # Initialize logging
    SLog->init($OPTIONS_ref);

    # Initialize Coderack
    SCoderack->clear();
    SCoderack->init($OPTIONS_ref);

    # Initialize Stream
    SStream->clear();
    SStream->init($OPTIONS_ref);

    # Initialize Workspace
    SWorkspace->clear();
    SWorkspace->init($OPTIONS_ref);

    # XXX(Board-it-up): [2006/10/23] Will need to pull memory in about here
    #    SNode->clear(); SNode->init( $OPTIONS_ref );

    # Initialize display
    init_display($OPTIONS_ref);

    my @seq = @{ $OPTIONS_ref->{seq} };
    my $tk  = $OPTIONS_ref->{tk};
    unless (@seq) {
        SGUI->ask_seq();
    }

}

# method: GET_GOING
#      Goes into an infinite loop: what loop depends upon whether there is interaction, whether or not we are running Tk

sub GET_GOING {

# This should be the last "setup" function: the real work begins here. Don't expect this to ever return.
    my $interactive = $OPTIONS_ref->{interactive};
    if ($interactive) {
        MainLoop();
    }
    else {
        Interaction_continue();
    }
}

# method: Interaction_continue
# Keeps taking steps until done
#
# The word Interaction is a misnomer

sub Interaction_continue {
    return Seqsee::Interaction_step_n(
        {
            n            => $OPTIONS_ref->{max_steps},
            update_after => $OPTIONS_ref->{update_interval},
            max_steps    => $OPTIONS_ref->{max_steps},
        }
    );
}

# method: Interaction_step
# A single step, with update display
#
#    return value:
#      True if program should stop

sub Interaction_step {
    return Seqsee::Interaction_step_n(
        {
            n            => 1,
            update_after => 1,
            max_steps    => $OPTIONS_ref->{max_steps},
        }
    );
}

#method: init_display
# Sets up update_display() as well.

sub init_display {
    SGUI::setup($OPTIONS_ref);
    SGUI::Update();
    my $update_display_sub = sub { SGUI::Update(); };
    my $default_error_handler = sub {
        my ($err) = @_;
        $Tk::Carp::MainWindow = $SGUI::MW;
        my $msg =
          UNIVERSAL::isa( $err, 'Exception::Class' ) ? $err->as_string() : $err;
        if ( $msg !~ m#\S# ) {
            $msg .= "<EMPTY MESSAGE>";
            confess $msg;
        }
        tkdie($msg);
    };
    my $msg_displayer = sub {
        my ($msg, $no_break) = @_;
        my $btn =
          $SGUI::MW->messageBox( -message => $msg, -type => "OkCancel" );
        ## $btn
        $Global::Break_Loop = 1 unless $no_break;
    };
    my $ask_user_extension_displayer = sub {
        my ( $arr_ref, $msg_suffix ) = @_;

        return if Seqsee::already_rejected_by_user($arr_ref);

        my $cnt = scalar(@$arr_ref);
        my $msg =
          ( $cnt == 1 )
          ? "Is the next term @$arr_ref? "
          : "Are the next terms: @$arr_ref?";
        my $mb = $SGUI::MW->Dialog(
            -text    => $msg . $msg_suffix,
            -bitmap  => 'question',
            -title   => 'Seqsee',
            -buttons => [qw/Yes No/],
        );
        my $btn = $mb->Show;

        # $SGUI::MW->messageBox(-message => $msg, -type => "YesNo");
        my $ok = $btn eq "Yes" ? 1 : 0;
        if ($ok) {
            $Global::AtLeastOneUserVerification = 1;
        }
        return $ok;
    };

    "main"->install_sub( { update_display => $update_display_sub } );

    "main"->install_sub( { default_error_handler => $default_error_handler } );
    "main"->install_sub( { message => $msg_displayer } );
    "main"
      ->install_sub( { ask_user_extension => $ask_user_extension_displayer } );
    "main"->install_sub(
        {
            ask_for_more_terms => sub {
                my $window = SGUI::ask_for_more_terms();

                # main::message("Got $window");
                $window->waitWindow();
              }
        }
    );

}
