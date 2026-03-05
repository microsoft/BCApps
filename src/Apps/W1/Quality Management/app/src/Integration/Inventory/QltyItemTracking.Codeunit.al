// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory;

using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Utilities;

/// <summary>
/// Methods to assist with dealing with item tracking.
/// </summary>
codeunit 20428 "Qlty. Item Tracking"
{
    InherentPermissions = X;

    var
        ThereIsNoSourceLotErr: Label 'There is no lot or item defined on the inspection %1. Please set the item and lot first before blocking or unblocking the lot.', Locked = true;
        ThereIsNoSourceSerialErr: Label 'There is no serial or item defined on the inspection %1. Please set the item and serial first before blocking or unblocking the serial.', Locked = true;
        ThereIsNoSourcePackageErr: Label 'There is no package or item defined on the inspection %1. Please set the item and package first before blocking or unblocking the package.', Locked = true;
        LotTypeLbl: Label 'Lot';
        SerialTypeLbl: Label 'Serial';
        PackageTypeLbl: Label 'Package';

    /// <summary>
    /// Sets the lot block state.
    /// If there is no lot no. information card then it will create a lot no information card.
    /// </summary>
    /// <param name="QltyInspectionHeader"></param>
    /// <param name="Blocked"></param>
    internal procedure SetLotBlockState(QltyInspectionHeader: Record "Qlty. Inspection Header"; Blocked: Boolean)
    var
        LotNoInformation: Record "Lot No. Information";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
    begin
        GetOrCreateLotNoInformation(QltyInspectionHeader, LotNoInformation);
        LotNoInformation.Validate(Blocked, Blocked);
        LotNoInformation.Modify(true);
        QltyNotificationMgmt.NotifyItemTrackingBlockStateChanged(QltyInspectionHeader, LotNoInformation.RecordId(), LotTypeLbl, LotNoInformation."Lot No.", LotNoInformation.Blocked);
    end;

    local procedure GetOrCreateLotNoInformation(QltyInspectionHeader: Record "Qlty. Inspection Header"; var LotNoInformation: Record "Lot No. Information")
    begin
        LotNoInformation.Reset();
        if (QltyInspectionHeader."Source Lot No." = '') or (QltyInspectionHeader."Source Item No." = '') then
            Error(ThereIsNoSourceLotErr, QltyInspectionHeader.GetFriendlyIdentifier());

        if LotNoInformation.Get(QltyInspectionHeader."Source Item No.", QltyInspectionHeader."Source Variant Code", QltyInspectionHeader."Source Lot No.") then
            exit;

        LotNoInformation.Init();
        LotNoInformation."Item No." := QltyInspectionHeader."Source Item No.";
        LotNoInformation."Variant Code" := QltyInspectionHeader."Source Variant Code";
        LotNoInformation."Lot No." := QltyInspectionHeader."Source Lot No.";
        LotNoInformation.Insert(true);
    end;

    /// <summary>
    /// Sets the serial block state.
    /// If there is no serial no. information card then it will create a serial no information card.
    /// </summary>
    /// <param name="QltyInspectionHeader"></param>
    /// <param name="Blocked"></param>
    internal procedure SetSerialBlockState(QltyInspectionHeader: Record "Qlty. Inspection Header"; Blocked: Boolean)
    var
        SerialNoInformation: Record "Serial No. Information";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
    begin
        GetOrCreateSerialNoInformation(QltyInspectionHeader, SerialNoInformation);
        SerialNoInformation.Validate(Blocked, Blocked);
        SerialNoInformation.Modify(true);
        QltyNotificationMgmt.NotifyItemTrackingBlockStateChanged(QltyInspectionHeader, SerialNoInformation.RecordId(), SerialTypeLbl, SerialNoInformation."Serial No.", SerialNoInformation.Blocked);
    end;

    local procedure GetOrCreateSerialNoInformation(QltyInspectionHeader: Record "Qlty. Inspection Header"; var SerialNoInformation: Record "Serial No. Information")
    begin
        SerialNoInformation.Reset();
        if (QltyInspectionHeader."Source Serial No." = '') or (QltyInspectionHeader."Source Item No." = '') then
            Error(ThereIsNoSourceSerialErr, QltyInspectionHeader.GetFriendlyIdentifier());

        if SerialNoInformation.Get(QltyInspectionHeader."Source Item No.", QltyInspectionHeader."Source Variant Code", QltyInspectionHeader."Source Serial No.") then
            exit;

        SerialNoInformation.Init();
        SerialNoInformation."Item No." := QltyInspectionHeader."Source Item No.";
        SerialNoInformation."Variant Code" := QltyInspectionHeader."Source Variant Code";
        SerialNoInformation."Serial No." := QltyInspectionHeader."Source Serial No.";
        SerialNoInformation.Insert(true);
    end;

    /// <summary>
    /// Sets the package block state.
    /// If no package no information card exists then one will be created.
    /// </summary>
    /// <param name="QltyInspectionHeader"></param>
    /// <param name="Blocked"></param>
    internal procedure SetPackageBlockState(QltyInspectionHeader: Record "Qlty. Inspection Header"; Blocked: Boolean)
    var
        PackageNoInformation: Record "Package No. Information";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
    begin
        GetOrCreatePackageNoInformation(QltyInspectionHeader, PackageNoInformation);
        PackageNoInformation.Validate(Blocked, Blocked);
        PackageNoInformation.Modify(true);
        QltyNotificationMgmt.NotifyItemTrackingBlockStateChanged(QltyInspectionHeader, PackageNoInformation.RecordId(), PackageTypeLbl, PackageNoInformation."Package No.", PackageNoInformation.Blocked);
    end;

    local procedure GetOrCreatePackageNoInformation(QltyInspectionHeader: Record "Qlty. Inspection Header"; var PackageNoInformation: Record "Package No. Information")
    begin
        PackageNoInformation.Reset();
        if (QltyInspectionHeader."Source Package No." = '') or (QltyInspectionHeader."Source Item No." = '') then
            Error(ThereIsNoSourcePackageErr, QltyInspectionHeader.GetFriendlyIdentifier());

        if PackageNoInformation.Get(QltyInspectionHeader."Source Item No.", QltyInspectionHeader."Source Variant Code", QltyInspectionHeader."Source Package No.") then
            exit;

        PackageNoInformation.Init();
        PackageNoInformation."Item No." := QltyInspectionHeader."Source Item No.";
        PackageNoInformation."Variant Code" := QltyInspectionHeader."Source Variant Code";
        PackageNoInformation."Package No." := QltyInspectionHeader."Source Package No.";
        PackageNoInformation.Insert(true);
    end;

    procedure GetMostRecentResultFor(ItemNo: Code[20]; VariantCodeFilter: Text; LotNo: Code[50]; SerialNo: Code[50]; PackageNo: Code[50]; var QualityResultCode: Code[20]; var QualityResultDescription: Text)
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        Clear(QualityResultCode);
        Clear(QualityResultDescription);

        if QltyInspectionHeader.IsEmpty() then
            exit;

        QltyInspectionHeader.SetCurrentKey(SystemModifiedAt);
        QltyInspectionHeader.Ascending(false);
        if ItemNo <> '' then
            QltyInspectionHeader.SetRange("Source Item No.", ItemNo);

        if VariantCodeFilter <> '' then
            QltyInspectionHeader.SetFilter("Source Variant Code", VariantCodeFilter);

        if LotNo <> '' then
            QltyInspectionHeader.SetRange("Source Lot No.", LotNo);
        if SerialNo <> '' then
            QltyInspectionHeader.SetRange("Source Serial No.", SerialNo);
        if PackageNo <> '' then
            QltyInspectionHeader.SetRange("Source Package No.", PackageNo);

        QltyInspectionHeader.SetAutoCalcFields("Result Description");
        if QltyInspectionHeader.FindFirst() then begin
            QualityResultCode := QltyInspectionHeader."Result Code";
            QualityResultDescription := QltyInspectionHeader."Result Description";
        end;
    end;

    /// <summary>
    /// Returns true if the item is either lot, or serial, or package tracked.
    /// </summary>
    /// <param name="ItemNo"></param>
    /// <returns></returns>
    internal procedure IsItemTrackingUsed(ItemNo: Code[20]): Boolean
    var
        TempDummyItemTrackingSetup: Record "Item Tracking Setup" temporary;
    begin
        TempDummyItemTrackingSetup."Lot No. Required" := true;
        TempDummyItemTrackingSetup."Serial No. Required" := true;
        TempDummyItemTrackingSetup."Package No. Required" := true;
        exit(IsItemTrackingUsed(ItemNo, TempDummyItemTrackingSetup));
    end;

    internal procedure IsItemTrackingUsed(ItemNo: Code[20]; var TempItemTrackingSetup: Record "Item Tracking Setup" temporary): Boolean
    var
        ItemTrackingCode: Record "Item Tracking Code";
        QltyItemTrackingMgmt: Codeunit "Qlty. Item Tracking Mgmt.";
    begin
        case true of
            ItemNo = '',
            not QltyItemTrackingMgmt.GetItemTrackingCode(ItemNo, ItemTrackingCode):
                begin
                    Clear(TempItemTrackingSetup);
                    exit(false);
                end;
        end;

        if TempItemTrackingSetup."Lot No. Required" then
            TempItemTrackingSetup."Lot No. Required" := IsLotTrackedItemTrackingCode(ItemTrackingCode);

        if TempItemTrackingSetup."Serial No. Required" then
            TempItemTrackingSetup."Serial No. Required" := IsSerialTrackedItemTrackingCode(ItemTrackingCode);

        if TempItemTrackingSetup."Package No. Required" then
            TempItemTrackingSetup."Package No. Required" := IsPackageTrackedItemTrackingCode(ItemTrackingCode);

        exit(TempItemTrackingSetup."Lot No. Required" or TempItemTrackingSetup."Serial No. Required" or TempItemTrackingSetup."Package No. Required");
    end;

    local procedure IsLotTrackedItemTrackingCode(ItemTrackingCode: Record "Item Tracking Code"): Boolean
    begin
        exit(ItemTrackingCode."Lot Manuf. Outbound Tracking" or
            ItemTrackingCode."Lot Neg. Adjmt. Inb. Tracking" or
            ItemTrackingCode."Lot Neg. Adjmt. Outb. Tracking" or
            ItemTrackingCode."Lot Pos. Adjmt. Inb. Tracking" or
            ItemTrackingCode."Lot Pos. Adjmt. Outb. Tracking" or
            ItemTrackingCode."Lot Assembly Inbound Tracking" or
            ItemTrackingCode."Lot Assembly Outbound Tracking" or
            ItemTrackingCode."Lot Purchase Inbound Tracking" or
            ItemTrackingCode."Lot Purchase Outbound Tracking" or
            ItemTrackingCode."Lot Specific Tracking");
    end;

    local procedure IsSerialTrackedItemTrackingCode(ItemTrackingCode: Record "Item Tracking Code"): Boolean
    begin
        exit(ItemTrackingCode."SN Manuf. Outbound Tracking" or
            ItemTrackingCode."SN Neg. Adjmt. Inb. Tracking" or
            ItemTrackingCode."SN Neg. Adjmt. Outb. Tracking" or
            ItemTrackingCode."SN Pos. Adjmt. Inb. Tracking" or
            ItemTrackingCode."SN Pos. Adjmt. Outb. Tracking" or
            ItemTrackingCode."SN Assembly Inbound Tracking" or
            ItemTrackingCode."SN Assembly Outbound Tracking" or
            ItemTrackingCode."SN Purchase Inbound Tracking" or
            ItemTrackingCode."SN Purchase Outbound Tracking" or
            ItemTrackingCode."SN Specific Tracking");
    end;

    local procedure IsPackageTrackedItemTrackingCode(ItemTrackingCode: Record "Item Tracking Code"): Boolean
    begin
        exit(ItemTrackingCode."Package Manuf. Outb. Tracking" or
            ItemTrackingCode."Package Neg. Inb. Tracking" or
            ItemTrackingCode."Package Neg. Outb. Tracking" or
            ItemTrackingCode."Package Pos. Inb. Tracking" or
            ItemTrackingCode."Package Pos. Outb. Tracking" or
            ItemTrackingCode."Package Assembly Inb. Tracking" or
            ItemTrackingCode."Package Assembly Out. Tracking" or
            ItemTrackingCode."Package Purchase Inb. Tracking" or
            ItemTrackingCode."Package Purch. Outb. Tracking" or
            ItemTrackingCode."Package Specific Tracking");
    end;
}
