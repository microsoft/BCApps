// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Posting;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;
using System.Utilities;

codeunit 6515 "Package Info. Management"
{

    var
        TrackingNoInfoAlreadyExistsErr: Label '%1 already exists for %2 %3. Do you want to overwrite the existing information?', Comment = '%1 - tracking info table caption, %2 - tracking field caption, %3 - tracking field value';

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'OnBeforeCalcQtyWithBlockedItemTracking', '', false, false)]
    local procedure BinContentOnBeforeCalcQtyWithBlockedItemTracking(BinContent: Record "Bin Content"; var QtyWithBlockedItemTracking: Decimal)
    var
        SerialNoInfo: Record "Serial No. Information";
        LotNoInfo: Record "Lot No. Information";
        XBinContent: Record "Bin Content";
        PackageNoInfo: Record "Package No. Information";
        QtySNBlocked: Decimal;
        QtyLNBlocked: Decimal;
        QtyCDBlocked: Decimal;
        QtySNAndLNBlocked: Decimal;
        QtySNAndCDBlocked: Decimal;
        QtyLNAndCDBlocked: Decimal;
        QtySNAndLNAndCDBlocked: Decimal;
        SNGiven: Boolean;
        LNGiven: Boolean;
        NoITGiven: Boolean;
        CDGiven: Boolean;
    begin
        SerialNoInfo.SetRange("Item No.", BinContent."Item No.");
        SerialNoInfo.SetRange("Variant Code", BinContent."Variant Code");
        BinContent.CopyFilter("Serial No. Filter", SerialNoInfo."Serial No.");
        SerialNoInfo.SetRange(Blocked, true);

        LotNoInfo.SetRange("Item No.", BinContent."Item No.");
        LotNoInfo.SetRange("Variant Code", BinContent."Variant Code");
        BinContent.CopyFilter("Lot No. Filter", LotNoInfo."Lot No.");
        LotNoInfo.SetRange(Blocked, true);

        PackageNoInfo.SetRange("Item No.", BinContent."Item No.");
        PackageNoInfo.SetRange("Variant Code", BinContent."Variant Code");
        BinContent.CopyFilter("Package No. Filter", PackageNoInfo."Package No.");
        PackageNoInfo.SetRange(Blocked, true);

        OnBinContentOnBeforeCalcQtyWithBlockedItemTrackingOnAfterTrackingInformationFiltered(SerialNoInfo, LotNoInfo, PackageNoInfo, BinContent);

        if SerialNoInfo.IsEmpty() and LotNoInfo.IsEmpty() and PackageNoInfo.IsEmpty() then
            exit;

        SNGiven := not (BinContent.GetFilter("Serial No. Filter") = '');
        LNGiven := not (BinContent.GetFilter("Lot No. Filter") = '');
        CDGiven := not (BinContent.GetFilter("Package No. Filter") = '');

        XBinContent.Copy(BinContent);
        BinContent.ClearTrackingFilters();

        NoITGiven := not SNGiven and not LNGiven and not CDGiven;
        if SNGiven or NoITGiven then
            if SerialNoInfo.FindSet() then
                repeat
                    BinContent.SetRange("Serial No. Filter", SerialNoInfo."Serial No.");
                    BinContent.CalcFields("Quantity (Base)");
                    QtySNBlocked += BinContent."Quantity (Base)";
                    BinContent.SetRange("Serial No. Filter");
                until SerialNoInfo.Next() = 0;

        if LNGiven or NoITGiven then
            if LotNoInfo.FindSet() then
                repeat
                    BinContent.SetRange("Lot No. Filter", LotNoInfo."Lot No.");
                    BinContent.CalcFields("Quantity (Base)");
                    QtyLNBlocked += BinContent."Quantity (Base)";
                    BinContent.SetRange("Lot No. Filter");
                until LotNoInfo.Next() = 0;

        if CDGiven or NoITGiven then
            if PackageNoInfo.FindSet() then
                repeat
                    BinContent.SetRange("Package No. Filter", PackageNoInfo."Package No.");
                    BinContent.CalcFields("Quantity (Base)");
                    QtyCDBlocked += BinContent."Quantity (Base)";
                    BinContent.SetRange("Package No. Filter");
                until PackageNoInfo.Next() = 0;

        if (SNGiven and LNGiven) or NoITGiven then
            if SerialNoInfo.FindSet() then
                repeat
                    if LotNoInfo.FindSet() then
                        repeat
                            BinContent.SetRange("Serial No. Filter", SerialNoInfo."Serial No.");
                            BinContent.SetRange("Lot No. Filter", LotNoInfo."Lot No.");
                            BinContent.CalcFields("Quantity (Base)");
                            QtySNAndLNBlocked += BinContent."Quantity (Base)";
                        until LotNoInfo.Next() = 0;
                until SerialNoInfo.Next() = 0;

        if (SNGiven and CDGiven) or NoITGiven then
            if SerialNoInfo.FindSet() then
                repeat
                    if PackageNoInfo.FindSet() then
                        repeat
                            BinContent.SetRange("Serial No. Filter", SerialNoInfo."Serial No.");
                            BinContent.SetRange("Package No. Filter", PackageNoInfo."Package No.");
                            BinContent.CalcFields("Quantity (Base)");
                            QtySNAndCDBlocked += BinContent."Quantity (Base)";
                        until PackageNoInfo.Next() = 0;
                until SerialNoInfo.Next() = 0;

        if (LNGiven and CDGiven) or NoITGiven then
            if LotNoInfo.FindSet() then
                repeat
                    if PackageNoInfo.FindSet() then
                        repeat
                            BinContent.SetRange("Lot No. Filter", LotNoInfo."Lot No.");
                            BinContent.SetRange("Package No. Filter", PackageNoInfo."Package No.");
                            BinContent.CalcFields("Quantity (Base)");
                            QtyLNAndCDBlocked += BinContent."Quantity (Base)";
                        until PackageNoInfo.Next() = 0;
                until LotNoInfo.Next() = 0;

        if SNGiven and LNGiven and CDGiven then
            if SerialNoInfo.FindSet() then
                repeat
                    if LotNoInfo.FindSet() then
                        repeat
                            if PackageNoInfo.FindSet() then
                                repeat
                                    BinContent.SetRange("Serial No. Filter", SerialNoInfo."Serial No.");
                                    BinContent.SetRange("Lot No. Filter", LotNoInfo."Lot No.");
                                    BinContent.SetRange("Package No. Filter", PackageNoInfo."Package No.");
                                    BinContent.CalcFields("Quantity (Base)");
                                    QtySNAndLNAndCDBlocked += BinContent."Quantity (Base)";
                                until PackageNoInfo.Next() = 0;
                        until LotNoInfo.Next() = 0;
                until SerialNoInfo.Next() = 0;

        BinContent.Copy(XBinContent);
        QtyWithBlockedItemTracking :=
            QtySNBlocked + QtyLNBlocked + QtyCDBlocked - QtySNAndLNBlocked - QtySNAndCDBlocked - QtyLNAndCDBlocked - QtySNAndLNAndCDBlocked;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Pick", 'OnAfterBlockedBinOrTracking', '', false, false)]
    local procedure CreatePickOnAfterBlockedBinOrTracking(BinContentBuffer: Record "Bin Content Buffer"; var IsBlocked: Boolean)
    var
        PackageNoInfo: Record "Package No. Information";
    begin
        if PackageNoInfo.Get(BinContentBuffer."Item No.", BinContentBuffer."Variant Code", BinContentBuffer."Package No.") then
            if PackageNoInfo.Blocked then
                IsBlocked := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Item Tracking FEFO", 'OnAfterIsItemTrackingBlocked', '', false, false)]
    local procedure WhseItemTrackingFEFOOnAfterIsItemTrackingBlocked(var ReservEntry: Record "Reservation Entry"; ItemNo: Code[20]; VariantCode: Code[10]; var IsBlocked: Boolean; ItemTrackingSetup: Record "Item Tracking Setup")
    var
        PackageNoInformation: Record "Package No. Information";
    begin
        if ItemTrackingSetup."Package No." <> '' then
            if PackageNoInformation.Get(ItemNo, VariantCode, ItemTrackingSetup."Package No.") then
                if PackageNoInformation.Blocked then
                    IsBlocked := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnAfterCheckItemTrackingInfoBlocked', '', false, false)]
    local procedure WhseActivityRegisterOnAfterCheckItemTrackingInfoBlocked(WhseActivityLine: Record "Warehouse Activity Line")
    var
        PackageNoInformation: Record "Package No. Information";
    begin
        if WhseActivityLine."Package No." <> '' then
            if PackageNoInformation.Get(
                WhseActivityLine."Item No.", WhseActivityLine."Variant Code", WhseActivityLine."Package No.")
            then
                PackageNoInformation.TestField(Blocked, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterCheckItemTrackingInformation', '', false, false)]
    local procedure ItemJnlPostLineOnAfterCheckItemTrackingInformation(Item: Record Item; ItemTrackingSetup: Record "Item Tracking Setup"; var TrackingSpecification: Record "Tracking Specification"; var ItemJnlLine2: Record "Item Journal Line")
    var
        PackageNoInfo: Record "Package No. Information";
    begin
        if ItemTrackingSetup."Package No. Info Required" then begin
            PackageNoInfo.Get(ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code", TrackingSpecification."Package No.");
            TestPackageNoInformation(PackageNoInfo, Item."Item Tracking Code", ItemJnlLine2."Location Code");
            if TrackingSpecification."New Package No." <> '' then begin
                PackageNoInfo.Get(ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code", TrackingSpecification."New Package No.");
                TestPackageNoInformation(PackageNoInfo, Item."Item Tracking Code", ItemJnlLine2."New Location Code")
            end;
        end else
            if ItemTrackingSetup."Package No. Required" then begin
                if PackageNoInfo.Get(ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code", TrackingSpecification."Package No.") then
                    TestPackageNoInformation(PackageNoInfo, Item."Item Tracking Code", ItemJnlLine2."Location Code")
                else
                    if TrackingSpecification."Package No." <> '' then
                        CreatePackageNoInfo(ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code", TrackingSpecification."Package No.");
                if TrackingSpecification."New Package No." <> '' then
                    if PackageNoInfo.Get(ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code", TrackingSpecification."New Package No.") then
                        TestPackageNoInformation(PackageNoInfo, Item."Item Tracking Code", ItemJnlLine2."New Location Code")
                    else
                        if TrackingSpecification."New Package No." <> '' then
                            CreatePackageNoInfo(ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code", TrackingSpecification."New Package No.");
            end;
    end;

    local procedure CreatePackageNoInfo(ItemNo: Code[20]; VariantCode: Code[10]; PackageNo: Code[50])
    var
        PackageNoInfo: Record "Package No. Information";
    begin
        PackageNoInfo.Init();
        PackageNoInfo."Item No." := ItemNo;
        PackageNoInfo."Variant Code" := VariantCode;
        PackageNoInfo.Validate("Package No.", PackageNo);
        PackageNoInfo.Insert();
    end;

    local procedure TestPackageNoInformation(PackageNoInfo: Record "Package No. Information"; ItemTrackingCode: Code[10]; LocationCode: Code[10])
    begin
        PackageNoInfo.TestField(Blocked, false);

        OnAfterTestPackageNoInformation(PackageNoInfo, ItemTrackingCode, LocationCode);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Doc. Management", 'OnCreateTrackingInformationOnAfterTrackingSpecLoop', '', false, false)]
    local procedure ItemTrackingDocManagementOnCreateTrackingInformationOnAfterTrackingSpecLoop(TrackingSpecification: Record "Tracking Specification"; ItemTrackingCode: Record "Item Tracking Code"; Inbound: Boolean)
    var
        PackageNoInfo: Record "Package No. Information";
    begin
        if ((Inbound and ItemTrackingCode."Package Info. Inb. Must Exist") or
            (not Inbound and ItemTrackingCode."Package Info. Outb. Must Exist")) and (TrackingSpecification."Lot No." <> '')
        then
            if not PackageNoInfo.Get(TrackingSpecification."Item No.", TrackingSpecification."Variant Code", TrackingSpecification."Package No.") then
                CreatePackageNoInfo(TrackingSpecification."Item No.", TrackingSpecification."Variant Code", TrackingSpecification."Package No.");
    end;

    procedure CopyPackageNoInformation(PackageNoInfo: Record "Package No. Information"; NewPackageNo: Code[50])
    var
        NewPackageNoInfo: Record "Package No. Information";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if NewPackageNoInfo.Get(PackageNoInfo."Item No.", PackageNoInfo."Variant Code", NewPackageNo) then begin
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   TrackingNoInfoAlreadyExistsErr, PackageNoInfo.TableCaption(), PackageNoInfo.FieldCaption("Package No."), NewPackageNo), true)
            then
                Error('');
            NewPackageNoInfo.TransferFields(PackageNoInfo, false);
            NewPackageNoInfo.Modify();
        end else begin
            NewPackageNoInfo := PackageNoInfo;
            NewPackageNoInfo."Package No." := NewPackageNo;
            NewPackageNoInfo.Insert();
        end;
    end;

    procedure LookupPackageNo(var TrackingSpecification: Record "Tracking Specification")
    var
        PackageNoInfo: Record "Package No. Information";
        PackageNoInfoList: Page "Package No. Information List";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupPackageNo(TrackingSpecification, IsHandled);
        if IsHandled then
            exit;

        Clear(PackageNoInfoList);
        PackageNoInfo.SetRange("Item No.", TrackingSpecification."Item No.");
        PackageNoInfo.SetRange("Variant Code", TrackingSpecification."Variant Code");
        PackageNoInfo."Package No." := TrackingSpecification."Package No.";
        PackageNoInfoList.SetTableView(PackageNoInfo);
        PackageNoInfoList.SetRecord(PackageNoInfo);
        PackageNoInfoList.LookupMode(true);
        if PackageNoInfoList.RunModal() = ACTION::LookupOK then begin
            PackageNoInfoList.GetRecord(PackageNoInfo);
            TrackingSpecification."Package No." := PackageNoInfo."Package No.";
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestPackageNoInformation(PackageNoInfo: Record "Package No. Information"; ItemTrackingCode: Code[10]; LocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupPackageNo(var TrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBinContentOnBeforeCalcQtyWithBlockedItemTrackingOnAfterTrackingInformationFiltered(var SerialNoInformation: Record "Serial No. Information"; var LotNoInformation: Record "Lot No. Information"; var PackageNoInformation: Record "Package No. Information"; var BinContent: Record "Bin Content")
    begin
    end;
}
