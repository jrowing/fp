RESOLUTION = 600
# ... 2400 seems OK for final version

default:
	./torus.rb svg >torus_lines.svg
	./torus.rb povray >torus_shading.pov
	povray Height=$(RESOLUTION) Width=$(RESOLUTION) torus_shading.pov
	display torus_shading.png
