// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Purchase;

using Microsoft.eServices.EDocument.Processing.AI;
using Microsoft.Finance.AllocationAccount;
using Microsoft.Purchases.History;
using System.Telemetry;

codeunit 6244 "E-Doc. Hist. Line Data Loader"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        TotalLoaded: Integer;
        HistoricalDataLoadEventTok: Label 'Historical Data Load', Locked = true;

    /// <summary>
    /// Loads up to 5000 historical posted purchase invoice lines for the draft line's vendor
    /// into a temporary table, prioritized by relevance to the selected draft line.
    /// Priority: vendor matching lines first (product code exact, description exact, and LLM-based
    /// similar descriptions), then any remaining lines for the same vendor.
    /// The search is scoped to the draft's vendor; no cross-vendor history is loaded.
    /// </summary>
    procedure LoadHistoricalLines(var TempPurchInvLine: Record "Purch. Inv. Line" temporary; VendorNo: Code[20]; ProductCode: Text[100]; Description: Text[100])
    var
        PurchInvLine: Record "Purch. Inv. Line";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        StartTime: DateTime;
        ElapsedTime: Duration;
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        TotalLoaded := 0;

        if not PurchInvLine.ReadPermission() then
            exit;

        // History is scoped to the draft's vendor; without a vendor there is nothing to match.
        if VendorNo = '' then
            exit;

        StartTime := CurrentDateTime();
        if not TryLoadHistoricalLines(TempPurchInvLine, VendorNo, ProductCode, Description) then begin
            // Redacted error text only: avoid emitting vendor-identifying data or unsanitized customer content to telemetry.
            FeatureTelemetry.LogError('0000SEO', FeatureName(), HistoricalDataLoadEventTok, GetLastErrorText(true), GetLastErrorCallStack());
            exit;
        end;

        ElapsedTime := CurrentDateTime() - StartTime;
        TelemetryDimensions.Add('RecordsLoaded', Format(TotalLoaded));
        TelemetryDimensions.Add('Duration', Format(ElapsedTime));
        TelemetryDimensions.Add('VendorMatchingScope', 'Same Vendor');
        TelemetryDimensions.Add('MaxRecordsLimit', Format(MaxHistoricalRecords()));
        TelemetryDimensions.Add('LimitReached', Format(TotalLoaded >= MaxHistoricalRecords()));
        FeatureTelemetry.LogUsage('0000SEN', FeatureName(), HistoricalDataLoadEventTok, TelemetryDimensions);
    end;

    [TryFunction]
    local procedure TryLoadHistoricalLines(var TempPurchInvLine: Record "Purch. Inv. Line" temporary; VendorNo: Code[20]; ProductCode: Text[100]; Description: Text[100])
    var
        EDocSimilarDescriptions: Codeunit "E-Doc. Similar Descriptions";
        ProductCodes: List of [Text];
        Descriptions: List of [Text];
        SimilarDescriptions: List of [Text];
        DescriptionEntry: Text;
        SimilarTerm: Text;
    begin
        if ProductCode <> '' then
            ProductCodes.Add(ProductCode);
        if Description <> '' then
            Descriptions.Add(Description);

        // Resolve LLM-based similar terms once for this invoice line and reuse across the matching passes.
        foreach DescriptionEntry in Descriptions do
            foreach SimilarTerm in EDocSimilarDescriptions.GetSimilarDescriptions(DescriptionEntry) do begin
                // AI-generated text is untrusted: strip filter metacharacters before it is used in SetFilter.
                SimilarTerm := SanitizeFilterValue(SimilarTerm.Trim());
                if (StrLen(SimilarTerm) > 3) and (not SimilarDescriptions.Contains(SimilarTerm)) then
                    SimilarDescriptions.Add(SimilarTerm);
            end;

        // Tier 1-3: same vendor, matched by product code / exact desc / similar desc
        LoadMatchingLines(TempPurchInvLine, VendorNo, ProductCodes, Descriptions, SimilarDescriptions);
        // Tier 4: same vendor, any remaining
        LoadRemainingLines(TempPurchInvLine, VendorNo);
    end;

    local procedure LoadMatchingLines(var TempPurchInvLine: Record "Purch. Inv. Line" temporary; VendorNo: Code[20]; ProductCodes: List of [Text]; Descriptions: List of [Text]; SimilarDescriptions: List of [Text])
    var
        PurchInvLine: Record "Purch. Inv. Line";
        ProductCode: Text;
        Description: Text;
        SimilarTerm: Text;
    begin
        if TotalLoaded >= MaxHistoricalRecords() then
            exit;

        // Exact product code matches
        foreach ProductCode in ProductCodes do begin
            if TotalLoaded >= MaxHistoricalRecords() then
                exit;
            PurchInvLine.Reset();
            SetBaseFilters(PurchInvLine);
            SetVendorFilter(PurchInvLine, VendorNo);
            PurchInvLine.SetRange("No.", ProductCode);
            InsertLines(TempPurchInvLine, PurchInvLine);
        end;

        // Exact description matches
        foreach Description in Descriptions do begin
            if TotalLoaded >= MaxHistoricalRecords() then
                exit;
            PurchInvLine.Reset();
            SetBaseFilters(PurchInvLine);
            SetVendorFilter(PurchInvLine, VendorNo);
            PurchInvLine.SetRange(Description, Description);
            InsertLines(TempPurchInvLine, PurchInvLine);
        end;

        // Similar description matches (LLM-generated semantically similar terms, precomputed once)
        foreach SimilarTerm in SimilarDescriptions do begin
            if TotalLoaded >= MaxHistoricalRecords() then
                exit;
            PurchInvLine.Reset();
            SetBaseFilters(PurchInvLine);
            SetVendorFilter(PurchInvLine, VendorNo);
            PurchInvLine.SetFilter(Description, '@*' + SimilarTerm + '*');
            InsertLines(TempPurchInvLine, PurchInvLine);
        end;
    end;

    local procedure LoadRemainingLines(var TempPurchInvLine: Record "Purch. Inv. Line" temporary; VendorNo: Code[20])
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        if TotalLoaded >= MaxHistoricalRecords() then
            exit;

        PurchInvLine.Reset();
        SetBaseFilters(PurchInvLine);
        SetVendorFilter(PurchInvLine, VendorNo);
        InsertLines(TempPurchInvLine, PurchInvLine);
    end;

    local procedure SetBaseFilters(var PurchInvLine: Record "Purch. Inv. Line")
    begin
        PurchInvLine.ReadIsolation(IsolationLevel::ReadCommitted);
        PurchInvLine.SetFilter("Posting Date", '>=%1', CalcDate('<-1Y>', Today));
        PurchInvLine.SetFilter(Type, '<>%1', PurchInvLine.Type::" ");
    end;

    local procedure SetVendorFilter(var PurchInvLine: Record "Purch. Inv. Line"; VendorNo: Code[20])
    begin
        if VendorNo <> '' then
            PurchInvLine.SetRange("Buy-from Vendor No.", VendorNo);
    end;

    local procedure SanitizeFilterValue(Value: Text): Text
    begin
        // Remove AL filter metacharacters so untrusted text (AI output/invoice content) cannot alter the
        // filter expression or trigger a filter-parse error when embedded in SetFilter.
        exit(DelChr(Value, '=', '&|()<>=?@*.''"%'));
    end;

    local procedure InsertLines(var TempPurchInvLine: Record "Purch. Inv. Line" temporary; var PurchInvLine: Record "Purch. Inv. Line")
    var
        AllocationAccount: Record "Allocation Account";
    begin
        PurchInvLine.SetLoadFields("Document No.", "Line No.", "Allocation Account No.", Description, "No.", Type, "Buy-from Vendor No.", Quantity, "Unit of Measure Code", "Deferral Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Posting Date");
        if PurchInvLine.FindSet() then
            repeat
                if not TempPurchInvLine.Get(PurchInvLine."Document No.", PurchInvLine."Line No.") then begin
                    TempPurchInvLine := PurchInvLine;
                    if TempPurchInvLine."Allocation Account No." <> '' then
                        if AllocationAccount.Get(TempPurchInvLine."Allocation Account No.") then
                            TempPurchInvLine.Description := AllocationAccount.Name;
                    TempPurchInvLine.Insert();
                    TotalLoaded += 1;
                end;
            until (PurchInvLine.Next() = 0) or (TotalLoaded >= MaxHistoricalRecords());
    end;

    procedure MaxHistoricalRecords(): Integer
    begin
        exit(5000);
    end;

    local procedure FeatureName(): Text
    begin
        exit('EDocument Historical Matching');
    end;
}
