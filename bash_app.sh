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
echo "Введите новое имя приложения:"
read new_app_name

echo "New App name is ${new_app_name} :)"