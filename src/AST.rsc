module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(AId name, list[AQuestion] questions)
  ; 

data AQuestion(loc src = |tmp:///|)
  = question(AId name, str text, AType varType) |
   computedQuestion(AId name, str text, AType varType, AExpr expr) |
   ifThenElse(AExpr expr, list[AQuestion] ifBlock, list[AQuestion] elseBlock) |
   ifThen(AExpr expr, list[AQuestion] ifBlock)
  ; 

data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | boolExpr(bool boolean)
  | intExpr(int integer)
  | stringExpr(str string)
  | bracketExpr(AExpr expr)
  
  | mulExpr(AExpr left, AExpr right)
  | divExpr(AExpr left, AExpr right)
  | addExpr(AExpr left, AExpr right)
  | subExpr(AExpr left, AExpr right)
  
  | notExpr(AExpr not)
  | andExpr(AExpr left, AExpr right)
  | orExpr(AExpr left, AExpr right)
  | neqExpr(AExpr left, AExpr right)
  | eqExpr(AExpr left, AExpr right)
  | htExpr(AExpr left, AExpr right)
  | hteExpr(AExpr left, AExpr right)
  | ltExpr(AExpr left, AExpr right)
  | lteExpr(AExpr left, AExpr right)
  ;


data AId(loc src = |tmp:///|)
  = id(str name);

data AType(loc src = |tmp:///|)
  = boolean()
  | integer()
  | string()
  ;