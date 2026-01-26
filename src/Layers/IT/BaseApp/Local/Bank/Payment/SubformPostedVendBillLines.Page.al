// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

page 12193 "Subform Posted Vend Bill Lines"
{
    Caption = 'Lines';
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Posted Vendor Bill Line";

    layout
    {
        area(content)
        {
            repeater(Control1130000)
            {
                ShowCaption = false;
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the vendor''s identification number from the original purchase transaction.';
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = All;
                    DrillDown = false;
                    ToolTip = 'Specifies the vendor''s name from the original purchase transaction.';
                }
                field("Manual Line"; Rec."Manual Line")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the vendor bill line was entered manually.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the bill line.';
                    Visible = false;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional part of the description of the bill line.';
                    Visible = false;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of document that is the source of the vendor bill.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the transaction date of the source document that generated the original purchase transaction.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a unique identification number that refers to the source document that generated the original purchase transaction.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies an identification number, which links the vendor''s source document to the posted vendor bill.';
                }
                field("Cumulative Transfers"; Rec."Cumulative Transfers")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the vendor bill entry is included in a cumulative bank transfer.';
                }
                field("Instalment Amount"; Rec."Instalment Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount due for the current installment payment.';
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that has not yet been paid.';
                }
                field("Amount to Pay"; Rec."Amount to Pay")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount due for the vendor bill line.';
                }
                field("Withholding Tax Amount"; Rec."Withholding Tax Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of withholding tax that is due for the vendor bill.';
                }
                field("Social Security Amount"; Rec."Social Security Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of Social Security tax that is due for the vendor bill line.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the due date for the payment amount.';
                }
                field("Vendor Bank Acc. No."; Rec."Vendor Bank Acc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s bank account number from the original purchase transaction.';
                }
                field("Beneficiary Value Date"; Rec."Beneficiary Value Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the transferred funds from vendor bill are available for use by the vendor.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("P&osted Vend. Bill Line")
            {
                Caption = 'P&osted Vend. Bill Line';
                Image = PostedVendorBill;
                action(InvoiceCard)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Invoice Card';
                    ToolTip = 'View the releated invoice card.';

                    trigger OnAction()
                    begin
                        Rec.ShowInvoice();
                    end;
                }
                action(Dimension)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimension';
                    ToolTip = 'View the related dimension.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
            }
        }
    }
}

