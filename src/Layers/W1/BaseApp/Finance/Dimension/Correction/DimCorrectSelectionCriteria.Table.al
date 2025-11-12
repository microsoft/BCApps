// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

using Microsoft.Finance.GeneralLedger.Ledger;

table 2585 "Dim Correct Selection Criteria"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            AutoIncrement = true;
        }

        field(2; "Dimension Correction Entry No."; Integer)
        {
            DataClassification = CustomerContent;
        }

        field(3; "Selection Filter"; Blob)
        {
            DataClassification = CustomerContent;
        }

        field(4; "Filter Type"; Option)
        {
            DataClassification = CustomerContent;
            OptionMembers = Manual,Excluded,"Related Entries","Custom Filter","By Dimension";
        }

        field(5; "Dimension Set IDs"; Blob)
        {
            DataClassification = CustomerContent;
        }

        field(6; "Last Entry No."; Integer)
        {
            DataClassification = CustomerContent;
        }

        field(7; "Language Id"; Integer)
        {
            DataClassification = CustomerContent;
        }

        field(8; "UTF16 Encoding"; Boolean)
        {
            DataClassification = CustomerContent;
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }

        key(Key2; "Dimension Correction Entry No.")
        {
        }
    }

    trigger OnInsert()
    var
        DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
    begin
        if Rec."Entry No." = 0 then
            if not DimCorrectSelectionCriteria.FindLast() then
                Rec."Entry No." := 1
            else
                Rec."Entry No." := DimCorrectSelectionCriteria."Entry No." + 1;
    end;

    procedure SetSelectionFilter(var MainRecordRef: RecordRef)
    var
        CurrentLanguage: Integer;
    begin
        CurrentLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        Rec.SetSelectionFilter(MainRecordRef.GetView());
        GlobalLanguage(CurrentLanguage);
    end;

    procedure SetSelectionFilter(NewSelectionFilter: Text)
    var
        SelectionFilterOutStream: OutStream;
    begin
        if Rec."UTF16 Encoding" then
            Rec."Selection Filter".CreateOutStream(SelectionFilterOutStream, TextEncoding::UTF16)
        else
            Rec."Selection Filter".CreateOutStream(SelectionFilterOutStream);

        SelectionFilterOutStream.WriteText(NewSelectionFilter);
        Rec."Language Id" := GlobalLanguage();
    end;

    procedure GetSelectionFilter(var SelectionFilterText: Text)
    var
        RecorordRef: RecordRef;
        SelectionFilterInStream: InStream;
        CurrentGlobalLanguage: Integer;
    begin
        Rec.CalcFields("Selection Filter");
        if "UTF16 Encoding" then
            Rec."Selection Filter".CreateInStream(SelectionFilterInStream, TextEncoding::UTF16)
        else
            Rec."Selection Filter".CreateInStream(SelectionFilterInStream);

        SelectionFilterInStream.ReadText(SelectionFilterText);

        if Rec."Language Id" = 0 then
            exit;

        if GlobalLanguage() <> Rec."Language Id" then begin
            CurrentGlobalLanguage := GlobalLanguage();
            GlobalLanguage(Rec."Language Id");
            RecorordRef.Open(Database::"G/L Entry");
            RecorordRef.SetView(SelectionFilterText);
            GlobalLanguage(CurrentGlobalLanguage);
            SelectionFilterText := RecorordRef.GetView();
        end;
    end;

    procedure SetDimensionSetIds(var DimensionSetIds: List of [Integer])
    var
        DimensionSetID: Integer;
        CommaSeparatedDimensionSetIds: Text;
        DimensionSetIDsOutStream: OutStream;
    begin
        if DimensionSetIds.Count() = 0 then begin
            Clear(Rec."Dimension Set IDs");
            exit;
        end;

        foreach DimensionSetID in DimensionSetIds do
            if CommaSeparatedDimensionSetIds <> '' then
                CommaSeparatedDimensionSetIds += ',' + Format(DimensionSetID)
            else
                CommaSeparatedDimensionSetIds := Format(DimensionSetID);

        Rec."Dimension Set IDs".CreateOutStream(DimensionSetIDsOutStream);
        DimensionSetIDsOutStream.WriteText(CommaSeparatedDimensionSetIds);
    end;

    procedure GetDimensionSetIds(var DimensionSetIds: List of [Integer])
    var
        TextDimensionSetID: Text;
        TextDimensionSetIds: List of [Text];
        DimensionSetID: Integer;
    begin
        GetDimensionSetIds(TextDimensionSetIds);
        foreach TextDimensionSetID in TextDimensionSetIds do begin
            Evaluate(DimensionSetID, TextDimensionSetID);
            DimensionSetIDs.Add(DimensionSetID);
        end;
    end;

    local procedure GetDimensionSetIds(var DimensionSetIds: List of [Text])
    var
        DimensionSetIDsInStream: InStream;
        CommaSeparatedDimensionSetIds: Text;
    begin
        Clear(DimensionSetIds);
        Rec.CalcFields("Dimension Set IDs");
        if not Rec."Dimension Set IDs".HasValue() then
            exit;

        Rec."Dimension Set IDs".CreateInStream(DimensionSetIDsInStream);
        DimensionSetIDsInStream.ReadText(CommaSeparatedDimensionSetIds);

        if CommaSeparatedDimensionSetIds = '' then
            exit;

        DimensionSetIds := CommaSeparatedDimensionSetIds.Split(',');
    end;

    procedure GetSelectionDisplayText(var DisplayText: Text)
    var
        MainRecordRef: RecordRef;
        SelectionFilterText: Text;
    begin
        Rec.GetSelectionFilter(SelectionFilterText);
        MainRecordRef.Open(Database::"G/L Entry", true);
        MainRecordRef.SetView(SelectionFilterText);
        DisplayText := MainRecordRef.GetFilters();
    end;
}
