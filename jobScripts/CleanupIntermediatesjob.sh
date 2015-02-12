FILEREMOVALARRAY=${@}

for file in ${FILEREMOVALARRAY[@]}
do
	echo "rm -f ${file}"
	rm -f ${file}
done


