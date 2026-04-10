// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

using Microsoft.Finance.GeneralLedger.Ledger;

/// <summary>
/// Stores selection criteria for identifying general ledger entries to include in dimension correction.
/// Manages filters and dimension set IDs for both included and excluded entries.
/// </summary>
table 2585 "Dim Correct Selection Criteria"
{
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the selection criteria entry.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            AutoIncrement = true;
        }

        /// <summary>
        /// Reference to the parent dimension correction entry.
        /// </summary>
        field(2; "Dimension Correction Entry No."; Integer)
        {
            DataClassification = CustomerContent;
        }

        /// <summary>
        /// BLOB field containing serialized selection filter criteria for G/L entries.
        /// </summary>
        field(3; "Selection Filter"; Blob)
        {
            DataClassification = CustomerContent;
        }

        /// <summary>
        /// Type of filter used for selecting entries in the dimension correction.
        /// </summary>
        field(4; "Filter Type"; Option)
        {
            ToolTip = 'Specifies the type of the selection.';
            DataClassification = CustomerContent;
            OptionMembers = Manual,Excluded,"Related Entries","Custom Filter","By Dimension";
        }

        /// <summary>
        /// BLOB field containing serialized dimension set IDs that match the selection criteria.
        /// </summary>
        field(5; "Dimension Set IDs"; Blob)
        {
            DataClassification = CustomerContent;
        }

        /// <summary>
        /// Last entry number processed for this selection criteria.
        /// </summary>
        field(6; "Last Entry No."; Integer)
        {
            DataClassification = CustomerContent;
        }

        /// <summary>
        /// Language identifier for localization of selection criteria text.
        /// </summary>
        field(7; "Language Id"; Integer)
        {
            DataClassification = CustomerContent;
        }

        /// <summary>
        /// Indicates whether UTF-16 encoding is used for text processing.
        /// </summary>
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

    /// <summary>
    /// Sets selection filter from a record reference with language handling.
    /// </summary>
    /// <param name="MainRecordRef">Record reference to extract filter view from</param>
    procedure SetSelectionFilter(var MainRecordRef: RecordRef)
    var
        CurrentLanguage: Integer;
    begin
        CurrentLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        Rec.SetSelectionFilter(MainRecordRef.GetView());
        GlobalLanguage(CurrentLanguage);
    end;

    /// <summary>
    /// Sets selection filter text with proper encoding in the BLOB field.
    /// </summary>
    /// <param name="NewSelectionFilter">Filter text to store</param>
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

    /// <summary>
    /// Retrieves selection filter text from the BLOB field with proper language and encoding handling.
    /// </summary>
    /// <param name="SelectionFilterText">Variable to store the retrieved filter text</param>
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

    /// <summary>
    /// Sets dimension set IDs in the BLOB field for efficient storage and retrieval.
    /// </summary>
    /// <param name="DimensionSetIds">List of dimension set IDs to store</param>
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

    /// <summary>
    /// Retrieves dimension set IDs from the BLOB field as a list of integers.
    /// </summary>
    /// <param name="DimensionSetIds">List to populate with dimension set IDs</param>
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

    /// <summary>
    /// Generates display text for the selection criteria for user interface presentation.
    /// </summary>
    /// <param name="DisplayText">Variable to store the generated display text</param>
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
