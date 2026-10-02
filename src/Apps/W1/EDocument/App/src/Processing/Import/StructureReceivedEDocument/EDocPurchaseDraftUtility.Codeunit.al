// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;

codeunit 6234 "E-Doc. Purchase Draft Utility"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure PersistDraft(EDocument: Record "E-Document"; var TempEDocPurchaseHeader: Record "E-Document Purchase Header" temporary; var TempEDocPurchaseLine: Record "E-Document Purchase Line" temporary)
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        // Clean up old data, since we are re-reading data
        EDocumentPurchaseHeader.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocumentPurchaseHeader.DeleteAll();
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocumentPurchaseLine.DeleteAll(true);

        EDocumentPurchaseHeader := TempEDocPurchaseHeader;
        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader.Insert();
        OnInsertedEDocumentPurchaseHeader(EDocument, EDocumentPurchaseHeader);

        if TempEDocPurchaseLine.FindSet() then begin
            repeat
                EDocumentPurchaseLine := TempEDocPurchaseLine;
                EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
                EDocumentPurchaseLine."Line No." := EDocumentPurchaseLine.GetNextLineNo(EDocument."Entry No");
                EDocumentPurchaseLine.Insert();
            until TempEDocPurchaseLine.Next() = 0;

            OnInsertedEDocumentPurchaseLines(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseLine);
        end;
    end;

    procedure JoinInvoiceReferences(InvoiceReferences: List of [Text]): Text
    var
        DistinctReferences: List of [Text];
        Reference: Text;
        Result: TextBuilder;
    begin
        foreach Reference in InvoiceReferences do begin
            Reference := DelChr(Reference, '<>', ' ');
            if (Reference <> '') and not DistinctReferences.Contains(Reference) then
                DistinctReferences.Add(Reference);
        end;
        foreach Reference in DistinctReferences do begin
            if Result.Length() > 0 then
                Result.Append(InvoiceReferenceSeparatorTok);
            Result.Append(Reference);
        end;
        exit(Result.ToText());
    end;

    procedure ReferencesSeveralInvoices(InvoiceReferences: Text): Boolean
    begin
        exit(InvoiceReferences.Contains(DelChr(InvoiceReferenceSeparatorTok, '>', ' ')));
    end;

    [InternalEvent(false, false)]
    local procedure OnInsertedEDocumentPurchaseHeader(EDocument: Record "E-Document"; EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    begin
    end;

    [InternalEvent(false, false)]
    local procedure OnInsertedEDocumentPurchaseLines(EDocument: Record "E-Document"; EDocumentPurchaseHeader: Record "E-Document Purchase Header"; EDocumentPurchaseLine: Record "E-Document Purchase Line")
    begin
    end;

    var
        InvoiceReferenceSeparatorTok: Label ', ', Locked = true;
}
