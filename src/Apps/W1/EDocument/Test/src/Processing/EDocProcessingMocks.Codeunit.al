// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Purchases.Document;

codeunit 133503 "E-Doc. Processing Mocks" implements IEDocumentCreatePurchaseInvoice, IEDocumentCreatePurchaseCreditMemo
{

    procedure CreatePurchaseInvoice(EDocument: Record "E-Document") PurchaseHeader: Record "Purchase Header"
    begin
        PurchaseHeader."No." := 'ED-' + Format(EDocument."Entry No");
        PurchaseHeader."Document Type" := "Purchase Document Type"::Invoice;
        PurchaseHeader.Insert();
    end;

    procedure CreatePurchaseCreditMemo(EDocument: Record "E-Document") PurchaseHeader: Record "Purchase Header"
    begin
        PurchaseHeader."No." := 'CM-' + Format(EDocument."Entry No");
        PurchaseHeader."Document Type" := "Purchase Document Type"::"Credit Memo";
        PurchaseHeader.Insert();
    end;

}
