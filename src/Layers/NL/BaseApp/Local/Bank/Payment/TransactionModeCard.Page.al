// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

page 11000011 "Transaction Mode Card"
{
    Caption = 'Transaction Mode Card';
    PageType = Card;
    SourceTable = "Transaction Mode";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account the transaction mode will be used for.';
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a code you want attached to the transaction mode.';
                }
                field("Order"; Rec.Order)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of order the transaction mode will be used for.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for the transaction mode.';
                }
            }
            group("Paym. Proposal")
            {
                Caption = 'Paym. Proposal';
                field("Our Bank"; Rec."Our Bank")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of your bank, through which you want to perform payments or collections.';
                }
                field("Include in Payment Proposal"; Rec."Include in Payment Proposal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that you want vendor ledger, employee ledger, or customer ledger entries linked to this transaction mode.';
                }
                field("Combine Entries"; Rec."Combine Entries")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that you want ledger entries for the same customer, employee, or vendor, combined into one payment proposal.';
                }
                field("Pmt. Disc. Possible"; Rec."Pmt. Disc. Possible")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that you want payment discount applied to ledger entries linked to this transaction mode.';
                }
                field("Run No. Series"; Rec."Run No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series code used to assign run numbers to payment history entries.';
                }
                field("Export Protocol"; Rec."Export Protocol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the export protocol ID you want to link to the transaction mode.';
                }
                field("Identification No. Series"; Rec."Identification No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series code used to assign identification numbers to proposal lines.';
                }
                field("Partner Type"; Rec."Partner Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Partner Type';
                    ToolTip = 'Specifies if the transaction mode is for a person or a company.';
                }
                field(WorldPayment; Rec.WorldPayment)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the payment will be processed as WorldPayment in the SEPA file export.';
                }
            }
            group("Paym./Rcpts. in Process")
            {
                Caption = 'Paym./Rcpts. in Process';
                field("Acc. No. Pmt./Rcpt. in Process"; Rec."Acc. No. Pmt./Rcpt. in Process")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the G/L account to which payments/receipts in process are to be posted.';
                }
                field("Posting No. Series"; Rec."Posting No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series code used to assign document numbers to payments/receipts in process.';
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source code that you want attached to the transaction mode.';
                }
                field("Correction Posting No. Series"; Rec."Correction Posting No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series code used to assign correction posting document numbers.';
                }
                field("Correction Source Code"; Rec."Correction Source Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the correction source code that you want attached to the transaction mode.';
                }
            }
            group(Integration)
            {
                Caption = 'Integration';
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the method used to submit payment (bank transfer or check, for example), through this transaction mode.';
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the payment terms.';
                }
            }
            group(Costs)
            {
                Caption = 'Costs';
                field("Transfer Cost Domestic"; Rec."Transfer Cost Domestic")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies who will bear the expenses of payments or collections.';
                }
                field("Transfer Cost Foreign"; Rec."Transfer Cost Foreign")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies who will bear the expenses of payments or collections charged by the foreign bank.';
                }
            }
        }
    }

    actions
    {
    }
}

