// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Finance.RoleCenters;
using Microsoft.Purchases.Payables;
using System.Threading;

codeunit 9089 "Top Vendors By Purchases Job"
{
    TableNo = "Job Queue Entry";
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AllOtherVendorsTxt: Label 'All Other Vendors';

    trigger OnRun()
    begin
        UpdateVendorTop10List();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnFindingIfJobNeedsToBeRun', '', false, false)]
    local procedure OnFindingIfJobNeedsToBeRun(var Sender: Record "Job Queue Entry"; var Result: Boolean)
    var
        TopVendorsByPurchases: Record "Top Vendors By Purchase";
        LastVendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if Sender."Object Type to Run" <> Sender."Object Type to Run"::Codeunit then
            exit;

        if Sender."Object ID to Run" <> Codeunit::"Top Vendors By Purchases Job" then
            exit;

        if not LastVendLedgerEntry.FindLast() then
            exit;

        if TopVendorsByPurchases.FindFirst() then
            if TopVendorsByPurchases.LastVendLedgerEntryNo = LastVendLedgerEntry."Entry No." then
                exit;

        Result := true;
    end;

    /// <summary>
    /// Updates the vendors by purchases buffer with top 10 vendors.
    /// </summary>
    procedure UpdateVendorTop10List()
    var
        LastVendLedgerEntry: Record "Vendor Ledger Entry";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        TopVendorsByPurchases: Record "Top Vendors By Purchase";
        TempTopVendorsByPurchases: Record "Top Vendors By Purchase" temporary;
        Vendor: Record Vendor;
        PayablePerformance: Codeunit "Acc. Payable Performance";
        Top10VendorPurchasesQry: Query "Top 10 Vendor Purchases";
        VendorCounter: Integer;
        OtherVendorsPurchasesLCY: Decimal;
        DTUpdated: DateTime;
        LastVendorLedgerEntryNo: Integer;
    begin
        if PayablePerformance.TopVendorListUpdatedRecently(LastVendorLedgerEntryNo) then
            exit;

        if not LastVendLedgerEntry.FindLast() then
            exit;

        if LastVendLedgerEntry."Entry No." = LastVendorLedgerEntryNo then
            exit;

        DTUpdated := CurrentDateTime;

        if Top10VendorPurchasesQry.Open() then
            while Top10VendorPurchasesQry.Read() do
                if Vendor.Get(Top10VendorPurchasesQry.Vendor_No) then begin
                    VendorCounter += 1;
                    InsertRow(TempTopVendorsByPurchases, VendorCounter, Vendor."No.", Vendor.Name, Top10VendorPurchasesQry.Sum_Purchases_LCY, LastVendLedgerEntry."Entry No.", DTUpdated);
                    OtherVendorsPurchasesLCY -= Top10VendorPurchasesQry.Sum_Purchases_LCY;
                end;

        if Vendor.Count > 10 then begin
            VendLedgerEntry.CalcSums("Purchase (LCY)");
            OtherVendorsPurchasesLCY += VendLedgerEntry."Purchase (LCY)";
            VendorCounter += 1;
            InsertRow(TempTopVendorsByPurchases,
              VendorCounter, '', AllOtherVendorsTxt, OtherVendorsPurchasesLCY, LastVendLedgerEntry."Entry No.", DTUpdated);
        end;

        if TempTopVendorsByPurchases.FindSet() then begin
            TopVendorsByPurchases.LockTable();
            TopVendorsByPurchases.DeleteAll(false);
            repeat
                TopVendorsByPurchases.TransferFields(TempTopVendorsByPurchases);
                TopVendorsByPurchases.Insert(false);
            until TempTopVendorsByPurchases.Next() = 0
        end;
    end;

    local procedure InsertRow(var TempTopVendorsByPurchases: Record "Top Vendors By Purchase" temporary; Ranking: Integer; VendorNo: Code[20]; VendorName: Text[100]; PurchasesLCY: Decimal; LastVendLedgEntryNo: Integer; DTUpdated: DateTime)
    begin
        TempTopVendorsByPurchases.Ranking := Ranking;
        TempTopVendorsByPurchases.VendorNo := VendorNo;
        TempTopVendorsByPurchases.VendorName := VendorName;
        TempTopVendorsByPurchases.PurchasesLCY := PurchasesLCY;
        TempTopVendorsByPurchases.LastVendLedgerEntryNo := LastVendLedgEntryNo;
        TempTopVendorsByPurchases.DateTimeUpdated := DTUpdated;
        TempTopVendorsByPurchases.Insert(false);
    end;
}
