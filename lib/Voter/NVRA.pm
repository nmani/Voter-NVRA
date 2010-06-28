package Voter::NVRA;

use warnings;
use strict;
use Carp 'croak';
#use File::Temp qw(tempfile tempdir);
use Time::Local qw(timegm);
use Text::MicroTemplate::File;
use File::ShareDir qw(dist_dir);
use XML::Simple;
#use Data::Dumper;

our $VERSION = '0.01';

sub new {

  my ($class, %options) = @_;

  # Preload the templating stuff...
  my $base_dir = dist_dir('Voter-NVRA');
  my $renderer = Text::MicroTemplate::File->new(
				   include_path => [$base_dir . "/templates/"],
				   escape_func=> undef, # Reminder for me to add feature Text::Micro.. later
				  );
  my $prim_meta = XML::Simple->new()->XMLin ($base_dir . '/meta/basic_state_info.xml', 
					     KeyAttr => {State => 'abbrv'}) || 
					       croak 'Couldn\'t find/process .XML meta file!';  
  
  bless {
	 
	 workdir  => delete $options{workdir} || '/tmp/',
	 outdir	  => delete $options{outdir}  || '/tmp/',
	 engine	  => delete $options{engine}  || 
	 (system('which inkscape >/dev/null') == 0 ? 'inkscape' : croak 'No other templating engine found.'),
	 base_dir => $base_dir,
	 renderer => \$renderer,
	 meta	  => \$prim_meta,
	 files    => delete $options{files}   || {template_cover => 'vtreg_cover.svg',
						  template_form  => 'vtreg_form.svg',
						  cover_vars     => 'vars_cover.svg',
						  template_vars  => 'vars.svg'},
	}, $class;
  
}

sub _age {
  
  # I don't care enough about accuracy to use Data::Calc so shutup.
  my ($birth_month, $birth_day, $birth_year) = split('/', shift); 
  my ($elec_month, $elec_day, $elec_year) = split('/',shift);

  --$birth_month; --$elec_month; # Since 0 is Jan.

  my $bday_time = timegm(0,0,0,$birth_day,$birth_month,$birth_year);
  my $elec_time = timegm(0,0,0,$elec_day, $elec_month, $elec_year);

  # 31557600 seconds in 365.25 days.
  return int(($elec_time-$bday_time)/31557600);
  
}

sub _ecroak {
  my $reason = shift;
  for my $key ( keys %{$reason}) {
    croak "You did not provide a ${$reason}{$key}: $key"; 
  }

}

sub _comment_wrap {
  my $taco = shift;
  return '' if (!defined $taco);
  return '-->' . $taco . '<!--';
}

sub _rand_str
{
  # Thanks Guy Malachi of http://guymal.com
	my $len_str=shift; 
       
	my @chars=('a'..'z','A'..'Z','0'..'9','_');
	my $random_string;
	foreach (1..$len_str) 
	{
		$random_string.=$chars[rand @chars];
	}
	
	return $random_string;
}

sub _process_file {
  my ($c_render, $filler, $files, $out_info) = @_;
  
  my %type;

  if (defined $filler->{fname}) {
    %type = (
	     vars     => $files->{template_vars},
	     template => $files->{template_form},
	     offset   => 0,);
    
  } elsif (defined $filler->{addr_line1}) {
    %type = (
	     vars     => $files->{cover_vars},
	     template => $files->{template_cover},
	     offset   => 1);
    
  } else { 
    warn 'Shit went wrong...';
    return undef;
    
  }

  my $vars = $c_render->render_file($type{vars}, $filler)->as_string;

  # Move below out of new() later? 
  open(TEMPLATE, "<$out_info->{base_dir}/$type{template}") || croak "$out_info->{base_dir}/$type{template}";
  my @template = <TEMPLATE>;
  close TEMPLATE;
  #----

  splice @template, $#template - $type{offset}, 0, $vars;

  if (defined $out_info->{filename}) {
    open(FB, ">", $out_info->{workdir} . $out_info->{filename} . '.svg');
    print FB @template;
    close(FB); 
  }

}

sub _engine {
  my ($engine, $in_file, $out_file) = @_;

  if ($engine eq 'svg2pdf') {
    if ((system('svg2pdf', $in_file, $out_file)) == -1) {
      croak 'svg2pdf has failed to process the file...';
    }

  } elsif ($engine eq 'inkscape') {
    if (system('inkscape', '-A', $out_file, $in_file) == -1) {
      croak 'Inkscape failed to process the file...';
    }
  } else {
    croak 'Cannot figure out which rendering engine you want...';
  }
}

sub _inkfork_states {
  my ($engine, $dir) = shift || croak 'No directory provided';

  opendir(STATES, $dir);
  my @files = grep(/\.svg$/,readdir(STATES));
  closedir(STATES);

  # Increase sleep for slower computers
  foreach my $file (@files) {
    sleep 1;
    my $pid = fork();
    $file =~ s/\.svg$//;
    if ($pid == -1) {
      croak 'Was not able to fork';
    } elsif ($pid == 0) {      
      _engine($engine, $dir . $file . '.svg', $dir . $file . '.pdf');
      exit 0;
    }
  }

  while (wait() != -1) {} # No child left behind... :)
  map { unlink ($dir . $_ . '.svg')  } @files;

}

sub process {
  my ($self, %param) = @_;

  my @curr_time = (localtime(time))[3..5];
  my $filename = _rand_str(50);
    
    if (defined $param{full_name}) {
      delete $param{full_name};
    }
    
    # Parse out DOB. 
    if (defined $param{DOB}) {
      if ( $param{DOB} =~ m/^(0[1-9]|1[012]|[1-9])[-|\/.](0[1-9]|[12][0-9]|3[01]|[1-9])[-|\/.](((19|20)\d{2}$)|(\d{2}$))/) {
	
	# include one for Jan/10/2003 and ect. later?
	$param{DOB_month} = $1;
	$param{DOB_day} = $2;
	$param{DOB_year} = $3;
	
	# } elsif ($param{DOB} =~ m/(((19|20)\d{2}$)|(\d{2}$))[-|\/.](0[1-9]|1[012]|[1-9])[-|\/.](0[1-9]|[12][0-9]|3[01]|[1-9])/) {
	
	#   # Military/FAA time yyyy-mm-dd
	#   $param{DOB_month} = $2;
	#   $param{DOB_day} = $3;
	#   $param{DOB_year} = $1;
	
      } else {
	croak  'Failed to parse out DOB! Re-check format';
      }
      
      delete $param{DOB}; 
    }
    
    #  Attack of the hashes
    my $template_hash = {
			 outfile      => delete $param{outfile} || $filename,
			 cover	      => delete $param{cover} || 1,
			 
			 prefix	      => delete $param{prefix},
			 fname	      => delete $param{fname} || _ecroak({fname  => 'first name'}),
			 lname	      => delete $param{lname} || _ecroak({lname  => 'last name'}), 
			 mname	      => delete $param{mname},
			 suffix	      => delete $param{suffix},
			 home_addr    => delete $param{home_addr} || _ecroak({home_addr  => 'home street address'}),
			 apt_num      => delete $param{apt_num},
			 home_city    => delete $param{home_city} || _ecroak({home_city  => 'home city'}),
			 home_st      => delete $param{home_st} || _ecroak({home_st  => 'home state'}),
			 home_zip     => delete $param{home_zip} || _ecroak({home_zip  => 'home zip'}),
			 mail_addr    => delete $param{mail_addr},
			 mail_city    => delete $param{mail_city},
			 mail_st      => delete $param{mail_st},
			 mail_zip     => delete $param{mail_zip},
			 DOB_month    => delete $param{DOB_month} || _ecroak({DOB_month  => 'month for date of birth'}),
			 DOB_day      => delete $param{DOB_day} || _ecroak({DOB_day  => 'day for date of birth'}),
			 DOB_year     => (length($param{DOB_year}) == 4) ? substr($param{DOB_year},2,2) : delete $param{DOB_year} || _ecroak({DOB_year  => 'year for date of birth'}),
			 phone_num    => delete $param{phone_num},
			 race_ethnic  => delete $param{race_ethnic},
			 party	      => delete $param{party},
			 id_num	      => delete $param{id_num} || _ecroak({id_num  => 'identification number'}),	,
			 curr_day     => delete $param{curr_day} || $curr_time[0],
			 curr_month   => delete $param{curr_month} || $curr_time[1],
			 curr_year => delete $param{curr_year} || 1900 + $curr_time[2],
			 
			 change_prefix => delete $param{change_prefix},
			 change_lname  => delete $param{change_lname},
			 change_fname  => delete $param{change_fname},
			 change_mname  => delete $param{change_mname},
			 change_suffix => delete $param{change_suffix},
			 prev_addr     => delete $param{prev_addr},
			 prev_apt_num  => delete $param{prev_apt_num},
			 prev_city     => delete $param{prev_city},
			 prev_state    => delete $param{prev_state},
			 prev_zip      => delete $param{prev_zip},
			 app_helper    => delete $param{app_helper},
			 
			};
    
    # Starting the real work
    (-d $self->{workdir}) ? (mkdir "$self->{workdir}vtreg_tmp/" || croak 'Unable to create processing directory. Permissions?') : croak "$self->{workdir} doesn't exist or don't have permission to access";
    
    unless (-d $self->{workdir} . 'vtreg_tmp/states/') {
      mkdir($self->{workdir} . 'vtreg_tmp/states/');
 
      
    # Preprocess state info files during first process... Build now so you don't have to later
      foreach my $state (keys %{${$self->{meta}}->{State}}) {
	my %cover_hash;
	
	foreach my $num_line (0..$#{${$self->{meta}}->{State}->{$state}->{Addr_Line}}) {
        $cover_hash{"addr_line" . ($num_line + 1)} = 
	  ${${$self->{meta}}->{State}->{$state}->{Addr_Line}}[$num_line];
      }
	
      _process_file(${$self->{renderer}}, \%cover_hash, $self->{files}, {workdir => $self->{workdir} . 'vtreg_tmp/states/',
									filename => $state, base_dir => $self->{base_dir} . '/templates/'});
	undef %cover_hash;
      }
      _inkfork_states($self->{engine}, $self->{workdir} . 'vtreg_tmp/states/');
    } else { 
      
    }
  
  _process_file(${$self->{renderer}}, $template_hash, $self->{files}, {workdir => $self->{workdir} . 'vtreg_tmp/' ,								     filename => $template_hash->{outfile}, base_dir => $self->{base_dir} . '/templates/'});
  

  _engine($self->{engine}, "$self->{workdir}vtreg_tmp/" . $filename . '.svg', "$self->{workdir}vtreg_tmp/" . $filename . '.pdf');
  #unlink ("$self->{workdir}vtreg_tmp/$filename.svg");

  my @combine_pdf = qw(gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite);
  push (@combine_pdf, "-sOutputFile=$self->{outdir}$filename". '_final.pdf', 
	"$self->{workdir}vtreg_tmp/$filename.pdf",
	"$self->{workdir}vtreg_tmp/states/" . "$template_hash->{home_st}.pdf");

  $ENV{'TEMP'} = '/tmp/'; # Ghostscript requires it if files are too big... w/e
  if (system(@combine_pdf)) { croak 'Final pdf creation failed'};

  return {file_location => $self->{outdir} . $filename . '_final.pdf', 
	  data => $template_hash};
}

1;

__END__

=head1 NAME

Voter::NVRA - Generate Voter Registration Forms

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

   > use Voter::NVRA;

   # Run with default settings and bare minimums required. 
   > my $foo = Voter::NVRA->new();
   > my $file_loc = $foo->process(fname => 'Homer',
			    lname	=> 'Simpson',
			    home_addr	=> '55 Evergreen Terrance',
			    home_city	=> 'Springfield',
			    home_st	=> 'IL', # yah yah..
			    home_zip	=> '90701', # There are actually two/three
			    DOB_month	=> '3',
			    DOB_day	=> '11',
			    DOB_year	=> '56',
			    id_num	=> '568-47-0008'));
   > print $file_loc->{file_location};

=head1 DESCRIPTION

*NOTE: UNSTABLE VERSION WITH NO VALIDATIONS... DO NOT USE IN PRODUCTION YET*

The National Voter Rights Act of 1993 created 'The National Mail Voter Registration Form' 
which is one standard form for voters to register to vote and update voter registration
information. Several states do not accept this form or require more info. Please
consult: http://www.eac.gov

=head1 DEPENDENCIES

VERY IMPORTANT:

Step 1: ImageMagick:
>Ubuntu/Debian: sudo apt-get install imagemagick;
>CentOS/RHEL: sudo yum install ImageMagick; #ImageMagick is case sensitive for w/e reason

It should install GhostScript as dependency. Otherwise:
Ubuntu/Debian: sudo apt-get install gs;
CentOS/RHEL: sudo yum install ghostscript;

Step 2: Install a engine (svg2pdf is HIGHLY RECOMMENDED FOR SPEED but requires setup)

>Using Inkscape (minimum 9MB RAM used per process):
>Ubuntu/Debian: sudo apt-get install inkscape;
>CentOS/RHEL: sudo yum install inkscape;

>OR

>Using svg2pdf (minimum 12Kb RAM used per process):

>Libraries needed to compile:
>Get librsvg DEVELOPMENT FIRST =>
>Ubuntu/Debian: sudo apt-get install librsvg2-dev;
>CentOS/RHEL: sudo yum install librsvg2-devel;

>Note: This should install the cairo and libxml2 dependencies.
>Otherwise find'em yourself... =)

Get svg2pdf =>

git clone git://people.freedesktop.org/~cworth/svg2pdf
git pull
cd svg2pdf
make
mv svg2pdf /usr/local/bin/. #OR 'ln -s' if you want a symbolic link

Step 3: Perl Modules (installed during './Build' but might as well do it now):
GET cpanminus(http://github.com/miyagawa/cpanminus):
> sudo cpanm Text::MicroTemplate::File File::ShareDir Time::Local

=head1 INSTALLATION

"So simple a caveman can do it..."

perl Build.PL
./Build
./Build test
sudo ./Build install

=head1 API

"But I use PHP / Python / Ruby (the Autotune of scripting languages), how do I use this?"
"You don't. Go home and cry."

You can access the server using a build in server

=head1 AUTHOR
Naveen Manivannan, C<< <naveen.manivannan at gmail.com> >>

=head1 BUGS

Submit bugs through github and please consider forking. 

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Voter::NVRA

=head1 CONTRIBUTORS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Naveen Manivannan.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this program; if not, write to the Free
Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
02111-1307 USA.


=cut
