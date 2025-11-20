// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany;

using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Outbox;
using Microsoft.Intercompany.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

codeunit 437 "IC Navigation"
{
    var
        UnableToNavigateToSpecifiedDocumentMsg: Label 'Unable to navigate to the related document.';

    procedure NavigateToDocument(HandledICInboxTrans: Record "Handled IC Inbox Trans.")
    begin
        if HandledICInboxTrans.IsEmpty() then
            exit;
        NavigateToDocument(HandledICInboxTrans."Document No.", Enum::"IC Direction Type"::Incoming, HandledICInboxTrans."IC Partner Code", HandledICInboxTrans."Document Type", HandledICInboxTrans."IC Source Type");
    end;

    procedure NavigateToDocument(ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
        if ICOutboxTransaction.IsEmpty() then
            exit;
        NavigateToDocument(ICOutboxTransaction."Document No.", Enum::"IC Direction Type"::Outgoing, ICOutboxTransaction."IC Partner Code", ICOutboxTransaction."Document Type", ICOutboxTransaction."IC Source Type");
    end;

    procedure NavigateToDocument(HandledICOutboxTrans: Record "Handled IC Outbox Trans.")
    begin
        if HandledICOutboxTrans.IsEmpty() then
            exit;
        NavigateToDocument(HandledICOutboxTrans."Document No.", Enum::"IC Direction Type"::Outgoing, HandledICOutboxTrans."IC Partner Code", HandledICOutboxTrans."Document Type", HandledICOutboxTrans."IC Source Type");
    end;


    local procedure NavigateToSalesInvoice(DocumentNo: Code[20]): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: Page "Posted Sales Invoice";
    begin
        // An IC Transaction of type Sales Invoice can only be sent when posted, not received.
        if not SalesInvoiceHeader.Get(DocumentNo) then
            exit(false);
        // The related document is a Posted Sales Invoice.
        PostedSalesInvoice.SetRecord(SalesInvoiceHeader);
        PostedSalesInvoice.Run();
        exit(true);
    end;

    local procedure NavigateToSalesCreditMemo(DocumentNo: Code[20]): Boolean
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: Page "Posted Sales Credit Memo";
    begin
        // An IC Transaction of type Sales Credit Memo can only be sent when posted.
        if not SalesCrMemoHeader.Get(DocumentNo) then
            exit(false);
        // The related document is a Posted Sales Credit Memo.
        PostedSalesCreditMemo.SetRecord(SalesCrMemoHeader);
        PostedSalesCreditMemo.Run();
        exit(true);
    end;

    local procedure NavigateToSalesInvoice(DocumentNo: Code[20]; ICPartnerCode: Code[20]): Boolean
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: Page "Posted Sales Invoice";
    begin
        // This is called when we couldn't find a related sales order,
        // so we attempt to find a Posted Sales Invoice
        Customer.SetRange("IC Partner Code", ICPartnerCode);
        if not Customer.FindSet() then
            exit(false);
        repeat
            SalesInvoiceHeader.Reset();
            SalesInvoiceHeader.SetRange("Order No.", DocumentNo);
            SalesInvoiceHeader.SetRange("Sell-to Customer No.", Customer."No.");
            if SalesInvoiceHeader.FindFirst() then begin
                PostedSalesInvoice.SetRecord(SalesInvoiceHeader);
                PostedSalesInvoice.Run();
                exit(true);
            end;
        until Customer.Next() = 0;
        exit(false);
    end;

    local procedure NavigateToSalesOrderDocument(DocumentNo: Code[20]; ICDirectionType: Enum "IC Direction Type"; ICPartnerCode: Code[20]): Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: Page "Sales Order";
    begin
        // An IC transaction line of type sales order, could navigate to either
        // the sales order, or the invoice if it was posted after received

        // We first attempt to find the Sales Order
        case ICDirectionType of
            ICDirectionType::Outgoing:
                begin
                    SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                    SalesHeader.SetRange("No.", DocumentNo);
                end;
            ICDirectionType::Incoming:
                begin
                    SalesHeader.SetRange("External Document No.", DocumentNo);
                    SalesHeader.SetRange("IC Direction", ICDirectionType);
                    SalesHeader.SetRange("Sell-to IC Partner Code", ICPartnerCode);
                end;
        end;
        if SalesHeader.FindFirst() then begin
            SalesOrder.SetRecord(SalesHeader);
            SalesOrder.Run();
            exit(true);
        end;
        // If we can't find it, we attempt to find the corresponding Sales Invoice
        exit(NavigateToSalesInvoice(DocumentNo, ICPartnerCode));
    end;

    local procedure NavigateToSalesDocument(DocumentNo: Code[20]; ICDirectionType: Enum "IC Direction Type"; ICPartnerCode: Code[20]; DocumentType: Enum "IC Transaction Document Type"): Boolean
    var
        ShouldNavigateToDoc: Boolean;
    begin
        case DocumentType of
            DocumentType::Order:
                exit(NavigateToSalesOrderDocument(DocumentNo, ICDirectionType, ICPartnerCode));
            DocumentType::Invoice:
                exit(NavigateToSalesInvoice(DocumentNo));
            DocumentType::"Credit Memo":
                exit(NavigateToSalesCreditMemo(DocumentNo));
            else begin
                ShouldNavigateToDoc := false;
                OnNavigateToSalesDocumentOnAfterCheckDocumentType(DocumentNo, ICDirectionType, ICPartnerCode, DocumentType, ShouldNavigateToDoc);
                exit(ShouldNavigateToDoc);
            end;
        end;
    end;

    local procedure NavigateToPurchaseInvoice(DocumentNo: Code[20]; ICPartnerCode: Code[20]): Boolean
    var
        Vendor: Record Vendor;
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: Page "Posted Purchase Invoice";
    begin
        // When this is called, we tried to find a purchase order, but we couldn't find it
        // so we attempt to navigate to the Posted Purchase Invoice instead
        Vendor.SetRange("IC Partner Code", ICPartnerCode);
        if not Vendor.FindSet() then
            exit(false);
        repeat
            PurchInvHeader.Reset();
            PurchInvHeader.SetRange("Vendor Order No.", DocumentNo);
            PurchInvHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
            if PurchInvHeader.FindFirst() then begin
                PostedPurchaseInvoice.SetRecord(PurchInvHeader);
                PostedPurchaseInvoice.Run();
                exit(true);
            end;
        until Vendor.Next() = 0;
        exit(false);
    end;

    local procedure NavigateToPostedPurchaseInvoice(DocumentNo: Code[20]; VendorNo: Code[20]): Boolean
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: Page "Posted Purchase Invoice";
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchInvHeader.SetRange("Vendor Invoice No.", DocumentNo);
        if not PurchInvHeader.FindFirst() then
            exit(false);
        PostedPurchaseInvoice.SetRecord(PurchInvHeader);
        PostedPurchaseInvoice.Run();
        exit(true);
    end;

    local procedure NavigateToPurchaseInvoiceDocument(DocumentNo: Code[20]; ICPartnerCode: Code[20]): Boolean
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: Page "Purchase Invoice";
    begin
        // An IC Transaction of type purchase invoice, could navigate to either
        // the purchase invoice, or the posted purchase invoice if it was posted after received.
        Vendor.SetRange("IC Partner Code", ICPartnerCode);
        if not Vendor.FindSet() then
            exit(false);
        repeat
            PurchaseHeader.SetRange("IC Direction", PurchaseHeader."IC Direction"::Incoming);
            PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
            PurchaseHeader.SetRange("Vendor Invoice No.", DocumentNo);
            if PurchaseHeader.FindFirst() then begin
                PurchaseInvoice.SetRecord(PurchaseHeader);
                PurchaseInvoice.Run();
                exit(true);
            end;
            if NavigateToPostedPurchaseInvoice(DocumentNo, Vendor."No.") then
                exit(true);
        until Vendor.Next() = 0;
        exit(false);
    end;

    local procedure NavigateToPurchaseOrderDocument(DocumentNo: Code[20]; ICDirectionType: Enum "IC Direction Type"; ICPartnerCode: Code[20]): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: Page "Purchase Order";
    begin
        // An IC transaction line of type sales order, could navigate to either
        // the sales order, or the invoice if it was posted after received

        // We first attempt to find the Sales Order
        case ICDirectionType of
            ICDirectionType::Outgoing:
                begin
                    PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
                    PurchaseHeader.SetRange("No.", DocumentNo);
                end;
            ICDirectionType::Incoming:
                begin
                    PurchaseHeader.SetRange("Vendor Order No.", DocumentNo);
                    PurchaseHeader.SetRange("IC Direction", ICDirectionType);
                    PurchaseHeader.SetRange("Buy-from IC Partner Code", ICPartnerCode);
                end;
        end;
        if PurchaseHeader.FindFirst() then begin
            PurchaseOrder.SetRecord(PurchaseHeader);
            PurchaseOrder.Run();
            exit(true);
        end;
        // If we can't find it, we attempt to find the corresponding Sales Invoice
        exit(NavigateToPurchaseInvoice(DocumentNo, ICPartnerCode));
    end;

    local procedure NavigateToPurchaseDocument(DocumentNo: Code[20]; ICDirectionType: Enum "IC Direction Type"; ICPartnerCode: Code[20]; DocumentType: Enum "IC Transaction Document Type"): Boolean
    var
        OpenDoc: Boolean;
    begin
        case DocumentType of
            DocumentType::Order:
                exit(NavigateToPurchaseOrderDocument(DocumentNo, ICDirectionType, ICPartnerCode));
            DocumentType::Invoice:
                exit(NavigateToPurchaseInvoiceDocument(DocumentNo, ICPartnerCode));
            else begin
                OnNavigateToPurchaseDocumentOnDocumentTypeCaseElse(DocumentNo, ICDirectionType, ICPartnerCode, DocumentType, OpenDoc);
                exit(OpenDoc);
            end;
        end;
        exit(false);
    end;

    local procedure NavigateToDocument(DocumentNo: Code[20]; ICDirectionType: Enum "IC Direction Type"; ICPartnerCode: Code[20]; DocumentType: Enum "IC Transaction Document Type"; SourceType: enum "IC Transaction Source Type")
    var
        Succeeded: Boolean;
    begin
        case SourceType of
            SourceType::"Sales Document":
                Succeeded := NavigateToSalesDocument(DocumentNo, ICDirectionType, ICPartnerCode, DocumentType);
            SourceType::"Purchase Document":
                Succeeded := NavigateToPurchaseDocument(DocumentNo, ICDirectionType, ICPartnerCode, DocumentType);
        end;
        if not Succeeded then
            Error(UnableToNavigateToSpecifiedDocumentMsg);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNavigateToPurchaseDocumentOnDocumentTypeCaseElse(DocumentNo: Code[20]; ICDirectionType: Enum "IC Direction Type"; ICPartnerCode: Code[20]; DocumentType: Enum "IC Transaction Document Type"; var OpenDoc: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNavigateToSalesDocumentOnAfterCheckDocumentType(DocumentNo: Code[20]; ICDirectionType: Enum "IC Direction Type"; ICPartnerCode: Code[20]; ICTransactionDocumentType: Enum "IC Transaction Document Type"; var ShouldNavigateToDoc: Boolean)
    begin
    end;
}
