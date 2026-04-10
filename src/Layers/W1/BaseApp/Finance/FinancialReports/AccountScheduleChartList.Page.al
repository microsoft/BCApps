// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

/// <summary>
/// Displays list of account schedule chart configurations with navigation to detailed setup.
/// Provides overview of user-defined financial report chart setups for visualization management.
/// </summary>
/// <remarks>
/// Primary functionality: Chart setup browsing, creation of new chart configurations.
/// Navigation: Links to Account Schedules Chart Setup card page for detailed configuration.
/// Extensibility: Standard page extension patterns for additional fields and actions.
/// </remarks>
page 767 "Account Schedule Chart List"
{
    Caption = 'Account Schedule Chart List';
    CardPageID = "Account Schedules Chart Setup";
    PageType = List;
    SourceTable = "Account Schedules Chart Setup";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Account Schedule Name"; Rec."Account Schedule Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the account schedule that is used to generate the chart that is shown in the Finance Performance window.';
                    Visible = false;
                }
                field("Column Layout Name"; Rec."Column Layout Name")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Base X-Axis on"; Rec."Base X-Axis on")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date on which account schedule values are included in the chart.';
                }
                field("Period Length"; Rec."Period Length")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("No. of Periods"; Rec."No. of Periods")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Start Date" := WorkDate();
    end;
}

