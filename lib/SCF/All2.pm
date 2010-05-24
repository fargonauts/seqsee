CodeletFamily ConvulseEnd( $object !, $direction ! ) does {
  NAME: { Shake Group Boundries }
INITIAL: {

    }
RUN: {
        unless ( SWorkspace::__CheckLiveness($object) ) {
            return;    # main::message("SCF::ConvulseEnd: " . $object->as_text());
        }
        my $change_at_end_p = ( $direction eq $DIR::RIGHT ) ? 1 : 0;
        my @object_parts = @$object;
        my $ejected_object;
        if ($change_at_end_p) {
            $ejected_object = pop(@object_parts);
        }
        else {
            $ejected_object = shift(@object_parts);
        }

        my $underlying_reln = $object->get_underlying_reln();
        multimethod 'SanityCheck';
        if ($underlying_reln) {
            SanityCheck( $object, $underlying_reln, "Pre-extension" );
        }

        my $new_extension = $object->FindExtension( $direction, 1 ) or return;
        if ( my $unstarred = $new_extension->get_is_a_metonym() ) {
            main::message("new_extension was metonym! fixing...");
            $new_extension = $unstarred;
        }
        if ( $new_extension and $new_extension ne $ejected_object ) {
            if ($underlying_reln) {
                SanityCheck( $object, $underlying_reln, "post-extension" );
            }

            my $structure_string_before_ejection = $object->as_text();
            if ($change_at_end_p) {
                $ejected_object = pop(@$object);
            }
            else {
                $ejected_object = shift(@$object);
            }
            SWorkspace::__RemoveFromSupergroups_of( $ejected_object, $object );
            $object->recalculate_edges();

            #main::message( "New extension! Instead of "
            #      . $ejected_object->as_text()
            #      . " I can use "
            #      . $new_extension->as_text() );
            my $extended = eval { $object->Extend( $new_extension, $change_at_end_p ) };
            if ( my $e = $EVAL_ERROR ) {
                if ( UNIVERSAL::isa( $e, "SErr::CouldNotCreateExtendedGroup" ) ) {
                    print STDERR "(structure before ejection): $structure_string_before_ejection\n";
                    print STDERR "Extending group: ", $object->as_text(), "\n";
                    print STDERR "(But effectively): ", $object->GetEffectiveStructureString();
                    print STDERR "Ejected object: ", $ejected_object->get_structure_string(), "\n";
                    print STDERR "(But effectively): ",
                        $ejected_object->GetEffectiveStructureString();
                    print STDERR "New object: ", $new_extension->get_structure_string(), "\n";
                    print STDERR "(But effectively): ",
                        $new_extension->GetEffectiveStructureString();
                    confess "Unable to extend group!";
                }
                confess $e;
            }
            unless ($extended) {

                # main::message("Failed to extend, and no deaths!");
                if ($change_at_end_p) {
                    push( @$object, $ejected_object );
                }
                else {
                    unshift( @$object, $ejected_object );
                }
                $object->recalculate_edges();
            }
        }

    }
FINAL: {

    }
}

CodeletFamily CheckProgress() does {
  NAME: {Check Progress}
INITIAL: {
        our $last_time_progresschecker_run = 0;
    }
RUN: {
        our $last_time_progresschecker_run;
        my $time_since_last_addn    = $Global::Steps_Finished - $Global::TimeOfNewStructure;
        my $time_since_new_elements = $Global::Steps_Finished - $Global::TimeOfLastNewElement;
        my $time_since_codelet_run  = $Global::Steps_Finished - $last_time_progresschecker_run;

        # Don't run too frequently
        return if $time_since_codelet_run < 100;
        $last_time_progresschecker_run = $Global::Steps_Finished;

        my $desperation = CalculateDesperation( $time_since_last_addn, $time_since_new_elements );

        my $chooser_on_inv_strength = SChoose->create( { map => q{100 - $_->get_strength()} } );
        if ( $desperation > 50 ) {
            main::ask_for_more_terms();
        }
        elsif ( $desperation > 30 ) {

            # XXX(Board-it-up): [2007/02/14] should be biased by 100 - strength?
            # my $gp = SChoose->uniform([SWorkspace::GetGroups()]);
            my $gp = $chooser_on_inv_strength->( [ SWorkspace::GetGroups() ] );
            if ($gp) {

                # main::message("Deleting group $gp: " . $gp->get_structure_string());
                SWorkspace->remove_gp($gp);
            }
        }
        elsif ( $desperation > 10 ) {
            for ( values %SWorkspace::relations ) {
                my $age = $_->GetAge();
                if (    SUtil::toss( ( 100 - $_->get_strength() ) / 200 )
                    and SUtil::toss( $age / 400 ) )
                {
                    $_->uninsert();
                }
            }
        }

    }
FINAL: {
        my @Cutoffs = ( [ 1500, 0, 80 ], [ 800, 2500, 80 ], [ 500, 0, 40 ], [ 200, 0, 20 ], );

        sub CalculateDesperation {
            my ( $time_since_last_addn, $time_since_new_elements ) = @_;
            for (@Cutoffs) {
                my ( $a, $b, $c ) = @$_;
                return $c if ( $time_since_last_addn >= $a
                    and $time_since_new_elements >= $b );
            }
            return 0;
        }
    }
}

