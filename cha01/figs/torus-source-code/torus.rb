#!/usr/bin/ruby

# produce an svg file showing triangulation of a torus

$graphic = '' # accumulator for the xml code that draws the graphic

# theta = angle around the large circle
# phi = angle around the neck
$n_theta=14 # should be even for this algorithm
$n_phi = 8

$a = 3.0 # radius of large circle
$b = 1.5 # ...small

$PI=3.1415926535


$brightness = 0.8 # gamma style, from 0 to infinity
$contrast =  0.9 # nominally 0 to 1, but can go higher
$lighting = [0.5,-1.0,1.0] # direction to light source; doesn't matter if it's normalized

$fmt = ARGV[0] # can be povray or svg
if $fmt.nil? then $fmt='svg' end

if $fmt=='svg' then
  $scale = 60.0 # not sure what units these are, maybe points?
end

if $fmt=='povray' then
  $scale = 0.3
  $torus_color = 'Gray'
  $background_color = 'Gray'
end

$blobby = true

def main
  (1..2).each { |layer|
    (0..$n_theta-1).each { |i|
      (0..$n_phi-1).each { |j|
        do_triangle(layer,i,j,    i,j+1,  i+1,j)
        do_triangle(layer,i+1,j,  i,j+1,  i+1,j+1)
      }
    }
  }
  print template().gsub!(/BLANK/,$graphic)
end

def do_triangle(layer,i1,j1,i2,j2,i3,j3)
  p = vertex(i1,j1)
  q = vertex(i2,j2)
  r = vertex(i3,j3)
  u = vector_sub(q,p)
  v = vector_sub(r,p)
  n = normalize(cross_product(v,u)) # outward-directed normal vector
  nn = dot(n,normalize($lighting))*$contrast
  if nn<0 then nn=0 end
  if nn>1 then nn=1 end
  s = (1.0+nn)*0.5 # put in range from 0 to 1
  s = s**(1.0/$brightness)
  s_byte = (s*255.0).to_i
  shading = "%2x" % s_byte # convert to a hex byte
  visible = $fmt=='povray' || n[2]> -0.0001
  if visible then
    if layer==1 then
      if $fmt=='povray' then draw_triangle(shading+shading+shading,i1,j1,i2,j2,i3,j3) end # let povray do shading
    end
    if layer==2 && $fmt=='svg' then
      draw_line(i1,j1,i2,j2)
      draw_line(i1,j1,i3,j3)
      draw_line(i2,j2,i3,j3)
    end
  end
end

def find_theta_and_phi(i,j)
  k = 2.*$PI
  theta = k*i.to_f/$n_theta.to_f
  phi = k*(j.to_f+i.to_f/2.0)/$n_phi.to_f
  c1 = 0.1
  c2 = 0.1
  c3 = 0.3
  c4 = 0.1
  c5 = 0.1
  c6 = 0.2
  c7 = 0.3
  c8 = 0.1
  if $blobby then
    theta = theta+c1*Math::sin(theta)+c2*Math::sin(phi)+c3*Math::sin(theta)*Math::sin(phi)+c4*Math::sin(2*theta)
    phi = phi+c5*Math::sin(theta)+c6*Math::sin(phi)+c7*Math::sin(theta)*Math::sin(phi)+c8*Math::sin(2*phi)
  end
  return [put_angle_in_range(theta),put_angle_in_range(phi)]
end

def put_angle_in_range(x)
  i = (x/(20.*$PI)).to_i
  x = x-i*2.0*$PI
  if x>2.0*$PI then x=x-2.0*$PI end
  if x<0 then x=x+2.0*$PI end
  return x
end

def vertex(i,j)
  theta,phi = find_theta_and_phi(i,j)
  aa = $a
  bb = $b
  d1 = 0.1
  d2 = 0.0
  d3 = 0.1
  d4 = 2.0
  e1 = 0.1
  e2 = 1.5
  e3 = 0.2
  e4 = 2
  e5 = 0.2
  e6 = 0.2
  if $blobby then
    aa = aa*(1.0+d1*Math::sin(theta+d2)+d2*Math::sin(phi+d4))
    bb = bb*(1.0+e1*Math::sin(theta+e2)+e3*Math::sin(phi+e4)+e5*Math::sin(2.0*theta)+e6*Math::sin(3.0*theta))
  end
  x = aa+bb*Math::cos(phi)
  y = 0
  z = bb*Math::sin(phi)
  # rotate by theta in the xy plane:
  x,y = [x*Math::cos(theta)-y*Math::sin(theta),x*Math::sin(theta)+y*Math::cos(theta)]
  return x,y,z
end

def normalize(u)
  m=magnitude(u)
  return [u[0]/m,u[1]/m,u[2]/m]
end

def to_deg(x)
  return 180.0*x/$PI
end

def angle_between(u,v)
  return Math::acos(dot(u,v)/(magnitude(u)*magnitude(v)))
end

def scalar_mult(s,v)
  return [s*v[0],s*v[1],s*v[2]]
end

def dot(u,v)
  return u[0]*v[0]+u[1]*v[1]+u[2]*v[2]
end

def magnitude(v)
  return Math::sqrt(v[0]**2+v[1]**2+v[2]**2)
end

def cross_product(p,q)
  return p[1]*q[2]-p[2]*q[1],p[2]*q[0]-p[0]*q[2],p[0]*q[1]-p[1]*q[0]
end

def vector_sub(p,q)
  return p[0]-q[0],p[1]-q[1],p[2]-q[2]
end

def draw_triangle(fill,i1,j1,i2,j2,i3,j3)
  if $fmt=='svg' then
    x1,y1 = project(vertex(i1,j1))
    x2,y2 = project(vertex(i2,j2))
    x3,y3 = project(vertex(i3,j3))
    $graphic = $graphic + triangle_xml(fill,x1,y1,x2,y2,x3,y3)
  end
  if $fmt=='povray' then
    $graphic = $graphic + triangle_povray(vertex(i1,j1),vertex(i2,j2),vertex(i3,j3))
  end
end

def point_to_povray(p)
  s = scalar_mult($scale,p)
  return "<#{s[0]},#{s[1]},#{s[2]}>"
end

def triangle_povray(p,q,r)
return <<"POVRAY"
triangle {
  #{point_to_povray(p)}, #{point_to_povray(q)}, #{point_to_povray(r)}
  texture {
    pigment { color #{$torus_color} }
  }
}
POVRAY
end

def draw_line(i1,j1,i2,j2)
  x1,y1 = project(vertex(i1,j1))
  x2,y2 = project(vertex(i2,j2))
  $graphic = $graphic + line_xml(x1,y1,x2,y2)
end

def project(p)
  x,y,z = p
  offset = 1.3*($a+$b)
  # project out z for a view from infinitely far away along the z axis
  return [$scale*(x+offset),$scale*(y+offset)]
end

def triangle_xml(fill,x1,y1,x2,y2,x3,y3)
# fill = 'a7a7a7'
return <<"XML"
    <path
       style="color:#000000;clip-rule:nonzero;display:inline;overflow:visible;visibility:visible;opacity:1;isolation:auto;mix-blend-mode:normal;color-interpolation:sRGB;color-interpolation-filters:linearRGB;solid-color:#000000;solid-opacity:1;fill:##{fill};fill-opacity:1;fill-rule:evenodd;stroke:none;stroke-width:0.56275719;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1;marker:none;marker-start:none;marker-mid:none;marker-end:none;color-rendering:auto;image-rendering:auto;shape-rendering:auto;text-rendering:auto;enable-background:accumulate"
       d="m #{x1},#{y1} #{x2-x1},#{y2-y1} #{x3-x2},#{y3-y2}  z"
       id="path3336"
       inkscape:connector-curvature="0" />
XML
end

def line_xml(x1,y1,x2,y2)
return <<"XML"
    <path
       style="color:#000000;clip-rule:nonzero;display:inline;overflow:visible;visibility:visible;opacity:1;isolation:auto;mix-blend-mode:normal;color-interpolation:sRGB;color-interpolation-filters:linearRGB;solid-color:#000000;solid-opacity:1;fill:none;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:0.56275719;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1;marker:none;marker-start:none;marker-mid:none;marker-end:none;color-rendering:auto;image-rendering:auto;shape-rendering:auto;text-rendering:auto;enable-background:accumulate"
       d="M #{x1},#{y1} #{x2},#{y2}"
       id="path4136"
       inkscape:connector-curvature="0" />
XML
end

def fatal_error(m)
  $stderr.print m+"\n"
  exit(-1)
end

def template
  if $fmt=='svg' then return svg_template() end
  if $fmt=='povray' then return povray_template() end
  fatal_error('illegal fmt in template()')
end

def svg_template
return <<'TEMPLATE'
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!-- Created with Inkscape (http://www.inkscape.org/) -->

<svg
   xmlns:dc="http://purl.org/dc/elements/1.1/"
   xmlns:cc="http://creativecommons.org/ns#"
   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
   xmlns:svg="http://www.w3.org/2000/svg"
   xmlns="http://www.w3.org/2000/svg"
   xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
   xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
   width="210mm"
   height="297mm"
   viewBox="0 0 744.09448819 1052.3622047"
   id="svg2"
   version="1.1"
   inkscape:version="0.91 r"
   sodipodi:docname="line.svg">
  <defs
     id="defs4" />
  <sodipodi:namedview
     id="base"
     pagecolor="#ffffff"
     bordercolor="#666666"
     borderopacity="1.0"
     inkscape:pageopacity="0.0"
     inkscape:pageshadow="2"
     inkscape:zoom="0.35"
     inkscape:cx="-90.714286"
     inkscape:cy="520"
     inkscape:document-units="mm"
     inkscape:current-layer="layer1"
     showgrid="false"
     inkscape:window-width="1280"
     inkscape:window-height="998"
     inkscape:window-x="0"
     inkscape:window-y="0"
     inkscape:window-maximized="1" />
  <metadata
     id="metadata7">
    <rdf:RDF>
      <cc:Work
         rdf:about="">
        <dc:format>image/svg+xml</dc:format>
        <dc:type
           rdf:resource="http://purl.org/dc/dcmitype/StillImage" />
        <dc:title></dc:title>
      </cc:Work>
    </rdf:RDF>
  </metadata>
  <g
     inkscape:label="Layer 1"
     inkscape:groupmode="layer"
     id="layer1">
     BLANK
  </g>
</svg>
TEMPLATE

end

def povray_template
return <<"TEMPLATE"
#version 3.7;
global_settings { assumed_gamma 1.0 }
#include "colors.inc"
background { color #{$background_color} }
camera {
  orthographic // not perspective
  angle 20 // width of camera view, in degrees
  location <0, -5, 10>
  look_at  <0, 0, 0>
  up    <0,10,0>
  right <10,0,0> 
}
BLANK
light_source { <-10, 10, 4> color White} // up and above, a little in front
light_source {
  <0,0,10> color White
  area_light
  <1,0,0>, <0,1,0>, 10, 10
}
TEMPLATE
end

main()
