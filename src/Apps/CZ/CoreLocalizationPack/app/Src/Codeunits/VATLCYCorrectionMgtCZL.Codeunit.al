// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Calculation;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

codeunit 11769 "VAT LCY Correction Mgt. CZL"
{
    var
        VATCorrectionNotAllowedErr: Label 'VAT correction in LCY is not allowed on the %1 %2.', Comment = '%1 = Table Caption, %2 = Document No.';

    internal procedure CheckSourceDocument(SourceDocument: Variant)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
#if not CLEAN29
        VATLCYCorrectionCZL: Page "VAT LCY Correction CZL";
#endif
        SourceDocumentRecRef: RecordRef;
#if not CLEAN29
        NewDocumentNo: Code[20];
        NewPostingDate: Date;
        NewTransactionNo: Integer;
        IsHandled: Boolean;
#endif
    begin
        SourceDocumentRecRef.GetTable(SourceDocument);
        case SourceDocumentRecRef.Number of
            Database::"Purch. Inv. Header":
                begin
                    SourceDocumentRecRef.SetTable(PurchInvHeader);
                    if not PurchInvHeader.IsVATLCYCorrectionAllowedCZL() then
                        Error(VATCorrectionNotAllowedErr, PurchInvHeader.TableCaption(), PurchInvHeader."No.");
                end;
            Database::"Purch. Cr. Memo Hdr.":
                begin
                    SourceDocumentRecRef.SetTable(PurchCrMemoHdr);
                    if not PurchCrMemoHdr.IsVATLCYCorrectionAllowedCZL() then
                        Error(VATCorrectionNotAllowedErr, PurchCrMemoHdr.TableCaption(), PurchCrMemoHdr."No.");
                end;
            Database::"Sales Invoice Header":
                begin
                    SourceDocumentRecRef.SetTable(SalesInvoiceHeader);
                    if not SalesInvoiceHeader.IsVATLCYCorrectionAllowedCZL() then
                        Error(VATCorrectionNotAllowedErr, SalesInvoiceHeader.TableCaption(), SalesInvoiceHeader."No.");
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    SourceDocumentRecRef.SetTable(SalesCrMemoHeader);
                    if not SalesCrMemoHeader.IsVATLCYCorrectionAllowedCZL() then
                        Error(VATCorrectionNotAllowedErr, SalesCrMemoHeader.TableCaption(), SalesCrMemoHeader."No.");
                end;
#if not CLEAN29
            else begin
                VATLCYCorrectionCZL.RaiseOnInitGlobals(SourceDocumentRecRef, NewDocumentNo, NewPostingDate, NewTransactionNo, IsHandled);
                OnCheckSourceDocumentElse(SourceDocumentRecRef);
            end;
#else
            else
                OnCheckSourceDocumentElse(SourceDocumentRecRef);
#endif
        end;
    end;

    /// <summary>
    /// Gets the VAT LCY correction buffer entries for the specified source document.
    /// </summary>
    /// <param name="SourceDocument">The source document variant (Purch. Inv. Header, Purch. Cr. Memo Hdr., Sales Invoice Header, or Sales Cr.Memo Header).</param>
    /// <param name="TempVATLCYCorrectionBufferCZL">The temporary buffer to populate with VAT correction entries.</param>
    /// <returns>True if any VAT entries were found; otherwise, false.</returns>
    procedure GetVATLCYCorrectionBuffer(SourceDocument: Variant; var TempVATLCYCorrectionBufferCZL: Record "VAT LCY Correction Buffer CZL" temporary): Boolean
    var
        TempVATLCYCorrDocumentCZL: Record "VAT LCY Corr. Document CZL";
    begin
        TempVATLCYCorrDocumentCZL.CopyFrom(SourceDocument);
        exit(GetVATLCYCorrectionBuffer(TempVATLCYCorrDocumentCZL, TempVATLCYCorrectionBufferCZL));
    end;

    local procedure GetVATLCYCorrectionBuffer(TempVATLCYCorrDocumentCZL: Record "VAT LCY Corr. Document CZL"; var TempVATLCYCorrectionBufferCZL: Record "VAT LCY Correction Buffer CZL" temporary): Boolean
    var
        VATEntry: Record "VAT Entry";
        SourceCodeSetup: Record "Source Code Setup";
#if not CLEAN29
        VATLCYCorrectionCZL: Page "VAT LCY Correction CZL";
#endif
    begin
        SourceCodeSetup.Get();

        TempVATLCYCorrectionBufferCZL.Reset();
        TempVATLCYCorrectionBufferCZL.DeleteAll(false);

        if TempVATLCYCorrDocumentCZL."Transaction No." = 0 then
            exit(false);

        VATEntry.Reset();
        VATEntry.SetCurrentKey("Transaction No.");
        VATEntry.SetRange("Transaction No.", TempVATLCYCorrDocumentCZL."Transaction No.");
        if VATEntry.FindSet() then
            repeat
                TempVATLCYCorrectionBufferCZL.InsertFromVATEntry(VATEntry);
                TempVATLCYCorrectionBufferCZL."Dimension Set ID" := TempVATLCYCorrDocumentCZL."Dimension Set ID";
                TempVATLCYCorrectionBufferCZL.Modify(false);
            until VATEntry.Next() = 0;

        VATEntry.Reset();
        VATEntry.SetCurrentKey("Document No.", "Posting Date");
        VATEntry.SetRange("Document No.", TempVATLCYCorrDocumentCZL."Document No.");
        VATEntry.SetRange("Posting Date", TempVATLCYCorrDocumentCZL."Posting Date");
        VATEntry.SetRange("Source Code", SourceCodeSetup."VAT LCY Correction CZL");
        if VATEntry.FindSet() then
            repeat
                TempVATLCYCorrectionBufferCZL.InsertFromVATEntry(VATEntry);
                TempVATLCYCorrectionBufferCZL."Dimension Set ID" := TempVATLCYCorrDocumentCZL."Dimension Set ID";
                TempVATLCYCorrectionBufferCZL.Modify(false);
            until VATEntry.Next() = 0;

#if not CLEAN29
        VATLCYCorrectionCZL.RaiseOnAfterGetDocumentVATEntries(TempVATLCYCorrectionBufferCZL, TempVATLCYCorrDocumentCZL."Document No.", TempVATLCYCorrDocumentCZL."Posting Date", TempVATLCYCorrDocumentCZL."Transaction No.", TempVATLCYCorrDocumentCZL."Dimension Set ID");
#endif
        OnAfterGetVATLCYCorrectionBuffer(TempVATLCYCorrDocumentCZL, TempVATLCYCorrectionBufferCZL);
        exit(not TempVATLCYCorrectionBufferCZL.IsEmpty());
    end;

    local procedure ReverseVATLCYCorrections(var FromVATLCYCorrBufferCZL: Record "VAT LCY Correction Buffer CZL"; var ToVATLCYCorrBufferCZL: Record "VAT LCY Correction Buffer CZL")
    begin
        if FromVATLCYCorrBufferCZL.FindCorrectionEntries() then
            repeat
                ToVATLCYCorrBufferCZL.SetRange("VAT Bus. Posting Group", FromVATLCYCorrBufferCZL."VAT Bus. Posting Group");
                ToVATLCYCorrBufferCZL.SetRange("VAT Prod. Posting Group", FromVATLCYCorrBufferCZL."VAT Prod. Posting Group");
                if ToVATLCYCorrBufferCZL.FindFirst() then begin
                    ToVATLCYCorrBufferCZL."Corrected VAT Amount" -= FromVATLCYCorrBufferCZL."Corrected VAT Amount";
                    ToVATLCYCorrBufferCZL."VAT Correction Amount" := ToVATLCYCorrBufferCZL."Corrected VAT Amount" - ToVATLCYCorrBufferCZL."VAT Amount";
                    ToVATLCYCorrBufferCZL.Modify(false);
                end
            until FromVATLCYCorrBufferCZL.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Correct Posted Purch. Invoice", OnRunOnAfterUpdatePurchaseOrderLinesFromCancelledInvoice, '', false, false)]
    local procedure OnRunOnAfterUpdatePurchaseOrderLinesFromCancelledInvoice(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchaseHeader: Record "Purchase Header")
    var
        TempInvoiceVATLCYCorrBufferCZL: Record "VAT LCY Correction Buffer CZL" temporary;
        TempCrMemoVATLCYCorrBufferCZL: Record "VAT LCY Correction Buffer CZL" temporary;
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        if not PurchInvHeader.IsVATLCYCorrectionAllowedCZL() then
            exit;
        if not GetVATLCYCorrectionBuffer(PurchInvHeader, TempInvoiceVATLCYCorrBufferCZL) then
            exit;
        if not TempInvoiceVATLCYCorrBufferCZL.FindCorrectionEntries() then
            exit;

        PurchCrMemoHdr.SetRange("Applies-to Doc. Type", PurchInvHeader."Applies-to Doc. Type"::Invoice);
        PurchCrMemoHdr.SetRange("Applies-to Doc. No.", PurchInvHeader."No.");
        if not PurchCrMemoHdr.FindFirst() then
            exit;
        if not GetVATLCYCorrectionBuffer(PurchCrMemoHdr, TempCrMemoVATLCYCorrBufferCZL) then
            exit;

        ReverseVATLCYCorrections(TempInvoiceVATLCYCorrBufferCZL, TempCrMemoVATLCYCorrBufferCZL);

        TempCrMemoVATLCYCorrBufferCZL.Reset();
        Codeunit.Run(Codeunit::"VAT LCY Correction-Post CZL", TempCrMemoVATLCYCorrBufferCZL);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Correct Posted Sales Invoice", OnOnRunOnAfterUpdateSalesOrderLinesFromCancelledInvoice, '', false, false)]
    local procedure OnRunOnAfterUpdateSalesOrderLinesFromCancelledInvoice(var Rec: Record "Sales Invoice Header"; var SalesHeader: Record "Sales Header")
    var
        TempInvoiceVATLCYCorrBufferCZL: Record "VAT LCY Correction Buffer CZL" temporary;
        TempCrMemoVATLCYCorrBufferCZL: Record "VAT LCY Correction Buffer CZL" temporary;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        if not Rec.IsVATLCYCorrectionAllowedCZL() then
            exit;
        if not GetVATLCYCorrectionBuffer(Rec, TempInvoiceVATLCYCorrBufferCZL) then
            exit;
        if not TempInvoiceVATLCYCorrBufferCZL.FindCorrectionEntries() then
            exit;

        SalesCrMemoHeader.SetRange("Applies-to Doc. Type", SalesCrMemoHeader."Applies-to Doc. Type"::Invoice);
        SalesCrMemoHeader.SetRange("Applies-to Doc. No.", Rec."No.");
        if not SalesCrMemoHeader.FindFirst() then
            exit;
        if not GetVATLCYCorrectionBuffer(SalesCrMemoHeader, TempCrMemoVATLCYCorrBufferCZL) then
            exit;

        ReverseVATLCYCorrections(TempInvoiceVATLCYCorrBufferCZL, TempCrMemoVATLCYCorrBufferCZL);

        TempCrMemoVATLCYCorrBufferCZL.Reset();
        Codeunit.Run(Codeunit::"VAT LCY Correction-Post CZL", TempCrMemoVATLCYCorrBufferCZL);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSourceDocumentElse(SourceDocumentRecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVATLCYCorrectionBuffer(TempVATLCYCorrDocumentCZL: Record "VAT LCY Corr. Document CZL"; var VATLCYCorrectionBufferCZL: Record "VAT LCY Correction Buffer CZL" temporary)
    begin
    end;
}