module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id name "{" Question* questions "}"; 

// TODO: question, computed question, block, if-then-else, if-then
syntax Question 
  = Str Id name ":" Type |                  // Question
    Str Id name ":" Type "=" Expr  |        // Computed Question
    "if" "(" Expr ")" Block "else" Block |  // If-Then-Else
    "if" "(" Expr ")" Block;                // If-Then

syntax Block 
 = "{" Question* questions "}";


// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = Id \ "true" \ "false" // true/false are reserved keywords.
  | Bool
  | Int
  | Str
  | bracket "(" Expr ")" 
  > left Expr "||" Expr
  > left Expr "&&" Expr
  > left ( Expr "!=" Expr | Expr "==" Expr)
  > left ( Expr "\<" Expr | Expr "\>" Expr | Expr "\<=" Expr| Expr "\>=" Expr)
  > left ( Expr "*" Expr | Expr "/" Expr )
  > left ( Expr "+" Expr | Expr "-" Expr ) 
  ;
  
syntax Type 
 =  "string" |
    "integer" |
    "boolean";

lexical Str = "\"" (![\"])* "\"";

lexical Int 
  = [0-9]+;

lexical Bool 
  = "true" |
    "false ";



// import IDE; import ParesTree; import Syntax;
// gl :)