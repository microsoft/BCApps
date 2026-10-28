// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

page 8133 "Report Filename Record Lookup"
{
    // Chooses the record a pattern is tested against. Used only for tables with no lookup page
    // (Table Metadata's LookupPageID is 0); otherwise the table's lookup page opens instead.

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
        if MoreThanListed and not MoreThanListedSaid then begin
            MoreThanListedSaid := true;
            Message(MoreThanListedMsg, Rec.Count());
        end;
    end;

    /// <summary>
    /// Must be called before the page runs; the list is built in OnOpenPage.
    /// </summary>
    /// <param name="NewReportId">Limits the list to records this report could render. Zero lists the whole table.</param>
    internal procedure SetRecordTable(NewTableNo: Integer; NewReportId: Integer)
    begin
        RecordTableNo := NewTableNo;
        RecordReportId := NewReportId;
    end;

    /// <returns>A blank RecordId when nothing was chosen.</returns>
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
