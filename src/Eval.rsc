module Eval

import AST;
import Resolve;
import CST2AST;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.

// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// this is only for testing
Value Value_from_value(value v) {
  switch (v) {
    case int n: return vint(n);
    case bool b: return vbool(b);
    case str s: return vstr(s);
  }
    throw "Unsupported value <v>";
}

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);

Value defaultValue(AType t) {
  switch (t) {
    case integer(): return vint(0);
    case boolean(): return vbool(false);
    case string(): return vstr("");
    default: throw "Unsupported type <t>";
  }
}
  
// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
  VEnv ienv = ();

  for (/AQuestion q <- f.questions) {
    switch(q) {
      case question(AId id, _, AType t):
        ienv += (id.name: defaultValue(t));
      case computedQuestion(AId id, _, AType t, _):
        ienv += (id.name: defaultValue(t));
    }
  } 

  return ienv;
}

// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  venv[inp.question] = inp.\value;
  for(/AQuestion q <- f.questions) {
    venv = eval(q, inp, venv);
  }
  return venv; 
}

// evaluate conditions for branching,
// evaluate inp and computed questions to return updated VEnv
VEnv eval(AQuestion q, Input inp, VEnv venv) {
  switch(q) {
    case question(AId id, str _, AType _): 
      if (id.name == inp.question) venv[id.name] = inp.\value;
    
    case computedQuestion(AId id, str _, AType _, AExpr e):
      venv[id.name] = eval(e, venv);

    case ifThen(AExpr e, list[AQuestion] ifBlock): {
      if (eval(e, venv).b) {
        for (AQuestion ifQ <- ifBlock) {
          venv = eval(ifQ, inp, venv);
        }
      }
    }

    case ifThenElse(AExpr e, list[AQuestion] ifBlock, list[AQuestion] elseBlock): {
      if (eval(e, venv).b) {
        for (AQuestion ifQ <- ifBlock) {
          venv = eval(ifQ, inp, venv);
        }
      } else {
        for (AQuestion ifQ <- elseBlock) {
          venv = eval(ifQ, inp, venv);
        }
      }
    }
  }
  return venv;
}

Value eval(AExpr e, VEnv venv) {
    switch (e) {
        case ref(id(str x)): 
            return venv[x];
        case stringExpr(str name): 
            return vstr(name);
        case intExpr(int vlue): 
            return vint(vlue);
        case boolExpr(bool boolean): 
            return vbool(boolean);
        case notExpr(AExpr expr): 
            return vbool(!eval(expr, venv).b);

        case mulExpr(AExpr lhs, AExpr rhs): 
            return vint(eval(lhs, venv).n * eval(rhs,venv).n);
        case divExpr(AExpr lhs, AExpr rhs): 
            return vint(eval(lhs, venv).n / eval(rhs,venv).n);
        case addExpr(AExpr lhs, AExpr rhs): 
            return vint(eval(lhs, venv).n + eval(rhs,venv).n);
        case subExpr(AExpr lhs, AExpr rhs): 
            return vint(eval(lhs, venv).n - eval(rhs,venv).n);
        
        case ltExpr(AExpr lhs, AExpr rhs): 
            return vbool(eval(lhs, venv).n < eval(rhs, venv).n);
        case lteExpr(AExpr lhs, AExpr rhs): 
            return vbool(eval(lhs, venv).n <= eval(rhs, venv).n);
        case htExpr(AExpr lhs, AExpr rhs): 
            return vbool(eval(lhs, venv).n > eval(rhs, venv).n);
        case hteExpr(AExpr lhs, AExpr rhs): 
            return vbool(eval(lhs, venv).n >= eval(rhs, venv).n);
        case eqExpr(AExpr lhs, AExpr rhs): 
            return vbool(eval(lhs, venv) == eval(rhs, venv));
        case neqExpr(AExpr lhs, AExpr rhs): 
            return vbool(eval(lhs, venv) != eval(rhs, venv));
        case andExpr(AExpr lhs, AExpr rhs): 
            return vbool(eval(lhs, venv).b &&  eval(rhs, venv).b);
        case orExpr(AExpr lhs, AExpr rhs): 
            return vbool(eval(lhs, venv).b ||  eval(rhs, venv).b);
        default: 
            throw "Unsupported expression <e>";
    }
}