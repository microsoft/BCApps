// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

/// <summary>
/// Page 1206 "Credit Transfer Reg. Entries" displays credit transfer entries in a list format.
/// Provides a read-only view of individual payment entries within credit transfer registers,
/// showing recipient details, amounts, applied entries, and related information.
/// </summary>
/// <remarks>
/// Source table: Credit Transfer Entry. Used for viewing and analyzing exported payment details
/// including SEPA credit transfers and bank-specific payment formats.
/// </remarks>
page 1206 "Credit Transfer Reg. Entries"
{
    Caption = 'Credit Transfer Reg. Entries';
    Editable = false;
    PageType = List;
    SourceTable = "Credit Transfer Entry";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Applies-to Entry No."; Rec."Applies-to Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Transfer Date"; Rec."Transfer Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                }
                field("Transfer Amount"; Rec."Transfer Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Canceled; Rec.Canceled)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Transaction ID"; Rec."Transaction ID")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(CreditorName; Rec."Recipient Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Recipient Name';
                }
                field(RecipientIBAN; Rec."Recipient IBAN")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Recipient IBAN';
                }
                field("GetRecipientIBANOrBankAccNo(FALSE)"; Rec."Recipient Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Recipient Bank Account No.';
                    ToolTip = 'Specifies the number of the creditor bank account that was used on the payment journal line that this credit transfer file was exported from.';
                }
                field("Message to Recipient"; Rec."Message to Recipient")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Message to Recipient';
                }
                field(AppliesToEntryDocumentNo; Rec.AppliesToEntryDocumentNo())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applies-to Entry Document No.';
                    ToolTip = 'Specifies the entry number of the purchase invoice that the vendor ledger entry behind this credit transfer was applied to.';
                }
                field(AppliesToEntryPostingDate; Rec.AppliesToEntryPostingDate())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applies-to Entry Posting Date';
                    ToolTip = 'Specifies when the purchase invoice that the vendor ledger entry behind this credit transfer entry applies to was posted.';
                }
                field(AppliesToEntryDescription; Rec.AppliesToEntryDescription())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applies-to Entry Description';
                    ToolTip = 'Specifies the description of the purchase invoice that the vendor ledger entry behind this credit transfer entry applies to.';
                }
                field(AppliesToEntryCurrencyCode; Rec.AppliesToEntryCurrencyCode())
                {
                    ApplicationArea = Suite;
                    Caption = 'Applies-to Entry Currency Code';
                    ToolTip = 'Specifies the currency of the purchase invoice that the vendor ledger entry behind this credit transfer entry applies to.';
                }
                field(AppliesToEntryAmount; Rec.AppliesToEntryAmount())
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Applies-to Entry Amount';
                    ToolTip = 'Specifies the payment amount on the purchase invoice that the vendor ledger entry behind this credit transfer entry applies to.';
                }
                field(AppliesToEntryRemainingAmount; Rec.AppliesToEntryRemainingAmount())
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Applies-to Entry Remaining Amount';
                    ToolTip = 'Specifies the amount that remains to be paid on the purchase invoice that the vendor ledger entry behind this credit transfer entry applies to.';
                }
                field("Credit Transfer Register No."; Rec."Credit Transfer Register No.")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }
}

