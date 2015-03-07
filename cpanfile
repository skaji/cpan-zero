requires 'perl', '5.008001';
requires 'OrePAN2';
requires 'Module::CPANfile';
requires 'Capture::Tiny';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

