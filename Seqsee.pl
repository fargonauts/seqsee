use strict;
use blib;

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
use IO::Prompt;
use English qw(-no_match_vars );

# var: %DEFAULTS
# Defaults for configuration
#
# used if not spec'd in config file or on the command line.
my %DEFAULTS 
    = ( seed => int( rand() * 32000 ),
        update_interval => 0, # If default used, carps when interactive 
            );


# variable: $Steps_Finished
#    number of steps taken so far
#
# Should be my!!
our $Steps_Finished = 0;


# variable: $OPTIONS_ref
#    final configuration hash
#     
#    This is the result after passing through all the three stages (config, command line, default)
#     
#     This is passed on to initialize several others, and is thus very important
#     
#  seed - the random number seed
#  log  - whether logging should be on or off
#  tk   - to tk or not
#  seq  - the sequence seqsee will deal with: an arrayref
#  update_interval - force redisplay after so many steps
#  interactive - for non-tk, this specifies interactivity

my $OPTIONS_ref = _read_config_and_commandline();
INITIALIZE();
GET_GOING(); # Potentially "infinite" loop

# method: INITIALIZE
# pulls all the pieces(logging, display etc) in, initializes 
#   them
# 
#context of call: 
#   should get called only once, at the beginning

sub INITIALIZE{ 

    Seqsee->initialize_codefamilies();
    Seqsee->initialize_thoughttypes();

    # Initialize logging
    SLog->init( $OPTIONS_ref );

    # Initialize Coderack
    SCoderack->clear(); SCoderack->init( $OPTIONS_ref );

    # Initialize Stream
    SStream->clear(); SStream->init( $OPTIONS_ref );

    # Initialize Workspace
    SWorkspace->clear(); SWorkspace->init( $OPTIONS_ref );

    SNode->clear(); SNode->init( $OPTIONS_ref );

    # Initialize display
    init_display( $OPTIONS_ref );

    my @seq = @{ $OPTIONS_ref->{seq}};
    my $tk = $OPTIONS_ref->{tk};
    unless (@seq) {
        if ($tk) {
            # confess "Should ask for sequence";
            SGUI->ask_seq();
        } else {
            confess "Sequence must be passed on the command line with --seq";
        }
    }

}



# method: GET_GOING
#      Goes into an infinite loop: what loop depends upon whether there is interaction, whether or not we are running Tk
#
#    details:
#
#        tk - (this implies interactive) Calls MainLoop
#        interactive - Calls TextMainLoop()
#        batch mode - Calls Interaction_continue()
#
#    usage:
#     GET_GOING( $OPTIONS_ref )
#
#    parameter list:
#        $OPTIONS_ref - 
#
#    return value:
#      may never return
#
#    possible exceptions:

sub GET_GOING{
    # This should be the last "setup" function: the real work begins here. Don't expect this to ever return.
    my $tk = $OPTIONS_ref->{tk};
    my $interactive = $OPTIONS_ref->{interactive};
    if ( $interactive ) {
        if ( $tk ) {
            MainLoop();
        } else {
            TextMainLoop();
        }
    } else {
        Interaction_continue();
    }
}



# method: _read_config_and_commandline
# reads in config/commandline/defaults
#
# Reads the configuration (conf/seqsee.conf), updates what it sees using the commandline arguments, sets defaults, and returns the whole thing in a HASH
#
#    return value:
#       The OptionsRef      

sub _read_config_and_commandline{
    my $RETURN_ref = {};
    read_config 'config/seqsee.conf' => my %config;
    my %options;
    GetOptions( \%options,
                "seed=i",
                "log!",
                "tk!",
                "seq=s",
                "update_interval=i",
                "interactive!",
                "max_steps=i",
                    );
    for (qw{seed log tk max_steps 
            interactive update_interval

            UseScheduledThoughtProb ScheduledThoughtVanishProb
            DecayRate
        }) {
        my $val 
            = exists($options{$_})        ? $options{$_} :
              exists($config{seqsee}{$_}) ? $config{seqsee}{$_} :
              exists($DEFAULTS{$_})       ? $DEFAULTS{$_} :
                  confess "Option '$_' not set either on command line, conf file or defauls";
        $RETURN_ref->{$_} = $val;
    }

    $RETURN_ref->{seq} = $options{seq}; # or confess "Sequence not set!";

    # SANITY CHECKING: SEQ
    my $seq = $RETURN_ref->{seq};
    unless ($seq =~ /^[\d\s,]*$/) {
        confess "The option --seq must be a space or comma separated list of integers; I got '$seq' instead";
    }
    for ($seq) { s/^\s*//; s/\s*$//; }
    my @seq = split(/[\s,]+/, $seq);
    $RETURN_ref->{seq} = [ @seq ];

    # SANITY CHECKING: interactive
    if ($RETURN_ref->{tk} and not($RETURN_ref->{interactive})) {
        print "Using Tk forces interactivity! Reading your mind...\n";
        $RETURN_ref->{interactive} = 1;
    }

    # SANITY CHECKING: update_interval
    if ($RETURN_ref->{interactive} 
            and not($RETURN_ref->{update_interval})) {
        confess "Seqsee is being used interactively: absolutely must have the update interval: it cannot use the value $RETURN_ref->{update_interval}";
    }

    return $RETURN_ref;
}


# method: Interaction_continue
# Keeps taking steps until done
#
# The word Interaction is a misnomer

sub Interaction_continue{
    return
        Seqsee::Interaction_step_n
            ( {
                n => $OPTIONS_ref->{max_steps},
                update_after => $OPTIONS_ref->{update_interval},
                max_steps => $OPTIONS_ref->{max_steps},
            });
}



# method: Interaction_step
# A single step, with update display
#
#    return value:
#      True if program should stop

sub Interaction_step{
    return 
        Seqsee::Interaction_step_n( { n => 1,
                              update_after => 1,
                              max_steps => $OPTIONS_ref->{max_steps},
                          });
}


#method: init_display
# Initializes display related attributes, windows(if necessary) etc.
#
# Also pulls in the Tk modules if called for. Sets up update_display() as well.

sub init_display{
    my $tk = $OPTIONS_ref->{tk};

    if ($tk) {
        "Tk"->require();
        "SGUI"->require();
        import Tk;
        SGUI::setup();
        SGUI::Update();
        my $update_display_sub = sub { SGUI::Update(); };
        my $default_error_handler = sub {
            my  ($err) = @_;
            $Tk::Carp::MainWindow = $SGUI::MW;
            tkdie($err);
        };
        my $msg_displayer = sub {
            my ( $msg ) = @_;
            my $btn = $SGUI::MW->messageBox(-message => $msg, -type => "OkCancel");
	    ## $btn
            $::_BREAK_LOOP = 1;
        };
        my $ask_user_extension_displayer = sub {
            my ( $arr_ref ) = @_;

            return if already_rejected_by_user($arr_ref);

            my $cnt = scalar(@$arr_ref);
            my $msg = ($cnt == 1) ? "Is the next term @$arr_ref? " : "Are the next terms: @$arr_ref?";
            my $mb = $SGUI::MW->Dialog(-text    => $msg,
                                       -bitmap  => 'question',
                                       -title   => 'Seqsee',
                                       -buttons => [qw/Yes No/],
                                           );
            my $btn = $mb->Show; 
                # $SGUI::MW->messageBox(-message => $msg, -type => "YesNo");
            my $ok= $btn eq "Yes" ? 1 : 0;
            if ($ok) {
                $main::AtLeastOneUserVerification = 1;
            }
            return $ok;
        };


        "main"->install_sub( {update_display =>
                                  $update_display_sub
                                  });

        "main"->install_sub( {default_error_handler =>
                                  $default_error_handler
                                  });
        "main"->install_sub( { message =>
                                  $msg_displayer
                                  });
        "main"->install_sub( { ask_user_extension =>
                                  $ask_user_extension_displayer
                                  });


    } else {
        my $update_display_sub = sub {
            # print "Updated Tk display! (change me)\n";
        };
        my $default_error_handler = sub {
            confess $_[0];
        }; 
        my $msg_displayer = sub {
            my ( $msg ) = @_;
            print "Message: ", $msg, "\n";
        };
        my $ask_user_extension_displayer = sub {
            my ( $arr_ref ) = @_;

            return if already_rejected_by_user($arr_ref);

            my $cnt = scalar(@$arr_ref);
            my $msg = ($cnt == 1) ? "Is the next term @$arr_ref? " : "Are the next terms: @$arr_ref?";
            return prompt($msg, "-yn");
        };

        "main"->install_sub( {update_display =>
                                  $update_display_sub
                                      });
        "main"->install_sub( { default_error_handler =>
                                $default_error_handler });
        "main"->install_sub( { message =>
                                  $msg_displayer
                                  });
        "main"->install_sub( { ask_user_extension =>
                                  $ask_user_extension_displayer
                                  });

    }
}


#method: TextMainLoop
# Main interaction loop for text mode
#
# Available commands:
#
# 's', 's \d+' - Takes one or the specified number of steps
# 'c' - continue all the way to the end
# 'e' - exit

sub TextMainLoop{
    while (my $line = prompt -require => { "Seqsee[$Steps_Finished] > " =>  qr{\S}},
           "Seqsee[$Steps_Finished] > ") {
        if ($line =~ m/^ \s* s \s* $/xi) {
            Interaction_step( { n => 1,
                                update_after => 1,} );
        } elsif ( $line =~ m/^ \s* s \s* (\d+) \s* $/xi) {
            Seqsee::Interaction_step_n( { n => $1, 
                                update_after=> $OPTIONS_ref->{update_interval},
                                  max_steps => $OPTIONS_ref->{max_steps},                            } );
        } elsif ( $line =~ m/^ \s* c \s* $/ix) {
            Interaction_continue();
        } elsif ($line =~ m/^ \s* e \s* $/ix) {
            if (prompt "Really quit? ", "-yn") {
                return;
            }
        } elsif ($line =~ m/^ \s* d \s* (\S+) \s* $/ix) {
            _display($1);
        } else {
            chomp($line);
            print "Unknown command '$line': should be s, s n, c or e\n";
            print "It can also be d followed by one of w, s or c\n";
        }
    }
}


# method: do_background_activity
# Don't know what this'll do
#

sub do_background_activity{
    SCoderack->add_codelet( SCodelet->new( "Reader",
                                           50, {}
                                               ));

}



# method: _display
# displays the object
#
#    Argument says what to display:
#    * w is workspace
#    * s is stream
#    * c is coderack
sub _display{
    my ( $what ) = @_;
    if ($what eq "w") {
        SWorkspace->display_as_text;
    } elsif ($what eq "s") {
        SStream->display_as_text;
    } elsif ($what eq "c") {
        SCoderack->display_as_text;
    } else {
        print "#"x10, "\n", "Error: the second argument to display must be one of 'w', 's' or 'c'";
    }
}

sub already_rejected_by_user{
    my ( $aref ) = @_;
    my @a = @$aref;
    my $cnt = scalar @a;
    for my $i (0..$cnt-1) {
        my $substr = join(", ", @a[0..$i] );
        ## Chekin for user rejection: $substr
        return 1 if $::EXTENSION_REJECTED_BY_USER{$substr};
    }
    return 0;
}
