#!/usr/bin/perl
#while(<STDIN>){if($l++){s/(.{$b})(.$r)(.*)/"\$1.$s\$3"/ee;print}else{$b=index$_,"*";$r=index$_,"\$",$b-$b;$r=$r>0?"{$r}":'*';$s='$2.'x$ARGV[0]}}
while(<STDIN>){if($l++){print join(substr$_,0,$r),substr($_,$r,$e-$r)x$ARGV[0],substr$_,$e}else{$r=index$_,"*";$e=index$_,"\$",$r}}
