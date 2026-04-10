// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;

/// <summary>
/// Manages dimension functionality specific to manufacturing objects including work center dimension integration.
/// Handles global dimension updates for manufacturing master data and supports dimension validation for manufacturing-related transactions.
/// </summary>
codeunit 99000780 "Mfg. Dimension Management"
{
    [EventSubscriber(ObjectType::Table, Database::"Default Dimension", 'OnAfterUpdateGlobalDimCode', '', true, false)]
    local procedure OnAfterUpdateGlobalDimCode(GlobalDimCodeNo: Integer; TableID: Integer; AccNo: Code[20]; NewDimValue: Code[20])
    begin
        if TableID = Database::"Work Center" then
            UpdateWorkCenterGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
    end;

    local procedure UpdateWorkCenterGlobalDimCode(GlobalDimCodeNo: Integer; WorkCenterNo: Code[20]; NewDimValue: Code[20])
    var
        WorkCenter: Record "Work Center";
    begin
        if WorkCenter.Get(WorkCenterNo) then begin
            case GlobalDimCodeNo of
                1:
                    WorkCenter."Global Dimension 1 Code" := NewDimValue;
                2:
                    WorkCenter."Global Dimension 2 Code" := NewDimValue;
                else
                    OnUpdateWorkCenterGlobalDimCodeCaseElse(GlobalDimCodeNo, WorkCenterNo, NewDimValue);
            end;
            WorkCenter.Modify(true);
        end;
    end;

    /// <summary>
    /// Integration event raised for handling additional global dimension code updates on work centers beyond global dimensions 1 and 2.
    /// Enables custom dimension management for work center records when shortcut dimensions are updated.
    /// </summary>
    /// <param name="GlobalDimCodeNo">Global dimension number being updated (3-8)</param>
    /// <param name="WorkCenterNo">Work center number being updated</param>
    /// <param name="NewDimValue">New dimension value code to assign</param>
    [IntegrationEvent(false, false)]
    local procedure OnUpdateWorkCenterGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; WorkCenterNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Check Dimensions", 'OnCheckDimValuePostingOnAfterCreateDimTableIDs', '', true, false)]
    local procedure OnCheckDimValuePostingOnAfterCreateDimTableIDs(RecordVariant: Variant; var TableIDArr: array[10] of Integer; var NumberArr: array[10] of Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecordVariant);
        if RecRef.Number = Database::"Purchase Line" then begin
            RecRef.SetTable(PurchaseLine);
            TableIDArr[3] := Database::"Work Center";
            NumberArr[3] := PurchaseLine."Work Center No.";
        end;
    end;
}