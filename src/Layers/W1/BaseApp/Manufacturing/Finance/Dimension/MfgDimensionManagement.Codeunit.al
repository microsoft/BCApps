// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;

codeunit 99000780 "Mfg. Dimension Management"
{
    [EventSubscriber(ObjectType::Table, Database::"Default Dimension", 'OnAfterUpdateGlobalDimCode', '', false, false)]
    local procedure OnAfterUpdateGlobalDimCode(GlobalDimCodeNo: Integer; TableID: Integer; AccNo: Code[20]; NewDimValue: Code[20])
    begin
        if TableID = Database::"Work Center" then
            UpdateWorkCenterGlobalDimCode(GlobalDimCodeNo, AccNo, NewDimValue);
    end;

    local procedure UpdateWorkCenterGlobalDimCode(GlobalDimCodeNo: Integer; WorkCenterNo: Code[20]; NewDimValue: Code[20])
    var
        WorkCenter: Record "Work Center";
#if not CLEAN26
        DefaultDimension: Record "Default Dimension";
#endif
    begin
        if WorkCenter.Get(WorkCenterNo) then begin
            case GlobalDimCodeNo of
                1:
                    WorkCenter."Global Dimension 1 Code" := NewDimValue;
                2:
                    WorkCenter."Global Dimension 2 Code" := NewDimValue;
                else
#if CLEAN26
                    OnUpdateWorkCenterGlobalDimCodeCaseElse(GlobalDimCodeNo, WorkCenterNo, NewDimValue);
#else
                    begin
                    DefaultDimension.RunOnUpdateWorkCenterGlobalDimCodeCaseElse(GlobalDimCodeNo, WorkCenterNo, NewDimValue);
                    OnUpdateWorkCenterGlobalDimCodeCaseElse(GlobalDimCodeNo, WorkCenterNo, NewDimValue);
                end;
#endif
            end;
            WorkCenter.Modify(true);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateWorkCenterGlobalDimCodeCaseElse(GlobalDimCodeNo: Integer; WorkCenterNo: Code[20]; NewDimValue: Code[20])
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Check Dimensions", 'OnCheckDimValuePostingOnAfterCreateDimTableIDs', '', false, false)]
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