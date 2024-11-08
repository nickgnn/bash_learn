#!/bin/bash

echo "Hello World!"
echo "App is starting..."
echo ""

# Создание переменных
default_app_name="Start_Learn_Bash"
echo "App name is ${default_app_name} :)"
echo ""

int_var=55

# Создание массива
#      0 1 2 3 4 5  6  7  8  9  10  11    12
array=(1 3 5 7 9 11 13 15 17 19 190 1240 2050)
echo "11-й элемент : ${array[11]}"

# вывести весь массив toString, собака(@)
echo "All array is ${array[@]}"
echo ""

# размер массива, добавлена решётка(#)
echo "Размер массива : ${#array[@]} элементов"
echo ""

# изменение значения в массиве
echo "Изменение значения в массиве"
array[2]=555
echo "All array is ${array[@]}"
echo ""

# добавлять значения в массив
echo "Добавление значений в массив"
array+=(10999 342)
echo "All array is ${array[@]}"
echo ""

# Ввод текста
#echo "Введите новое имя приложения:"
#read new_app_name

echo "New App name is ${new_app_name} :)"
echo "================================================="

# Brace expansion
echo "Brace expansion:"
touch file1 file2 file3 file4 file5 file6 file7 file8

echo {1..9}
echo {a..e}
echo {a..n}
echo {a..z}

# Показать все файлы
ls -l file{1..8}
# Удаление всех файлов
rm -v file{1..8}
echo "================================================="
# Tilde expansion
echo "Tilde expansion:"

var=~/foo
echo "var is: ${var}"
echo "================================================="
# Parameter & variable expansion
echo "Parameter & variable expansion:"

val1=10
val2=
val3=11
echo "${val1}"
echo "${val2:=20}"

# В val3 останется 11
echo "${val3:=22}"
echo "================================================="
# Command substitution
echo "Command substitution:"
echo "The first file in directory ${PWD} is $(ls | head -1)"
echo "Все строки кроме первой (начиная со второй)"
echo "$(ls -l | tail -n +2)"
echo "================================================="
# Arithmetic expansion
echo "Arithmetic expansion:"

echo "$(( 5*3/2 ))"
echo "$(( (5**2+3)/2 ))"
echo "================================================="
# Filename expansion - * ? [..]
echo "Filename expansion:"

touch loga logb logc logd logdd

# Любое количество символов после 'log'
ls log*

# Только один символ после 'log', поэтому logdd не попал в выборку
ls log?

# Перечень конкретных символов, которые могут идти после 'log'
ls log[a,d]
ls log[c,b]
# Удаление всех файлов
rm -v log*
echo "================================================="
# Word splitting
echo "Word splitting: is antipattern"