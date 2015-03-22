GVCFARRAY=${@:1}

for file in ${GVCFARRAY[@]}
do
	echo "rm -f ${file}; rm -f ${file}.idx"
	rm -f ${file}
	rm -f ${file}.idx
done



