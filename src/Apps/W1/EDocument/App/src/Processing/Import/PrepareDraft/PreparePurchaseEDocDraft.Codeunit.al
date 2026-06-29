// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.AI;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;
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
        LineAmount: Decimal;
        LineVATAmount: Decimal;
        TotalLineVATAmount: Decimal;
        VendorAlreadyAssigned: Boolean;
        VendorFoundByProvider: Boolean;
    begin
        IUnitOfMeasureProvider := EDocImportParameters."Processing Customizations";
        IPurchaseLineProvider := EDocImportParameters."Processing Customizations";
        IPurchaseOrderProvider := EDocImportParameters."Processing Customizations";

        if EDocActivityLogSession.CreateSession() then;

        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        EDocumentPurchaseHeader.TestField("E-Document Entry No.");
        VendorAlreadyAssigned := EDocumentPurchaseHeader."[BC] Vendor No." <> '';
        if not VendorAlreadyAssigned then begin
            Vendor := GetVendor(EDocument, EDocImportParameters."Processing Customizations");
            EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        end;
        VendorFoundByProvider := (not VendorAlreadyAssigned) and (EDocumentPurchaseHeader."[BC] Vendor No." <> '');

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

        case true of
            VendorAlreadyAssigned:
                EDocImpSessionTelemetry.SetText('Vendor Assignment Source', 'Already Assigned');
            VendorFoundByProvider:
                EDocImpSessionTelemetry.SetText('Vendor Assignment Source', 'Provider');
            EDocumentPurchaseHeader."[BC] Vendor No." <> '':
                EDocImpSessionTelemetry.SetText('Vendor Assignment Source', 'History');
            else
                EDocImpSessionTelemetry.SetText('Vendor Assignment Source', 'None');
        end;
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

        // Log telemetry and activity sessions
        Clear(EDocumentPurchaseLine);
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        TotalLineVATAmount := 0;
        if EDocumentPurchaseLine.FindSet() then
            repeat
                LineAmount := Round(EDocumentPurchaseLine.Quantity * EDocumentPurchaseLine."Unit Price" - EDocumentPurchaseLine."Total Discount");
                LineVATAmount := Round(LineAmount * EDocumentPurchaseLine."VAT Rate" / 100);
                TotalLineVATAmount += LineVATAmount;
                EDocImpSessionTelemetry.SetLine(EDocumentPurchaseLine.SystemId);
            until EDocumentPurchaseLine.Next() = 0;

        ComputeAndApplyVATAmountDifference(EDocumentPurchaseHeader, TotalLineVATAmount);
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
        EDocumentPurchaseLine.SetLoadFields("E-Document Entry No.", "[BC] Purchase Type No.", "[BC] Deferral Code", Description, "Product Code", Quantity, "Unit of Measure", "Unit Price");
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
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        Vendor: Record Vendor;
        VATRate: Decimal;
        LineBase: Decimal;
        LineCount: Integer;
    begin
        if not PurchasesPayablesSetup.Get() then
            exit;
        if not PurchasesPayablesSetup."Resolve VAT Group Purch EDoc" then
            exit;
        Vendor := EDocumentPurchaseHeader.GetBCVendor();
        if Vendor."No." = '' then
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
                if (VATRate = 0) and (LineCount = 1) and (EDocumentPurchaseHeader."Total VAT" > 0) then begin
                    LineBase := EDocumentPurchaseLine.Quantity * EDocumentPurchaseLine."Unit Price" - EDocumentPurchaseLine."Total Discount";
                    if LineBase = 0 then
                        LineBase := EDocumentPurchaseHeader."Sub Total";
                    if LineBase > 0 then
                        VATRate := Round((EDocumentPurchaseHeader."Total VAT" / LineBase) * 100, 0.01);
                end;

                if VATRate > 0 then begin
                    EDocumentPurchaseLine."[BC] VAT Prod. Posting Group" :=
                        FindVATProductPostingGroup(Vendor."VAT Bus. Posting Group", VATRate);
                    EDocumentPurchaseLine.Modify();
                    if EDocumentPurchaseLine."[BC] VAT Prod. Posting Group" = '' then
                        EDocumentPurchaseLine.LogVATRateMismatch(Vendor."VAT Bus. Posting Group", VATRate)
                    else
                        EDocumentPurchaseLine.LogVATRateResolved(Vendor."VAT Bus. Posting Group", VATRate);
                end;
            until EDocumentPurchaseLine.Next() = 0;
    end;

    local procedure FindVATProductPostingGroup(VATBusPostingGroup: Code[20]; VATRate: Decimal): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        EDocPurchDocHelper: Codeunit "E-Doc. Purch. Doc. Helper";
        CustomDimensions: Dictionary of [Text, Text];
        VATPostingGroupNotFoundLbl: Label 'VAT Product Posting Group not found for VAT Rate %1.', Comment = '%1 = VAT rate', Locked = true;
    begin
        EDocPurchDocHelper.SetNormalReverseChargeFilter(VATPostingSetup, VATBusPostingGroup);
        VATPostingSetup.SetRange("VAT %", VATRate);
        if VATPostingSetup.Count() = 1 then begin
            VATPostingSetup.FindFirst();
            exit(VATPostingSetup."VAT Prod. Posting Group");
        end;
        Session.LogMessage('0000TXZ', StrSubstNo(VATPostingGroupNotFoundLbl, VATRate), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
        exit('');
    end;

    local procedure ComputeAndApplyVATAmountDifference(EDocumentPurchaseHeader: Record "E-Document Purchase Header"; TotalLineVATAmount: Decimal)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ActivityLog: Codeunit "Activity Log Builder";
        VATAmountDiff: Decimal;
        Reasoning: Text[250];
        VATDiffAppliedLbl: Label 'Applied VAT amount difference of %1 to reconcile document Total VAT %2 with computed Total Line VAT Amount %3.', Comment = '%1 = VAT difference, %2 = Total VAT, %3 = Total Line VAT Amount';
        VATDiffSkippedSetupLbl: Label 'VAT amount difference of %1 was not applied because Apply VAT Diff. For Purch. E-Doc. is disabled in Purchases & Payables Setup.', Comment = '%1 = VAT difference';
        VATDiffSkippedAllowLbl: Label 'VAT amount difference of %1 was not applied because Allow VAT Difference is disabled in Purchases & Payables Setup.', Comment = '%1 = VAT difference';
        VATDiffSkippedMaxLbl: Label 'VAT amount difference of %1 was not applied because it exceeds the Max. VAT Difference Allowed of %2 in General Ledger Setup.', Comment = '%1 = VAT difference, %2 = Max. VAT Difference Allowed';
    begin
        if (EDocumentPurchaseHeader."Total VAT" = 0) or (TotalLineVATAmount = EDocumentPurchaseHeader."Total VAT") then
            exit;

        VATAmountDiff := EDocumentPurchaseHeader."Total VAT" - TotalLineVATAmount;

        if not PurchasesPayablesSetup.Get() then
            exit;

        if not PurchasesPayablesSetup."Apply VAT Diff. For Purch EDoc" then begin
            Reasoning := CopyStr(StrSubstNo(VATDiffSkippedSetupLbl, VATAmountDiff), 1, MaxStrLen(Reasoning));
            ActivityLog
                .Init(Database::"E-Document Purchase Header", EDocumentPurchaseHeader.FieldNo("Total VAT"), EDocumentPurchaseHeader.SystemId)
                .SetExplanation(Reasoning)
                .SetType(Enum::"Activity Log Type"::"AL")
                .Log();
            exit;
        end;

        if not PurchasesPayablesSetup."Allow VAT Difference" then begin
            Reasoning := CopyStr(StrSubstNo(VATDiffSkippedAllowLbl, VATAmountDiff), 1, MaxStrLen(Reasoning));
            ActivityLog
                .Init(Database::"E-Document Purchase Header", EDocumentPurchaseHeader.FieldNo("Total VAT"), EDocumentPurchaseHeader.SystemId)
                .SetExplanation(Reasoning)
                .SetType(Enum::"Activity Log Type"::"AL")
                .Log();
            exit;
        end;

        if not GeneralLedgerSetup.Get() then
            exit;
        if Abs(VATAmountDiff) > GeneralLedgerSetup."Max. VAT Difference Allowed" then begin
            Reasoning := CopyStr(StrSubstNo(VATDiffSkippedMaxLbl, VATAmountDiff, GeneralLedgerSetup."Max. VAT Difference Allowed"), 1, MaxStrLen(Reasoning));
            ActivityLog
                .Init(Database::"E-Document Purchase Header", EDocumentPurchaseHeader.FieldNo("Total VAT"), EDocumentPurchaseHeader.SystemId)
                .SetExplanation(Reasoning)
                .SetType(Enum::"Activity Log Type"::"AL")
                .Log();
            exit;
        end;

        Reasoning := CopyStr(StrSubstNo(VATDiffAppliedLbl, VATAmountDiff, EDocumentPurchaseHeader."Total VAT", TotalLineVATAmount), 1, MaxStrLen(Reasoning));
        ActivityLog
            .Init(Database::"E-Document Purchase Header", EDocumentPurchaseHeader.FieldNo("Total VAT"), EDocumentPurchaseHeader.SystemId)
            .SetExplanation(Reasoning)
            .SetType(Enum::"Activity Log Type"::"AL")
            .Log();
    end;
}