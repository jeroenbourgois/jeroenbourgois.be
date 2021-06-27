set title 'Yoda weight'
set xlabel "Date"
set xdata time 
set timefmt "%d/%m/%Y"         # specify our time string format
set format x "%m/%d"           # tell gnuplot x are dates, and show the format
set ylabel "Weight in g"
set terminal jpeg;
set termoption font "Courier,12"
set datafile separator ';'
set style data line
#set key autotitle columnhead   # ignore headers
plot 'yoda-measurements.csv' using 1:2 title "" 
