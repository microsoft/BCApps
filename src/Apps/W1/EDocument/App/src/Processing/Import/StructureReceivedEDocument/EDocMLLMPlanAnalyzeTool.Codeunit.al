// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using System.AI;

codeunit 6320 "E-Doc. MLLM Plan Analyze Tool" implements "AOAI Function"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetName(): Text
    begin
        exit('analyze_invoice');
    end;

    procedure GetPrompt(): JsonObject
    var
        ToolObj, FunctionObj, ParamsObj, PropsObj, PropObj : JsonObject;
        ItemsObj: JsonObject;
        RequiredArr: JsonArray;
    begin
        PropObj.Add('type', 'string'); PropObj.Add('description', 'Document type (invoice, credit_memo, etc.)');
        PropsObj.Add('doc_type', PropObj); Clear(PropObj);
        PropObj.Add('type', 'string'); PropObj.Add('description', 'Document language code (e.g. sv, en, de)');
        PropsObj.Add('language', PropObj); Clear(PropObj);
        PropObj.Add('type', 'string'); PropObj.Add('description', 'Decimal separator used in this document (. or ,)');
        PropsObj.Add('decimal_sep', PropObj); Clear(PropObj);
        PropObj.Add('type', 'string'); PropObj.Add('description', 'Thousands separator used in this document (space, . or ,)');
        PropsObj.Add('thousands_sep', PropObj); Clear(PropObj);
        PropObj.Add('type', 'string'); PropObj.Add('description', 'Description of each line item column and its role (e.g. which column is gross price, discount %, net price, quantity, line total)');
        PropsObj.Add('line_columns', PropObj); Clear(PropObj);
        PropObj.Add('type', 'string'); PropObj.Add('description', 'Any other observations about the document layout or unusual features');
        PropsObj.Add('notes', PropObj); Clear(PropObj);
        ItemsObj.Add('type', 'string');
        PropObj.Add('type', 'array'); PropObj.Add('items', ItemsObj); PropObj.Add('description', 'IDs of all invoice lines visible on the document (e.g. ["1","2","3"])');
        PropsObj.Add('line_ids', PropObj);
        RequiredArr.Add('doc_type'); RequiredArr.Add('language'); RequiredArr.Add('decimal_sep');
        RequiredArr.Add('thousands_sep'); RequiredArr.Add('line_columns'); RequiredArr.Add('line_ids');
        ParamsObj.Add('type', 'object'); ParamsObj.Add('properties', PropsObj); ParamsObj.Add('required', RequiredArr);
        FunctionObj.Add('name', GetName());
        FunctionObj.Add('description', 'CALL THIS FIRST before extracting any values. Records your structural analysis of the document and initializes the verification checklist. Returns the full checklist of items to verify.');
        FunctionObj.Add('parameters', ParamsObj);
        ToolObj.Add('type', 'function'); ToolObj.Add('function', FunctionObj);
        exit(ToolObj);
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        ExtractionPlan: Codeunit "E-Doc. MLLM Extraction Plan";
        ResultObj: JsonObject;
        LineIdsToken: JsonToken;
        LineIdToken: JsonToken;
        LineIds: List of [Text];
        AnalysisObj: JsonObject;
        Token: JsonToken;
        AnalysisText, ResultText : Text;
        DocType, Language, DecimalSep, ThousandsSep, LineColumns, Notes : Text;
    begin
        if Arguments.Get('doc_type', Token) then DocType := Token.AsValue().AsText();
        if Arguments.Get('language', Token) then Language := Token.AsValue().AsText();
        if Arguments.Get('decimal_sep', Token) then DecimalSep := Token.AsValue().AsText();
        if Arguments.Get('thousands_sep', Token) then ThousandsSep := Token.AsValue().AsText();
        if Arguments.Get('line_columns', Token) then LineColumns := Token.AsValue().AsText();
        if Arguments.Get('notes', Token) then Notes := Token.AsValue().AsText();
        if Arguments.Get('line_ids', LineIdsToken) then
            foreach LineIdToken in LineIdsToken.AsArray() do
                LineIds.Add(LineIdToken.AsValue().AsText());

        AnalysisObj.Add('doc_type', DocType); AnalysisObj.Add('language', Language);
        AnalysisObj.Add('decimal_sep', DecimalSep); AnalysisObj.Add('thousands_sep', ThousandsSep);
        AnalysisObj.Add('line_columns', LineColumns); AnalysisObj.Add('notes', Notes);
        AnalysisObj.WriteTo(AnalysisText);

        ExtractionPlan.InitializePlan(LineIds, AnalysisText);

        ResultObj.Add('status', 'analysis_recorded');
        ResultObj.Add('checklist', ExtractionPlan.GetChecklistJson());
        ResultObj.WriteTo(ResultText);
        exit(ResultText);
    end;
}
