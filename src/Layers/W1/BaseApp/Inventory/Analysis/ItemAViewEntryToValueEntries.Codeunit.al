// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Ledger;

codeunit 7151 ItemAViewEntryToValueEntries
{

    trigger OnRun()
    begin
    end;

    var
        ItemAnalysisView: Record "Item Analysis View";
        GLSetup: Record "General Ledger Setup";
        DimSetEntry: Record "Dimension Set Entry";

    procedure GetValueEntries(var ItemAnalysisViewEntry: Record "Item Analysis View Entry"; var TempValueEntry: Record "Value Entry")
    var
        ValueEntry: Record "Value Entry";
        ItemAnalysisViewFilter: Record "Item Analysis View Filter";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        StartDate: Date;
        EndDate: Date;
        GlobalDimValue: Code[20];
    begin
        ItemAnalysisView.Get(
          ItemAnalysisViewEntry."Analysis Area",
          ItemAnalysisViewEntry."Analysis View Code");

        if ItemAnalysisView."Date Compression" = ItemAnalysisView."Date Compression"::None then begin
            if ValueEntry.Get(ItemAnalysisViewEntry."Entry No.") then begin
                TempValueEntry := ValueEntry;
                TempValueEntry.Insert();
            end;
            exit;
        end;

        GLSetup.Get();

        StartDate := ItemAnalysisViewEntry."Posting Date";
        EndDate := StartDate;

        if StartDate < ItemAnalysisView."Starting Date" then
            StartDate := 0D
        else
            if (ItemAnalysisViewEntry."Posting Date" = NormalDate(ItemAnalysisViewEntry."Posting Date")) and
               not (ItemAnalysisView."Date Compression" in [ItemAnalysisView."Date Compression"::None, ItemAnalysisView."Date Compression"::Day])
            then
                case ItemAnalysisView."Date Compression" of
                    ItemAnalysisView."Date Compression"::Week:
                        EndDate := ItemAnalysisViewEntry."Posting Date" + 6;
                    ItemAnalysisView."Date Compression"::Month:
                        EndDate := CalcDate('<+1M-1D>', ItemAnalysisViewEntry."Posting Date");
                    ItemAnalysisView."Date Compression"::Quarter:
                        EndDate := CalcDate('<+3M-1D>', ItemAnalysisViewEntry."Posting Date");
                    ItemAnalysisView."Date Compression"::Year:
                        EndDate := CalcDate('<+1Y-1D>', ItemAnalysisViewEntry."Posting Date");
                end;

        ValueEntry.SetCurrentKey("Item No.", ValueEntry."Posting Date");
        ValueEntry.SetRange("Item No.", ItemAnalysisViewEntry."Item No.");
        ValueEntry.SetRange("Posting Date", StartDate, EndDate);
        ValueEntry.SetRange("Entry No.", 0, ItemAnalysisView."Last Entry No.");

        if ItemAnalysisViewEntry.GetFilter("Location Code") <> '' then
            ItemAnalysisViewEntry.CopyFilter("Location Code", ValueEntry."Location Code");

        if GetGlobalDimValue(GLSetup."Global Dimension 1 Code", ItemAnalysisViewEntry, GlobalDimValue) then
            ValueEntry.SetRange("Global Dimension 1 Code", GlobalDimValue)
        else
            if ItemAnalysisViewFilter.Get(
                 ItemAnalysisView."Analysis Area",
                 ItemAnalysisViewEntry."Analysis View Code",
                 GLSetup."Global Dimension 1 Code")
            then
                ValueEntry.SetFilter("Global Dimension 1 Code", ItemAnalysisViewFilter."Dimension Value Filter");

        if GetGlobalDimValue(GLSetup."Global Dimension 2 Code", ItemAnalysisViewEntry, GlobalDimValue) then
            ValueEntry.SetRange("Global Dimension 2 Code", GlobalDimValue)
        else
            if ItemAnalysisViewFilter.Get(
                 ItemAnalysisView."Analysis Area",
                 ItemAnalysisViewEntry."Analysis View Code",
                 GLSetup."Global Dimension 2 Code")
            then
                ValueEntry.SetFilter("Global Dimension 2 Code", ItemAnalysisViewFilter."Dimension Value Filter");

        if ValueEntry.Find('-') then
            repeat
                if DimEntryOK(ValueEntry."Dimension Set ID", ItemAnalysisView."Dimension 1 Code", ItemAnalysisViewEntry."Dimension 1 Value Code") and
                   DimEntryOK(ValueEntry."Dimension Set ID", ItemAnalysisView."Dimension 2 Code", ItemAnalysisViewEntry."Dimension 2 Value Code") and
                   DimEntryOK(ValueEntry."Dimension Set ID", ItemAnalysisView."Dimension 3 Code", ItemAnalysisViewEntry."Dimension 3 Value Code") and
                   UpdateItemAnalysisView.DimSetIDInFilter(ValueEntry."Dimension Set ID", ItemAnalysisView)
                then
                    if ((ItemAnalysisView."Analysis Area" = ItemAnalysisView."Analysis Area"::Sales) and
                        (ValueEntry."Item Ledger Entry Type" = ValueEntry."Item Ledger Entry Type"::Sale) and
                        (ValueEntry."Entry Type" <> ValueEntry."Entry Type"::Revaluation)) or
                       ((ItemAnalysisView."Analysis Area" = ItemAnalysisView."Analysis Area"::Purchase) and
                        (ValueEntry."Item Ledger Entry Type" = ValueEntry."Item Ledger Entry Type"::Purchase)) or
                       ((ItemAnalysisView."Analysis Area" = ItemAnalysisView."Analysis Area"::Inventory) and
                        (ValueEntry."Item Ledger Entry Type" <> ValueEntry."Item Ledger Entry Type"::" "))
                    then
                        if not TempValueEntry.Get(ValueEntry."Entry No.") then begin
                            TempValueEntry := ValueEntry;
                            TempValueEntry.Insert();
                        end;
            until ValueEntry.Next() = 0;

        OnAfterGetValueEntries(ValueEntry, ItemAnalysisView, ItemAnalysisViewEntry, GlobalDimValue);
    end;

    local procedure DimEntryOK(DimSetID: Integer; Dim: Code[20]; DimValue: Code[20]) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDimEntryOK(DimSetID, Dim, DimValue, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if Dim = '' then
            exit(true);

        if DimSetEntry.Get(DimSetID, Dim) then
            exit(DimSetEntry."Dimension Value Code" = DimValue);

        exit(DimValue = '');
    end;

    local procedure GetGlobalDimValue(GlobalDim: Code[20]; var ItemAnalysisViewEntry: Record "Item Analysis View Entry"; var GlobalDimValue: Code[20]): Boolean
    var
        IsGlobalDim: Boolean;
    begin
        case GlobalDim of
            ItemAnalysisView."Dimension 1 Code":
                begin
                    IsGlobalDim := true;
                    GlobalDimValue := ItemAnalysisViewEntry."Dimension 1 Value Code";
                end;
            ItemAnalysisView."Dimension 2 Code":
                begin
                    IsGlobalDim := true;
                    GlobalDimValue := ItemAnalysisViewEntry."Dimension 2 Value Code";
                end;
            ItemAnalysisView."Dimension 3 Code":
                begin
                    IsGlobalDim := true;
                    GlobalDimValue := ItemAnalysisViewEntry."Dimension 3 Value Code";
                end;
        end;
        exit(IsGlobalDim);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetValueEntries(var ValueEntry: Record "Value Entry"; ItemAnalysisView: Record "Item Analysis View"; ItemAnalysisViewEntry: Record "Item Analysis View Entry"; var GlobalDimValue: Code[20]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDimEntryOK(DimSetID: Integer; Dim: Code[20]; DimValue: Code[20]; var Result: Boolean; var IsHandled: Boolean);
    begin
    end;
}

