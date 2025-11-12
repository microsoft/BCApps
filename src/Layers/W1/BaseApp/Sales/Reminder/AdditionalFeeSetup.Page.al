// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using System.Environment;

page 1050 "Additional Fee Setup"
{
    Caption = 'Additional Fee Setup';
    DataCaptionExpression = PageCaptionText;
    PageType = List;
    SourceTable = "Additional Fee Setup";

    layout
    {
        area(content)
        {
            repeater(Control15)
            {
                ShowCaption = false;
                field("Charge Per Line"; Rec."Charge Per Line")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that additional fees are calculated per document line.';
                    Visible = false;
                }
                field("Reminder Terms Code"; Rec."Reminder Terms Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the reminder terms code for the reminder.';
                    Visible = false;
                }
                field("Reminder Level No."; Rec."Reminder Level No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the total of the additional fee amounts on the reminder lines.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency that is used on the entry.';
                }
                field("Threshold Remaining Amount"; Rec."Threshold Remaining Amount")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the amount that remains before the additional fee is incurred.';
                }
                field("Additional Fee Amount"; Rec."Additional Fee Amount")
                {
                    ApplicationArea = Suite;
                    CaptionClass = AddFeeCaptionExpression;
                    ToolTip = 'Specifies the line amount of the additional fee.';
                }
                field("Additional Fee %"; Rec."Additional Fee %")
                {
                    ApplicationArea = Suite;
                    CaptionClass = AddFeePercCaptionExpression;
                    ToolTip = 'Specifies the percentage of the total amount that makes up the additional fee.';
                }
                field("Min. Additional Fee Amount"; Rec."Min. Additional Fee Amount")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the lowest amount that a fee can be.';
                }
                field("Max. Additional Fee Amount"; Rec."Max. Additional Fee Amount")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the highest amount that a fee can be.';
                }
            }
            part(Chart; "Additional Fee Chart")
            {
                ApplicationArea = Suite;
                Visible = ShowChart;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        if ShowChart then
            CurrPage.Chart.PAGE.UpdateData();
    end;

    trigger OnOpenPage()
    var
        ReminderLevel: Record "Reminder Level";
    begin
        ShowChart := ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Windows;
        if ShowChart then begin
            ReminderLevel.Get(Rec."Reminder Terms Code", Rec."Reminder Level No.");
            CurrPage.Chart.PAGE.SetViewMode(ReminderLevel, Rec."Charge Per Line", false);
            CurrPage.Chart.PAGE.UpdateData();
        end;

        if Rec."Charge Per Line" then
            PageCaptionText := AddFeePerLineTxt;

        PageCaptionText += ' ' + ReminderTermsTxt + ' ' + Rec."Reminder Terms Code" + ' ' +
          ReminderLevelTxt + ' ' + Format(Rec."Reminder Level No.");

        if Rec."Charge Per Line" then begin
            AddFeeCaptionExpression := AddFeeperLineCaptionTxt;
            AddFeePercCaptionExpression := AddFeeperLineCaptionTxt + ' %';
        end else begin
            AddFeeCaptionExpression := AddFeeCaptionTxt;
            AddFeePercCaptionExpression := AddFeeCaptionTxt + ' %';
        end;
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";
        PageCaptionText: Text;
        AddFeePerLineTxt: Label 'Additional Fee per Line Setup -';
        ReminderTermsTxt: Label 'Reminder Terms:';
        ReminderLevelTxt: Label 'Level:';
        ShowChart: Boolean;
        AddFeeCaptionExpression: Text;
        AddFeeperLineCaptionTxt: Label 'Additional Fee per Line';
        AddFeeCaptionTxt: Label 'Additional Fee';
        AddFeePercCaptionExpression: Text;
}

