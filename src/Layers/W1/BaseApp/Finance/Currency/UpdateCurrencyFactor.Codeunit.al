// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Purchases.History;
using Microsoft.Sales.History;

/// <summary>
/// Provides procedures for updating currency factors in posted document headers.
/// Handles modifications to sales and purchase invoice and credit memo headers
/// when currency factors need to be updated after posting.
/// </summary>
/// <remarks>
/// Contains restricted procedures with special permissions for modifying posted documents.
/// Used primarily during currency factor corrections and data migration scenarios.
/// </remarks>
codeunit 325 "Update Currency Factor"
{
    Permissions = TableData "Sales Invoice Header" = rm,
                  TableData "Sales Cr.Memo Header" = rm,
                  TableData "Purch. Inv. Header" = rm,
                  TableData "Purch. Cr. Memo Hdr." = rm;

    trigger OnRun()
    begin
    end;

    /// <summary>
    /// Modifies a posted sales invoice header record with updated currency factor information.
    /// </summary>
    /// <param name="SalesInvoiceHeader">Sales invoice header to be modified</param>
    procedure ModifyPostedSalesInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader.Modify();
    end;

    /// <summary>
    /// Modifies a posted sales credit memo header record with updated currency factor information.
    /// </summary>
    /// <param name="SalesCrMemoHeader">Sales credit memo header to be modified</param>
    procedure ModifyPostedSalesCreditMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        SalesCrMemoHeader.Modify();
    end;

    /// <summary>
    /// Modifies a posted purchase invoice header record with updated currency factor information.
    /// </summary>
    /// <param name="PurchInvHeader">Purchase invoice header to be modified</param>
    procedure ModifyPostedPurchaseInvoice(var PurchInvHeader: Record "Purch. Inv. Header")
    begin
        PurchInvHeader.Modify();
    end;

    /// <summary>
    /// Modifies a posted purchase credit memo header record with updated currency factor information.
    /// </summary>
    /// <param name="PurchCrMemoHdr">Purchase credit memo header to be modified</param>
    procedure ModifyPostedPurchaseCreditMemo(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
        PurchCrMemoHdr.Modify();
    end;
}

