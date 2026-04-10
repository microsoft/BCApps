namespace System.Test.AI;

using System.AI;

codeunit 132689 "Bad Test Function 1" implements "AOAI Function"
{
    procedure GetPrompt() Function: JsonObject;
    begin
        Function.ReadFrom('{"function": {"name": "bad_test_function_1", "parameters": {"type": "object", "properties": {"message": {"type": "string", "description": "The input from user."}}}}}');
    end;

    procedure Execute(Arguments: JsonObject): Variant
    begin
        exit('This is bad test function 1');
    end;

    procedure GetName(): Text
    begin
        exit('bad_test_function_1');
    end;
}