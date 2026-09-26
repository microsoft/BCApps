// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Bank.DirectDebit;

/// <summary>
/// Extends the Customer Bank Account Card page with NL-specific account holder fields and direct debit mandate.
/// </summary>
pageextension 11463 "Customer Bank Acc. Card NL" extends "Customer Bank Account Card"
{
    layout
    {
        addafter(IBAN)
        {
            field("Direct Debit Mandate ID"; Rec."Direct Debit Mandate ID")
            {
                ApplicationArea = Basic, Suite;
                LookupPageID = "SEPA Direct Debit Mandates";
                ToolTip = 'Specifies the direct debit mandate of the customer that this bank account is for.';
            }
        }
        addlast(content)
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
    }
}
