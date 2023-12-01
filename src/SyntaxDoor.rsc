module SyntaxDoor

extend lang::std::Layout;

start syntax Machine =
    "machine"  Ident State*;

syntax Trans
 = "state" Ident Trans* "end";

syntax State  
 = Ident "=\>" Ident;

lexical Ident
    =[a-zA-Z][a-zA-Z0-9]* !>> [a-zA-Z0-9];