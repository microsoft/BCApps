// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.FixedAsset;

using Microsoft.Finance.Dimension;

codeunit 5674 FADimensionManagement
{

    trigger OnRun()
    begin
    end;

    var
        TempSelectedDim: Record "Selected Dimension" temporary;
        TempSelectedDim2: Record "Selected Dimension" temporary;
        TempSelectedDim3: Record "Selected Dimension" temporary;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'The combination of dimensions used in %1 %2, %3, %4 is blocked. %5';
        Text001: Label 'A dimension used in %1 %2, %3, %4 has caused an error. %5';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure GetSelectedDim(var SelectedDim: Record "Selected Dimension")
    begin
        Clear(TempSelectedDim);
        TempSelectedDim.Reset();
        TempSelectedDim.DeleteAll();
        if SelectedDim.Find('-') then
            repeat
                TempSelectedDim."Dimension Code" := SelectedDim."Dimension Code";
                TempSelectedDim.Insert();
            until SelectedDim.Next() = 0;
    end;

    procedure GetDimensions(var DimBuf: Record "Dimension Buffer")
    begin
        if TempSelectedDim2.Find('-') then
            repeat
                DimBuf."Dimension Code" := TempSelectedDim2."Dimension Code";
                DimBuf."Dimension Value Code" := TempSelectedDim2."New Dimension Value Code";
                DimBuf.Insert();
            until TempSelectedDim2.Next() = 0;
    end;

    procedure CheckFAAllocDim(var FAAlloc: Record "FA Allocation"; DimSetID: Integer)
    var
        DimMgt: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckFAAllocDim(FAAlloc, DimSetID, IsHandled);
        if IsHandled then
            exit;

        if not DimMgt.CheckDimIDComb(DimSetID) then
            Error(
              Text000,
              FAAlloc.TableCaption(), FAAlloc.Code, FAAlloc."Allocation Type", FAAlloc."Line No.",
              DimMgt.GetDimCombErr());

        TableID[1] := DimMgt.TypeToTableID1(0);
        No[1] := FAAlloc."Account No.";

        if not DimMgt.CheckDimValuePosting(TableID, No, DimSetID) then
            Error(
              Text001,
              FAAlloc.TableCaption(), FAAlloc.Code, FAAlloc."Allocation Type", FAAlloc."Line No.",
              DimMgt.GetDimValuePostingErr());
    end;

    procedure GetFALedgEntryDimID(Type: Integer; DimSetID: Integer)
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        if Type = 0 then begin
            Clear(TempSelectedDim2);
            TempSelectedDim2.Reset();
            TempSelectedDim2.DeleteAll();
        end;
        if Type = 1 then begin
            Clear(TempSelectedDim3);
            TempSelectedDim3.Reset();
            TempSelectedDim3.DeleteAll();
        end;
        DimSetEntry.SetRange("Dimension Set ID", DimSetID);
        if DimSetEntry.Find('-') then
            repeat
                TempSelectedDim.SetRange("Dimension Code", DimSetEntry."Dimension Code");
                if TempSelectedDim.FindFirst() then begin
                    if Type = 0 then begin
                        TempSelectedDim2."Dimension Code" := DimSetEntry."Dimension Code";
                        TempSelectedDim2."New Dimension Value Code" := DimSetEntry."Dimension Value Code";
                        TempSelectedDim2.Insert();
                    end;
                    if Type = 1 then begin
                        TempSelectedDim3."Dimension Code" := DimSetEntry."Dimension Code";
                        TempSelectedDim3."New Dimension Value Code" := DimSetEntry."Dimension Value Code";
                        TempSelectedDim3.Insert();
                    end;
                end;
            until DimSetEntry.Next() = 0;
    end;

    procedure TestEqualFALedgEntryDimID(DimSetID: Integer): Boolean
    begin
        GetFALedgEntryDimID(1, DimSetID);
        if TempSelectedDim2.Count <> TempSelectedDim3.Count then
            exit(false);
        if TempSelectedDim2.Find('-') then
            repeat
                TempSelectedDim3.SetRange("Dimension Code", TempSelectedDim2."Dimension Code");
                if not TempSelectedDim3.FindFirst() then
                    exit(false);
                if TempSelectedDim2."New Dimension Value Code" <> TempSelectedDim3."New Dimension Value Code" then
                    exit(false);
            until TempSelectedDim2.Next() = 0;
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckFAAllocDim(var FAAlloc: Record "FA Allocation"; DimSetID: Integer; var IsHandled: Boolean)
    begin
    end;
}

