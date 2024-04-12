namespace System.Test.AI;

using System.AI;

codeunit 132688 "Test Function 2" implements "AOAI Function"
{
    procedure GetPrompt() Function: JsonObject;
    begin
        Function.ReadFrom('{"type": "function", "function": {"name": "test_function_2", "parameters": {"type": "object", "properties": {"message": {"type": "string", "description": "The input from user."}}}}}');
    end;

    procedure Execute(Arguments: JsonObject): Variant
    begin
        exit('This is test function 2');
    end;

    procedure GetName(): Text
    begin
        exit('test_function_2');
    end;
}