module Check

import AST;
import Resolve;
import Message; // see standard library

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// Helper function to convert AType - from AST - to corresponding environment type
Type mapATypeToType(AType atype) {
  switch (atype) {
    case boolean(): return tbool();
    case integer(): return tint();
    case string(): return tstr();
    default: return tunknown();
  }
}

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
  TEnv tenv = {}; 
  visit(f) {
    case question(AId id, str text, AType varType):
      tenv += {<id.src, id.name, text, mapATypeToType(varType)>};
    case computedQuestion(AId id, str text, AType varType, _):
      tenv += {<id.src, id.name, text, mapATypeToType(varType)>};
  }
  return tenv;
}

// Iterate over questions and expressions in the form and do checks
set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};

  for (/AQuestion q <- f) {
    msgs += check(q, tenv, useDef);
  }

  for (/AExpr expr <- f) {
    msgs += check(expr, tenv, useDef);
  }

  return msgs;
}

// check if the text -label- of a question has already been used
// and produce warning
set[Message] checkDuplicateLabels(AId id, str text, TEnv tenv) {
  set[Message] msgs = {};

  for (<loc lloc, str _, str l, _> <- tenv) {
    if (id.src != lloc && l == text) {
      msgs += { warning("Warning: duplicate labels!", id.src) };
      break; 
    }
  }

  return msgs;
}


// check if a question with the same name but different type has already been defined
// and produce error
set[Message] checkDiffTypes(AId id, AType varType, TEnv tenv) {
  set[Message] msgs = {};

  if (<loc lloc, str name, _, Type t> <- tenv) {
    if (t != mapATypeToType(varType) && id.src != lloc && name == id.name) {
      msgs += { error("Question with same name but different type already defined!", id.src) };
    }
  }

  return msgs;
}


// check if the type of a computed question matches the type of the expression and ensure it 
set[Message] checkComputedQType(AExpr expr, AType varType, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};

  Type exprType = typeOf(expr, tenv, useDef);
  if (exprType != mapATypeToType(varType)) {
    msgs += { error("Type of expression does not match declared type!", varType.src) };
  }

  return msgs;
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {}; 

  switch(q) {
    case question(AId id, str text, AType varType):
    {
      //msgs += checkDiffTypes(id, varType, tenv) + checkDuplicateLabels(id, text, tenv);
      for (<loc lloc, str _, str l, _> <- tenv) {
        if (id.src != lloc && l == text) {
          msgs += { warning("Warning: duplicate labels!", q.src) };
          break; 
        }
      }
      msgs += checkDiffTypes(id, varType, tenv);
    }

    case computedQuestion(AId id, str text, AType varType, AExpr expr):
    {
      msgs += checkDiffTypes(id, varType, tenv) + checkDuplicateLabels(id, text, tenv) + checkComputedQType(expr, varType, tenv, useDef);
    }

    case ifThenElse(AExpr expr, list[AQuestion] ifBlocks, list[AQuestion] elseBlocks):
    {
      msgs += check(expr, tenv, useDef);
      for (AQuestion ifBlock <- ifBlocks) {
        msgs += check(ifBlock, tenv, useDef);
      }
      for (AQuestion elseBlock <- elseBlocks) {
        msgs += check(elseBlock, tenv, useDef);
      }
    }

    case ifThen(AExpr expr, list[AQuestion] ifBlocks):
    {
      msgs += check(expr, tenv, useDef);
      for (ifBlock <- ifBlocks) {
        msgs += check(ifBlock, tenv, useDef);
      }
    }
  }

  return msgs;
}

str typeString(Type t) {
    switch (t) {
        case tint(): return "int";
        case tbool(): return "bool";
        case tstr(): return "string";
        default: return "unknown";
    }
}

set[Message] checkOperandsType(AExpr left, AExpr right,  Type expectedType, TEnv tenv, UseDef useDef) {
    set[Message] msgs = {};

    Type leftType = typeOf(left, tenv, useDef);
    Type rightType = typeOf(right, tenv, useDef);

    if (leftType != expectedType) {
      msgs +=  {error("Error: Operation expects operands of type <typeString(rightType)>!" , left.src)};
    } 

    if (rightType != expectedType) {
      msgs += {error("Error: Operation expects operands of type <typeString(leftType)>!" , right.src)};
    }

    return msgs;
}

set[Message] checkOperandType(AExpr expr, Type expectedType, TEnv tenv, UseDef useDef, str context) {
    Type exprType = typeOf(expr, tenv, useDef);
    if (exprType != expectedType) {
        return {error("Error: " + context + " expects operands of type " + typeString(expectedType) + "!", expr.src)};
    }
    return {};
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch (e) {
    case ref(AId x):
      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };

    case bracketExpr(AExpr x):
      msgs += check(x, tenv, useDef);

      // Arithmetic expressions
    case mulExpr(AExpr left, AExpr right):
      msgs += checkOperandsType(left, right, tint(), tenv, useDef);
    case divExpr(AExpr left, AExpr right):
      msgs += checkOperandsType(left, right, tint(), tenv, useDef);
    case addExpr(AExpr left, AExpr right):
      msgs += checkOperandsType(left, right, tint(), tenv, useDef);
    case subExpr(AExpr left, AExpr right):
      msgs += checkOperandsType(left, right, tint(), tenv, useDef);

    // Boolean expressions
    case notExpr(AExpr not):
      msgs += checkOperandType(not, tbool(), tenv, useDef, "Boolean operation");
    case andExpr(AExpr left, AExpr right):
      checkOperandsType(left, right, tbool(), tenv, useDef);
    case orExpr(AExpr left, AExpr right):
      checkOperandsType(left, right, tbool(), tenv, useDef);

    // Comparison expressions
    case eqExpr(AExpr left, AExpr right):
      msgs += checkOperandsType(left, right, tint(), tenv, useDef);
    case neqExpr(AExpr left, AExpr right):
      msgs += checkOperandsType(left, right, tint(), tenv, useDef);
    case htExpr(AExpr left, AExpr right):
      msgs += checkOperandsType(left, right, tint(), tenv, useDef);
    case hteExpr(AExpr left, AExpr right):
      msgs += checkOperandsType(left, right, tint(), tenv, useDef);
    case ltExpr(AExpr left, AExpr right):
      msgs += checkOperandsType(left, right, tint(), tenv, useDef);
    case lteExpr(AExpr left, AExpr right):
      msgs += checkOperandsType(left, right, tint(), tenv, useDef);

    //default : {};
  }
  return msgs;
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(_, src = loc u)):  
      if (<u, loc d> <- useDef, <d, _, _, Type t> <- tenv) {
        return t;
      }
    case boolExpr(_): return tbool();
    case intExpr(_): return tint();
    case stringExpr(_): return tstr();
    case bracketExpr(AExpr expr): return typeOf(expr, tenv, useDef);

    case mulExpr(_, _): return tint();
    case divExpr(_, _): return tint();
    case addExpr(_, _): return tint();
    case subExpr(_, _): return tint();

    case notExpr(_): return tbool();
    case andExpr(_, _): return tbool();
    case orExpr(_, _): return tbool();
    case neqExpr(_, _): return tbool();
    case eqExpr(_, _): return tbool();
    case htExpr(_, _): return tbool();
    case hteExpr(_, _): return tbool();
    case ltExpr(_, _): return tbool();
    case lteExpr(_, _): return tbool();
    //default: return tunknown();
  }
  return tunknown(); 
}

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(id(_, src = loc u)), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
 

