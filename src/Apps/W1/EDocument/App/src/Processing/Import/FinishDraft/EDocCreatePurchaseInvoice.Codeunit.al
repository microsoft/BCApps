// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using System.Telemetry;

/// <summary>
/// Dealing with the creation of the purchase invoice after the draft has been populated.
/// </summary>
codeunit 6117 "E-Doc. Create Purchase Invoice" implements IEDocumentFinishDraft, IEDocumentCreatePurchaseInvoice
{
    Access = Internal;

    var
        Telemetry: Codeunit "Telemetry";
        InvoiceAlreadyExistsErr: Label 'A purchase invoice with external document number %1 already exists for vendor %2.', Comment = '%1 = Vendor Invoice No., %2 = Vendor No.';
        DraftLineDoesNotConstantTypeAndNumberErr: Label 'One of the draft lines do not contain the type and number. Please, specify these fields manually.';

    procedure ApplyDraftToBC(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters"): RecordId
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        TempPOMatchWarnings: Record "E-Doc PO Match Warning" temporary;
        EDocPOMatching: Codeunit "E-Doc. PO Matching";
        EDocPurchaseDocumentHelper: Codeunit "E-Doc. Purch. Doc. Helper";
        EDocImpSessionTelemetry: Codeunit "E-Doc. Imp. Session Telemetry";
        EmptyRecordId: RecordId;
        IEDocumentFinishPurchaseDraft: Interface IEDocumentCreatePurchaseInvoice;
        MissingInformationForMatchErr: Label 'Some of the draft lines that were matched to purchase order lines are missing unit of measure information. Please specify the unit of measure for those lines and try again.';
    begin
        EDocumentPurchaseHeader.GetFromEDocument(EDocument);

        EDocPOMatching.SuggestReceiptsForMatchedOrderLines(EDocumentPurchaseHeader);
        EDocPOMatching.CalculatePOMatchWarnings(EDocumentPurchaseHeader, TempPOMatchWarnings);
        // Only MissingInformationForMatch is blocking by design; all other warning types (e.g. AmountMismatch) are informational and must not gate invoice creation.
        TempPOMatchWarnings.SetRange("Warning Type", "E-Doc PO Match Warning"::MissingInformationForMatch);
        if not TempPOMatchWarnings.IsEmpty() then
            Error(MissingInformationForMatchErr);

        IEDocumentFinishPurchaseDraft := EDocImportParameters."Processing Customizations";
        if EDocImportParameters."Existing Doc. RecordId" <> EmptyRecordId then begin
            EDocImpSessionTelemetry.SetBool('LinkedToExisting', true);
            PurchaseHeader.Get(EDocImportParameters."Existing Doc. RecordId");
        end else
            PurchaseHeader := IEDocumentFinishPurchaseDraft.CreatePurchaseInvoice(EDocument);

        EDocPOMatching.TransferPOMatchesFromEDocumentToInvoice(EDocument);
        EDocPurchaseDocumentHelper.FinalizeCreatedDocument(EDocument, PurchaseHeader);

        exit(PurchaseHeader.RecordId);
    end;

    procedure RevertDraftActions(EDocument: Record "E-Document")
    var
        PurchaseHeader: Record "Purchase Header";
        EDocPOMatching: Codeunit "E-Doc. PO Matching";
        EDocPurchaseDocumentHelper: Codeunit "E-Doc. Purch. Doc. Helper";
    begin
        PurchaseHeader.SetRange("E-Document Link", EDocument.SystemId);
        if not PurchaseHeader.FindFirst() then
            exit;

        EDocPOMatching.TransferPOMatchesFromInvoiceToEDocument(PurchaseHeader);
        PurchaseHeader.TestField("Document Type", "Purchase Document Type"::Invoice);
        EDocPurchaseDocumentHelper.RevertCreatedDocument(EDocument);
    end;

    procedure CreatePurchaseInvoice(EDocument: Record "E-Document"): Record "Purchase Header"
    var
        PurchaseHeader: Record "Purchase Header";
        GLSetup: Record "General Ledger Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocRecordLink: Record "E-Doc. Record Link";
        EDocPurchaseDocumentHelper: Codeunit "E-Doc. Purch. Doc. Helper";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        PurchaseLineNo: Integer;
        StopCreatingPurchaseInvoice: Boolean;
        VendorInvoiceNo: Code[35];
    begin
        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        if not EDocPurchaseDocumentHelper.AllDraftLinesHaveTypeAndNumber(EDocumentPurchaseHeader) then begin
            Telemetry.LogMessage('0000PLY', 'Draft line does not contain type or number', Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All);
            Error(DraftLineDoesNotConstantTypeAndNumberErr);
        end;
        EDocumentPurchaseHeader.TestField("E-Document Entry No.");
        PurchaseHeader.SetRange("Buy-from Vendor No.", EDocumentPurchaseHeader."[BC] Vendor No."); // Setting the filter, so that the insert trigger assigns the right vendor to the purchase header
        PurchaseHeader."Document Type" := "Purchase Document Type"::Invoice;
        PurchaseHeader."Pay-to Vendor No." := EDocumentPurchaseHeader."[BC] Vendor No.";
        PurchaseHeader."Posting Description" := EDocumentPurchaseHeader."Posting Description";
        if EDocumentPurchaseHeader."Document Date" <> 0D then
            EDocPurchaseDocumentHelper.ValidateFieldWithContext(PurchaseHeader, PurchaseHeader.FieldNo("Document Date"), EDocumentPurchaseHeader."Document Date");
        if EDocumentPurchaseHeader."Due Date" <> 0D then
            EDocPurchaseDocumentHelper.ValidateFieldWithContext(PurchaseHeader, PurchaseHeader.FieldNo("Due Date"), EDocumentPurchaseHeader."Due Date");

        VendorInvoiceNo := CopyStr(EDocumentPurchaseHeader."Sales Invoice No.", 1, MaxStrLen(PurchaseHeader."Vendor Invoice No."));
        VendorLedgerEntry.SetLoadFields("Entry No.");
        VendorLedgerEntry.ReadIsolation := VendorLedgerEntry.ReadIsolation::ReadUncommitted;
        StopCreatingPurchaseInvoice := PurchaseHeader.FindPostedDocumentWithSameExternalDocNo(VendorLedgerEntry, VendorInvoiceNo);
        if StopCreatingPurchaseInvoice then begin
            Telemetry.LogMessage('0000PHC', InvoiceAlreadyExistsErr, Verbosity::Error, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::All);
            Error(InvoiceAlreadyExistsErr, VendorInvoiceNo, EDocumentPurchaseHeader."[BC] Vendor No.");
        end;

        EDocPurchaseDocumentHelper.ValidateFieldWithContext(PurchaseHeader, PurchaseHeader.FieldNo("Vendor Invoice No."), VendorInvoiceNo);
        if EDocumentPurchaseHeader."Purchase Order No." <> '' then
            PurchaseHeader."Vendor Order No." := CopyStr(EDocumentPurchaseHeader."Purchase Order No.", 1, MaxStrLen(PurchaseHeader."Vendor Order No."));
        PurchaseHeader.Insert(true);

        EDocPurchaseDocumentHelper.ApplyDefaultPostingDateFromSetup(PurchaseHeader, EDocumentPurchaseHeader);
        PurchaseHeader."Invoice Received Date" := PurchaseHeader."Document Date";
        PurchaseHeader.Modify();

        // Validate of currency has to happen after insert.
        GLSetup.GetRecordOnce();
        if EDocumentPurchaseHeader."Currency Code" <> GLSetup.GetCurrencyCode('') then begin
            EDocPurchaseDocumentHelper.ValidateFieldWithContext(PurchaseHeader, PurchaseHeader.FieldNo("Currency Code"), EDocumentPurchaseHeader."Currency Code");
            PurchaseHeader.Modify();
        end;
        EDocRecordLink.InsertEDocumentHeaderLink(EDocumentPurchaseHeader, PurchaseHeader);

        PurchaseLineNo := EDocPurchaseDocumentHelper.GetLastPurchaseLineNo("Purchase Document Type"::Invoice, PurchaseHeader."No."); // We get the last line number, even if this is a new document since recurrent lines get inserted on the header's creation
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        if EDocumentPurchaseLine.FindSet() then
            repeat
                PurchaseLineNo += 10000;
                EDocPurchaseDocumentHelper.CreatePurchaseLineFromDraft(PurchaseHeader, EDocumentPurchaseLine, EDocumentPurchaseHeader."Total Discount" > 0, PurchaseLineNo);
            until EDocumentPurchaseLine.Next() = 0;
        PurchaseHeader.Modify();
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(EDocumentPurchaseHeader."Total Discount", PurchaseHeader);
        EDocPurchaseDocumentHelper.ApplyVATDifferenceToLines(PurchaseHeader, EDocumentPurchaseHeader);
        exit(PurchaseHeader);
    end;

}
