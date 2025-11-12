// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.BankAccount;

page 698 "IC Bank Account Card"
{
    Caption = 'Intercompany Bank Account Card';
    PageType = Card;
    SourceTable = "IC Bank Account";
    ApplicationArea = Intercompany;
    CardPageID = "IC Bank Account Card";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ICPartnerNo; Rec."IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the IC Bank Account''s IC partner Code.';
                    Editable = false;
                    Enabled = false;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series. Should match an existing bank account number of the partner''s list of bank accounts.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the name of the bank where the IC partner has the bank account.';
                }
                field(BankAccountNo; Rec."Bank Account No.")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the number used by the IC partner''s bank for the bank account.';
                }
                field(IBAN; Rec.IBAN)
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the bank account''s international bank account number.';
                }
                field(CurrencyCode; Rec."Currency Code")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the relevant currency code for the bank account.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies that the IC bank account is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
            }
        }
    }
}
