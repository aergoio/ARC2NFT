pushd $(dirname $0) # move to the script directory
for file in *.brick # for each brick files
do
  brick "$file" # run brick test
done 
popd