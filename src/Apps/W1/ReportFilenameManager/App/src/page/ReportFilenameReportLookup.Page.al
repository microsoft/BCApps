// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
page 50114 "Report Filename Report Lookup"
{
    // Picks a report by its name. The pattern stores the report's object id, and no page in
    // this design shows one: a number is not something an administrator should have to know,
    // recognise or type.
    //
    // Reports that render nothing are left out. Two objects share the caption
    // Customer Statement - one is the launcher a user chooses from the customer list, which
    // renders nothing itself and delegates - and filtering those out resolves the collision
    // without showing an object number to tell them apart.

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
        // In a filter group of its own, so it cannot be cleared from the page: the reports shown
        // are the only ones a run of this pattern's records could come from.
        if ReportIdFilter <> '' then begin
            Rec.FilterGroup(2);
            Rec.SetFilter(ID, ReportIdFilter);
            Rec.FilterGroup(0);
        end;
    end;

    /// <summary>
    /// Offers only the reports a run of which is about this table - for a pattern that names a
    /// table and no report, where every other report is one its records never come out of.
    /// Raised by the user on 28 September: Test Pattern on an Assembly Header pattern offered every
    /// report in the company.
    /// </summary>
    /// <param name="TableNo">The pattern's table.</param>
    internal procedure SetReportsAbout(TableNo: Integer)
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        ReportIdFilter := ReportFilenameMgt.ReportsAboutTable(TableNo);
    end;

    var
        ReportIdFilter: Text;
}
