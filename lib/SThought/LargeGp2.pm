ThoughtType LargeGroup( $group ! ) does {
ACTIONS: {
        my $flush_right = $group->IsFlushRight();
        my $flush_left  = $group->IsFlushLeft();

        if ( $flush_right and $flush_left ) {
            THOUGHT AreWeDone, { group => $group };
        }
        elsif ( $flush_right and !$flush_left ) {
            THOUGHT MaybeStartBlemish, { group => $group };
        }
    }
}

ThoughtType MaybeStartBlemish( $group ! ) does {
ACTIONS: {
        my $flush_right = $group->IsFlushRight();
        my $flush_left  = $group->IsFlushLeft();
        if ( !$flush_left ) {
            my $extension = $group->FindExtension( $DIR::LEFT, 0 );
            if ($extension) {
            }
            else {

                # So there *is* a blemish!
                #main::message("Start Blemish?");
                my $underlying_rule = $group->get_underlying_reln()->get_rule();
                my $statecount      = $underlying_rule->get_state_count();
                if ( $statecount == 1 ) {
                    my $reln = $underlying_rule->get_relations()->[0];

                    #main::message("Blemish reln: $reln");
                    if ( $reln->isa("SRelnType::Compound") ) {
                        my $cat = $reln->get_base_category();

                        #main::message($cat->get_name());
                        if ( $cat->get_name() =~ m#^ad_hoc_(.*)#o ) {
                            THOUGHT InterlacedInitialBlemish,
                                {
                                count => $1,
                                group => $group,
                                cat   => $cat,
                                };

                            # XXX(Board-it-up): [2007/04/15] just return useless.
                            # Add to compiler: RETURN that translates to line below..

                            return @actions_ret;
                        }
                    }
                }

                # So: either statecount > 1, or not interlaced.
                if ($flush_right) {
                    THOUGHT ArbitraryInitialBlemish, { group => $group };
                }
            }
        }
    }
}

ThoughtType InterlacedInitialBlemish( $count !, $group !, $cat ! ) does {
ACTIONS: {
        main::message(
            "I realize that there are $count interlaced groups in the sequence, and I have started on the wrong foot. Will shift the big group right one unit, see if that helps!!"
        );
        my @parts = @$group;
        my @subparts = map {@$_} @parts;
        SWorkspace->remove_gp($group);
        SWorkspace->remove_gp($_) for @parts;
        shift(@subparts);
        my @newparts;
        while ( @subparts > $count ) {
            my @new_part;
            for ( 1 .. $count ) {
                push @new_part, shift(@subparts);
            }
            my $newpart = SAnchored->create(@new_part);
            $newpart->describe_as($cat);
            SWorkspace->add_group($newpart) or return;
            main::message("Adding a single group succeded");
            push @newparts, $newpart;
        }
        main::message("Adding all groups succeeded");
        my $new_gp = SAnchored->create(@newparts);
        SWorkspace->add_group($new_gp);
        SThought->create($new_gp)->schedule();
    }
}

ThoughtType ArbitraryInitialBlemish( $group ! ) does {
ACTIONS: {
        SErr::FinishedTestBlemished->throw() if $Global::TestingMode;
        ACTION 100, DescribeSolution, { group => $group };
    }
}

1;
