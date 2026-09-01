// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using System.Environment;

/// <summary>
/// Configures interest calculation and additional fee settings for a reminder level.
/// </summary>
page 1895 "Reminder Level Fee Setup"
{
    Caption = 'Reminder Level Fee Setup';
    PageType = ListPlus;
    SourceTable = "Reminder Level";
    UsageCategory = None;

    layout
    {
        area(content)
        {
            field("Calculate Interest"; Rec."Calculate Interest")
            {
                Caption = 'Calculate Interest';
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies whether to calculate interest on the reminder lines.';
            }
            field("Add. Fee Calculation Type"; Rec."Add. Fee Calculation Type")
            {
                Caption = 'Additional Fee Calculation Type';
                ApplicationArea = Basic, Suite;
            }
            group(FixedFees)
            {
                ShowCaption = false;
                Visible = Rec."Add. Fee Calculation Type" = Rec."Add. Fee Calculation Type"::Fixed;
                field("Additional Fee (LCY)"; Rec."Additional Fee (LCY)")
                {
                    Caption = 'Fee per reminder (LCY)';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the additional fee in LCY that will be added on the reminder.';
                }
                field("Add. Fee per Line Amount (LCY)"; Rec."Add. Fee per Line Amount (LCY)")
                {
                    Caption = 'Fee per line (LCY)';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line amount of the additional fee in LCY.';
                }
            }
            part(ReminderLevelFeeDetail; "Reminder Level Fee Detail")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Additional Fee Details';
                Visible = Rec."Add. Fee Calculation Type" <> Rec."Add. Fee Calculation Type"::Fixed;
                SubPageLink = "Charge Per Line" = const(false),
                                  "Reminder Terms Code" = field("Reminder Terms Code"),
                                  "Reminder Level No." = field("No.");
                UpdatePropagation = Both;
            }
            part(ReminderLevelLineFeeDetail; "Reminder Level Fee Detail")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Additional Fee per line Details';
                Visible = Rec."Add. Fee Calculation Type" <> Rec."Add. Fee Calculation Type"::Fixed;
                SubPageLink = "Charge Per Line" = const(true),
                                  "Reminder Terms Code" = field("Reminder Terms Code"),
                                  "Reminder Level No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("View Additional Fee Chart")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'View Additional Fee Chart';
                Image = Forecast;
                ToolTip = 'View additional fees in a chart.';
                Visible = IsWinClient;

                trigger OnAction()
                var
                    AddFeeChart: Page "Additional Fee Chart";
                begin
                    if ClientTypeManagement.GetCurrentClientType() <> CLIENTTYPE::Windows then
                        Error(ChartNotAvailableInWebErr, PRODUCTNAME.Short());

                    AddFeeChart.SetViewMode(Rec, false, true);
                    AddFeeChart.RunModal();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        IsWinClient := ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Windows;
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";
        ChartNotAvailableInWebErr: Label 'The chart cannot be shown in the %1 Web client. To see the chart, use the %1 Windows client.', Comment = '%1 - product name';
        IsWinClient: Boolean;
}
