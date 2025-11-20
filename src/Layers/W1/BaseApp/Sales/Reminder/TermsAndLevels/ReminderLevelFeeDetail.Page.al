// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

page 836 "Reminder Level Fee Detail"
{
    PageType = ListPart;
    SourceTable = "Additional Fee Setup";
    UsageCategory = None;

    layout
    {
        area(content)
        {
            repeater(Control)
            {
                ShowCaption = false;
                field("Charge Per Line"; Rec."Charge Per Line")
                {
                    Caption = 'Charge Per Line';
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that additional fees are calculated per document line.';
                    Visible = false;
                }
                field("Reminder Terms Code"; Rec."Reminder Terms Code")
                {
                    Caption = 'Reminder Terms Code';
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the reminder terms code for the reminder.';
                    Visible = false;
                }
                field("Reminder Level No."; Rec."Reminder Level No.")
                {
                    Caption = 'Reminder Level No.';
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the total of the additional fee amounts on the reminder lines.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    Caption = 'Currency Code';
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency that is used on the entry.';
                }
                field("Threshold Remaining Amount"; Rec."Threshold Remaining Amount")
                {
                    Caption = 'Threshold Remaining Amount';
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the amount that remains before the additional fee is incurred.';
                }
                field("Additional Fee Amount"; Rec."Additional Fee Amount")
                {
                    Caption = 'Additional Fee Amount';
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
                    Caption = 'Min. Additional Fee Amount';
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the lowest amount that a fee can be.';
                }
                field("Max. Additional Fee Amount"; Rec."Max. Additional Fee Amount")
                {
                    Caption = 'Max. Additional Fee Amount';
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the highest amount that a fee can be.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin

        if not Rec."Charge Per Line" then begin
            AddFeeCaptionExpression := AddFeeCaptionTxt;
            AddFeePercCaptionExpression := AddFeeCaptionTxt + ' %';
        end else begin
            AddFeeCaptionExpression := AddFeeperLineCaptionTxt;
            AddFeePercCaptionExpression := AddFeeperLineCaptionTxt + ' %';
        end;
    end;

    var
        AddFeeCaptionExpression: Text;
        AddFeeCaptionTxt: Label 'Additional Fee';
        AddFeeperLineCaptionTxt: Label 'Additional Fee per Line';
        AddFeePercCaptionExpression: Text;
}

