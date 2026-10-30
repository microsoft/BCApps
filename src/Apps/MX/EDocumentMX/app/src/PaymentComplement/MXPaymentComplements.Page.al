// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.Sales.Receivables;

page 3359 "MX Payment Complements"
{
    Caption = 'Payment Complements';
    PageType = List;
    SourceTable = "MX Payment Complement";
    SourceTableView = sorting("Entry No.") order(descending);
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Complements)
            {
                field(PaymentDocumentNo; PaymentDocumentNo)
                {
                    Caption = 'Payment Document No.';
                    ToolTip = 'Specifies the document number of the payment.';
                }
                field(CustomerNo; CustomerNo)
                {
                    Caption = 'Customer No.';
                    ToolTip = 'Specifies the customer of the payment.';
                }
                field("Stamped UUID"; Rec."Stamped UUID")
                {
                    ToolTip = 'Specifies the UUID assigned by SAT when the payment complement was stamped.';
                }
                field("Stamped At"; Rec."Stamped At")
                {
                    ToolTip = 'Specifies when the payment complement was stamped.';
                }
                field("Cancellation Status"; Rec."Cancellation Status")
                {
                    ToolTip = 'Specifies the SAT cancellation status of the payment complement.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        PaymentDocumentNo := '';
        CustomerNo := '';
        CustLedgerEntry.SetLoadFields("Document No.", "Customer No.");
        if CustLedgerEntry.Get(Rec."Payment Entry No.") then begin
            PaymentDocumentNo := CustLedgerEntry."Document No.";
            CustomerNo := CustLedgerEntry."Customer No.";
        end;
    end;

    var
        PaymentDocumentNo: Code[20];
        CustomerNo: Code[20];
}
