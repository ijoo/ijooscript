#!/usr/bin/env perl
use LWP::Simple;
#my $target=$ARGV[0];

$i=1;
while ($i == 1) {
print "Enter Link : ";
my $target= <>;
chomp($target);

my $ua = LWP::UserAgent->new();
   $ua->agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:76.0) Gecko/20100101 Firefox/76.0");
   $ua->timeout(30);
my $askweb = $ua->get($target);
my $content = $askweb->decoded_content;
#print $content;
if ($content =~ /short.ink/) {
   my ($copas) = $content =~ m{<a href="https://short.ink/(.*?)" target="iframe" class="HYDRAX"}gism;
   my ($judul) = $content =~ m{<head><title>LK21 Nonton (.*?)Film dan Series}gism;
   print "TITLE : $judul \n";
   print "SLUG : $copas \n";
   my $cc = "https://api.hydrax.net/a31e01ae9b6afc4d0ce238113ca580e6/copy/$copas";
   my $ua2 = LWP::UserAgent->new();
      $ua2->agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:76.0) Gecko/20100101 Firefox/76.0");
      $ua2->timeout(30);
   my $ask2web = $ua->get($cc);
   my $content2 = $ask2web->decoded_content;
   if ($content2 =~ /true/) {
        my ($okcc) = $content2 =~ m{"slug":"(.*?)"}gism;
        print "LINK : https://pemutar.xyz/?v=$okcc \n\n"
   }
}
#print "Lanjut? [y/n] : ";
#my $lanjut= <>;
#chomp($lanjut);
#if($lanjut =~ /n/){
#       $i=10;
#} elsif($lanjut =~ /y/) {
        $i=1;
#} else {
#       $i=5;
#}
}
