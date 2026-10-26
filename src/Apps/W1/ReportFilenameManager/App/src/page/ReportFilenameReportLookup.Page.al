// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using System.Reflection;

page 8129 "Report Filename Report Lookup"
{
    // Picks a report by caption. Processing-only reports are left out, so of the two reports
    // captioned Customer Statement only 1316 is listed; 153 is processing-only and runs the
    // statement through Customer Layout - Statement.

    Caption = 'Reports';
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Report Metadata";
    SourceTableView = where(ProcessingOnly = const(false));
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Reports)
            {
                field(Caption; Rec.Caption)
                {
                    Caption = 'Report';
                    ToolTip = 'Specifies the report.';
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey(Caption);
        // Filter group 2 so the user cannot clear the filter.
        if ReportIdFilter <> '' then begin
            Rec.FilterGroup(2);
            Rec.SetFilter(ID, ReportIdFilter);
            Rec.FilterGroup(0);
        end;
    end;

    internal procedure SetReportsAbout(TableNo: Integer)
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        ReportIdFilter := ReportFilenameMgt.ReportsAboutTable(TableNo);
    end;

    var
        ReportIdFilter: Text;
}
