// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Sales.History;

page 36640 "Order Header Status Factbox"
{
    Caption = 'Sales Order Status';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Sales Header";
    SourceTableView = sorting("Document Type", "Combine Shipments", "Bill-to Customer No.", "Currency Code")
                      where("Document Type" = filter(Order | "Return Order"));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document Type"; Rec."Document Type")
                {
                    Editable = false;
                    ToolTip = 'Specifies the type of the document.';
                    Visible = false;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the record.';

                    trigger OnDrillDown()
                    begin
                        case Rec."Document Type" of
                            Rec."Document Type"::Order:
                                if PAGE.RunModal(PAGE::"Sales Order", Rec) = ACTION::LookupOK then
                                    ;
                            Rec."Document Type"::"Return Order":
                                if PAGE.RunModal(PAGE::"Sales Return Order", Rec) = ACTION::LookupOK then
                                    ;
                        end;
                    end;
                }
                field("Your Reference"; Rec."Your Reference")
                {
                    ToolTip = 'Specifies the customer''s reference. The content will be printed on sales documents.';
                    Visible = false;
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date on which the related sales order was created.';
                }
                field(LastShipmentDate; LastShipmentDate)
                {
                    Caption = 'Last Shipment Date';
                    Editable = false;
                    ToolTip = 'Specifies the date of the last shipment.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        case Rec."Document Type" of
                            Rec."Document Type"::Order:
                                begin
                                    GetLastShipment();
                                    if PAGE.RunModal(PAGE::"Posted Sales Shipments", SalesShipmentHeader) = ACTION::LookupOK then;
                                end;
                            Rec."Document Type"::"Return Order":
                                begin
                                    GetLastRetReceipt();
                                    if PAGE.RunModal(PAGE::"Posted Return Receipts", RetReceiptHeader) = ACTION::LookupOK then;
                                end;
                        end;
                    end;
                }
                field("Requested Delivery Date"; Rec."Requested Delivery Date")
                {
                    Editable = false;
                    ToolTip = 'Specifies the requested delivery date.';
                    Visible = false;
                }
                field("Promised Delivery Date"; Rec."Promised Delivery Date")
                {
                    Editable = false;
                    ToolTip = 'Specifies the promised delivery date for the customer order.';
                    Visible = false;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Next Shipment Date';
                    Editable = false;
                    ToolTip = 'Specifies the next data a shipment is planned for the order.';
                }
                field("Shipping Time"; Rec."Shipping Time")
                {
                    Editable = false;
                    ToolTip = 'Specifies the shipping time for the order. ';
                    Visible = false;
                }
                field("Completely Shipped"; Rec."Completely Shipped")
                {
                    Editable = false;
                    ToolTip = 'Specifies whether all the items on the order have been shipped or, in the case of inbound items, completely received.';
                    Visible = false;
                }
                field(LastInvoiceDate; LastInvoiceDate)
                {
                    Caption = 'Last Invoice Date';
                    Editable = false;
                    ToolTip = 'Specifies the date of the last invoice.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        case Rec."Document Type" of
                            Rec."Document Type"::Order:
                                begin
                                    GetLastInvoice();
                                    if PAGE.RunModal(PAGE::"Posted Sales Invoices", SalesInvoiceHeader) = ACTION::LookupOK then;
                                end;
                            Rec."Document Type"::"Return Order":
                                begin
                                    GetLastCrMemo();
                                    if PAGE.RunModal(PAGE::"Posted Sales Credit Memos", RetCreditMemoHeader) = ACTION::LookupOK then;
                                end;
                        end;
                    end;
                }
                field("Outstanding Amount ($)"; Rec."Outstanding Amount ($)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open Amount';
                    Editable = false;
                    ToolTip = 'Specifies the outstanding amount that is calculated, based on the Sales Line table and the Outstanding Amount (LCY) field.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the status of the document.';
                }
                field("On Hold"; Rec."On Hold")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the document was put on hold when it was posted, for example because payment of the resulting customer ledger entries is overdue.';
                }
            }
            group("Open Amounts")
            {
                Caption = 'Open Amounts';
                field(TotalOpenAmount; TotalOpenAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total';
                    Editable = false;
                    ToolTip = 'Specifies the total amount less any invoice discount amount and exclusive of VAT for the posted document.';
                }
                field(TotalOpenAmountOnHold; TotalOpenAmountOnHold)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'On Hold';
                    Editable = false;
                    ToolTip = 'Specifies lines that are on orders that are on hold.';
                }
                field(TotalOpenAmountPendingApproval; TotalOpenAmountPendingApproval)
                {
                    ApplicationArea = Suite;
                    Caption = 'Pending Approval';
                    Editable = false;
                    ToolTip = 'Specifies that the document remains to be approved.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        GetLastShipmentInvoice();
        UpdateTotal();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        UpdateTotal();
    end;

    trigger OnOpenPage()
    begin
        UpdateTotal();
    end;

    var
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        RetReceiptHeader: Record "Return Receipt Header";
        RetCreditMemoHeader: Record "Sales Cr.Memo Header";
        LastShipmentDate: Date;
        LastInvoiceDate: Date;
        TotalOpenAmount: Decimal;
        TotalOpenAmountOnHold: Decimal;
        TotalOpenAmountPendingApproval: Decimal;

    procedure UpdateTotal()
    begin
        TotalOpenAmount := 0;
        TotalOpenAmountOnHold := 0;
        SalesHeader.Copy(Rec);
        if SalesHeader.FindSet() then
            repeat
                SalesHeader.CalcFields("Outstanding Amount ($)");
                TotalOpenAmount := TotalOpenAmount + SalesHeader."Outstanding Amount ($)";
                if SalesHeader."On Hold" <> '' then
                    TotalOpenAmountOnHold := TotalOpenAmountOnHold + SalesHeader."Outstanding Amount ($)";
                if SalesHeader.Status = SalesHeader.Status::"Pending Approval" then
                    TotalOpenAmountPendingApproval := TotalOpenAmountPendingApproval + SalesHeader."Outstanding Amount ($)";
            until SalesHeader.Next() = 0;
    end;

    procedure GetLastShipmentInvoice()
    begin
        // Calculate values for this row
        case Rec."Document Type" of
            Rec."Document Type"::Order:
                begin
                    if GetLastShipment() then
                        LastShipmentDate := SalesShipmentHeader."Shipment Date"
                    else
                        LastShipmentDate := 0D;
                    if GetLastInvoice() then
                        LastInvoiceDate := SalesInvoiceHeader."Posting Date"
                    else
                        LastInvoiceDate := 0D;
                end;
            Rec."Document Type"::"Return Order":
                begin
                    if GetLastRetReceipt() then
                        LastShipmentDate := RetReceiptHeader."Posting Date"
                    else
                        LastShipmentDate := 0D;
                    if GetLastCrMemo() then
                        LastInvoiceDate := RetCreditMemoHeader."Posting Date"
                    else
                        LastInvoiceDate := 0D;
                end;
            else begin
                LastShipmentDate := 0D;
                LastInvoiceDate := 0D;
            end;
        end;
    end;

    procedure GetLastShipment(): Boolean
    begin
        SalesShipmentHeader.SetCurrentKey("Order No."/*, "Shipment Date"*/); // may want to create this key
        SalesShipmentHeader.SetRange("Order No.", Rec."No.");
        exit(SalesShipmentHeader.FindLast());

    end;

    procedure GetLastInvoice(): Boolean
    begin
        SalesInvoiceHeader.SetCurrentKey("Order No."/*, "Shipment Date"*/); // may want to create this key
        SalesInvoiceHeader.SetRange("Order No.", Rec."No.");
        exit(SalesInvoiceHeader.FindLast());

    end;

    procedure GetLastRetReceipt(): Boolean
    begin
        RetReceiptHeader.SetCurrentKey("Return Order No."/*, "Shipment Date"*/); // may want to create this key
        RetReceiptHeader.SetRange("Return Order No.", Rec."No.");
        exit(RetReceiptHeader.FindLast());

    end;

    procedure GetLastCrMemo(): Boolean
    begin
        RetCreditMemoHeader.SetCurrentKey("Return Order No."/*, "Shipment Date"*/); // may want to create this key
        RetCreditMemoHeader.SetRange("Return Order No.", Rec."No.");
        exit(RetCreditMemoHeader.FindLast());

    end;
}

