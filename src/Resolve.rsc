module Resolve

import AST;
import IO;

/*
 * Name resolution for QL
 */ 


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

alias UseDef = rel[loc use, loc def];

// the reference graph
alias RefGraph = tuple[
  Use uses, 
  Def defs, 
  UseDef useDef
]; 

RefGraph resolve(AForm f) = <us, ds, us o ds>
  when Use us := uses(f), Def ds := defs(f);

Use uses(AForm f) {
  Use uses = {};
  for (/AExpr expr <- f) {
    if (/AId id := expr)
      uses = uses + <id.src, id.name>;
  }
  return uses; 
}

Def defs(AForm f) {
  Def defs = {};
  for (/AQuestion question <- f) {
    switch(question) {
      case question(AId id, _, _):
        defs = defs + {<id.name, id.src>};
      case computedQuestion(AId id, _, _, _):
        defs = defs + {<id.name, id.src>};    
    }
  }
  return defs; 
}