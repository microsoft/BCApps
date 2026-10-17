// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
page 50118 "Report Filename Record Lookup"
{
    // Chooses the record a pattern is tested against.
    //
    // Lookup mode is set by the caller on a Page variable, the same way as the report, kinds and
    // field lookups.
    //
    // Used only where a kind of record has no list page of its own. Where it has one, that page
    // is what opens, with the columns it shows - a sales invoice is chosen from Posted Sales
    // Invoices. This page exists so that a report about a kind of record Business Central never
    // built a list for can still be tested.

    Caption = 'Choose a Record to Test Against';
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Report Filename Record Buffer";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(Details; Rec.Details)
                {
                    ApplicationArea = All;
                }
                field(More; Rec.More)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
    begin
        ReportFilenamePreviewMgt.BuildRecordsToTestAgainst(RecordTableNo, RecordReportId, Rec, MoreThanListed);
        Rec.SetCurrentKey(Description);
        if Rec.FindFirst() then;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        // Said once, and only when it is true. A list silently showing part of a table is the
        // kind of quiet half-answer this feature exists to remove, but saying it on every
        // keystroke would be worse than not saying it.
        if MoreThanListed and not MoreThanListedSaid then begin
            MoreThanListedSaid := true;
            Message(MoreThanListedMsg, Rec.Count());
        end;
    end;

    /// <summary>
    /// Which kind of record to list. Set before the page is run, because the list is built when
    /// the page opens and there is nothing to show until the table is known.
    /// </summary>
    /// <param name="NewTableNo">The table the pattern applies to.</param>
    /// <param name="NewReportId">The report the pattern names, so the list shows only the records that report could render. Zero lists the whole kind.</param>
    internal procedure SetRecordTable(NewTableNo: Integer; NewReportId: Integer)
    begin
        RecordTableNo := NewTableNo;
        RecordReportId := NewReportId;
    end;

    /// <summary>
    /// The record the administrator chose, identified exactly rather than by description.
    /// </summary>
    /// <returns>Its RecordId; a blank RecordId when nothing was chosen.</returns>
    internal procedure ChosenRecordId(): RecordId
    begin
        exit(Rec."Record ID");
    end;

    var
        RecordTableNo: Integer;
        RecordReportId: Integer;
        MoreThanListed: Boolean;
        MoreThanListedSaid: Boolean;
        MoreThanListedMsg: Label 'There are more records in this table than can be listed at once, so the first %1 are shown. Filter the list to find one that is not shown.', Comment = '%1 how many are listed';
}
