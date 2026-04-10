namespace System.Test.AI;

using System.AI;

codeunit 132687 "Test Function 1" implements "AOAI Function"
{
    procedure GetPrompt() Function: JsonObject;
    begin
        Function.ReadFrom('{"type": "function", "function": {"name": "test_function_1", "parameters": {"type": "object", "properties": {"message": {"type": "string", "description": "The input from user."}}}}}');
    end;

    procedure Execute(Arguments: JsonObject): Variant
    begin
        exit('This is test function 1');
    end;

    procedure GetName(): Text
    begin
        exit('test_function_1');
    end;
}