module Series1

import IO;
/*
 * Documentation: https://www.rascal-mpl.org/docs/GettingStarted/
 */

/*
 * Hello world
 *
 * - Import IO, write a function that prints out Hello World!
 * - open the console (click "Import in new Rascal Terminal")
 * - import this module and invoke helloWorld.
 */
 
void helloWorld() {
} 


/*
 * FizzBuzz (https://en.wikipedia.org/wiki/Fizz_buzz)
 * - implement imperatively
 * - implement as list-returning function
 */
 
void fizzBuzz() {
  for(int n <- [1 .. 100]) {
    if (n % 3 == 0 && n % 5 == 0) {
      println("FizzBuzz");
    } 
    if (n % 3 == 0 && !(n % 5 == 0) ){
      println("Fizz");
    }
    if (!(n % 3 == 0) && n % 5 == 0){
      println("Buzz");
    }
    if (!(n % 3 == 0) && !(n % 5 == 0)){
      println("<n>");
    }
  }
}

list[str] fizzBuzzlist() {
  return  for(int n <- [1 .. 100]) {
    if (n % 3 == 0 && n % 5 == 0) {
      append "FizzBuzz";
    } 
    if (n % 3 == 0 && !(n % 5 == 0) ){
      append "Fizz";
    }
    if (!(n % 3 == 0) && n % 5 == 0){
      append "Buzz";
    }
    if (!(n % 3 == 0) && !(n % 5 == 0)){
      append "<n>";
    }
  };
}

/*
 * Factorial
 * - first using ordinary recursion
 * - then using pattern-based dispatch 
 *  (complete the definition with a default case)
 */
 


int factorial(0) = 1;
int factorial(1) = 1;

default int factorial(int n) {
  return n * factorial(n - 1); // <- replace
}




/*
 * Comprehensions
 * - use println to see the result
 */
 
list[int] comprehensions() {

  // construct a list of squares of integer from 0 to 9 (use range [0..10])
  //return [i*i| i <- [0..10]];
  
  // same, but construct a set
  //return {i*i| i <- [0..10]};
  
  // same, but construct a map
  //return (i : i*i| i <- [0..10]);

  // construct a list of factorials from 0 to 9
  //return [factorial(i)| i <- [0..10]];

  // same, but now only for even numbers  
  return [factorial(i)| i <- [0..10], i % 2 == 0];
}
 

/*
 * Pattern matching
 * - fill in the blanks with pattern match expressions (using :=)
 */
 

void patternMatching() {
  str hello = "Hello World!";
  
  
 
  // print all splits of list
  list[int] aList = [1,2,3,4,5];
  for ([*L1, *L2] := aList) {
    println("<L1> and <L2>");
  }
  
  // print all partitions of a set
  set[int] aSet = {1,2,3,4,5};
  for ({*L1, *L2} := aSet) {
    println("<L1> and <L2>");
  } 

  

}  
 
 
 
/*
 * Trees
 * - complete the data type ColoredTree with
 *   constructors for binary red and black branches
 * - use the exampleTree() to test in the console
 */
 
data ColoredTree
  = leaf(int n);
  

ColoredTree exampleTree()
  =  red(black(leaf(1), red(leaf(2), leaf(3))),
              black(leaf(4), leaf(5)));  
  
  
// write a recursive function summing the leaves
// (use switch or pattern-based dispatch)

int sumLeaves(ColoredTree t) = 0; // TODO: Change this!

// same, but now with visit
int sumLeavesWithVisit(ColoredTree t) {
  return -1; // <- replace
}

// same, but now with a for loop and deep match
int sumLeavesWithFor(ColoredTree t) {
  return -1; // <- replace 
}

// same, but now with a reducer and deep match
// Reducer = ( <initial value> | <some expression with `it` | <generators> )
int sumLeavesWithReducer(ColoredTree t) = 0; // TODO: Change this!


// add 1 to all leaves; use visit + =>
ColoredTree inc1(ColoredTree t) {
  return leaf(-1); // <- replace 
}

// write a test for inc1, run from console using :test
test bool testInc1() = false;

// define a property for inc1, i.e. a boolean
// function that checks if one tree is inc1 of the other
// (without using inc1).
// Use switch on the tupling of t1 and t2 (`<t1, t2>`)
// or pattern based dispatch.
// Hint! The tree also needs to have the same shape!
bool isInc1(ColoredTree t1, ColoredTree t2) {
  return false; // <- replace
}
 
// write a randomized test for inc1 using the property
// again, execute using :test
test bool testInc1Randomized(ColoredTree t1) = false;


 

 
  
  
