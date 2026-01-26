// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

page 11000010 "Transaction Mode List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Transaction Modes';
    CardPageID = "Transaction Mode Card";
    Editable = false;
    PageType = List;
    SourceTable = "Transaction Mode";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of account the transaction mode will be used for.';
                    Visible = "Account TypeVisible";
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a code you want attached to the transaction mode.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for the transaction mode.';
                }
                field("Our Bank"; Rec."Our Bank")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of your bank, through which you want to perform payments or collections.';
                }
                field("Order"; Rec.Order)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of order the transaction mode will be used for.';
                }
                field("Pmt. Disc. Possible"; Rec."Pmt. Disc. Possible")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that you want payment discount applied to ledger entries linked to this transaction mode.';
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
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the method used to submit payment (bank transfer or check, for example), through this transaction mode.';
                    Visible = false;
                }
                field("Acc. No. Pmt./Rcpt. in Process"; Rec."Acc. No. Pmt./Rcpt. in Process")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the G/L account to which payments/receipts in process are to be posted.';
                    Visible = false;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source code that you want attached to the transaction mode.';
                    Visible = false;
                }
                field("Posting No. Series"; Rec."Posting No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series code used to assign document numbers to payments/receipts in process.';
                    Visible = false;
                }
                field("Correction Posting No. Series"; Rec."Correction Posting No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series code used to assign correction posting document numbers.';
                    Visible = false;
                }
                field("Correction Source Code"; Rec."Correction Source Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the correction source code that you want attached to the transaction mode.';
                    Visible = false;
                }
                field("Identification No. Series"; Rec."Identification No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series code used to assign identification numbers to proposal lines.';
                    Visible = false;
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the payment terms.';
                    Visible = false;
                }
                field("Export Protocol"; Rec."Export Protocol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the export protocol ID you want to link to the transaction mode.';
                    Visible = false;
                }
                field("Run No. Series"; Rec."Run No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series code used to assign run numbers to payment history entries.';
                    Visible = false;
                }
                field(WorldPayment; Rec.WorldPayment)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the payment will be processed as WorldPayment in the SEPA file export.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        "Account TypeVisible" := true;
    end;

    var
        "Account TypeVisible": Boolean;
}

