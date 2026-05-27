// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using System.AI;

codeunit 6346 "E-Doc. MLLM Plan Submit Tool" implements "AOAI Function"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetName(): Text
    begin
        exit('submit_extraction');
    end;

    procedure GetPrompt(): JsonObject
    var
        ToolObj, FunctionObj, ParamsObj, PropsObj, PropObj : JsonObject;
        RequiredArr: JsonArray;
    begin
        PropObj.Add('type', 'string');
        PropObj.Add('description', 'The complete UBL JSON you have extracted. Must be the full document, not a snippet.');
        PropsObj.Add('json', PropObj);
        RequiredArr.Add('json');
        ParamsObj.Add('type', 'object'); ParamsObj.Add('properties', PropsObj); ParamsObj.Add('required', RequiredArr);
        FunctionObj.Add('name', GetName());
        FunctionObj.Add('description', 'Save the current complete UBL JSON extraction. Call this after Phase 2 and after every correction. The saved JSON is the final result — do not output JSON as a text response.');
        FunctionObj.Add('parameters', ParamsObj);
        ToolObj.Add('type', 'function'); ToolObj.Add('function', FunctionObj);
        exit(ToolObj);
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        ExtractionPlan: Codeunit "E-Doc. MLLM Extraction Plan";
        ResultObj: JsonObject;
        Token: JsonToken;
        Json, ResultText : Text;
    begin
        if Arguments.Get('json', Token) then
            if Token.IsObject() then
                Token.WriteTo(Json)  // model passed the JSON as an object — serialize it
            else
                Json := Token.AsValue().AsText();  // model passed it as a string — use as-is
        ExtractionPlan.SetCurrentJson(Json);
        ResultObj.Add('status', 'saved');
        ResultObj.Add('checklist', ExtractionPlan.GetChecklistJson());
        ResultObj.WriteTo(ResultText);
        exit(ResultText);
    end;
}
