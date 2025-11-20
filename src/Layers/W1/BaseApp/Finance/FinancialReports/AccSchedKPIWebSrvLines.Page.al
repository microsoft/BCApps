// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

page 196 "Acc. Sched. KPI Web Srv. Lines"
{
    Caption = 'Financial Report KPI Web Service Setup';
    PageType = ListPart;
    SourceTable = "Acc. Sched. KPI Web Srv. Line";

    layout
    {
        area(content)
        {
            repeater(Control13)
            {
                ShowCaption = false;
                field("Acc. Schedule Name"; Rec."Acc. Schedule Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Row definition';
                    ToolTip = 'Specifies the row definition that the KPI web service is based on. To view or edit the selected financial report, choose the Edit Row Definition button.';
                }
                field("Acc. Schedule Description"; Rec."Acc. Schedule Description")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the row definition that the KPI web service is based on.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(EditAccSchedule)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Row Definition';
                ToolTip = 'Opens the Row Definition window so that you can modify the selected row.';

                trigger OnAction()
                var
                    AccountSchedule: Page "Account Schedule";
                begin
                    AccountSchedule.SetAccSchedName(Rec."Acc. Schedule Name");
                    AccountSchedule.Run();
                end;
            }
        }
    }
}

