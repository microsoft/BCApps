// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

codeunit 6340 "E-Doc. MLLM Extraction Plan"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    SingleInstance = true;

    var
        ItemStatus: Dictionary of [Text, Text];
        ItemErrors: Dictionary of [Text, Text];
        AnalysisPayload: Text;
        CurrentJson: Text;
        FixedItemsTok: Label 'verify_invoice_totals,verify_vat,verify_dates,verify_required_fields,verify_ranges,verify_payable', Locked = true;

    procedure Reset()
    begin
        Clear(ItemStatus);
        Clear(ItemErrors);
        AnalysisPayload := '';
        CurrentJson := '';
    end;

    procedure InitializePlan(LineIds: List of [Text]; Analysis: Text)
    var
        LineId: Text;
        FixedIds: List of [Text];
        FixedId: Text;
    begin
        Reset();
        AnalysisPayload := Analysis;
        ItemStatus.Add('analyze_invoice', 'passed');
        foreach LineId in LineIds do
            ItemStatus.Add('verify_line_' + LineId, 'pending');
        FixedIds.AddRange(FixedItemsTok.Split(','));
        foreach FixedId in FixedIds do
            ItemStatus.Add(FixedId, 'pending');
    end;

    procedure MarkItem(ItemId: Text; Passed: Boolean; ErrorMsg: Text)
    var
        Status: Text;
    begin
        if Passed then Status := 'passed' else Status := 'failed';
        if ItemStatus.ContainsKey(ItemId) then
            ItemStatus.Set(ItemId, Status)
        else
            ItemStatus.Add(ItemId, Status);
        if not Passed then begin
            if ItemErrors.ContainsKey(ItemId) then
                ItemErrors.Set(ItemId, ErrorMsg)
            else
                ItemErrors.Add(ItemId, ErrorMsg);
        end else
            if ItemErrors.ContainsKey(ItemId) then
                ItemErrors.Remove(ItemId);
    end;

    procedure SetCurrentJson(Json: Text)
    var
        ItemId, Status : Text;
    begin
        CurrentJson := Json;
        // Reset failed items to pending so the model re-verifies after correction
        foreach ItemId in ItemStatus.Keys() do begin
            ItemStatus.Get(ItemId, Status);
            if Status = 'failed' then
                ItemStatus.Set(ItemId, 'pending');
        end;
        if ItemErrors.Count() > 0 then
            Clear(ItemErrors);
    end;

    procedure GetCurrentJson(): Text
    begin
        exit(CurrentJson);
    end;

    procedure HasCurrentJson(): Boolean
    begin
        exit(CurrentJson <> '');
    end;

    procedure GetChecklistJson(): Text
    var
        ResultArr: JsonArray;
        ItemObj: JsonObject;
        ItemId, Status, ErrorMsg : Text;
        ResultText: Text;
    begin
        foreach ItemId in ItemStatus.Keys() do begin
            Clear(ItemObj);
            ItemStatus.Get(ItemId, Status);
            ItemObj.Add('id', ItemId);
            ItemObj.Add('status', Status);
            if (Status = 'failed') and ItemErrors.ContainsKey(ItemId) then begin
                ItemErrors.Get(ItemId, ErrorMsg);
                ItemObj.Add('error', ErrorMsg);
            end;
            ResultArr.Add(ItemObj);
        end;
        ResultArr.WriteTo(ResultText);
        exit(ResultText);
    end;

    procedure IsInitialized(): Boolean
    begin
        exit(ItemStatus.Count() > 0);
    end;
}
