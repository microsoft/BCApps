// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using System.Environment;

page 432 "Reminder Levels"
{
    Caption = 'Reminder Levels';
    DataCaptionFields = "Reminder Terms Code";
    PageType = List;
    SourceTable = "Reminder Level";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Reminder Terms Code"; Rec."Reminder Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reminder terms code for the reminder.';
                    Visible = ReminderTermsCodeVisible;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Grace Period"; Rec."Grace Period")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the length of the grace period for this reminder level.';
                }
                field("Due Date Calculation"; Rec."Due Date Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a formula that determines how to calculate the due date on the reminder.';
                }
                field("Calculate Interest"; Rec."Calculate Interest")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether interest should be calculated on the reminder lines.';
                }
                field("Additional Fee (LCY)"; Rec."Additional Fee (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = AddFeeFieldsEnabled;
                    ToolTip = 'Specifies the amount of the additional fee in LCY that will be added on the reminder.';
                }
                field("Add. Fee per Line Amount (LCY)"; Rec."Add. Fee per Line Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = AddFeeFieldsEnabled;
                    ToolTip = 'Specifies the line amount of the additional fee.';
                }
                field("Add. Fee Calculation Type"; Rec."Add. Fee Calculation Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the additional fee is calculated. Fixed: The Additional Fee values on the line on the Reminder Levels page are used. Dynamics Single: The per-line values on the Additional Fee Setup page are used. Accumulated Dynamic: The values on the Additional Fee Setup page are used.';

                    trigger OnValidate()
                    begin
                        CheckAddFeeCalcType();
                    end;
                }
                field("Add. Fee per Line Description"; Rec."Add. Fee per Line Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the additional fee.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Level")
            {
                Caption = '&Level';
                Image = ReminderTerms;
                action(BeginningText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Beginning Text';
                    Image = BeginningText;
                    RunObject = Page "Reminder Text";
                    RunPageLink = "Reminder Terms Code" = field("Reminder Terms Code"),
                                  "Reminder Level" = field("No."),
                                  Position = const(Beginning);
                    ToolTip = 'Define a beginning text for each reminder level. The text will then be printed on the reminder.';
                }
                action(EndingText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ending Text';
                    Image = EndingText;
                    RunObject = Page "Reminder Text";
                    RunPageLink = "Reminder Terms Code" = field("Reminder Terms Code"),
                                  "Reminder Level" = field("No."),
                                  Position = const(Ending);
                    ToolTip = 'Define an ending text for each reminder level. The text will then be printed on the reminder.';
                }
                separator(Action21)
                {
                }
                action(Currencies)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Currencies';
                    Enabled = AddFeeFieldsEnabled;
                    Image = Currency;
                    RunObject = Page "Currencies for Reminder Level";
                    RunPageLink = "Reminder Terms Code" = field("Reminder Terms Code"),
                                  "No." = field("No.");
                    ToolTip = 'View or edit additional feed in additional currencies.';
                }
            }
            group(Setup)
            {
                Caption = 'Setup';
                action("Additional Fee")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Additional Fee';
                    Enabled = AddFeeSetupEnabled;
                    Image = SetupColumns;
                    RunObject = Page "Additional Fee Setup";
                    RunPageLink = "Charge Per Line" = const(false),
                                  "Reminder Terms Code" = field("Reminder Terms Code"),
                                  "Reminder Level No." = field("No.");
                    ToolTip = 'View or edit the fees that apply to late payments.';
                }
                action("Additional Fee per Line")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Additional Fee per Line';
                    Enabled = AddFeeSetupEnabled;
                    Image = SetupLines;
                    RunObject = Page "Additional Fee Setup";
                    RunPageLink = "Charge Per Line" = const(true),
                                  "Reminder Terms Code" = field("Reminder Terms Code"),
                                  "Reminder Level No." = field("No.");
                    ToolTip = 'View or edit the fees that apply to late payments.';
                }
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
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Additional Fee_Promoted"; "Additional Fee")
                {
                }
                actionref("Additional Fee per Line_Promoted"; "Additional Fee per Line")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CheckAddFeeCalcType();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.NewRecord();
    end;

    trigger OnOpenPage()
    var
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        ReminderTerms.SetFilter(Code, Rec.GetFilter("Reminder Terms Code"));
        ShowColumn := true;
        if ReminderTerms.FindFirst() then begin
            ReminderTerms.SetRecFilter();
            if ReminderTerms.GetFilter(Code) = Rec.GetFilter("Reminder Terms Code") then
                ShowColumn := false;
        end;
        ReminderTermsCodeVisible := ShowColumn;
        IsWinClient := ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Windows;
    end;

    var
        ReminderTerms: Record "Reminder Terms";
        ClientTypeManagement: Codeunit "Client Type Management";
        ShowColumn: Boolean;
        ReminderTermsCodeVisible: Boolean;
        AddFeeSetupEnabled: Boolean;
        AddFeeFieldsEnabled: Boolean;
        ChartNotAvailableInWebErr: Label 'The chart cannot be shown in the %1 Web client. To see the chart, use the %1 Windows client.', Comment = '%1 - product name';
        IsWinClient: Boolean;

    local procedure CheckAddFeeCalcType()
    begin
        if Rec."Add. Fee Calculation Type" = Rec."Add. Fee Calculation Type"::Fixed then begin
            AddFeeSetupEnabled := false;
            AddFeeFieldsEnabled := true;
        end else begin
            AddFeeSetupEnabled := true;
            AddFeeFieldsEnabled := false;
        end;
    end;
}

