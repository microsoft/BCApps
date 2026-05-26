// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using System.AI;

codeunit 6238 "E-Doc. MLLM VL Dates Tool" implements "AOAI Function"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetName(): Text
    begin
        exit('verify_dates');
    end;

    procedure GetPrompt(): JsonObject
    var
        ToolObj: JsonObject;
        FunctionObj: JsonObject;
        ParamsObj: JsonObject;
        PropsObj: JsonObject;
        PropObj: JsonObject;
        RequiredArr: JsonArray;
    begin
        PropObj.Add('type', 'string'); PropObj.Add('description', 'issue_date in YYYY-MM-DD format');
        PropsObj.Add('issue_date', PropObj); Clear(PropObj);
        PropObj.Add('type', 'string'); PropObj.Add('description', 'due_date in YYYY-MM-DD format, or empty string if not present');
        PropsObj.Add('due_date', PropObj);
        RequiredArr.Add('issue_date'); RequiredArr.Add('due_date');
        ParamsObj.Add('type', 'object'); ParamsObj.Add('properties', PropsObj); ParamsObj.Add('required', RequiredArr);
        FunctionObj.Add('name', GetName());
        FunctionObj.Add('description', 'Verify that issue_date and due_date are valid XML dates (YYYY-MM-DD), year 1900-2100, and due_date >= issue_date if present.');
        FunctionObj.Add('parameters', ParamsObj);
        ToolObj.Add('type', 'function'); ToolObj.Add('function', FunctionObj);
        exit(ToolObj);
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ResultObj: JsonObject;
        ErrorText: Text;
        IssueDate: Text;
        DueDate: Text;
        Token: JsonToken;
    begin
        if Arguments.Get('issue_date', Token) then IssueDate := Token.AsValue().AsText();
        if Arguments.Get('due_date', Token) then DueDate := Token.AsValue().AsText();
        if VerifyTools.VerifyDates(IssueDate, DueDate, ErrorText) then
            ResultObj.Add('pass', true)
        else begin
            ResultObj.Add('pass', false);
            ResultObj.Add('error', ErrorText);
        end;
        exit(ResultObj);
    end;
}
