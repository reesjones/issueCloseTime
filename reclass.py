# Matt Martin
# 7/14/16
# re-classify classes for issue lifetimes

import sys, os

'''
Converts the range of the `timeopen` class variable in a dataset from many
(0, 1, 7, 14, etc) to simply before or not before `n` days (0 for closed before n
days, n for closed at or after n days).
argv[1] is the filename of the input dataset
argv[2] is the filename of the output dataset to write to
argv[3] is the `n` threshold to re-classify `timeopen` as
'''
def main(argv):
	inf = open(argv[1],'r')
	outf = open(argv[2],'w')
	targetclass = argv[3]
	outlines = []
	datasection = False
	for line in inf:
		if not datasection:
			if "@data" in line.lower():
				datasection = True
				newline = ["@data\n"]
			elif "@attribute timeopen" in line.lower():
				newline = ["@attribute timeopen {0," + targetclass + "}\n\n"]
			else:
				newline = [line]
		elif line.isspace():
			continue
		else:
			newline = line.split(',')
			if(int(newline[-1].rstrip()) > int(targetclass)):
				newline[-1] = targetclass + "\n"
			else:
				newline[-1] = "0\n"
		outlines.append(",".join(newline))
	for line in outlines:
		for word in line:
			outf.write(word)
	outf.close()
	inf.close()

if __name__ == '__main__':
	main(sys.argv)
