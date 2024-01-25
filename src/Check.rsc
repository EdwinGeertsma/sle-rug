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

// Iterate over questions in the form and do checks
set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};

  for (/AQuestion q := f) {
    msgs += check(q, tenv, useDef);
  }

  return msgs;
}

// check if the text -label- of a question has already been used
// and produce warning
set[Message] checkDuplicateLabels(AId id, str text, TEnv tenv) {
  set[Message] msgs = {};

  for (<_, _, l, _> <- tenv) {
    if (l == text) {
      msgs += { warning("Warning! Duplicate labels!", id.src) };
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
      msgs += checkDiffTypes(id, varType, tenv) + checkDuplicateLabels(id, text, tenv);
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
    {
      msgs += checkArithmeticOperand(left, tenv, useDef);
      msgs += checkArithmeticOperand(right, tenv, useDef);
    }
    case divExpr(AExpr left, AExpr right):
    {
      msgs += checkArithmeticOperand(left, tenv, useDef);
      msgs += checkArithmeticOperand(right, tenv, useDef);
    }
    case addExpr(AExpr left, AExpr right):
    {
      msgs += checkArithmeticOperand(left, tenv, useDef);
      msgs += checkArithmeticOperand(right, tenv, useDef);
    }
    case subExpr(AExpr left, AExpr right):
    {
      msgs += checkArithmeticOperand(left, tenv, useDef);
      msgs += checkArithmeticOperand(right, tenv, useDef);
    }

    // Boolean expressions
    case notExpr(AExpr not):
    {
      msgs += checkBooleanOperand(not, tenv, useDef);
    }
    case andExpr(AExpr left, AExpr right):
    {
      msgs += checkBooleanOperand(left, tenv, useDef);
      msgs += checkBooleanOperand(right, tenv, useDef);
    }
    case orExpr(AExpr left, AExpr right):
    {
      msgs += checkBooleanOperand(left, tenv, useDef);
      msgs += checkBooleanOperand(right, tenv, useDef);
    }

    // Comparison expressions
    case eqExpr(AExpr left, AExpr right):
      msgs += checkComparisonOperands(left, right, tenv, useDef);
    case neqExpr(AExpr left, AExpr right):
      msgs += checkComparisonOperands(left, right, tenv, useDef);
    case htExpr(AExpr left, AExpr right):
      msgs += checkComparisonOperands(left, right, tenv, useDef);
    case hteExpr(AExpr left, AExpr right):
      msgs += checkComparisonOperands(left, right, tenv, useDef);
    case ltExpr(AExpr left, AExpr right):
      msgs += checkComparisonOperands(left, right, tenv, useDef);
    case lteExpr(AExpr left, AExpr right):
        msgs += checkComparisonOperands(left, right, tenv, useDef);

    default : {};
  }
  return msgs;
}

// Helper functions for different types of expressions
set[Message] checkArithmeticOperand(AExpr expr, TEnv tenv, UseDef useDef) {
    return checkInt(typeOf(expr, tenv, useDef)) ? {} : {error("Error: Expected type is int!", expr.src)};
}

set[Message] checkBooleanOperand(AExpr expr, TEnv tenv, UseDef useDef) {
    return checkBool(typeOf(expr, tenv, useDef)) ? {} : {error("Error: Expected type is bool!", expr.src)};
}

set[Message] checkComparisonOperands(AExpr left, AExpr right, TEnv tenv, UseDef useDef) {
    return typeOf(left, tenv, useDef) == typeOf(right, tenv, useDef) ? {} : {error("Error: Operands for comparison do not match!", left.src)};
}

bool checkBool(Type t) {
    return t == tbool() || t == tunknown();
}

bool checkInt(Type t) {
    return t == tint() || t == tunknown();
}


Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(_, src = loc u)):  
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
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
    default: return tunknown();
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
 
 

