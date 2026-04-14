// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.AI;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using System.Log;

codeunit 6125 "Prepare Purchase E-Doc. Draft" implements IProcessStructuredData
{
    Access = Internal;

    var
        EDocImpSessionTelemetry: Codeunit "E-Doc. Imp. Session Telemetry";

    procedure PrepareDraft(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters"): Enum "E-Document Type"
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        UnitOfMeasure: Record "Unit of Measure";
        Vendor: Record Vendor;
        PurchaseOrder: Record "Purchase Header";
        EDocVendorAssignmentHistory: Record "E-Doc. Vendor Assign. History";
        EDocPurchaseHistMapping: Codeunit "E-Doc. Purchase Hist. Mapping";
        EDocActivityLogSession: Codeunit "E-Doc. Activity Log Session";
        IUnitOfMeasureProvider: Interface IUnitOfMeasureProvider;
        IPurchaseLineProvider: Interface IPurchaseLineProvider;
        IPurchaseOrderProvider: Interface IPurchaseOrderProvider;
    begin
        IUnitOfMeasureProvider := EDocImportParameters."Processing Customizations";
        IPurchaseLineProvider := EDocImportParameters."Processing Customizations";
        IPurchaseOrderProvider := EDocImportParameters."Processing Customizations";

        if EDocActivityLogSession.CreateSession() then;

        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        EDocumentPurchaseHeader.TestField("E-Document Entry No.");
        if EDocumentPurchaseHeader."[BC] Vendor No." = '' then begin
            Vendor := GetVendor(EDocument, EDocImportParameters."Processing Customizations");
            EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        end;

        PurchaseOrder := IPurchaseOrderProvider.GetPurchaseOrder(EDocumentPurchaseHeader);
        if PurchaseOrder."No." <> '' then begin
            // Matching purchase order specified in the E-Document 
            EDocumentPurchaseHeader."[BC] Purchase Order No." := PurchaseOrder."No.";
            EDocumentPurchaseHeader.Modify();
        end;
        if EDocPurchaseHistMapping.FindRelatedPurchaseHeaderInHistory(EDocument, EDocVendorAssignmentHistory) then
            EDocPurchaseHistMapping.UpdateMissingHeaderValuesFromHistory(EDocVendorAssignmentHistory, EDocumentPurchaseHeader);
        EDocumentPurchaseHeader.Modify();

        // If we can't find a vendor 
        EDocImpSessionTelemetry.SetBool('Vendor', EDocumentPurchaseHeader."[BC] Vendor No." <> '');
        if EDocumentPurchaseHeader."[BC] Vendor No." <> '' then begin

            // Get all purchase lines for the document
            EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");

            // Apply basic unit of measure and text-to-account resolution first
            if EDocumentPurchaseLine.FindSet() then
                repeat
                    UnitOfMeasure := IUnitOfMeasureProvider.GetUnitOfMeasure(EDocument, EDocumentPurchaseLine."Line No.", EDocumentPurchaseLine."Unit of Measure");
                    EDocumentPurchaseLine."[BC] Unit of Measure" := UnitOfMeasure.Code;
                    IPurchaseLineProvider.GetPurchaseLine(EDocumentPurchaseLine);
                    EDocumentPurchaseLine.Modify();
                until EDocumentPurchaseLine.Next() = 0;

            // Resolve VAT Product Posting Groups from extracted VAT rates
            ResolveVATProductPostingGroups(EDocument."Entry No", EDocumentPurchaseHeader);

            // Apply all Copilot-powered matching techniques to the lines
            CopilotLineMatching(EDocument."Entry No");
        end;

        Clear(EDocumentPurchaseLine);
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        if EDocumentPurchaseLine.FindSet() then
            repeat
                // Update total line amount on the header
                EDocumentPurchaseHeader."Total Line Amount" := Round(EDocumentPurchaseLine.Quantity * EDocumentPurchaseLine."Unit Price" - EDocumentPurchaseLine."Total Discount");
                // Log telemetry and activity sessions
                EDocImpSessionTelemetry.SetLine(EDocumentPurchaseLine.SystemId);
            until EDocumentPurchaseLine.Next() = 0;
        EDocumentPurchaseHeader.Modify();

        // Log all accumulated activity session changes at the end
        LogAllActivitySessionChanges(EDocActivityLogSession);

        if EDocActivityLogSession.EndSession() then;
        exit("E-Document Type"::"Purchase Invoice");
    end;

    local procedure LogAllActivitySessionChanges(EDocActivityLogSession: Codeunit "E-Doc. Activity Log Session")
    begin
        Log(EDocActivityLogSession, EDocActivityLogSession.AccountNumberTok());
        Log(EDocActivityLogSession, EDocActivityLogSession.DeferralTok());
        Log(EDocActivityLogSession, EDocActivityLogSession.ItemRefTok());
        Log(EDocActivityLogSession, EDocActivityLogSession.TextToAccountMappingTok());
    end;

    local procedure Log(EDocActivityLogSession: Codeunit "E-Doc. Activity Log Session"; ActivityLogName: Text)
    var
        ActivityLog: Codeunit "Activity Log Builder";
        ActivityLogList: List of [Codeunit "Activity Log Builder"];
        Found: Boolean;
    begin
        Clear(ActivityLogList);
        EDocActivityLogSession.GetAll(ActivityLogName, ActivityLogList, Found);
        foreach ActivityLog in ActivityLogList do
            ActivityLog.Log();
    end;

    local procedure CopilotLineMatching(EDocumentEntryNo: Integer)
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        EDocumentPurchaseLine.SetLoadFields("E-Document Entry No.", "[BC] Purchase Type No.", "[BC] Deferral Code");
        EDocumentPurchaseLine.ReadIsolation(IsolationLevel::ReadCommitted);

        // Step 1: Apply historical pattern matching
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentEntryNo);
        EDocumentPurchaseLine.SetRange("[BC] Purchase Type No.", '');
        EDocumentPurchaseLine.SetRange("[BC] Item Reference No.", '');

        if not EDocumentPurchaseLine.IsEmpty() then begin
            Commit();
            Codeunit.Run(Codeunit::"E-Doc. Historical Matching", EDocumentPurchaseLine);
        end;

        // Step 2: Apply line-to-account matching for remaining lines with no purchase type
        Clear(EDocumentPurchaseLine);
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentEntryNo);
        EDocumentPurchaseLine.SetRange("[BC] Purchase Type No.", '');
        EDocumentPurchaseLine.SetRange("[BC] Item Reference No.", '');
        if not EDocumentPurchaseLine.IsEmpty() then begin
            Commit();
            Codeunit.Run(Codeunit::"E-Doc. GL Account Matching", EDocumentPurchaseLine);
        end;

        // Step 3: Apply deferral matching for lines with a purchase type but no deferral code
        Clear(EDocumentPurchaseLine);
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentEntryNo);
        EDocumentPurchaseLine.SetRange("[BC] Deferral Code", '');
        EDocumentPurchaseLine.SetRange("[BC] Item Reference No.", '');
        if not EDocumentPurchaseLine.IsEmpty() then begin
            Commit();
            if Codeunit.Run(Codeunit::"E-Doc. Deferral Matching", EDocumentPurchaseLine) then;
        end;
    end;

    procedure OpenDraftPage(var EDocument: Record "E-Document")
    var
        EDocumentPurchaseDraft: Page "E-Document Purchase Draft";
    begin
        EDocumentPurchaseDraft.Editable(true);
        EDocumentPurchaseDraft.SetRecord(EDocument);
        EDocumentPurchaseDraft.Run();
    end;

    procedure CleanUpDraft(EDocument: Record "E-Document")
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        EDocumentPurchaseHeader.SetRange("E-Document Entry No.", EDocument."Entry No");
        if not EDocumentPurchaseHeader.IsEmpty() then
            EDocumentPurchaseHeader.DeleteAll(true);

        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        if not EDocumentPurchaseLine.IsEmpty() then
            EDocumentPurchaseLine.DeleteAll(true);
    end;

    procedure GetVendor(EDocument: Record "E-Document"; Customizations: Enum "E-Doc. Proc. Customizations") Vendor: Record Vendor
    var
        IVendorProvider: Interface IVendorProvider;
    begin
        IVendorProvider := Customizations;
        Vendor := IVendorProvider.GetVendor(EDocument);
    end;

    local procedure ResolveVATProductPostingGroups(EDocumentEntryNo: Integer; EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        Vendor: Record Vendor;
        VATRate: Decimal;
        LineCount: Integer;
    begin
        if EDocumentPurchaseHeader."[BC] Vendor No." = '' then
            exit;
        if not Vendor.Get(EDocumentPurchaseHeader."[BC] Vendor No.") then
            exit;
        if Vendor."VAT Bus. Posting Group" = '' then
            exit;

        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentEntryNo);
        LineCount := EDocumentPurchaseLine.Count();
        if LineCount = 0 then
            exit;

        if EDocumentPurchaseLine.FindSet() then
            repeat
                VATRate := EDocumentPurchaseLine."VAT Rate";

                // Single-line fallback: compute from header Total VAT
                if (VATRate = 0) and (LineCount = 1) and
                   (EDocumentPurchaseHeader."Total VAT" > 0) and (EDocumentPurchaseHeader."Sub Total" > 0)
                then
                    VATRate := Round((EDocumentPurchaseHeader."Total VAT" / EDocumentPurchaseHeader."Sub Total") * 100, 0.01);

                if VATRate > 0 then begin
                    EDocumentPurchaseLine."[BC] VAT Prod. Posting Group" :=
                        FindVATProductPostingGroup(Vendor."VAT Bus. Posting Group", VATRate);
                    EDocumentPurchaseLine."[BC] VAT Rate Mismatch" :=
                        EDocumentPurchaseLine."[BC] VAT Prod. Posting Group" = '';
                    EDocumentPurchaseLine.Modify();
                end;
            until EDocumentPurchaseLine.Next() = 0;
    end;

    local procedure FindVATProductPostingGroup(VATBusPostingGroup: Code[20]; VATRate: Decimal): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("VAT Bus. Posting Group", VATBusPostingGroup);
        VATPostingSetup.SetFilter("VAT Calculation Type", '%1|%2',
            VATPostingSetup."VAT Calculation Type"::"Normal VAT",
            VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.SetRange("VAT %", VATRate);
        if VATPostingSetup.Count() = 1 then begin
            VATPostingSetup.FindFirst();
            exit(VATPostingSetup."VAT Prod. Posting Group");
        end;
        exit('');
    end;
}