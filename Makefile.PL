use 5.010000;
use ExtUtils::MakeMaker;

sub MY::postamble {
	return <<'EOF'
PAR_SUFFIX = .elf

par: $(foreach each,$(filter %.pl,$(TO_INST_PM)),$(subst .pl,-$(VERSION)$(PAR_SUFFIX),$(each)))

%-$(VERSION)$(PAR_SUFFIX): %.pl pm_to_blib
	pp -I blib/lib \
		$(foreach mod, \
			$(shell perl -MYAML -e 'print(join(q/ /, sort(keys(%{YAML::LoadFile(q/MYMETA.yml/)->{requires}}))). qq/\n/)') \
				$(shell find lib/ -maxdepth 1 -mindepth 1 -type d -printf '%P '), \
			-M $(mod)::\
		) $< -o $@

EOF
}

WriteMakefile(
    NAME              => 'HTTPSim',
    VERSION_FROM      => 'lib/HTTPSim.pm',
    PREREQ_PM         => {
        Moose                                       => 0,
        Carp                                        => 0,
        Moose::Autobox                              => 0,
        POE                                         => 0,
        MooseX::POE                                 => 0,
        Data::Compare                               => 0,
        Fcntl                                       => 0,
        File::Path                                  => 0,
        File::Slurp                                 => 0,
        IO::Dir                                     => 0,
        IO::File                                    => 0,
        LWP::UserAgent                              => 0,
        POE::Component::Server::SimpleHTTP          => 0,
        Scalar::Util                                => 0,
        Tk                                          => 0,
        YAML                                        => 0,
        Log::Dispatch                               => 0,
        POE::Loop::Tk                               => 0,
        Log::Log4perl                               => 0,
        MooseX::Log::Log4perl                       => 0,
        Log::Dispatch::ToTk                         => 0,
        Log::Dispatch::TkText                       => 0,
        POE::Component::SSLify                      => 0,
        HTTP::Request                               => 0,
        HTTP::Response                              => 0,
        URI                                         => 0,
        DateTime                                    => 0,
        PerlIO::gzip                                => 0,
        Template                                    => 0,
        IO::Socket::SSL                             => 0,
	Pod::Usage                                  => 0,
    },
    ABSTRACT_FROM     => 'lib/HTTPSim.pm',
    AUTHOR            => 'Rika Lena Denia <rika.denia@t-online.de>',
    LICENSE           => 'perl',
);
