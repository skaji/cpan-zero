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
require Getopt::Long;

our $VERSION = "0.01";

sub new { bless { default_mirror => "http://www.cpan.org" }, shift }

sub parse_options {
    my ($self, @argv) = @_;
    local @ARGV = @argv;
    my $parser = Getopt::Long::Parser->new(
        config => [ "no_auto_abbrev", "no_ignore_case", "pass_through" ],
    );
    $parser->getoptions(
        "h|help" => sub { pod2usage },
        "d|debug" => \$self->{debug},
        "default-mirror=s" => \$self->{default_mirror},
    ) or podusage(1);
    $self->{argv} = \@ARGV;
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
        "--mirror" => $self->{default_mirror},
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
            $git = "$git\@$option->{ref}" if $option->{ref};
            push @need_inject, { module => $module, from => $git };
        } elsif (my $dist = $option->{dist}) {
            # which dist support? read OrePAN2::Injector :-)
            push @need_inject, { module => $module, from => $dist };
        }
    }
    return unless @need_inject;

    $self->debug("building local repository $directory");
    my $injector = OrePAN2::Injector->new(directory => $directory);
    for my $module (@need_inject) {
        $self->debug("injecting $module->{module} from $module->{from}");
        my $merged = capture_merged { $injector->inject($module->{from}) };
    }
    my $indexer = OrePAN2::Indexer->new(directory => $directory);
    $self->debug("indexing $directory");
    my $merged = capture_merged { $indexer->make_index };
}

1;
__END__

=encoding utf-8

=head1 NAME

App::cpan::zero - cpanm or carton helper for dependencies not in cpan

=head1 SYNOPSIS

    $ cat cpanfile
    requires 'Test::PackageName',
        git => 'git://github.com/shoichikaji/Test-PackageName.git', ref => "master";
    requires 'My::Module',
        dist => 'http://darkpan.example.com/My-Module-0.01.tar.gz';

    $ cpan-zero cpanm -nq -Llocal --installdeps .
    # or
    $ cpan-zero carton install

=head1 DESCRIPTION

App::cpan::zero helps cpanm or carton when dependencies are not in cpan.

I'm looking forward to cpanm and carton's native dist/git support.

=head1 HOW IT WORKS

=over 4

=item * find dependencies which are on git repositories in C<cpanfile>

=item * inject them to local mirror and make index by L<OrePAN2>

=item * execute cpanm or carton with C<--mirror local-mirror>

=back

=head1 SEE ALSO

L<https://speakerdeck.com/miyagawa/whats-new-in-carton-and-cpanm-at-yapc-asia-2013>

L<App::cpanminus>

L<Carton>

L<OrePAN2>

L<cpanfile>

=head1 LICENSE

Copyright (C) Shoichi Kaji.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Shoichi Kaji E<lt>skaji@cpan.orgE<gt>

=cut

