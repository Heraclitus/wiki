Dallas @ Hulu asked me... to write method for index of globbed string in input string.

<code>

import java.io.*;
import java.util.*;

class Solution {
  public static void main(String[] args) {
   
    //System.out.println(indexOf("fo*", "foo"));
    //System.out.println(indexOf("*fo*", "foo"));
    System.out.println(indexOf("*si*p", "mississipi"));
    System.out.println(indexOf("**si**p**", "mississipi"));
    System.out.println(indexOf("**di**p**", "mississipi"));
    
    //System.out.println(indexOf("*si*dog", "mississipi"));
    //System.out.println(indexOf("*si*dog*pi", "mississipi"));
    
    //System.out.println(indexOf("**si*dog*pi", "mississipi"));
    
  }
  
  public static int indexOf(String glob, String inp)
  {
    String[] tokens = glob.split("\\*");
    System.out.println(Arrays.toString(tokens));
    int indexOfGlob = -1;
    for(int i=0; i < tokens.length; i++)
    {
       indexOfGlob = inp.indexOf(tokens[i], indexOfGlob);
       if(i > 0 && indexOfGlob == -1)
       {
         return -1; 
       }
    }
     return indexOfGlob;
  }
  
// a stab at recursive  
  // terminal cases
  // (globC != '*' && globC != inpC)
  //      mismatch
  // (globC != '*' && !inpItr.hasNext())
  //      mismatch 
  // (!globIter.hasNext())
  //      match
  // (globC != '*' && !globIter.hasNext() && inpItr.hasNext() && globC == inpC)
  //      match 

}
</code>
