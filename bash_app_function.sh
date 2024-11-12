#!/bin/bash

echo "Script all argument $*"

# Function
cleanDir() {
  echo "going to cleanDir..."
}

# функция вызывается после её объявления, важен порядок (процедурный стиль)
cleanDir

echo "======================================================================="
echo ""

# Function with args
clean() {
  echo "going to clean with args..."
  echo "function 1st arg is : $1"

  # $* - "program3 23 99 arg5" - параметры как строка, используется при выводе на консоль
  echo "String is: $*"

  #$@ - "program3" "23" "99" "arg5" - параметры как массив
  echo "Array is: $@"

  #перечисление массива в цикле fori
  echo ""
  echo "Перечисление массива в цикле"
  index=0
  for arg in "$@" ; do
      echo "Index: ${index}. Array el: ${arg}"
      (( index++ ))
  done

  echo "VALUE_FROM_FUNCTION"

  # exit status, по умолчанию 0
  # return 3
}

result=$(clean program3 23 99 arg5)
echo "Clean function result is : ${result}"

# смотрим exit status
echo ""
echo "Отображение exit status"
echo "clean function status is : $?"