module Eval

import AST;
import Resolve;

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
    default: return vstr("");  // Default case to handle unexpected types
  }
}
  
// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
  VEnv init = ();
  for (AQuestion q <- f.questions) {
    init = addDefaultValues(q, init);
  } 
  return init;
}

VEnv addDefaultValues(AQuestion q, VEnv venv) {
  switch (q) {
    case question(AId id, _, AType t):
      venv[id.name] = defaultValue(t);
    case computedQuestion(AId id, _, AType t, _):
      venv[id.name] = defaultValue(t);
    case ifThen(_, list[AQuestion] ifqs):
    {
      for (AQuestion ifq <- ifqs) {
          venv = addDefaultValues(ifq, venv);
      }
    }
    case ifThenElse(_, list[AQuestion] ifqs, list[AQuestion] elseqs):
    {
      for (AQuestion ifq <- ifqs) {
          venv = addDefaultValues(ifq, venv);
      }
      for (AQuestion elseq <- elseqs) { // Only for ifThenElse
          venv = addDefaultValues(elseq, venv);
      }
    }
  }
  return venv;
}

// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  for(/AQuestion q <- f) {
    venv += eval(q, inp, venv);
  }
  return venv; 
}

// evaluate conditions for branching,
// evaluate inp and computed questions to return updated VEnv
VEnv eval(AQuestion q, Input inp, VEnv venv) {
  switch(q) {
    case question(AId id, str label, AType t):
      return venv;
    case computedQuestion(AId id, str label, AType t, AExpr e):
    {
      venv[id.name] = eval(e, venv);
      return venv;
    }
    case ifThen(AExpr e, list[AQuestion] ifqs):
    {
      if (eval(e, venv) == vbool(true)) {
        for (AQuestion ifq <- ifqs) {
          venv += eval(ifq, inp, venv);
        }
      }
      return venv;
    }
    case ifThenElse(AExpr e, list[AQuestion] ifqs, list[AQuestion] elseqs):
    {
      if (eval(e, venv) == vbool(true)) {
        for (AQuestion ifq <- ifqs) {
          venv += eval(ifq, inp, venv);
        }
      }
      else {
        for (AQuestion elseq <- elseqs) {
          venv += eval(elseq, inp, venv);
        }
      }
      return venv;
    }
  }
  return (); 
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(id(str x)): return venv[x];
    
    // etc.
    
    default: throw "Unsupported expression <e>";
  }
}