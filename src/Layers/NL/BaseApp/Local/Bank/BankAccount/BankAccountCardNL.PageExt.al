// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

pageextension 11420 "Bank Account Card NL" extends "Bank Account Card"
{
    layout
    {
        modify("Min. Balance")
        {
            Visible = true;
        }
        addafter(IBAN)
        {
            field("Creditor Identifier"; Rec."Creditor Identifier")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Creditor Identifier';
                ToolTip = 'Specifies the creditor identifier.';
            }
        }
        addafter("Posting Details")
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
                    ToolTip = 'Specifies the bank account owner''s city.';
                }
                field("Acc. Hold. Country/Region Code"; Rec."Acc. Hold. Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the bank account holder.';
                }
            }
        }
        moveafter("Acc. Hold. Country/Region Code"; "Bank Statement Import Format", "Payment Export Format", CheckTransmitted, "Positive Pay Export Code")
    }
}
