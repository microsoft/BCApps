// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

/// <summary>
/// Provides a detailed view of exchange rate adjustment ledger entries.
/// Displays individual adjustment transactions with account details, amounts, and audit information.
/// </summary>
/// <remarks>
/// Source Table: Exch. Rate Adjmt. Ledg. Entry (186). Offers comprehensive visibility
/// into adjustment calculations including base amounts, adjustment amounts, and
/// currency factors used for each individual adjustment entry.
/// </remarks>
page 186 "Exch.Rate Adjmt. Ledg.Entries"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Exch. Rate Adjmt. Ledger Entries';
    DataCaptionFields = "Account Type", "Account No.";
    Editable = false;
    PageType = List;
    SourceTable = "Exch. Rate Adjmt. Ledg. Entry";
    SourceTableView = sorting("Register No.", "Entry No.")
                      order(descending);
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Account"; Rec."Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                }
                field("Currency Factor"; Rec."Currency Factor")
                {
                    ApplicationArea = Suite;
                }
                field("Base Amount"; Rec."Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Base Amount (LCY)"; Rec."Base Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that remains to be applied to before the entry is totally applied to.';
                }
                field("Adjustment Amount"; Rec."Adjustment Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Register No."; Rec."Register No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Detailed Ledger Entry No."; Rec."Detailed Ledger Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
            }
        }
    }
}
