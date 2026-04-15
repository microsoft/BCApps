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
/// Dealing with the creation of the purchase credit memo after the draft has been populated.
/// </summary>
codeunit 6404 "E-Doc. Create Purch. Cr. Memo" implements IEDocumentFinishDraft, IEDocumentCreatePurchaseCreditMemo
{
    Access = Internal;

    var
        Telemetry: Codeunit "Telemetry";
        CrMemoAlreadyExistsErr: Label 'A purchase credit memo with external document number %1 already exists for vendor %2.', Comment = '%1 = Vendor Cr. Memo No., %2 = Vendor No.';
        DraftLineDoesNotContainTypeAndNumberErr: Label 'One of the draft lines do not contain the type and number. Please, specify these fields manually.';

    procedure ApplyDraftToBC(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters"): RecordId
    var
        PurchaseHeader: Record "Purchase Header";
        EDocPurchaseDocumentHelper: Codeunit "E-Doc. Purch. Doc. Helper";
        EDocImpSessionTelemetry: Codeunit "E-Doc. Imp. Session Telemetry";
        EmptyRecordId: RecordId;
        IEDocumentFinishPurchaseCrMemo: Interface IEDocumentCreatePurchaseCreditMemo;
    begin
        IEDocumentFinishPurchaseCrMemo := EDocImportParameters."Processing Customizations";
        if EDocImportParameters."Existing Doc. RecordId" <> EmptyRecordId then begin
            EDocImpSessionTelemetry.SetBool('LinkedToExisting', true);
            PurchaseHeader.Get(EDocImportParameters."Existing Doc. RecordId");
        end else
            PurchaseHeader := IEDocumentFinishPurchaseCrMemo.CreatePurchaseCreditMemo(EDocument);

        EDocPurchaseDocumentHelper.FinalizeCreatedDocument(EDocument, PurchaseHeader);

        exit(PurchaseHeader.RecordId);
    end;

    procedure RevertDraftActions(EDocument: Record "E-Document")
    var
        PurchaseHeader: Record "Purchase Header";
        EDocPurchaseDocumentHelper: Codeunit "E-Doc. Purch. Doc. Helper";
    begin
        PurchaseHeader.SetRange("E-Document Link", EDocument.SystemId);
        if not PurchaseHeader.FindFirst() then
            exit;

        PurchaseHeader.TestField("Document Type", "Purchase Document Type"::"Credit Memo");
        EDocPurchaseDocumentHelper.RevertCreatedDocument(EDocument);
    end;

    procedure CreatePurchaseCreditMemo(EDocument: Record "E-Document"): Record "Purchase Header"
    var
        PurchaseHeader: Record "Purchase Header";
        GLSetup: Record "General Ledger Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocRecordLink: Record "E-Doc. Record Link";
        EDocPurchaseDocumentHelper: Codeunit "E-Doc. Purch. Doc. Helper";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        StopCreatingCreditMemo: Boolean;
        VendorCrMemoNo: Code[35];
        PurchaseLineNo: Integer;
    begin
        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        if not EDocPurchaseDocumentHelper.AllDraftLinesHaveTypeAndNumber(EDocumentPurchaseHeader) then begin
            Telemetry.LogMessage('0000SNH', 'Draft line does not contain type or number', Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All);
            Error(DraftLineDoesNotContainTypeAndNumberErr);
        end;
        EDocumentPurchaseHeader.TestField("E-Document Entry No.");
        PurchaseHeader.SetRange("Buy-from Vendor No.", EDocumentPurchaseHeader."[BC] Vendor No.");
        PurchaseHeader."Document Type" := "Purchase Document Type"::"Credit Memo";
        PurchaseHeader."Pay-to Vendor No." := EDocumentPurchaseHeader."[BC] Vendor No.";
        PurchaseHeader."Posting Description" := EDocumentPurchaseHeader."Posting Description";
        if EDocumentPurchaseHeader."Document Date" <> 0D then
            PurchaseHeader.Validate("Document Date", EDocumentPurchaseHeader."Document Date");
        if EDocumentPurchaseHeader."Due Date" <> 0D then
            PurchaseHeader.Validate("Due Date", EDocumentPurchaseHeader."Due Date");

        VendorCrMemoNo := CopyStr(EDocumentPurchaseHeader."Sales Invoice No.", 1, MaxStrLen(PurchaseHeader."Vendor Cr. Memo No."));
        VendorLedgerEntry.SetLoadFields("Entry No.");
        VendorLedgerEntry.ReadIsolation := VendorLedgerEntry.ReadIsolation::ReadUncommitted;
        StopCreatingCreditMemo := PurchaseHeader.FindPostedDocumentWithSameExternalDocNo(VendorLedgerEntry, VendorCrMemoNo);
        if StopCreatingCreditMemo then begin
            Telemetry.LogMessage('0000SNI', CrMemoAlreadyExistsErr, Verbosity::Error, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::All);
            Error(CrMemoAlreadyExistsErr, VendorCrMemoNo, EDocumentPurchaseHeader."[BC] Vendor No.");
        end;

        PurchaseHeader.Validate("Vendor Cr. Memo No.", VendorCrMemoNo);
        if EDocumentPurchaseHeader."Purchase Order No." <> '' then
            PurchaseHeader."Vendor Order No." := CopyStr(EDocumentPurchaseHeader."Purchase Order No.", 1, MaxStrLen(PurchaseHeader."Vendor Order No."));
        PurchaseHeader.Insert(true);
        PurchaseHeader.Modify();

        GLSetup.GetRecordOnce();
        if EDocumentPurchaseHeader."Currency Code" <> GLSetup.GetCurrencyCode('') then
            PurchaseHeader.Validate("Currency Code", EDocumentPurchaseHeader."Currency Code");

        if EDocumentPurchaseHeader."Applies-to Doc. No." <> '' then
            PurchaseHeader."Applies-to Doc. No." := CopyStr(EDocumentPurchaseHeader."Applies-to Doc. No.", 1, MaxStrLen(PurchaseHeader."Applies-to Doc. No."));

        PurchaseHeader.Modify();

        EDocRecordLink.InsertEDocumentHeaderLink(EDocumentPurchaseHeader, PurchaseHeader);

        PurchaseLineNo := EDocPurchaseDocumentHelper.GetLastPurchaseLineNo("Purchase Document Type"::"Credit Memo", PurchaseHeader."No.");
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        if EDocumentPurchaseLine.FindSet() then
            repeat
                PurchaseLineNo += 10000;
                EDocPurchaseDocumentHelper.CreatePurchaseLineFromDraft(PurchaseHeader, EDocumentPurchaseLine, EDocumentPurchaseHeader."Total Discount" > 0, PurchaseLineNo);
            until EDocumentPurchaseLine.Next() = 0;

        PurchaseHeader.Modify();
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(EDocumentPurchaseHeader."Total Discount", PurchaseHeader);
        exit(PurchaseHeader);
    end;
}
