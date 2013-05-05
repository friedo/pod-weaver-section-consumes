package Pod::Weaver::Section::Consumes;

use strict;
use warnings;
use Module::Load;
use lib './lib';    #instead messing with INC

# ABSTRACT: Add a list of roles to your POD.
use Moose;
with 'Pod::Weaver::Role::Section';

use aliased 'Pod::Elemental::Element::Nested';
use aliased 'Pod::Elemental::Element::Pod5::Command';

sub weave_section {
    my ( $self, $doc, $input ) = @_;

    my $filename = $input->{filename};    #full rel path
    return unless $filename =~ m{^lib/};

    # works only if one package pro file
    my $inc_filename = $filename;         #as in %INC's keys
    $inc_filename =~ s{^lib/}{};          # assume modules live under lib
    my $module = $inc_filename;
    $module =~ s{/}{::}g;
    $module =~ s{\.\w+$}{};

    eval { load $inc_filename };
    print "$@" if $@;
    #print map {"$_\n"} sort keys %INC;

    return unless $module->can('meta');
    my @roles = sort
      grep { $_ ne $module }
      map  { $_->name } $self->_get_roles($module);
    return unless @roles;

    my @pod = (
        Command->new(
            {
                command => 'over',
                content => 4
            }
        ),

        (
            map {
                Command->new(
                    {
                        command => 'item',
                        content => "* L<$_>",
                    }
                  ),
            } @roles
        ),

        Command->new(
            {
                command => 'back',
                content => ''
            }
        )
    );

    push @{ $doc->children },
      Nested->new(
        {
            type     => 'command',
            command  => 'head1',
            content  => 'CONSUMES',
            children => \@pod
        }
      );

}

sub _get_roles {
    my ( $self, $module ) = @_;

    my @roles = eval { $module->meta->calculate_all_roles };
    print "Possibly harmless: $@" if $@;
    return @roles;
}

1;

=pod

=head1 SYNOPSIS

In your C<weaver.ini>:

    [Consumes]

=head1 DESCRIPTION

This L<Pod::Weaver> section plugin creates a "CONSUMES" section in your POD
which will contain a list of all the roles consumed by your class. It accomplishes
this by attempting to compile your class and interrogating its metaclass object.

Classes which do not have a C<meta> method will be skipped.



 

