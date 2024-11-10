#!/bin/bash

# Loops
echo "Loops"
echo ""

# while - тело выполняется до тех пор, пока условие true
echo "1. While"
counter=10
while (( counter > 0 )); do
  echo "Counter value is : ${counter}"
#  counter=$(( counter-1 )) # вариант с присваниванием и использованием Arithmetic expansion
  (( counter-- )) # вариант с декрементом
done