// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.QualityManagement.Utilities;

/// <summary>
/// Methods to assist with dealing with item tracking.
/// </summary>
codeunit 20428 "Qlty. Item Tracking"
{
    SingleInstance = true;
    InherentPermissions = X;

    var
        CacheLotTracked: Dictionary of [Text, Boolean];
        CacheSerialTracked: Dictionary of [Text, Boolean];
        CachePackageTracked: Dictionary of [Text, Boolean];
        ThereIsNoSourceLotErr: Label 'There is no lot or item defined on the test %1. Please set the item and lot first before blocking or unblocking the lot.', Locked = true;
        ThereIsNoSourceSerialErr: Label 'There is no serial or item defined on the test %1. Please set the item and serial first before blocking or unblocking the serial.', Locked = true;
        ThereIsNoSourcePackageErr: Label 'There is no package or item defined on the test %1. Please set the item and package first before blocking or unblocking the serial.', Locked = true;
        LotTypeLbl: Label 'Lot';
        SerialTypeLbl: Label 'Serial';
        PackageTypeLbl: Label 'Package';

    /// <summary>
    /// Sets the lot block state.
    /// If there is no lot no. information card then it will create a lot no information card.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="Blocked"></param>
    procedure SetLotBlockState(QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; Blocked: Boolean)
    var
        LotNoInformation: Record "Lot No. Information";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
    begin
        GetOrCreateLotNoInformation(QltyInspectionTestHeader, LotNoInformation);
        LotNoInformation.Validate(Blocked, Blocked);
        LotNoInformation.Modify(true);
        QltyNotificationMgmt.NotifyItemTrackingBlockStateChanged(QltyInspectionTestHeader, LotNoInformation.RecordId(), LotTypeLbl, LotNoInformation."Lot No.", LotNoInformation.Blocked);
    end;

    /// <summary>
    /// Sets the serial block state.
    /// If there is no serial no. information card then it will create a serial no information card.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="Blocked"></param>
    procedure SetSerialBlockState(QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; Blocked: Boolean)
    var
        SerialNoInformation: Record "Serial No. Information";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
    begin
        GetOrCreateSerialNoInformation(QltyInspectionTestHeader, SerialNoInformation);
        SerialNoInformation.Validate(Blocked, Blocked);
        SerialNoInformation.Modify(true);
        QltyNotificationMgmt.NotifyItemTrackingBlockStateChanged(QltyInspectionTestHeader, SerialNoInformation.RecordId(), SerialTypeLbl, SerialNoInformation."Serial No.", SerialNoInformation.Blocked);
    end;

    /// <summary>
    /// Sets the package block state.
    /// If no package no information card exists then one will be created.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="Blocked"></param>
    procedure SetPackageBlockState(QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; Blocked: Boolean)
    var
        PackageNoInformation: Record "Package No. Information";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
    begin
        GetOrCreatePackageNoInformation(QltyInspectionTestHeader, PackageNoInformation);
        PackageNoInformation.Validate(Blocked, Blocked);
        PackageNoInformation.Modify(true);
        QltyNotificationMgmt.NotifyItemTrackingBlockStateChanged(QltyInspectionTestHeader, PackageNoInformation.RecordId(), PackageTypeLbl, PackageNoInformation."Package No.", PackageNoInformation.Blocked);
    end;

    local procedure GetOrCreateLotNoInformation(QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var LotNoInformation: Record "Lot No. Information")
    begin
        LotNoInformation.Reset();
        if (QltyInspectionTestHeader."Source Lot No." = '') or (QltyInspectionTestHeader."Source Item No." = '') then
            Error(ThereIsNoSourceLotErr, QltyInspectionTestHeader.GetFriendlyIdentifier());

        if LotNoInformation.Get(QltyInspectionTestHeader."Source Item No.", QltyInspectionTestHeader."Source Variant Code", QltyInspectionTestHeader."Source Lot No.") then
            exit;

        LotNoInformation.Init();
        LotNoInformation."Item No." := QltyInspectionTestHeader."Source Item No.";
        LotNoInformation."Variant Code" := QltyInspectionTestHeader."Source Variant Code";
        LotNoInformation."Lot No." := QltyInspectionTestHeader."Source Lot No.";
        LotNoInformation.Insert(true);
    end;

    local procedure GetOrCreateSerialNoInformation(QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var SerialNoInformation: Record "Serial No. Information")
    begin
        SerialNoInformation.Reset();
        if (QltyInspectionTestHeader."Source Serial No." = '') or (QltyInspectionTestHeader."Source Item No." = '') then
            Error(ThereIsNoSourceSerialErr, QltyInspectionTestHeader.GetFriendlyIdentifier());

        if SerialNoInformation.Get(QltyInspectionTestHeader."Source Item No.", QltyInspectionTestHeader."Source Variant Code", QltyInspectionTestHeader."Source Serial No.") then
            exit;

        SerialNoInformation.Init();
        SerialNoInformation."Item No." := QltyInspectionTestHeader."Source Item No.";
        SerialNoInformation."Variant Code" := QltyInspectionTestHeader."Source Variant Code";
        SerialNoInformation."Serial No." := QltyInspectionTestHeader."Source Serial No.";
        SerialNoInformation.Insert(true);
    end;

    local procedure GetOrCreatePackageNoInformation(QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var PackageNoInformation: Record "Package No. Information")
    begin
        PackageNoInformation.Reset();
        if (QltyInspectionTestHeader."Source Package No." = '') or (QltyInspectionTestHeader."Source Item No." = '') then
            Error(ThereIsNoSourcePackageErr, QltyInspectionTestHeader.GetFriendlyIdentifier());

        if PackageNoInformation.Get(QltyInspectionTestHeader."Source Item No.", QltyInspectionTestHeader."Source Variant Code", QltyInspectionTestHeader."Source Package No.") then
            exit;

        PackageNoInformation.Init();
        PackageNoInformation."Item No." := QltyInspectionTestHeader."Source Item No.";
        PackageNoInformation."Variant Code" := QltyInspectionTestHeader."Source Variant Code";
        PackageNoInformation."Package No." := QltyInspectionTestHeader."Source Package No.";
        PackageNoInformation.Insert(true);
    end;

    procedure GetMostRecentGradeFor(ItemNo: Code[20]; VariantCodeFilter: Text; LotNo: Code[50]; SerialNo: Code[50]; PackageNo: Code[50]; var QualityGradeCode: Code[20]; var QualityGradeDescription: Text)
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
    begin
        Clear(QualityGradeCode);
        Clear(QualityGradeDescription);

        if not CheckIfQualityManagementIsEnabled() then
            exit;

        QltyInspectionTestHeader.SetCurrentKey(SystemModifiedAt);
        QltyInspectionTestHeader.Ascending(false);
        if ItemNo <> '' then
            QltyInspectionTestHeader.SetRange("Source Item No.", ItemNo);

        if VariantCodeFilter <> '' then
            QltyInspectionTestHeader.SetFilter("Source Variant Code", VariantCodeFilter);

        if LotNo <> '' then
            QltyInspectionTestHeader.SetRange("Source Lot No.", LotNo);
        if SerialNo <> '' then
            QltyInspectionTestHeader.SetRange("Source Serial No.", SerialNo);
        if PackageNo <> '' then
            QltyInspectionTestHeader.SetRange("Source Package No.", PackageNo);

        QltyInspectionTestHeader.SetAutoCalcFields("Grade Description");
        if QltyInspectionTestHeader.FindFirst() then begin
            QualityGradeCode := QltyInspectionTestHeader."Grade Code";
            QualityGradeDescription := QltyInspectionTestHeader."Grade Description";
        end;
    end;

    local procedure CheckIfQualityManagementIsEnabled(): Boolean
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
    begin
        if not QltyManagementSetup.ReadPermission() then
            exit(false);
        if not QltyManagementSetup.Get() then
            exit(false);

        exit(QltyManagementSetup.Visibility <> QltyManagementSetup.Visibility::Hide);
    end;

    /// <summary>
    /// Returns true if the item is either lot, or serial, or package tracked.
    /// </summary>
    /// <param name="ItemNo"></param>
    /// <returns></returns>
    internal procedure IsItemTracked(ItemNo: Code[20]): Boolean
    begin
        if ItemNo = '' then
            exit(false);

        if IsLotTracked(ItemNo) then
            exit(true);
        if IsSerialTracked(ItemNo) then
            exit(true);
        if IsPackageTracked(ItemNo) then
            exit(true);

        exit(false);
    end;

    /// <summary>
    /// If the item is lot tracked.
    /// </summary>
    /// <param name="ItemNo"></param>
    /// <returns></returns>
    procedure IsLotTracked(ItemNo: Code[20]) Result: Boolean
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        DummyValue: Boolean;
    begin
        if CacheLotTracked.ContainsKey(ItemNo) then begin
            CacheLotTracked.Get(ItemNo, Result);
            exit;
        end;

        if ItemNo = '' then
            exit(false);
        if not Item.Get(ItemNo) then
            exit(false);
        if Item."Item Tracking Code" = '' then
            exit(false);
        if not ItemTrackingCode.Get(Item."Item Tracking Code") then
            exit(false);

        Result := (ItemTrackingCode."Lot Manuf. Outbound Tracking" or
                   ItemTrackingCode."Lot Neg. Adjmt. Inb. Tracking" or
                   ItemTrackingCode."Lot Neg. Adjmt. Outb. Tracking" or
                   ItemTrackingCode."Lot Pos. Adjmt. Inb. Tracking" or
                   ItemTrackingCode."Lot Pos. Adjmt. Outb. Tracking" or
                   ItemTrackingCode."Lot Assembly Inbound Tracking" or
                   ItemTrackingCode."Lot Assembly Outbound Tracking" or
                   ItemTrackingCode."Lot Purchase Inbound Tracking" or
                   ItemTrackingCode."Lot Purchase Outbound Tracking" or
                   ItemTrackingCode."Lot Specific Tracking");

        CacheLotTracked.Set(ItemNo, Result, DummyValue);
    end;

    /// <summary>
    /// If this item requires serial tracking.
    /// </summary>
    /// <returns></returns>
    procedure IsSerialTracked(ItemNo: Code[20]) Result: Boolean
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        DummyValue: Boolean;
    begin
        if CacheSerialTracked.ContainsKey(ItemNo) then begin
            CacheSerialTracked.Get(ItemNo, Result);
            exit;
        end;

        if ItemNo = '' then
            exit(false);
        if not Item.Get(ItemNo) then
            exit(false);
        if Item."Item Tracking Code" = '' then
            exit(false);
        if not ItemTrackingCode.Get(Item."Item Tracking Code") then
            exit(false);

        Result := (ItemTrackingCode."SN Manuf. Outbound Tracking" or
                   ItemTrackingCode."SN Neg. Adjmt. Inb. Tracking" or
                   ItemTrackingCode."SN Neg. Adjmt. Outb. Tracking" or
                   ItemTrackingCode."SN Pos. Adjmt. Inb. Tracking" or
                   ItemTrackingCode."SN Pos. Adjmt. Outb. Tracking" or
                   ItemTrackingCode."SN Assembly Inbound Tracking" or
                   ItemTrackingCode."SN Assembly Outbound Tracking" or
                   ItemTrackingCode."SN Purchase Inbound Tracking" or
                   ItemTrackingCode."SN Purchase Outbound Tracking" or
                   ItemTrackingCode."SN Specific Tracking");

        CacheSerialTracked.Set(ItemNo, Result, DummyValue);
    end;

    /// <summary>
    /// If the item is package tracked.
    /// </summary>
    /// <param name="ItemNo"></param>
    /// <returns></returns>
    procedure IsPackageTracked(ItemNo: Code[20]) Result: Boolean
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        DummyValue: Boolean;
    begin
        if CachePackageTracked.ContainsKey(ItemNo) then begin
            CachePackageTracked.Get(ItemNo, Result);
            exit;
        end;

        if ItemNo = '' then
            exit(false);
        if not Item.Get(ItemNo) then
            exit(false);
        if Item."Item Tracking Code" = '' then
            exit(false);
        if not ItemTrackingCode.Get(Item."Item Tracking Code") then
            exit(false);

        Result := (ItemTrackingCode."Package Manuf. Outb. Tracking" or
                   ItemTrackingCode."Package Neg. Inb. Tracking" or
                   ItemTrackingCode."Package Neg. Outb. Tracking" or
                   ItemTrackingCode."Package Pos. Inb. Tracking" or
                   ItemTrackingCode."Package Pos. Outb. Tracking" or
                   ItemTrackingCode."Package Assembly Inb. Tracking" or
                   ItemTrackingCode."Package Assembly Out. Tracking" or
                   ItemTrackingCode."Package Purchase Inb. Tracking" or
                   ItemTrackingCode."Package Purch. Outb. Tracking" or
                   ItemTrackingCode."Package Specific Tracking");

        CachePackageTracked.Set(ItemNo, Result, DummyValue);
    end;

    /// <summary>
    /// Internal use to clear cache to avoid item conflicts between auto tests
    /// </summary>
    /// <returns></returns>
    internal procedure ClearTrackingCache()
    begin
        Clear(CacheLotTracked);
        Clear(CacheSerialTracked);
        Clear(CachePackageTracked);
    end;
}
