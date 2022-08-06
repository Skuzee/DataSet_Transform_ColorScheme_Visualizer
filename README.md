This is a framework for my plotter / visualizer program.  
The program takes a DATASET of points (analog stick coordinates) and applies a TRANSFORM to the coordinate and then it will colorize the coordinates by some COLORSCHEME and then plot / display the output with a VISUALIZER.  
The design is modular such that any transform and any visualizer can be used on any set of coordinate points, and transforms/visualizers can be chained together.  

Extending the Sequence class is a "Pregen" a custom list of transforms/visualizer steps.  
Define a PREGEN and add the required elements, use NULL to skip transform, colorization, or visualization. Add the name to TypesOfPregens enum and selectPregen functions. pregen.run(coord) is called to render an image.  
  
Cycle through pregens with the spacebar, mouse wheel to scroll in/out.  
  
a Pregen might look something like this:  
this.addElement(null, new SolidColor, new PlotAsPoints(3)); // No transform, change color scheme, display intial coordinate points as dots.  
this.addElement(new translate(10,10), new Gradient_Mag_Fade(), new VectorField());  // apply transform, change color scheme, display as lines.  
this.addElement(null,         new Solid_Fade(),    new PlotAsPoints()); // No transform, change color scheme, display coordinate points as dots.  
  
  
TODO: a way to open Pregens from files?  
TODO: a way to add pregens to enum automatically.  
TODO: FIX XY diagonal visualizer for monotonic test.  
TODO: consider a FORCERENDER option for visualizer?  
TODO: not sure if isRendered is working anymore.  
  
ERRORS: InvertVC is not symetrical, I suspect folding math?  
ERROR: outline of the final VC shape is a octogon, as I would expect, but perhaps we can make it better fit the n64 gate shape.  This is not an error with the program, rather an error with the transform mapping function math.  