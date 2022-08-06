# This is a framework for my plotter / visualizer program.  
  
I made it to visualize the effects of functions and maps for use in my ESS adapter project in which we modify the area of a regular octogon to conform to a non-regular octogon an inverse function to negate the orignal function.  
For more information about the project and some of the math that inspired this project please check out https://github.com/Skuzee/ESS-Adapter  
  
The program takes a DATASET of points (analog stick coordinates) and applies a TRANSFORM to the coordinate and then it will colorize the coordinates by some COLORSCHEME and then plot / display the output with a VISUALIZER.  
The design is modular such that any transform and any visualizer can be used on any set of coordinate points, and transforms/visualizers can be chained together.  


## How to use
Extending the Sequence class is a "Pregen" a custom list of transforms/visualizer steps.  
Define a PREGEN and add the required elements, use NULL to skip transform, colorization, or visualization. Add the name to TypesOfPregens enum and selectPregen functions. pregen.run(coord) is called to render an image.  
  
Cycle through pregens with the spacebar, mouse wheel to scroll in/out, wasdqe to rotate, r to reset rotation, middle mouse to save image.  
  
a Pregen might look something like this:  
this.addElement(null, new SolidColor, new PlotAsPoints(3)); // No transform, change color scheme, display intial coordinate points as dots.  
this.addElement(new translate(10,10), new Gradient_Mag_Fade(), new VectorField());  // apply transform, change color scheme, display as lines.  
this.addElement(null,         new Solid_Fade(),    new PlotAsPoints()); // No transform, change color scheme, display coordinate points as dots.  
  
  
## TODO
TODO: a way to open Pregens from files?  
TODO: a way to add pregens to enum automatically.  
TODO: FIX XY diagonal visualizer for monotonic test.  
TODO: consider a FORCERENDER option for visualizer?  
TODO: not sure if isRendered is working anymore.  
  
ERRORS: InvertVC is not symmetrical, I suspect folding math?  
ERROR: outline of the final VC shape is a octagon, as I would expect, but perhaps we can make it better fit the n64 gate shape.  This is not an error with the program, rather an error with the transform mapping function math.  
  
  
## Show & Tell  
This is a simple transform that squares the original input values and colors them by magnitude.  
<img src="/DataSet_Transform_ColorScheme_Visualizer/images/x_squared_colored_magnitude.png" width="800" />  
  
  
This is the standard map for the analog stick of nintendo wii's virtual console (for ocarina of time).  Colored by change in magnitude.    
<img src="/DataSet_Transform_ColorScheme_Visualizer/images/VC map function.png" width="800" />  
  
  
This is the output after we apply our own map. Due to the use of truncation/rounding error in the original vc map, some values are lost, so a perfect inverse function is not possible. We generate a map to best estimate the original value while prioritizing maintaining the same angle.  
This is the current visualization of the result. Colored by change in magnitude.  
<img src="/DataSet_Transform_ColorScheme_Visualizer/images/invertVC.png" width="800" />  
