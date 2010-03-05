# File created: 2010-03-04 01:36:37
$p=$ARGV[0];
for ($n=0;1<<$n<$p;++$n){}
print "f.";
for ($i=1;$i<=$n;++$i) {
	print ">#vtv\n";
	print ' ' x (4*$i);
	print '> ';
}
print "v\n  @";
print '   z' x ($n - 1);
print "   <\n";
