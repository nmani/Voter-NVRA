#!/usr/bin/env perl

use strict;
use Test::More;
use Test::Exception;
use Data::Dumper;

use blib;
use Voter::NVRA;

plan tests => 27;


{
  ok(my $test = Voter::NVRA->new(workdir =>'/var/', engine => 'svg2pdf', 
				 files => {template_cover => 'test1.svg',
					   template_form  => 'test2.svg',
					   cover_vars	  => 'test3.svg',
					   template_vars  => 'test4.svg'}), 
     'Testing Custom Options for new() w/ bad option');

  is($test->{engine},			'svg2pdf');
  is($test->{workdir},			'/var/');
  is($test->{files}->{template_cover},	'test1.svg'); 
  is($test->{files}->{template_form},	'test2.svg'); 
  is($test->{files}->{cover_vars},	'test3.svg'); 
  is($test->{files}->{template_vars},	'test4.svg'); 
}


{
  ok(my $test = Voter::NVRA->new(),	'Testing Defaults for new()');
  is($test->{workdir},			'/tmp/');
  is($test->{files}->{template_cover},	'vtreg_cover.svg'); 
  is($test->{files}->{template_form},	'vtreg_form.svg'); 
  is($test->{files}->{cover_vars},	'vars_cover.svg'); 
  is($test->{files}->{template_vars},	'vars.svg');
}


{
  # Base minimum
  ok(my $process_test =  Voter::NVRA->new(),	'Testing process()');
  ok($process_test->process(fname     => 'Homer',
			    lname     => 'Simpson',
			    home_addr => '55 Evergreen Terrance',
			    home_city => 'Springfield',
			    home_st   => 'IL', # yah yah..
			    home_zip  => '90701', # Principal Charming episode
			    DOB_month => '3',
			    DOB_day   => '11',
			    DOB_year  => '56',
			    id_num    => '568-47-0008'));
}


{
  # DOB Parsing
  ok(my $test = Voter::NVRA->new(), 'Testing DOB');
  ok(my $hehe = $test->process(prefix => 'Mr.',
			       fname     => 'Homer',
			       lname     => 'Simpson',
			       suffix => 'II',
			       home_addr => '55 Evergreen Terrance',
			       home_city => 'Springfield',
			       home_st   => 'IL',# yah yah..
			       home_zip  => '90701', # Principal Charming episode
			       DOB  => '11/10/1986',
			       id_num    => '568-47-0008',
			      ));
 is($hehe->{data}->{DOB_year}, 86);
 is($hehe->{data}->{DOB_month}, 11);
 is($hehe->{data}->{DOB_day}, 10);
}

{
  ok(my $test = Voter::NVRA->new( engine => 'svg2pdf'), 'Testing DOB again and Different Engine');
  ok(my $hehe = $test->process(fname     => 'Homer',
			       lname     => 'Simpson',
			       home_addr => '55 Evergreen Terrance',
			       home_city => 'Springfield',
			       home_st   => 'IL', # yah yah..
			       home_zip  => '90701', # Principal Charming episode
			       DOB  => '1/3/86',
			       id_num    => '568-47-0008',
			      ));
  is($hehe->{data}->{DOB_year}, 86);
  is($hehe->{data}->{DOB_month}, 1);
  is($hehe->{data}->{DOB_day}, 3);

}

{
  # Everything
  ok(my $process_test =  Voter::NVRA->new());
  ok($process_test->process(prefix => 'Mr.',
			    fname	 => 'Pablo',
			    mname	 => 'Sexy',
			    lname	 => 'Escobar',
			    suffix => 'III',
			    home_addr	 => '313 Reed Street',
			    home_city	 => 'Tuscaloosa',
			    home_st	 => 'AL', 
			    home_zip	 => '35404', # Principal Charming episode
			    apt_num	 => '303',
			    mail_addr	 => '313 Awesome Street',
			    mail_city	 => 'New York City',
			    mail_st	 => 'NY',
			    mail_zip	 => '50550',
			    phone_num	 => '(205)551-1111',
			    race_ethnic	 => 'Hispanic',
			    party	 => 'Communist',
			    change_prefix => 'Mrs.',
			    change_lname => 'Fred',
			    change_mname => 'Sexy',
			    change_fname => 'Thompson',
			    change_suffix=> 'II',
			    prev_addr	 => '111 S. McFarland Banks Road',
			    prev_apt_num => '211',
			    prev_city	 => 'Tuscaloosa',
			    prev_state	 => 'AL',
			    prev_zip	 => '35404',
			    app_helper	 => 'Didls Minivan',
			    DOB_month	 => '3',
			    DOB_day	 => '11',
			    DOB_year	 => '56',
			    id_num	 => '568-47-0008',
			   ));
}
