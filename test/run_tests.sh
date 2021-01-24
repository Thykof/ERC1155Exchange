truffle test

if [ $? -eq 0 ]
then
  say "passed"
  exit 0
else
  say "failled"
  exit 1
fi
