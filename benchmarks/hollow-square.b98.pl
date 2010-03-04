$n=$ARGV[0];
print '>' x ($n-1);
print "v\n@"; print ' ' x ($n-2);
print "v\n."; print ' ' x ($n-2);
print "v\nf"; print ' ' x ($n-2);
print "v\n";
for ($i = 5; $i < $n; ++$i) {
	print '^';
	print ' ' x ($n-2);
	print "v\n"
}
print '^';
print '<' x ($n-1);
print "\n"
