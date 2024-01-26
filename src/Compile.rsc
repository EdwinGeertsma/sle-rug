module Compile

import AST;
import Resolve;
import IO;
import lang::html::AST; // see standard library
import lang::html::IO;
import String;
import vis::Basic;

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTMLElement type and the `str writeHTMLString(HTMLElement x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, writeHTMLString(form2html(f)));
}

HTMLElement form2html(AForm f) {
  return html([]);
}

str genInits() 
  = "import { useState } from \"react\";

function App() {";

str genTypeVarInit(str name, AType varType) {
  switch(varType) {
    case boolean(): return name + ": false";
    case integer(): return name + ": 0";
    case string(): return name + ": \"\"";
    default: throw "Unhandled Type: <varType>";
  }
}

str genUseState(AForm f) {
  str ret = "
  const [formData, setFormData] = useState({";

  for (/AQuestion q <- f) {
    switch(q) {
      case question(AId id, text, varType): {
          ret += genTypeVarInit(id.name, varType) + ", ";
      }
      case computedQuestion(AId id, text, varType, expr): {
          ret += genTypeVarInit(id.name, varType) + ", ";
      }
    }
  }
  ret = replaceLast(ret, ", ", "");
  ret += "});
";
  return ret;
}

str genOnChange(AForm f) {
  str ret = "
  const handleChange = (event) =\> {
    const {name, value} = event.target;
    setFormData((prevFormData) =\> ({...prevFormData, [name]: value}));
  };

  const handleChangeBool = (event) =\> {
        const {name, value} = event.target;
        setFormData((prevFormData) =\> ({...prevFormData, [name]: event.target.checked}));
  };
";
  return ret;
}

str genHTMLQuestionType(AId id, AType varType) {
  switch(varType) {
    case boolean(): return "\<input type=\"checkbox\" name=\"<id.name>\" checked={formData.<id.name>} onChange={handleChangeBool}/\>\n";
    case integer(): return "\<input type=\"number\" id=\"<id.name>\" name=\"<id.name>\" value={formData.name} onChange={handleChange}/\>\n";
    case string(): return "\<input id=\"<id.name>\" name=\"<id.name>\" value={formData.name} onChange={handleChange}/\>\n";
    default: throw "Unhandled Type: <varType>";
  }
}


str genHTMLQuestion(AId id, str text, AType varType) {
  str ret = "\<div\>\n";
  ret += "\<label\><text>\</label\>\n";
  ret += genHTMLQuestionType(id, varType);
  ret += "\</div\>\n";
  return ret;
}

str genHTMLCompQuestionType(AExpr expr) {
  switch (expr) {
    case ref(id):
      return "formData.<id.name>";
    case boolExpr(bool boolean): {
      if (boolean) {
        return "true";
      } else {
        return "false";
      }
    }
    case intExpr(int number): {
      return "<number>";
    }
    case stringExpr(str s): {
      return "\"" + s + "\"";
    }
    case bracketExpr(AExpr expr): {
      return "(" + genHTMLCompQuestionType(expr) + ")";
    }
    case mulExpr(AExpr left, AExpr right): {
      return genHTMLCompQuestionType(left) + "*" + genHTMLCompQuestionType(right);
    }
    case divExpr(AExpr left, AExpr right): {
      return genHTMLCompQuestionType(left) + "/" + genHTMLCompQuestionType(right);
    }
    case addExpr(AExpr left, AExpr right): {
      return genHTMLCompQuestionType(left) + "+" + genHTMLCompQuestionType(right);
    }
    case subExpr(AExpr left, AExpr right): {
      return genHTMLCompQuestionType(left) + "-" + genHTMLCompQuestionType(right);
    }
    case notExpr(AExpr expr): {
      return "!" + genHTMLCompQuestionType(expr);
    }
    case andExpr(AExpr left, AExpr right): {
      return genHTMLCompQuestionType(left) + "&&" + genHTMLCompQuestionType(right);
    }
    case orExpr(AExpr left, AExpr right): {
      return genHTMLCompQuestionType(left) + "||" + genHTMLCompQuestionType(right);
    }
    case neqExpr(AExpr left, AExpr right): {
      return genHTMLCompQuestionType(left) + "!=" + genHTMLCompQuestionType(right);
    }
    case eqExpr(AExpr left, AExpr right): {
      return genHTMLCompQuestionType(left) + "==" + genHTMLCompQuestionType(right);
    }
    case htExpr(AExpr left, AExpr right): {
      return genHTMLCompQuestionType(left) + "\>" + genHTMLCompQuestionType(right);
    }
    case hteExpr(AExpr left, AExpr right): {
      return genHTMLCompQuestionType(left) + "\>=" + genHTMLCompQuestionType(right);
    }
    case ltExpr(AExpr left, AExpr right): {
      return genHTMLCompQuestionType(left) + "\<" + genHTMLCompQuestionType(right);
    }
    case lteExpr(AExpr left, AExpr right): {
      return genHTMLCompQuestionType(left) + "\<=" + genHTMLCompQuestionType(right);
    }
    default: throw "Unhandled Expr: <expr>";
  }
}

str genHTMLCompQuestion(AId id, str text, AType varType, AExpr expr) {
  str ret = "\<div\>\n";
  ret += "\<label\><text> {formData.<id.name> = <genHTMLCompQuestionType(expr)>}\</label\>\n";
  ret += "\</div\>\n";
  return ret;
}

str genHTMLforQuestion(AQuestion q) {
  str ret = "";
  switch(q) {
      case question(AId id, text, varType): {
          ret += genHTMLQuestion(id, text, varType);
      }
      case computedQuestion(AId id, text, varType, expr): {
          ret += genHTMLCompQuestion(id, text, varType, expr);
      }
      case ifThen(expr, questions): {
        ret += genHTMLIf(expr, questions);
      }
      case ifThenElse(expr, ifQuestions, elseQuestions): {
        ret += genHTMLIf(expr, ifQuestions);
        ret += genHTMLIf(notExpr(bracketExpr(expr)), elseQuestions);
      }
    }
  return ret;
}

str genHTMLIf(AExpr expr, list[AQuestion] questions) {
  str ret = "{ ";
  ret += genHTMLCompQuestionType(expr);
  ret += "&&\n(\<\>";
  for (q <- questions) {
    ret += genHTMLforQuestion(q);
  }
  ret +=  "\</\>)}\n";
  return ret;
}


str genHTML(AForm f) {
  str ret = "\<form\>\n";
  list[AQuestion] qlist = f.questions;
  for (q <- qlist) {
    ret += genHTMLforQuestion(q);
  }
  ret += "\</form\>\n";
  return ret;
}

str genEnding()
 = "  );
}

export default App;";

str form2js(AForm f) {
  str ret = "";
  ret += genInits();
  ret += genUseState(f);
  ret += genOnChange(f);
  ret += "\n\treturn (\n";
  ret += genHTML(f);
  ret += genEnding();
  return ret;
}
