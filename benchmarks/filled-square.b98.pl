$n=$ARGV[0];
$x=$n / 2;
print "v>" x $x; print "v\n";
for ($i=1;$i<=$n-4;++$i) {
	print "v^" x $x;
	print "v\n"
}
print "v^" x $x; print "f\n";
print "v^" x $x; print ".\n";
print ">^" x $x; print "@\n";
