
FILEREMOVALARRAY=${@}

for file in ${FILEREMOVALARRAY[@]}
do
        rm -f ${file}
done

