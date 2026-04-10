// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

/// <summary>
/// List part page displaying account schedule KPI web service line configurations.
/// Provides interface for selecting and configuring account schedules included in KPI web service data.
/// </summary>
/// <remarks>
/// Part page used within KPI web service setup for managing multiple account schedule selections.
/// Enables configuration of row definitions and descriptions for KPI data exposure through web services.
/// </remarks>
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
                }
                field("Acc. Schedule Description"; Rec."Acc. Schedule Description")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
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

