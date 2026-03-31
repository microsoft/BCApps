// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Purchase;

using Microsoft.eServices.EDocument.Processing.AI;
using Microsoft.Finance.AllocationAccount;
using Microsoft.Purchases.History;

codeunit 6244 "E-Doc. Hist. Line Data Loader"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        TotalLoaded: Integer;

    /// <summary>
    /// Loads up to 5000 historical posted purchase invoice lines into a temporary table,
    /// prioritized by relevance to the selected draft line.
    /// Priority: same-vendor matching lines first, then cross-vendor matching lines,
    /// then remaining same-vendor lines, then remaining cross-vendor lines.
    /// Matching considers product code (exact), description (exact), and LLM-based similar descriptions.
    /// </summary>
    procedure LoadHistoricalLines(var TempPurchInvLine: Record "Purch. Inv. Line" temporary; VendorNo: Code[20]; ProductCode: Text[100]; Description: Text[100])
    var
        ProductCodes: List of [Text];
        Descriptions: List of [Text];
    begin
        TotalLoaded := 0;

        if ProductCode <> '' then
            ProductCodes.Add(ProductCode);
        if Description <> '' then
            Descriptions.Add(Description);

        // Priority tiers — same vendor matching, then cross vendor matching, then fill
        if VendorNo <> '' then begin
            // Tier 1-3: Same vendor, matched by product code / exact desc / similar desc
            LoadMatchingLines(TempPurchInvLine, VendorNo, ProductCodes, Descriptions);
            // Tier 4-6: Cross vendor, matched by product code / exact desc / similar desc
            LoadMatchingLines(TempPurchInvLine, '', ProductCodes, Descriptions);
            // Tier 7: Same vendor, any remaining
            LoadRemainingLines(TempPurchInvLine, VendorNo);
            // Tier 8: Cross vendor, any remaining
            LoadRemainingLines(TempPurchInvLine, '');
        end else begin
            LoadMatchingLines(TempPurchInvLine, '', ProductCodes, Descriptions);
            LoadRemainingLines(TempPurchInvLine, '');
        end;
    end;

    local procedure LoadMatchingLines(var TempPurchInvLine: Record "Purch. Inv. Line" temporary; VendorNo: Code[20]; ProductCodes: List of [Text]; Descriptions: List of [Text])
    var
        PurchInvLine: Record "Purch. Inv. Line";
        EDocSimilarDescriptions: Codeunit "E-Doc. Similar Descriptions";
        ProductCode: Text;
        Description: Text;
        SimilarTerm: Text;
        SimilarTerms: List of [Text];
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

        // Similar description matches (LLM-generated semantically similar terms)
        foreach Description in Descriptions do begin
            if TotalLoaded >= MaxHistoricalRecords() then
                exit;
            SimilarTerms := EDocSimilarDescriptions.GetSimilarDescriptions(Description);
            foreach SimilarTerm in SimilarTerms do begin
                SimilarTerm := SimilarTerm.Trim();
                if (SimilarTerm <> '') and (StrLen(SimilarTerm) > 3) then begin
                    if TotalLoaded >= MaxHistoricalRecords() then
                        exit;
                    PurchInvLine.Reset();
                    SetBaseFilters(PurchInvLine);
                    SetVendorFilter(PurchInvLine, VendorNo);
                    PurchInvLine.SetFilter(Description, '@*' + SimilarTerm + '*');
                    InsertLines(TempPurchInvLine, PurchInvLine);
                end;
            end;
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
        PurchInvLine.ReadIsolation(IsolationLevel::ReadUncommitted);
        PurchInvLine.SetFilter("Posting Date", '>=%1', CalcDate('<-1Y>', Today));
        PurchInvLine.SetFilter(Type, '<>%1', PurchInvLine.Type::" ");
    end;

    local procedure SetVendorFilter(var PurchInvLine: Record "Purch. Inv. Line"; VendorNo: Code[20])
    begin
        if VendorNo <> '' then
            PurchInvLine.SetRange("Buy-from Vendor No.", VendorNo);
    end;

    local procedure InsertLines(var TempPurchInvLine: Record "Purch. Inv. Line" temporary; var PurchInvLine: Record "Purch. Inv. Line")
    var
        AllocationAccount: Record "Allocation Account";
    begin
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
}
