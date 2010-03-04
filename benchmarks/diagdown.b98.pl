$n=$ARGV[0];
print "11x\n";
for ($i=1;$i<=$n;++$i) {
	print '  ';
	print ' ' x $i;
	print "z\n"
}
print ' ' x ($n + 3);
print "f\n";
print ' ' x ($n + 4);
print ".\n";
print ' ' x ($n + 5);
print "@\n";
