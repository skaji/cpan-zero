package App::cpan::zero;
use 5.008001;
use strict;
use warnings;
use OrePAN2::Injector;
use OrePAN2::Indexer;
use File::Temp ();
use File::Spec;
use Module::CPANfile;
use Capture::Tiny 'capture_merged';
use Pod::Usage 'pod2usage';
use constant DEBUG => $ENV{PERL_CPAN_ZERO_DEBUG};

our $VERSION = "0.01";

sub new { bless {}, shift }

sub parse_options {
    my ($self, @argv) = @_;
    my @option;
    while (my $try = shift @argv) {
        if ($try =~ /^-/) {
            push @option, $try;
        } else {
            unshift @argv, $try and last;
        }
    }
    for my $option (@option) {
        if ($option =~ /^-h|--help$/) {
            pod2usage;
        } elsif ($option =~ /^-d|--debug$/) {
            $self->{debug} = 1;
        } else {
            warn "Unexpected option $option\n";
            pod2usage(1);
        }
    }
    $self->{argv} = \@argv;
    $self;
}

sub doit {
    my $self = shift;
    my $directory = File::Temp::tempdir(CLEANUP => !$self->{debug});
    $self->prepare_repository($directory);
    my $mirror = "file://$directory";
    local $ENV{PERL_CARTON_MIRROR} = $mirror;
    local $ENV{PERL_CPANM_OPT} = join " ", (
        "--cascade-search",
        "--mirror" => $mirror,
        "--mirror" => "http://www.cpan.org",
    );
    system @{ $self->{argv} };
    $self->debug("NOTE: please remove local mirror $directory");
}

sub debug {
    my $self = shift;
    return unless $self->{debug};
    warn "--> @_\n";
}

sub prepare_repository {
    my ($self, $directory) = @_;
    my $cpanfile = Module::CPANfile->load("cpanfile");
    my @module = $cpanfile->merged_requirements->required_modules;

    my @need_inject;
    for my $module (@module) {
        my $option = $cpanfile->options_for_module($module) || +{};
        if (my $git = $option->{git}) {
            push @need_inject, { module => $module, git => $git };
        }
    }
    return unless @need_inject;

    $self->debug("building local repository $directory");
    my $injector = OrePAN2::Injector->new(directory => $directory);
    for my $module (@need_inject) {
        $self->debug("injecting $module->{module} from $module->{git}");
        my $merged = capture_merged { $injector->inject($module->{git}) };
    }
    my $indexer = OrePAN2::Indexer->new(directory => $directory);
    $self->debug("indexing $directory");
    my $merged = capture_merged { $indexer->make_index };
}

1;
__END__

=encoding utf-8

=head1 NAME

App::cpan::zero - cpanm or carton helper for dependencies on git repositories

=head1 SYNOPSIS

    $ cat cpanfile
    requires 'Test::PackageName', git => 'git://github.com/shoichikaji/Test-PackageName.git@master';

    $ cpan-zero cpanm -nq -Llocal --installdeps .
    # or
    $ cpan-zero carton install

=head1 DESCRIPTION

App::cpan::zero helps cpanm or carton when dependencies are on git repositories.

=head1 HOW IT WORKS

=over 4

=item * find dependencies which are on git repositories in C<cpanfile>

=item * inject them to local mirror by L<OrePAN2::Injector>.

=item * make local index by L<OrePAN2::Indexer>

=item * execute cpanm or carton with C<--mirror local-mirror>

=back

=head1 LICENSE

Copyright (C) Shoichi Kaji.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Shoichi Kaji E<lt>skaji@cpan.orgE<gt>

=cut

