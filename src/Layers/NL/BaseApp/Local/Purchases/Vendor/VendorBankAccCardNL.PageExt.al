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
                        ToolTip = 'Specifies the bank account owner''s name.';
                }
                field("Account Holder Address"; Rec."Account Holder Address")
                {
                    ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the bank account owner''s address.';
                }
                field("Account Holder Post Code"; Rec."Account Holder Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Holder Post Code/City';
                        ToolTip = 'Specifies the bank account owner''s postal code.';
                }
                field("Account Holder City"; Rec."Account Holder City")
                {
                    ApplicationArea = Basic, Suite;
                    ShowCaption = false;
                        ToolTip = 'Specifies the bank account owner''s city.';
                }
                field("Acc. Hold. Country/Region Code"; Rec."Acc. Hold. Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the country/region of the bank account holder.';
                }
                field("National Bank Code"; Rec."National Bank Code")
                {
                    ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the national code that identifies the bank.';
                }
                field("Abbrev. National Bank Code"; Rec."Abbrev. National Bank Code")
                {
                    ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the abbreviated national code that identifies the bank.';
                }
            }
        }
    }
}
