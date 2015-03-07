# NAME

App::cpan::zero - cpanm or carton helper for dependencies on git repositories

# SYNOPSIS

    $ cat cpanfile
    requires 'Test::PackageName', git => 'git://github.com/shoichikaji/Test-PackageName.git@master';

    $ cpan-zero cpanm -nq -Llocal --installdeps .
    # or
    $ cpan-zero carton install

# DESCRIPTION

App::cpan::zero helps cpanm or carton when dependencies are on git repositories.

# HOW IT WORKS

- find dependencies which are on git repositories in `cpanfile`
- inject them to local mirror by [OrePAN2::Injector](https://metacpan.org/pod/OrePAN2::Injector).
- make local index by [OrePAN2::Indexer](https://metacpan.org/pod/OrePAN2::Indexer)
- execute cpanm or carton with `--mirror local-mirror`

# LICENSE

Copyright (C) Shoichi Kaji.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Shoichi Kaji <skaji@cpan.org>
