module Transform

import Syntax;
import Resolve;
import AST;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (true && a && b) q1: "" int;
 *     if (true && a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
AForm flatten(AForm f) {
  list[AQuestion] questions= [];
  for(q <- f.questions) {
    questions = question + _flatten(q, boolExpr(true));
  }
  return form(f.name, questions); 
}

list[AQuestion] _flatten(AQuestion q, AExpr condition) {
  switch(q) {
    case question(id(name), text, varType) :
      return [ifThen(condition, [question(id(name), text, varType)])];
    
    case computedQuestion(id(name), text, varType, expr) :
      return [ifThen(condition, [computedQuestion(id(name), text, varType, expr)])];
    
    case ifThenElse(expr, ifQuestions, elseQuestions): {
      ret = [];
      for (ifq <- ifQuestions) {
        ret = ret + _flatten(ifq, andExpr(condition, expr));
      }
      for (elq <- elseQuestions) {
        ret = ret + _flatten(elq, andExpr(condition, notExpr(expr)));
      }
      return ret;
    }

    case ifThen(expr, ifQuestions): {
      ret = [];
      for (ifq <- ifQuestions) {
        ret = ret + _flatten(ifq, andExpr(condition, expr));
      }
      return ret;
    }

     default: throw "Unhandled question: <q>";
  }
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */

start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDef) {
  loc defLocation = useOrDef;
  for (<loc use, loc def> <- useDef) {
    if (use == useOrDef) {
      defLocation = def;
      break;
    }
  }

  set[loc] rename = {defLocation};

  // Collect uses and definitions associated with the identifier
  for (<loc useLoc, loc def> <- useDef) {
    if (def == defLocation) {
      rename += useLoc;
    }
  }
  
  // Traverse the AST and rename the identifier
  return visit(f) {
    case Id x => [Id]newName
      when x.src in rename
  };
}
 
 
 

