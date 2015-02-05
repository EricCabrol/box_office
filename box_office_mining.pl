#!/usr/bin/perl

 
use LWP::Simple;
use Date::Calc qw(:all);

$max_week = 1;
open OUT,">","box_office.tsv";
open LOG,">","box_office.log";

for ($year = 2002; $year < 2015 ; $year++) {
	for ($month = 1;$month<13;$month++) {
		for ($day=1;$day<32;$day++) {
			
			if (check_date($year,$month,$day)) {
				$wday = Day_of_Week($year,$month,$day);
				if (Day_of_Week_to_Text($wday) eq "Wednesday") {
					@titres=();
					@entrees=();
					@semaines=();
					foreach  ($year,$month,$day) { 
						s/^(\d)$/0$1/; 
					}
					if ($year.$month.$day>20020910) { 			# Les enregistrements commencent le 11/09/2002
						$url = 'http://www.cinemondial.com/visu_bofra.php?rechweek='.$year.$month.$day;
						print LOG "\n",$url,"\n";
						my $content = getstore($url,'titi.txt');
						if (is_success($content)) {print LOG "Ouverture OK\n";}

						open FIC,"<","titi.txt";
						while (<FIC>) {
							if (/<!-- affichage TOP 10 HEBDOMADAIRE -->/) {$traite=1;}
							if (/<!-- BO ANNUEL -->/) {$traite=0;}
							if (($traite) and (/<tr valign='middle'><td class='RANG'>1/)) {
								$line = $_;
							}
						}
						close FIC;
						while ($line =~ m/'TITRE'><b>(.+?)<\/b>/g ) {push (@titres,$1);}
						while ($line =~ m/<td class='COL3'>(.+?)</g) {push (@entrees,$1);}
						while ($line =~ m/<td class="COL2">(.+?)<td class='COL2'>/g) {
							if ($1 eq '<img border="0" src="new.gif" width="40" height="20">') {push (@semaines,1);}
							else {
								push (@semaines,$1);
								if($1>$max_week) {$max_week=$1;}
							}
						}
						foreach (@entrees) {s/ //g}; # Suppression séparateur de milliers

						if (($#titres !=9) or ($#semaines !=9) or ($#entrees !=9) ) {
							print LOG "PB\n";
						}

						for (0..9) {
							$films->{$titres[$_]}->[$semaines[$_]+0]=$entrees[$_]+0;
						}
					}

				} # fin si mercredi
			} # fin si date valide
		}# Fin boucle sur les dates 
	}
}


print OUT "Titre\t",join "\t",(1..$max_week);
print OUT "\n";
for $titre (keys %$films) {
	print OUT $titre,"\t";	
	for (1..$max_week) {
		if (defined($films->{$titre}->[$_])) {
			print OUT $films->{$titre}->[$_],"\t";
		}
		else {print OUT "\t";}
	}
	print OUT "\n";
}
close OUT;
close LOG;
