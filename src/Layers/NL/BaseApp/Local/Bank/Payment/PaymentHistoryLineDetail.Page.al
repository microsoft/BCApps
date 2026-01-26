// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

page 11000009 "Payment History Line Detail"
{
    Caption = 'Payment History Line Detail';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "Payment History Line";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the payment history line.';
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the account you want to perform payments to, or collections from.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the account you want to perform payments to, or collections from.';
                }
                field(Bank; Rec.Bank)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number for the bank you want to perform payments to, or collections from.';
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account number you want to perform payments to, or collections from.';
                }
                field("Transaction Mode"; Rec."Transaction Mode")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction mode used in telebanking.';
                }
                field("Order"; Rec.Order)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the order type of the payment history line.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies total amount (including VAT) for the entry.';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when you want the payment or collection to be performed.';
                }
            }
            part(Control47; "Detail Line Subform")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                SubPageLink = "Connect Batches" = field("Run No."),
                              "Connect Lines" = field("Line No."),
                              "Our Bank" = field("Our Bank"),
                              Status = filter("In process" | Posted | Correction);
                SubPageView = sorting("Our Bank", Status, "Connect Batches", "Connect Lines", Date);
            }
            group(Remark)
            {
                Caption = 'Remark';
                field(Identification; Rec.Identification)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identification number for the payment history line.';
                }
                field("Description 1"; Rec."Description 1")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the payment history line.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional description of the payment history line.';
                }
                field("Description 3"; Rec."Description 3")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional description of the payment history line.';
                }
                field("Description 4"; Rec."Description 4")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional description of the payment history line.';
                }
            }
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
                    ToolTip = 'Specifies the country/region code of the bank account holder.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange("Line No.");
    end;
}

