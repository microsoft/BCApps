// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using System.AI;

codeunit 6344 "E-Doc. MLLM Plan Mark Tool" implements "AOAI Function"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetName(): Text
    begin
        exit('mark_item');
    end;

    procedure GetPrompt(): JsonObject
    var
        ToolObj, FunctionObj, ParamsObj, PropsObj, PropObj : JsonObject;
        RequiredArr: JsonArray;
    begin
        PropObj.Add('type', 'string');
        PropObj.Add('description', 'The checklist item id to mark (e.g. "verify_line_1", "verify_invoice_totals")');
        PropsObj.Add('item_id', PropObj);
        Clear(PropObj);
        PropObj.Add('type', 'boolean');
        PropObj.Add('description', 'true if the verification passed, false if it failed');
        PropsObj.Add('passed', PropObj);
        Clear(PropObj);
        PropObj.Add('type', 'string');
        PropObj.Add('description', 'Error message if passed=false, empty string if passed=true');
        PropsObj.Add('error', PropObj);
        RequiredArr.Add('item_id');
        RequiredArr.Add('passed');
        RequiredArr.Add('error');
        ParamsObj.Add('type', 'object');
        ParamsObj.Add('properties', PropsObj);
        ParamsObj.Add('required', RequiredArr);
        FunctionObj.Add('name', GetName());
        FunctionObj.Add('description', 'Record the result of a verification on the checklist. Call this after every verify tool call to mark the item as passed or failed.');
        FunctionObj.Add('parameters', ParamsObj);
        ToolObj.Add('type', 'function');
        ToolObj.Add('function', FunctionObj);
        exit(ToolObj);
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        ExtractionPlan: Codeunit "E-Doc. MLLM Extraction Plan";
        ResultObj: JsonObject;
        Token: JsonToken;
        ItemId, ErrorMsg, ResultText : Text;
        Passed: Boolean;
    begin
        if Arguments.Get('item_id', Token) then ItemId := Token.AsValue().AsText();
        if Arguments.Get('passed', Token) then Passed := Token.AsValue().AsBoolean();
        if Arguments.Get('error', Token) then ErrorMsg := Token.AsValue().AsText();

        ExtractionPlan.MarkItem(ItemId, Passed, ErrorMsg);

        ResultObj.Add('item_id', ItemId);
        if Passed then
            ResultObj.Add('status', 'passed')
        else
            ResultObj.Add('status', 'failed');
        ResultObj.WriteTo(ResultText);
        exit(ResultText);
    end;
}
