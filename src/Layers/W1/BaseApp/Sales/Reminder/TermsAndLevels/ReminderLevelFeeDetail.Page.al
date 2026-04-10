// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Displays detailed fee setup information for a reminder level as a subpage part.
/// </summary>
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
                    Visible = false;
                }
                field("Reminder Terms Code"; Rec."Reminder Terms Code")
                {
                    Caption = 'Reminder Terms Code';
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Reminder Level No."; Rec."Reminder Level No.")
                {
                    Caption = 'Reminder Level No.';
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    Caption = 'Currency Code';
                    ApplicationArea = Suite;
                }
                field("Threshold Remaining Amount"; Rec."Threshold Remaining Amount")
                {
                    Caption = 'Threshold Remaining Amount';
                    ApplicationArea = Suite;
                }
                field("Additional Fee Amount"; Rec."Additional Fee Amount")
                {
                    Caption = 'Additional Fee Amount';
                    ApplicationArea = Suite;
                    CaptionClass = AddFeeCaptionExpression;
                }
                field("Additional Fee %"; Rec."Additional Fee %")
                {
                    ApplicationArea = Suite;
                    CaptionClass = AddFeePercCaptionExpression;
                }
                field("Min. Additional Fee Amount"; Rec."Min. Additional Fee Amount")
                {
                    Caption = 'Min. Additional Fee Amount';
                    ApplicationArea = Suite;
                }
                field("Max. Additional Fee Amount"; Rec."Max. Additional Fee Amount")
                {
                    Caption = 'Max. Additional Fee Amount';
                    ApplicationArea = Suite;
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

