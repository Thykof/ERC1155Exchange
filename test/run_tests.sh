if [ $1 == "cov" ]
then
  npm run coverage
else
  npm run test $2
fi

if [ $? -eq 0 ]
then
  say "passed"
  exit 0
else
  say "failled"
  exit 1
fi
