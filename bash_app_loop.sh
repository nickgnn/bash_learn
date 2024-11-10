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
echo "================================================="

echo ""

# fori
echo "4. ForEach"
for val in {1..5} ; do
    echo "For each loop is : ${val}"
done
echo "================================================="

echo ""

echo "Перебор массива с помощью fori"
for val1 in "${array[@]}" ; do
    echo "For each loop is : ${val1}"
done
echo "================================================="

echo ""

# перебор файлов
touch loga logb logc logd logdd

echo "Перебор файлов с помощью fori"
files=(loga logb logc logcc)
for file in "${files[@]}" ; do
    if [[ -f "${file}" ]]; then
        ls -l "${file}"
    else
      echo "File does not exist: ${file}"
    fi
done
echo "================================================="

# Удаление всех файлов
#rm log*

echo ""

# перебор файлов с предложением создать файл
touch loga logb logc logd logdd

echo "Перебор файлов с помощью fori и предложение создать файл"
for file in "${files[@]}" ; do
    if [[ -f "${file}" ]]; then
        ls -l "${file}"
    else
      echo "File does not exist: ${file}"
      echo "Do you want to create this file? y/n"
      read createFileAnswer
      if [[ "${createFileAnswer}" = "y" ]]; then
          touch "${file}"
      fi
    fi
done

# Удаление всех файлов
#rm log*