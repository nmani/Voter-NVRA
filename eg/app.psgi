#!/usr/bin/env perl

use Dancer;
use Data::Dumper;
use File::Slurp;

use blib;
use Voter::NVRA;

set apphandler => 'PSGI';
set serializer => 'JSON';
set show_errors => 1;
set warnings => 1;

my $test = Voter::NVRA->new();

get '/' => sub {

  send_file('/voter.html');  
  
};

get '/download/*.*' => sub {
  
  my ($file, $ext) = splat;
  content_type 'application/pdf';
  return read_file ($test->{outdir} . $file . '_final.pdf', binmode => ':raw');; 

};

post '/new_form' => sub {

  my $blah = $test->process(params);
  return {status => 'OK', filename => $blah->{data}->{outfile} . '.pdf'};

};

my $handler = sub {
  my $env = shift;
  my $request = Dancer::Request->new($env);
  Dancer->dance($request);
  
}
