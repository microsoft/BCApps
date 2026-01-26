// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

page 12102 "Subform Sent Vendor Bill Lines"
{
    Caption = 'Lines';
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Vendor Bill Line";

    layout
    {
        area(content)
        {
            repeater(Control1130000)
            {
                ShowCaption = false;
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the vendor''s identification number from the original purchase transaction.';
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = Basic, Suite;
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
                    ToolTip = 'Specifies a description for the bill line.';
                    Visible = false;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional description for the bill line.';
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
                    ToolTip = 'Specifies an identification number, using the numbering system of the vendor, which links the vendor''s source document to the vendor bill.';
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

                    trigger OnValidate()
                    begin
                        if (Rec."Withholding Tax Amount" <> 0) or (Rec."Social Security Amount" <> 0) then
                            Message(Text12100, Rec.FieldCaption("Withholding Tax Amount"), Rec.FieldCaption("Social Security Amount"));
                    end;
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
                field("Has Payment Export Error"; Rec."Has Payment Export Error")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if an error occurred during the payment export.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("V&end. Bill Lines")
            {
                Caption = 'V&end. Bill Lines';
                action("Invoice Card")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Invoice Card';
                    ToolTip = 'View the invoice card.';

                    trigger OnAction()
                    begin
                        Rec.ShowInvoice();
                    end;
                }
                action(Dimension)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimension';
                    ToolTip = 'View the dimension.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                action("Withholding-INPS")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Withholding-INPS';
                    Image = SocialSecurityTax;
                    ToolTip = 'View the withholding tax for INPS.';

                    trigger OnAction()
                    begin
                        Rec.ShowVendorBillWithhTax(false);
                    end;
                }
            }
        }
    }

    var
        Text12100: Label 'Please recalculate %1 and %2 from the Withholding - INPS.';
}

