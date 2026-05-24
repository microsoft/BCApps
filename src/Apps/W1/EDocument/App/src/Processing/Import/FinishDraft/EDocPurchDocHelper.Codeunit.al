// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.EServices.EDocument.Processing.Import.Purchase;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;

/// <summary>
/// Shared logic for creating BC purchase documents (invoices and credit memos) from e-document draft data.
/// </summary>
codeunit 6402 "E-Doc. Purch. Doc. Helper"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure ValidateFieldWithContext(var Rec: Record "Purchase Header"; FieldNo: Integer; Value: Variant)
    var
        VariantRec: Variant;
    begin
        VariantRec := Rec;
        ValidateFieldWithContext(VariantRec, FieldNo, Value);
        Rec := VariantRec;
    end;

    local procedure ValidateFieldWithContext(var RecVariant: Variant; FieldNo: Integer; Value: Variant)
    var
        EDocImportErrorContext: Codeunit "E-Doc. Import Error Context";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.GetTable(RecVariant);
        FldRef := RecRef.Field(FieldNo);
        EDocImportErrorContext.OnValidateFieldWithContext(FldRef.Caption());
        FldRef.Validate(Value);
        RecRef.SetTable(RecVariant);
    end;

    procedure ApplyDefaultPostingDateFromSetup(var PurchaseHeader: Record "Purchase Header"; EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.GetRecordOnce();
        if (PurchasesPayablesSetup."E-Doc. Def. Posting Date" <> PurchasesPayablesSetup."E-Doc. Def. Posting Date"::"Document Date") then
            exit;
        if EDocumentPurchaseHeader."Document Date" = 0D then
            exit;
        PurchaseHeader.Validate("Posting Date", EDocumentPurchaseHeader."Document Date");
    end;
}
