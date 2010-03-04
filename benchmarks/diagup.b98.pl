$n=$ARGV[0];
print '^';
print ' ' x ($n+2);
print "@\n";
print ' ' x ($n+2);
print ".\n";
print ' ' x ($n+1);
print "f\n";
for ($i=$n;$i>=1;--$i) {
	print ' ' x $i;
	print "z\n"
}
print <<EOF
x
-
1
0
1
EOF
