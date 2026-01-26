// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Sales.History;

page 10011 "Customer Order Header Part"
{
    Caption = 'Customer Order Header Status';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Sales Header";
    SourceTableView = sorting("Document Type", "Sell-to Customer No.", "No.")
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
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer''s reference. The content will be printed on sales documents.';
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date on which the related sales order was created.';
                }
                field(LastShipmentDate; LastShipmentDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Last Shipment Date';
                    Editable = false;
                    ToolTip = 'Specifies the date when the order was last posted as shipped.';

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
                                    if PAGE.RunModal(PAGE::"Posted Return Receipts", ReturnReceiptHeader) = ACTION::LookupOK then;
                                end;
                        end;
                    end;
                }
                field("Requested Delivery Date"; Rec."Requested Delivery Date")
                {
                    Editable = false;
                    ToolTip = 'Specifies the requested delivery date for the customer order.';
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
                    ToolTip = 'Specifies the shipping time for the order. This is the time it takes from when the order is shipped from the warehouse, to when the order is delivered to the customer''s address.';
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
                    ApplicationArea = Basic, Suite;
                    Caption = 'Last Invoice Date';
                    Editable = false;
                    ToolTip = 'Specifies the date when the order was last posted as invoiced.';

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
                                    if PAGE.RunModal(PAGE::"Posted Sales Credit Memos", SalesCrMemoHeader) = ACTION::LookupOK then;
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
                    Editable = "On HoldEditable";
                    ToolTip = 'Specifies if the document was put on hold when it was posted, for example because payment of the resulting customer ledger entries is overdue.';
                }
            }
            group(Control20)
            {
                ShowCaption = false;
                field(TotalOpenAmountOnHold; TotalOpenAmountOnHold)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Open Amount On Hold';
                    Editable = false;
                    ToolTip = 'Specifies the total amount on open documents that are on hold.';
                }
                field(TotalOpenAmount; TotalOpenAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Open Amount';
                    Editable = false;
                    ToolTip = 'Specifies the total amount on open documents.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        OnBeforeOnAfterGetRecord(Rec);

        GetLastShipmentInvoice();
        AfterGetCurrentRecord();
    end;

    trigger OnInit()
    begin
        "On HoldEditable" := true;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        UpdateTotal();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        AfterGetCurrentRecord();
    end;

    trigger OnOpenPage()
    begin
        OnCreditManagementForm(true);
        UpdateTotal();
    end;

    var
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        LastShipmentDate: Date;
        LastInvoiceDate: Date;
        TotalOpenAmount: Decimal;
        TotalOpenAmountOnHold: Decimal;
        "On HoldEditable": Boolean;

    procedure OnCreditManagementForm(SetOnCreditManagementForm: Boolean)
    begin
        // Make certain Fields editable
        "On HoldEditable" := SetOnCreditManagementForm;
    end;

    procedure UpdateTotal()
    begin
        TotalOpenAmount := 0;
        TotalOpenAmountOnHold := 0;
        SalesHeader.Copy(Rec);
        if SalesHeader.Find('-') then
            repeat
                OnUpdateTotalOnBeforeSalesHeaderCalcOutstandingAmount(SalesHeader);
                SalesHeader.CalcFields("Outstanding Amount ($)");
                TotalOpenAmount := TotalOpenAmount + SalesHeader."Outstanding Amount ($)";
                if SalesHeader."On Hold" <> '' then
                    TotalOpenAmountOnHold := TotalOpenAmountOnHold + SalesHeader."Outstanding Amount ($)";
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
                        LastShipmentDate := ReturnReceiptHeader."Posting Date"
                    else
                        LastShipmentDate := 0D;
                    if GetLastCrMemo() then
                        LastInvoiceDate := ReturnReceiptHeader."Posting Date"
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
        ReturnReceiptHeader.SetCurrentKey("Return Order No."/*, "Shipment Date"*/); // may want to create this key
        ReturnReceiptHeader.SetRange("Return Order No.", Rec."No.");
        exit(ReturnReceiptHeader.FindLast());

    end;

    procedure GetLastCrMemo(): Boolean
    begin
        SalesCrMemoHeader.SetCurrentKey("Return Order No."/*, "Shipment Date"*/); // may want to create this key
        SalesCrMemoHeader.SetRange("Return Order No.", Rec."No.");
        exit(SalesCrMemoHeader.FindLast());
    end;

    local procedure AfterGetCurrentRecord()
    begin
        xRec := Rec;
        UpdateTotal();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnAfterGetRecord(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateTotalOnBeforeSalesHeaderCalcOutstandingAmount(var SalesHeader: Record "Sales Header")
    begin
    end;
}

