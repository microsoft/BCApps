// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

page 1632 "Office Invoice Selection"
{
    Caption = 'Invoice Exists';
    DataCaptionExpression = CompanyName();
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    InstructionalText = 'An invoice already exists for this appointment.';
    ModifyAllowed = false;
    ShowFilter = false;
    SourceTable = "Office Invoice";

    layout
    {
        area(content)
        {
            group(Control2)
            {
                Editable = false;
                InstructionalText = 'At least one sales invoice has already been created for this appointment. You may select an existing invoice or continue creating a new invoice for the appointment.';
                ShowCaption = false;
            }
            field(NewInvoice; NewSalesInvoiceLbl)
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ShowCaption = false;
                ToolTip = 'Specifies a new invoice.';

                trigger OnDrillDown()
                var
                    Customer: Record Customer;
                begin
                    Customer.Get(CurrentCustomerNo);
                    Customer.CreateAndShowNewInvoice();
                    CurrPage.Close();
                end;
            }
            repeater("Existing Sales Invoices")
            {
                field("No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related document.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowInvoice();
                    end;
                }
                field("Sell-to Customer Name"; SellToCustomer)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sell-to Customer Name';
                    ToolTip = 'Specifies the name of the customer on the document.';
                }
                field(Posted; Rec.Posted)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted';
                    ToolTip = 'Specifies whether the document has been posted.';
                }
                field("Posting Date"; PostingDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Date';
                    ToolTip = 'Specifies the posting date for the document.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount';
                    ToolTip = 'Specifies the amount on the document.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if Rec.Posted then begin
            SalesInvoiceHeader.Get(Rec."Document No.");
            PostingDate := SalesInvoiceHeader."Posting Date";
            SalesInvoiceHeader.CalcFields(Amount);
            Amount := SalesInvoiceHeader.Amount;
            SellToCustomer := SalesInvoiceHeader."Sell-to Customer Name";
        end else begin
            SalesHeader.Get(SalesHeader."Document Type"::Invoice, Rec."Document No.");
            SalesHeader.CalcFields(Amount);
            Amount := SalesHeader.Amount;
            SellToCustomer := SalesHeader."Sell-to Customer Name";
        end;
    end;

    var
        SellToCustomer: Text[100];
        PostingDate: Date;
        Amount: Decimal;
        NewSalesInvoiceLbl: Label 'Create a new sales invoice';
        CurrentCustomerNo: Code[20];

    procedure SetCustomerNo(CustNo: Code[20])
    begin
        CurrentCustomerNo := CustNo;
    end;
}

