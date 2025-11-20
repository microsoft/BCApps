// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Purchases.History;
using Microsoft.Sales.History;

codeunit 325 "Update Currency Factor"
{
    Permissions = TableData "Sales Invoice Header" = rm,
                  TableData "Sales Cr.Memo Header" = rm,
                  TableData "Purch. Inv. Header" = rm,
                  TableData "Purch. Cr. Memo Hdr." = rm;

    trigger OnRun()
    begin
    end;

    procedure ModifyPostedSalesInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader.Modify();
    end;

    procedure ModifyPostedSalesCreditMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        SalesCrMemoHeader.Modify();
    end;

    procedure ModifyPostedPurchaseInvoice(var PurchInvHeader: Record "Purch. Inv. Header")
    begin
        PurchInvHeader.Modify();
    end;

    procedure ModifyPostedPurchaseCreditMemo(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
        PurchCrMemoHdr.Modify();
    end;
}

