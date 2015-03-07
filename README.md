# NAME

App::cpan::zero - cpanm or carton helper for dependencies not in cpan

# SYNOPSIS

    $ cat cpanfile
    requires 'Test::PackageName',
        git => 'git://github.com/shoichikaji/Test-PackageName.git', ref => "master";
    requires 'My::Module',
        dist => 'http://darkpan.example.com/My-Module-0.01.tar.gz';

    $ cpan-zero cpanm -nq -Llocal --installdeps .
    # or
    $ cpan-zero carton install

# DESCRIPTION

App::cpan::zero helps cpanm or carton when dependencies are not in cpan.

I'm looking forward to cpanm and carton's native dist/git support.

# HOW IT WORKS

- find dependencies which are on git repositories in `cpanfile`
- inject them to local mirror and make index by [OrePAN2](https://metacpan.org/pod/OrePAN2)
- execute cpanm or carton with `--mirror local-mirror`

# SEE ALSO

[https://speakerdeck.com/miyagawa/whats-new-in-carton-and-cpanm-at-yapc-asia-2013](https://speakerdeck.com/miyagawa/whats-new-in-carton-and-cpanm-at-yapc-asia-2013)

[App::cpanminus](https://metacpan.org/pod/App::cpanminus)

[Carton](https://metacpan.org/pod/Carton)

[OrePAN2](https://metacpan.org/pod/OrePAN2)

[cpanfile](https://metacpan.org/pod/cpanfile)

# LICENSE

Copyright (C) Shoichi Kaji.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Shoichi Kaji <skaji@cpan.org>
