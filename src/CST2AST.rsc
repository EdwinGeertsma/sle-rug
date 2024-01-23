module CST2AST

import Syntax;
import AST;
import ParseTree;

import util::Math;
import String;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form

  switch (f) {
    case (Form)`form <Id name> { <Question* questions> }`:
      return form(id("<name>", src=name.src), [cst2ast(q) | Question q <- questions], src=f.src);

    default: throw "Unhandled form: <f>";
  }
}

default AQuestion cst2ast(Question q) {
  switch(q) {
    case (Question)`<Str text> <Id name> : <Type varType> = <Expr expr>`: 
      return computedQuestion(id("<name>", src=name.src), "<text>", cst2ast(varType),  cst2ast(expr), src=q.src);

    case (Question)`<Str text> <Id name> : <Type varType>`:
      return question(id("<name>", src=name.src), "<text>", cst2ast(varType), src=q.src);

    case (Question)`if ( <Expr condition> ) { <Question* ifQuestions> } else { <Question* elseQuestions> }`: 
      return ifThenElse(cst2ast(condition), [cst2ast(x) | x <- ifQuestions], [cst2ast(x) | x <- elseQuestions], src=q.src);

    case (Question)`if ( <Expr condition> ) { <Question* questions> }`:
      return ifThen(cst2ast(condition), [cst2ast(x) | x <- questions], src=q.src);

    default: throw "Unhandled Question: <q>";
  }
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: return ref(id("<x>", src=x.src), src=x.src);
    case (Expr)`<Bool x>`: return boolExpr(fromString("<x>"), src=x.src);
    case (Expr)`<Int x>`: return intExpr(toInt("<x>"), src=x.src);
    case (Expr)`<Str x>`: return stringExpr("<x>", src=x.src);
    case (Expr)`(<Expr x>)`: return cst2ast(x);

    case (Expr)`<Expr left> + <Expr right>`: return addExpr(cst2ast(left), cst2ast(right), src=e.src); 
    case (Expr)`<Expr left> - <Expr right>`: return subExpr(cst2ast(left), cst2ast(right), src=e.src); 
    case (Expr)`<Expr left> * <Expr right>`: return mulExpr(cst2ast(left), cst2ast(right), src=e.src); 
    case (Expr)`<Expr left> / <Expr right>`: return divExpr(cst2ast(left), cst2ast(right), src=e.src); 

    case (Expr)`!<Expr not>`: return notExpr(cst2ast(not), src=e.src); 
    case (Expr)`<Expr left> \< <Expr right>`: return ltExpr(cst2ast(left), cst2ast(right), src=e.src);
    case (Expr)`<Expr left> \> <Expr right>`: return gtExpr(cst2ast(left), cst2ast(right), src=e.src);
    case (Expr)`<Expr left> \<= <Expr right>`: return lteExpr(cst2ast(left), cst2ast(right), src=e.src);
    case (Expr)`<Expr left> \>= <Expr right>`: return gteExpr(cst2ast(left), cst2ast(right), src=e.src);
    case (Expr)`<Expr left> == <Expr right>`: return eqExpr(cst2ast(left), cst2ast(right), src=e.src); 
    case (Expr)`<Expr left> != <Expr right>`: return neqExpr(cst2ast(left), cst2ast(right), src=e.src);
    
    case (Expr)`<Expr left> && <Expr right>`: return andExpr(cst2ast(left), cst2ast(right), src=e.src);
    case (Expr)`<Expr left> || <Expr right>`: return orExpr(cst2ast(left), cst2ast(right), src=e.src);
    default: throw "Unhandled expression: <e>";
  }
}

default AType cst2ast(Type t) {
  switch(t) {
     case (Type)`boolean`: return boolean(src=t.src);
     case (Type)`integer`: return integer(src=t.src);
     case (Type)`string`: return string(src=t.src);
     default: throw "Unkown type: <t>";
  }
}
