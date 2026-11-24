// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Finance.GeneralLedger.Setup;

pageextension 10549 "General Ledger Setup" extends "General Ledger Setup"
{
    layout
    {
        addafter(Application)
        {
            group("Reverse Charge GB")
            {
                Caption = 'Reverse Charge';

                field("Threshold applies GB"; Rec."Threshold applies GB")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether or not the program is setup to process Reverse Charge invoices.';

                    trigger OnValidate()
                    begin
                        if Rec."Threshold applies GB" then
                            ThresholdAmountEnable := true
                        else
                            ThresholdAmountEnable := false;
                    end;
                }
                field("Threshold Amount"; Rec."Threshold Amount GB")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Threshold Amount';
                    Enabled = ThresholdAmountEnable;
                    ToolTip = 'Specifies the de minimis rule amount determined by the tax authorities.';
                }
            }
        }
    }

    var
        ThresholdAmountEnable: Boolean;

    trigger OnOpenPage()
    var
    begin
        ThresholdAmountEnable := Rec."Threshold applies GB";
    end;
}