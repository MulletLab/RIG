GVCFARRAY=${@:1}

for file in ${GVCFARRAY[@]}
do
	rm -f ${file}
	rm -f ${file}.idx
done



