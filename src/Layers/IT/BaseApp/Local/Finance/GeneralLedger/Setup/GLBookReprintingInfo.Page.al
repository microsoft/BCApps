// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

page 12149 "G/L Book Reprinting Info."
{
    Caption = 'G/L Book Reprinting Information';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SourceTable = "Reprint Info Fiscal Reports";
    SourceTableView = where(Report = const("G/L Book - Print"));

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the start date that is associated with the printed fiscal report.';
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the end date that is associated with the printed fiscal report.';
                }
                field("First Page Number"; Rec."First Page Number")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the page number of the first page of the fiscal report.';
                }
            }
        }
    }

    actions
    {
    }
}

