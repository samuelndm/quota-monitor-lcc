# coding: utf-8

import matplotlib.pyplot as pyplot
import sys
import random


def generate_random_color():
	r = lambda: random.randint(0,255)

	return "#%02X%02X%02X" % (r(),r(),r())


def put_colors():
	list = []
	
	for label in label_list:
		if "Espaco Livre" in label:
			color = "#DCEBF1"
			list.append(color)
		else:
			color = generate_random_color()
			list.append(color)
	
	return tuple(list)


x_list = [ int(i) for i in (sys.argv[1].split(",")) ]
#x_list.sort()

label_list = sys.argv[2].split(",")

graph_name = sys.argv[3]

#explode = ( 0.1, 0.01, 0.1, 0.01, 0.01, 0.01, 0.0 )
explode = ( 0.1, ) * len(x_list)

colors = put_colors()

pyplot.axis("equal")

pyplot.pie( x_list, labels=label_list,autopct="%1.1f%%", shadow=True, explode=explode, colors = colors, startangle=50 )

pyplot.legend(fontsize="x-small",  bbox_to_anchor=(0.15, 0.13))

#pyplot.show()

pyplot.savefig(graph_name, dpi=None, facecolor='w', edgecolor='w',
        orientation='portrait', papertype=None, format="png",
        transparent=False, bbox_inches=None, pad_inches=0.1,
        frameon=None)



