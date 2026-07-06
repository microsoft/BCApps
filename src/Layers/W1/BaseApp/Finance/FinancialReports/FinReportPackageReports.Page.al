// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

page 8372 "Fin. Report Package Reports"
{
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = 'Financial Report Package Reports';
    DataCaptionFields = "Package Code";
    PageType = ListPart;
    SourceTable = "Fin. Report Package Report";
    UsageCategory = None;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Code; Rec."Package Code")
                {
                    Visible = false;
                }
                field("Line No."; Rec."Line No.")
                {
                    Visible = false;
                }
                field("Financial Report Name"; Rec."Financial Report Name")
                {
                    ShowMandatory = true;
                }
                field("Custom Filters"; Rec."Custom Filters") { }
                field("Start Date Filter Formula"; Rec."Start Date Filter Formula") { }
                field("End Date Filter Formula"; Rec."End Date Filter Formula") { }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(EditCustomFilters)
            {
                Caption = 'Edit Custom Filters';
                Enabled = Rec."Financial Report Name" <> '';
                Image = EditFilter;
                Scope = Repeater;
                ToolTip = 'Edit the custom filters for the report, which are used when the report is generated for export or emailing';

                trigger OnAction()
                begin
                    Rec.EditCustomFilters();
                end;
            }
        }
    }

}