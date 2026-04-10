namespace System.Test.AI;

using System.AI;

codeunit 132690 "Bad Test Function 2" implements "AOAI Function"
{
    procedure GetPrompt() Function: JsonObject;
    begin
        Function.ReadFrom('{"type": "function"}');
    end;

    procedure Execute(Arguments: JsonObject): Variant
    begin
        exit('This is bad test function 2');
    end;

    procedure GetName(): Text
    begin
        exit('bad_test_function_2');
    end;
}