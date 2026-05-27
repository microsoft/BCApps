// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using System.AI;

codeunit 6321 "E-Doc. MLLM Plan Status Tool" implements "AOAI Function"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetName(): Text
    begin
        exit('get_checklist');
    end;

    procedure GetPrompt(): JsonObject
    var
        ToolObj, FunctionObj, ParamsObj : JsonObject;
    begin
        ParamsObj.Add('type', 'object');
        FunctionObj.Add('name', GetName());
        FunctionObj.Add('description', 'Returns the current verification checklist showing status (pending/passed/failed) for each item. Call this to see what verifications remain before finalising.');
        FunctionObj.Add('parameters', ParamsObj);
        ToolObj.Add('type', 'function'); ToolObj.Add('function', FunctionObj);
        exit(ToolObj);
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        ExtractionPlan: Codeunit "E-Doc. MLLM Extraction Plan";
    begin
        exit(ExtractionPlan.GetChecklistJson());
    end;
}
