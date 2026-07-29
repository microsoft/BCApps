// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

pageextension 11303 VendorBankAccCardNL extends "Vendor Bank Account Card"
{
    layout
    {
        addafter(Transfer)
        {
            group("Account Holder")
            {
                Caption = 'Account Holder';
                field("Account Holder Name"; Rec."Account Holder Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Account Holder Address"; Rec."Account Holder Address")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Account Holder Post Code"; Rec."Account Holder Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Holder Post Code/City';
                }
                field("Account Holder City"; Rec."Account Holder City")
                {
                    ApplicationArea = Basic, Suite;
                    ShowCaption = false;
                }
                field("Acc. Hold. Country/Region Code"; Rec."Acc. Hold. Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("National Bank Code"; Rec."National Bank Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Abbrev. National Bank Code"; Rec."Abbrev. National Bank Code")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }
}
