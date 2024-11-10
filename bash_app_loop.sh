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
echo "================================================="

echo ""

# until - тело выполняется до тех пор, пока условие false
echo "2. Until"
counter=10
until (( counter <= 0 )); do
  echo "Counter value is : ${counter}"
#  counter=$(( counter-1 )) # вариант с присваниванием и использованием Arithmetic expansion
  (( counter-- )) # вариант с декрементом
done
echo "================================================="

echo ""

# for
echo "3. For"

for (( i = 0; i < 5; i++ )); do
  echo "Index value is : ${i}"
done

# перебор массива

echo ""
array=(7 92 81 27 63)

echo "Перебор массива с помощью for"
for (( i = 0; i < "${#array[@]}"; i++ )); do
  echo "Index value is : ${i}. Array value is : ${array[i]}"
done