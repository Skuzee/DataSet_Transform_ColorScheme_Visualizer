// List of Trasforms
// xSquared - Squares each cooridnate, preserving sign.
// Translate - Translates the cooridnate.
// VCmap - Emulates the mapping that is applied by Nintendo Wii's Virtual Console.
// Deadzone15 - Applies 15 unit deadzone. Used with VCMap
// InvertVC - Applies a stretching/scaling and then applies a linear/triagular map as an inverse to VCmap.
// MyScale -  A new way of scaling from a regular octogon to the n64s octogon.
// NotchSnapping - Snaps the coordinate to a point if it is within a certain range.


// Transforms Interface & Definitions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
public interface Transform {
  public Coord apply(Coord inputCoord);
}

public class xSquared implements Transform { // Squares each cooridnate, preserving sign. ~~~~
  private Coord outputCoord = new Coord();

  public Coord apply(Coord inputCoord) {
    int xSign = constrain(inputCoord.getX(),-1,1);
    int ySign = constrain(inputCoord.getY(),-1,1);
    outputCoord.setXY(inputCoord.getX()*inputCoord.getX()*xSign,inputCoord.getY()*inputCoord.getY()*ySign);
    return outputCoord;
  }
}

public class Translate implements Transform { // Translates the cooridnate. ~~~~~~~~~~~~~~~~~~
  private Coord outputCoord = new Coord();
  private int Xtrans=0;
  private int Ytrans=0;
  
  Translate(int Xtrans, int Ytrans) {
    this.Xtrans  = Xtrans;
    this.Ytrans = Ytrans;
  }

  public Coord apply(Coord inputCoord) {
    outputCoord.setXY(inputCoord.getX()+Xtrans, inputCoord.getY()+Ytrans);

    return outputCoord;
  }
}

public class VCmap implements Transform { // VCmap Emulates the mapping that is applied by Nintendo Wii's Virtual Console. ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  private Coord outputCoord = new Coord();

  public Coord apply(Coord inputCoord) {
    outputCoord.isRendered = inputCoord.isRendered;

    int signX = constrain(int(inputCoord.getX()), -1, 1);
    int signY = constrain(int(inputCoord.getY()), -1, 1);

    float outputX = ((inputCoord.getX() * signX)-15)*signX;
    outputX = int(outputX * 127 / 56); // trunc error is on purpose.
    outputX /= 127;
    outputX = 1 - sqrt(1 - abs(outputX));
    outputX *= 127;
    outputX *= signX;

    float outputY = ((inputCoord.getY() * signY)-15)*signY; 
    outputY = int(outputY * 127 / 56);
    outputY /= 127;
    outputY = 1 - sqrt(1 - abs(outputY));
    outputY *= 127;
    outputY *= signY;

    outputCoord.setXY(int(outputX), int(outputY));
    //outputCoord.HSBcolor = color(40-inputCoord.distToCoord(outputCoord)*2, 100, 100);
    return outputCoord;
  }
}

public class Deadzone15 implements Transform { // Applies 15 unit deadzone ~~~~~~~~~~~~~~~~~~~
  private Coord outputCoord = new Coord();

  public Coord apply(Coord inputCoord) {
    if (abs(inputCoord.getX()) <= 15) {
      outputCoord.setX(0);
    } else {
      outputCoord.setX(inputCoord.getX());
    }

    if (abs(inputCoord.getY()) <= 15) {
      outputCoord.setY(0);
    } else {
      outputCoord.setY(inputCoord.getY());
    }

    return outputCoord;
  }
}
public class InvertVC implements Transform { // InvertVC Applies a stretching/scaling and then applies a linear/triagular map as an inverse to VCmap.
  private Coord outputCoord = new Coord();
  private boolean x_positive = true;
  private boolean y_positive = true;
  private boolean swap = false;
  private int X=0;
  private int Y=0;
  private final int OOT_MAX=  80;
  private final int BOUNDARY = 39;

  //final char one_dimensional_map[] = {'0', '0', '0x10', '0x10', '0x11', '0x11', '0x12', '0x12', '0x13', '0x13', '0x14', '0x14', '0x15', '0x15', '0x16', '0x16', '0x16', '0x17', '0x17', '0x17', '0x18', '0x18', '0x19', '0x19', '0x1a', '0x1a', '0x1a', '0x1b', '0x1b', '0x1b', '0x1c', '0x1c', '0x1d', '0x1d', '0x1d', '0x1e', '0x1e', '0x1e', '0x1f', '0x1f, ' ', ' '!', '!', '!', '\\', '\"', '\\', '\"', '\\', '\"', '#', '#', '#', '$', '$', '$', '%', '%', '%', '&', '&', '&', '\'', '\'', '\'', '(', '(', '(', ')', ')', ')', '*', '*', '*', '+', '+', '+', ',', ',', ',', ',', '-', '-', '-', '.', '.', '.', '/', '/', '/', '0', '0', '0', '0', '1', '1', '1', '1', '2', '2', '2', '3', '3', '3', '3', '4', '4', '4', '4', '5', '5', '5', '5', '6', '6', '6', '6', '7', '7', '7', '7', '8', '8', '8', '8', '8', '9', '9', '9', '9', '9', ':', ':', ':', ':', ';', ';', ';', ';', ';', '<', '<', '<', '<', '<', '=', '=', '=', '=', '=', '>', '>', '>', '>', '>', '?', '?', '?', '?', '?', '?', '@', '@', '@'};
  //String trimap = ",,-,.,.,/,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,9,:,:,;,;,<,<,<,=,=,>,>,>,?,?,?,@,--.-.-/-0-0-1-1-2-2-3-3-4-4-5-5-6-6-7-7-8-8-9-9-9-:-:-;-;-<-<-<-=-=->->->-?-?-?-@,..../.0.0.1.1.2.2.3.3.4.4.5.5.6.6.7.7.8.8.9.9.9.:.:.;.;.<.<.<.=.=.>.>.>.?-?-?-?-../.0.0.1.1.2.2.3.3.4.4.5.5.6.6.7.7.8.8.9.9.9.:.:.;.;.<.<.<.=.=.>.>.>.?-?-?-?-//0/0/1/1/2/2/3/3/4/4/5/5/6/6/7/7/8/8/9/9/9/:/:/;/;/</</</=/=/>/>/>/>/>/?-?-000010102020303040405050606070708080909090:0:0;0;0<0<0<0=0=0>/>/>/>/>/>/>/0010102020303040405050606070708080909090:0:0;0;0<0<0<0=0=0=0>/>/>/>/>/>/11112121313141415151616171718181919191:1:1;1;1<1<1<1=0=0=0>/>/>/>/>/>/112121313141415151616171718181919191:1:1;1;1<1<1<1<1<1=0=0>/>/>/>/>/2222323242425252626272728282929292:2:2;2;2<1<1<1<1<1<1=0=0>/>/>/>/22323242425252626272728282929292:2:2;2;2;2<1<1<1<1<1<1<1=0=0>/>/333343435353636373738383939393:3:3;3;3;3;3<1<1<1<1<1<1<1=0=0>/3343435353636373738383939393:3:3;3;3;3;3;3<1<1<1<1<1<1<1<1=044445454646474748484949494:4:4:4;3;3;3;3;3<1<1<1<1<1<1<1<1445454646474748484949494:4:4:4:4;3;3;3;3;3;3<1<1<1<1<1<1555565657575858595959595:4:4:4:4;3;3;3;3;3;3<1<1<1<1<1556565757585859595959595:4:4:4:4;3;3;3;3;3;3<1<1<1<1666676768686869595959595:4:4:4:4;3;3;3;3;3;3;3<1<1667676868686959595959595:4:4:4:4:4;3;3;3;3;3;3<1777777868686959595959595:4:4:4:4:4;3;3;3;3;3;3777777868686869595959595:4:4:4:4:4;3;3;3;3;377777786868686959595959595:4:4:4:4:4;3;3;377777786868686959595959595:4:4:4:4:4;3;377777786868686959595959595:4:4:4:4:4;377777786868686959595959595:4:4:4:4:477777786868686959595959595:4:4:4:47777778686868695959595959595:4:47777778686868695959595959595:4777777868686869595959595959577777786868686959595959595777777868686869595959595777777868686869595959577777786868686869595777777868686868695777777868686868677777786868686777777868686777777868677777786777777777777";
  byte[] one_dimensional_map = {0, 0, 16, 16, 17, 17, 18, 18, 19, 19, 20, 20, 21, 21, 22, 22, 22, 23, 23, 23, 24, 24, 25, 25, 26, 26, 26, 27, 27, 27, 28, 28, 29, 29, 29, 30, 30, 30, 31, 31, 32, 32, 33, 33, 33, 34, 34, 34, 35, 35, 35, 36, 36, 36, 37, 37, 37, 38, 38, 38, 39, 39, 39, 40, 40, 40, 41, 41, 41, 42, 42, 42, 43, 43, 43, 44, 44, 44, 44, 45, 45, 45, 46, 46, 46, 47, 47, 47, 48, 48, 48, 48, 49, 49, 49, 49, 50, 50, 50, 51, 51, 51, 51, 52, 52, 52, 52, 53, 53, 53, 53, 54, 54, 54, 54, 55, 55, 55, 55, 56, 56, 56, 56, 56, 57, 57, 57, 57, 57, 58, 58, 58, 58, 59, 59, 59, 59, 59, 60, 60, 60, 60, 60, 61, 61, 61, 61, 61, 62, 62, 62, 62, 62, 63, 63, 63, 63, 63, 63, 64, 64, 64};
  byte[] triangular_map = {44, 44, 45, 44, 46, 44, 46, 44, 47, 44, 48, 44, 48, 44, 49, 44, 49, 44, 50, 44, 50, 44, 51, 44, 51, 44, 52, 44, 52, 44, 53, 44, 53, 44, 54, 44, 54, 44, 55, 44, 55, 44, 56, 44, 56, 44, 57, 44, 57, 44, 57, 44, 58, 44, 58, 44, 59, 44, 59, 44, 60, 44, 60, 44, 60, 44, 61, 44, 61, 44, 62, 44, 62, 44, 62, 44, 63, 44, 63, 44, 63, 44, 64, 44, 45, 45, 46, 45, 46, 45, 47, 45, 48, 45, 48, 45, 49, 45, 49, 45, 50, 45, 50, 45, 51, 45, 51, 45, 52, 45, 52, 45, 53, 45, 53, 45, 54, 45, 54, 45, 55, 45, 55, 45, 56, 45, 56, 45, 57, 45, 57, 45, 57, 45, 58, 45, 58, 45, 59, 45, 59, 45, 60, 45, 60, 45, 60, 45, 61, 45, 61, 45, 62, 45, 62, 45, 62, 45, 63, 45, 63, 45, 63, 45, 64, 44, 46, 46, 46, 46, 47, 46, 48, 46, 48, 46, 49, 46, 49, 46, 50, 46, 50, 46, 51, 46, 51, 46, 52, 46, 52, 46, 53, 46, 53, 46, 54, 46, 54, 46, 55, 46, 55, 46, 56, 46, 56, 46, 57, 46, 57, 46, 57, 46, 58, 46, 58, 46, 59, 46, 59, 46, 60, 46, 60, 46, 60, 46, 61, 46, 61, 46, 62, 46, 62, 46, 62, 46, 63, 45, 63, 45, 63, 45, 63, 45, 46, 46, 47, 46, 48, 46, 48, 46, 49, 46, 49, 46, 50, 46, 50, 46, 51, 46, 51, 46, 52, 46, 52, 46, 53, 46, 53, 46, 54, 46, 54, 46, 55, 46, 55, 46, 56, 46, 56, 46, 57, 46, 57, 46, 57, 46, 58, 46, 58, 46, 59, 46, 59, 46, 60, 46, 60, 46, 60, 46, 61, 46, 61, 46, 62, 46, 62, 46, 62, 46, 63, 45, 63, 45, 63, 45, 63, 45, 47, 47, 48, 47, 48, 47, 49, 47, 49, 47, 50, 47, 50, 47, 51, 47, 51, 47, 52, 47, 52, 47, 53, 47, 53, 47, 54, 47, 54, 47, 55, 47, 55, 47, 56, 47, 56, 47, 57, 47, 57, 47, 57, 47, 58, 47, 58, 47, 59, 47, 59, 47, 60, 47, 60, 47, 60, 47, 61, 47, 61, 47, 62, 47, 62, 47, 62, 47, 62, 47, 62, 47, 63, 45, 63, 45, 48, 48, 48, 48, 49, 48, 49, 48, 50, 48, 50, 48, 51, 48, 51, 48, 52, 48, 52, 48, 53, 48, 53, 48, 54, 48, 54, 48, 55, 48, 55, 48, 56, 48, 56, 48, 57, 48, 57, 48, 57, 48, 58, 48, 58, 48, 59, 48, 59, 48, 60, 48, 60, 48, 60, 48, 61, 48, 61, 48, 62, 47, 62, 47, 62, 47, 62, 47, 62, 47, 62, 47, 62, 47, 48, 48, 49, 48, 49, 48, 50, 48, 50, 48, 51, 48, 51, 48, 52, 48, 52, 48, 53, 48, 53, 48, 54, 48, 54, 48, 55, 48, 55, 48, 56, 48, 56, 48, 57, 48, 57, 48, 57, 48, 58, 48, 58, 48, 59, 48, 59, 48, 60, 48, 60, 48, 60, 48, 61, 48, 61, 48, 61, 48, 62, 47, 62, 47, 62, 47, 62, 47, 62, 47, 62, 47, 49, 49, 49, 49, 50, 49, 50, 49, 51, 49, 51, 49, 52, 49, 52, 49, 53, 49, 53, 49, 54, 49, 54, 49, 55, 49, 55, 49, 56, 49, 56, 49, 57, 49, 57, 49, 57, 49, 58, 49, 58, 49, 59, 49, 59, 49, 60, 49, 60, 49, 60, 49, 61, 48, 61, 48, 61, 48, 62, 47, 62, 47, 62, 47, 62, 47, 62, 47, 62, 47, 49, 49, 50, 49, 50, 49, 51, 49, 51, 49, 52, 49, 52, 49, 53, 49, 53, 49, 54, 49, 54, 49, 55, 49, 55, 49, 56, 49, 56, 49, 57, 49, 57, 49, 57, 49, 58, 49, 58, 49, 59, 49, 59, 49, 60, 49, 60, 49, 60, 49, 60, 49, 60, 49, 61, 48, 61, 48, 62, 47, 62, 47, 62, 47, 62, 47, 62, 47, 50, 50, 50, 50, 51, 50, 51, 50, 52, 50, 52, 50, 53, 50, 53, 50, 54, 50, 54, 50, 55, 50, 55, 50, 56, 50, 56, 50, 57, 50, 57, 50, 57, 50, 58, 50, 58, 50, 59, 50, 59, 50, 60, 49, 60, 49, 60, 49, 60, 49, 60, 49, 60, 49, 61, 48, 61, 48, 62, 47, 62, 47, 62, 47, 62, 47, 50, 50, 51, 50, 51, 50, 52, 50, 52, 50, 53, 50, 53, 50, 54, 50, 54, 50, 55, 50, 55, 50, 56, 50, 56, 50, 57, 50, 57, 50, 57, 50, 58, 50, 58, 50, 59, 50, 59, 50, 59, 50, 60, 49, 60, 49, 60, 49, 60, 49, 60, 49, 60, 49, 60, 49, 61, 48, 61, 48, 62, 47, 62, 47, 51, 51, 51, 51, 52, 51, 52, 51, 53, 51, 53, 51, 54, 51, 54, 51, 55, 51, 55, 51, 56, 51, 56, 51, 57, 51, 57, 51, 57, 51, 58, 51, 58, 51, 59, 51, 59, 51, 59, 51, 59, 51, 60, 49, 60, 49, 60, 49, 60, 49, 60, 49, 60, 49, 60, 49, 61, 48, 61, 48, 62, 47, 51, 51, 52, 51, 52, 51, 53, 51, 53, 51, 54, 51, 54, 51, 55, 51, 55, 51, 56, 51, 56, 51, 57, 51, 57, 51, 57, 51, 58, 51, 58, 51, 59, 51, 59, 51, 59, 51, 59, 51, 59, 51, 60, 49, 60, 49, 60, 49, 60, 49, 60, 49, 60, 49, 60, 49, 60, 49, 61, 48, 52, 52, 52, 52, 53, 52, 53, 52, 54, 52, 54, 52, 55, 52, 55, 52, 56, 52, 56, 52, 57, 52, 57, 52, 57, 52, 58, 52, 58, 52, 58, 52, 59, 51, 59, 51, 59, 51, 59, 51, 59, 51, 60, 49, 60, 49, 60, 49, 60, 49, 60, 49, 60, 49, 60, 49, 60, 49, 52, 52, 53, 52, 53, 52, 54, 52, 54, 52, 55, 52, 55, 52, 56, 52, 56, 52, 57, 52, 57, 52, 57, 52, 58, 52, 58, 52, 58, 52, 58, 52, 59, 51, 59, 51, 59, 51, 59, 51, 59, 51, 59, 51, 60, 49, 60, 49, 60, 49, 60, 49, 60, 49, 60, 49, 53, 53, 53, 53, 54, 53, 54, 53, 55, 53, 55, 53, 56, 53, 56, 53, 57, 53, 57, 53, 57, 53, 57, 53, 58, 52, 58, 52, 58, 52, 58, 52, 59, 51, 59, 51, 59, 51, 59, 51, 59, 51, 59, 51, 60, 49, 60, 49, 60, 49, 60, 49, 60, 49, 53, 53, 54, 53, 54, 53, 55, 53, 55, 53, 56, 53, 56, 53, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 58, 52, 58, 52, 58, 52, 58, 52, 59, 51, 59, 51, 59, 51, 59, 51, 59, 51, 59, 51, 60, 49, 60, 49, 60, 49, 60, 49, 54, 54, 54, 54, 55, 54, 55, 54, 56, 54, 56, 54, 56, 54, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 58, 52, 58, 52, 58, 52, 58, 52, 59, 51, 59, 51, 59, 51, 59, 51, 59, 51, 59, 51, 59, 51, 60, 49, 60, 49, 54, 54, 55, 54, 55, 54, 56, 54, 56, 54, 56, 54, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 58, 52, 58, 52, 58, 52, 58, 52, 58, 52, 59, 51, 59, 51, 59, 51, 59, 51, 59, 51, 59, 51, 60, 49, 55, 55, 55, 55, 55, 55, 56, 54, 56, 54, 56, 54, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 58, 52, 58, 52, 58, 52, 58, 52, 58, 52, 59, 51, 59, 51, 59, 51, 59, 51, 59, 51, 59, 51, 55, 55, 55, 55, 55, 55, 56, 54, 56, 54, 56, 54, 56, 54, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 58, 52, 58, 52, 58, 52, 58, 52, 58, 52, 59, 51, 59, 51, 59, 51, 59, 51, 59, 51, 55, 55, 55, 55, 55, 55, 56, 54, 56, 54, 56, 54, 56, 54, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 58, 52, 58, 52, 58, 52, 58, 52, 58, 52, 59, 51, 59, 51, 59, 51, 55, 55, 55, 55, 55, 55, 56, 54, 56, 54, 56, 54, 56, 54, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 58, 52, 58, 52, 58, 52, 58, 52, 58, 52, 59, 51, 59, 51, 55, 55, 55, 55, 55, 55, 56, 54, 56, 54, 56, 54, 56, 54, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 58, 52, 58, 52, 58, 52, 58, 52, 58, 52, 59, 51, 55, 55, 55, 55, 55, 55, 56, 54, 56, 54, 56, 54, 56, 54, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 58, 52, 58, 52, 58, 52, 58, 52, 58, 52, 55, 55, 55, 55, 55, 55, 56, 54, 56, 54, 56, 54, 56, 54, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 58, 52, 58, 52, 58, 52, 58, 52, 55, 55, 55, 55, 55, 55, 56, 54, 56, 54, 56, 54, 56, 54, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 58, 52, 58, 52, 55, 55, 55, 55, 55, 55, 56, 54, 56, 54, 56, 54, 56, 54, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 58, 52, 55, 55, 55, 55, 55, 55, 56, 54, 56, 54, 56, 54, 56, 54, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 55, 55, 55, 55, 55, 55, 56, 54, 56, 54, 56, 54, 56, 54, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 55, 55, 55, 55, 55, 55, 56, 54, 56, 54, 56, 54, 56, 54, 57, 53, 57, 53, 57, 53, 57, 53, 57, 53, 55, 55, 55, 55, 55, 55, 56, 54, 56, 54, 56, 54, 56, 54, 57, 53, 57, 53, 57, 53, 57, 53, 55, 55, 55, 55, 55, 55, 56, 54, 56, 54, 56, 54, 56, 54, 56, 54, 57, 53, 57, 53, 55, 55, 55, 55, 55, 55, 56, 54, 56, 54, 56, 54, 56, 54, 56, 54, 57, 53, 55, 55, 55, 55, 55, 55, 56, 54, 56, 54, 56, 54, 56, 54, 56, 54, 55, 55, 55, 55, 55, 55, 56, 54, 56, 54, 56, 54, 56, 54, 55, 55, 55, 55, 55, 55, 56, 54, 56, 54, 56, 54, 55, 55, 55, 55, 55, 55, 56, 54, 56, 54, 55, 55, 55, 55, 55, 55, 56, 54, 55, 55, 55, 55, 55, 55, 55, 55, 55, 55, 55, 55};


  // Fold the quadrants into a 1/8th slice.
  public Coord apply(Coord inputCoord) {
    if (inputCoord.getX() < 0) {
      x_positive = false;
      X = -1-inputCoord.getX();
    } else {
      x_positive = true;
      X= inputCoord.getX();
    }

    if (inputCoord.getY() < 0) {
      y_positive = false;
      Y = -1-inputCoord.getY();
    } else {
      y_positive = true;
      Y = inputCoord.getY();
    }

    if (Y > X) {
      swap = true;
      int temp = X;
      X = Y;
      Y = temp;
    } else {
      swap = false;
    }
    
 
    ////gc to n64
    long scale = 5L * X + 2L * Y;
    if (scale > 525) {
    // Multiply by 16 here to reduce precision loss from dividing by scale
      scale = 16L * 525 * 525 * 525 / scale; // clamp distance to 1.0
     } else {
      scale = 16 * scale * scale; // (5x + 2y)^2, leaving 525^2 to divide later.
     }
     
    scale *= Y; // * y, leaving another 525 to divide later.
    scale = scale * 2 / 115; // we already multiplied by an extra *16 above
    scale += 25565300; // ~= 2 * 80/105 * 2^24

    X = int((X * scale + 16774000) >> 24);
    Y = int((Y * scale + 16774000) >> 24);


    // double resolution
    X*=2;
    Y*=2;

    // INVERT VC HERE
    /* Assume 0 <= y <= x <= 2*127 - double resolution */
    /* Approach is documented in the python implementation */
    if (X > (2 * OOT_MAX)) {
      X = 2 * OOT_MAX;
    }
    if (Y > (2 * OOT_MAX)) {
      Y = 2 * OOT_MAX;
    }
    
    if ((X >= (2*BOUNDARY)) && (Y >= (2*BOUNDARY))) {  //39
      int remainder = OOT_MAX + 1 - BOUNDARY;          //42
      X = (X / 2) - BOUNDARY;                          //>=0
      Y = (Y / 2) - BOUNDARY;
      int  index = (remainder * (remainder - 1) / 2) - (remainder - Y) * ((remainder - Y) - 1) / 2 + X;
      X = triangular_map[2 * index];
      Y = triangular_map[2 * index + 1];
    } else {
      X = one_dimensional_map[X];
      Y = one_dimensional_map[Y];
    }

    // Restore coord to correct quadrants.
    if (swap) {
      int temp = X;
      X = Y;
      Y = temp;
    }

    if (!x_positive) {
      X = -X;
    }

    if (!y_positive) {
      Y = -Y;
    }
    
    outputCoord.setXY(X,Y);
    return outputCoord;
  }
}

public class MyScale implements Transform { // A new way of scaling from a regular octogon to the n64s octogon.
  private Coord outputCoord = new Coord();

  public Coord apply(Coord inputCoord) { //gc 105/73     n64 80/63 
    int signX = constrain(inputCoord.getX(),-1,1);
    int signY = constrain(inputCoord.getY(),-1,1);
    outputCoord.setX((inputCoord.getX()*80/105) + (inputCoord.getX()*inputCoord.getY()*14/105/105)*signY);
    outputCoord.setY((inputCoord.getY()*80/105) + (inputCoord.getX()*inputCoord.getY()*14/105/105)*signX);
    //outputCoord.setX(inputCoord.getX()-(11*inputCoord.getX()/105) - 14*(73-inputCoord.getY())/73*inputCoord.getX()/105);  
    //outputCoord.setY(inputCoord.getY()-(11*inputCoord.getY()/105) - 14*(73-inputCoord.getX())/73*inputCoord.getY()/105);  
    return outputCoord;
  }
}

public class NotchSnapping implements Transform { // Snaps the coordinate to a point if it is within a certain range.
  private Coord outputCoord = new Coord();
  private int notch_Snap_Strength = 2;
  private CornerNotch gateArray[];
  private Coord correctionVector = new Coord();

  NotchSnapping() {
  }

  NotchSnapping(CornerNotch gateArray[], int notch_Snap_Strength) {
    this.notch_Snap_Strength = notch_Snap_Strength;
    this.gateArray = gateArray;
  }

  private int findQuandrant(Coord inputCoord) {
    if (inputCoord.getY() > 0) {
      if (inputCoord.getX() > 0) { // Q1
        return 0;
      } else if (inputCoord.getX() < 0) { // Q2
        return 1;
      }
    } else if (inputCoord.getY() < 0) {
      if (inputCoord.getX() < 0) { // Q3
        return 2;
      } else if (inputCoord.getX() > 0) { // Q4
        return 3;
      }
    }
    return -1; // Does nothing if X or Y value equals 0.
  }

  public Coord apply(Coord inputCoord) {
    outputCoord.setXY(inputCoord.getX(), inputCoord.getY());
    int quadrant = findQuandrant(inputCoord);
    // inputX - unsigned NotchX - Correction
    if (quadrant!=-1) {
      correctionVector = new Coord(inputCoord.getX()-(gateArray[quadrant].Xvalue)-(gateArray[quadrant].correction*gateArray[quadrant].Xsign), 
        inputCoord.getY()-(gateArray[quadrant].Yvalue)+(gateArray[quadrant].correction*gateArray[quadrant].Ysign));
    }
    if (correctionVector.getMag() <= notch_Snap_Strength) {
      //v1 /= 2;
      outputCoord.setXY(inputCoord.getX()-correctionVector.getX(), inputCoord.getY()-correctionVector.getY());
    }
    return outputCoord;
  }
}
