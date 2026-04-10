// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Transfer;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using System.Environment.Configuration;

codeunit 5714 "Copy Location"
{
    TableNo = Location;

    trigger OnRun()
    var
        CopyLocationPage: Page "Copy Location";
        IsLocationCopied: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeOnRun(Rec, NewLocationCode, IsLocationCopied, IsHandled);
        if IsHandled then begin
            if IsLocationCopied then
                ShowNotification(Rec);
            exit;
        end;

        CopyLocationPage.SetLocation(Rec);
        if CopyLocationPage.RunModal() <> ACTION::OK then
            exit;

        CopyLocationPage.GetParameters(TempCopyLocationBuffer);

        DoCopyLocation();

        OnRunOnAfterLocationCopied(TempCopyLocationBuffer);

        if TempCopyLocationBuffer."Show Created Location" then
            ShowCreatedLocation()
        else
            ShowNotification(Rec);
    end;

    var
        SourceLocation: Record Location;
        TempCopyLocationBuffer: Record "Copy Location Buffer" temporary;
        NewLocationCode: Code[10];
        TargetLocationAlreadyExistsErr: Label 'Target location code %1 already exists.', Comment = '%1 - location code.';
        LocationCopiedMsg: Label 'Location %1 was successfully copied.', Comment = '%1 - location code';
        ShowCreatedLocationTxt: Label 'Show created location.';
        TargetLocationCodeEmptyErr: Label 'You must specify the target location code.';

    procedure DoCopyLocation()
    begin
        SourceLocation.LockTable();
        SourceLocation.Get(TempCopyLocationBuffer."Source Location Code");

        CopyLocation();
    end;

    procedure SetCopyLocationBuffer(NewCopyLocationBuffer: Record "Copy Location Buffer" temporary)
    begin
        TempCopyLocationBuffer := NewCopyLocationBuffer;
        if SourceLocation.Code <> TempCopyLocationBuffer."Source Location Code" then
            SourceLocation.Get(TempCopyLocationBuffer."Source Location Code");
    end;

    local procedure CopyLocation()
    var
        TargetLocation: Record Location;
    begin
        OnBeforeCopyLocation(SourceLocation, TargetLocation, TempCopyLocationBuffer);

        InitTargetLocation(TargetLocation);

        OnCopyLocationOnBeforeTargetLocationInsert(SourceLocation, TargetLocation, TempCopyLocationBuffer);
        TargetLocation.Insert();

        CopyLocationDimensions(SourceLocation, TargetLocation.Code);
        CopyZones(SourceLocation.Code, TargetLocation.Code);
        CopyBins(SourceLocation.Code, TargetLocation.Code);
        CopyWarehouseEmployees(SourceLocation.Code, TargetLocation.Code);
        CopyInventoryPostingSetup(SourceLocation.Code, TargetLocation.Code);
        CopyTransferRoutes(SourceLocation.Code, TargetLocation.Code);

        OnAfterCopyLocation(TempCopyLocationBuffer, SourceLocation, TargetLocation);
    end;

    local procedure InitTargetLocation(var TargetLocation: Record Location)
    begin
        if TempCopyLocationBuffer."Target Location Code" = '' then
            Error(TargetLocationCodeEmptyErr);

        CheckExistingLocation(TempCopyLocationBuffer."Target Location Code");

        TargetLocation := SourceLocation;
        TargetLocation.Code := TempCopyLocationBuffer."Target Location Code";
        TargetLocation.Name := CopyStr(SourceLocation.Name, 1, MaxStrLen(TargetLocation.Name));

        NewLocationCode := TargetLocation.Code;
    end;

    local procedure CheckExistingLocation(LocationCode: Code[10])
    var
        Location: Record Location;
    begin
        if Location.Get(LocationCode) then
            Error(TargetLocationAlreadyExistsErr, LocationCode);
    end;

    local procedure CopyLocationDimensions(FromLocation: Record Location; ToLocationCode: Code[10])
    var
        DefaultDim: Record "Default Dimension";
        NewDefaultDim: Record "Default Dimension";
    begin
        if TempCopyLocationBuffer.Dimensions then begin
            DefaultDim.SetRange("Table ID", Database::Location);
            DefaultDim.SetRange("No.", FromLocation.Code);
            if DefaultDim.FindSet() then
                repeat
                    NewDefaultDim := DefaultDim;
                    NewDefaultDim."No." := ToLocationCode;
                    NewDefaultDim.Insert();
                until DefaultDim.Next() = 0;
        end;
    end;

    local procedure CopyZones(FromLocationCode: Code[10]; ToLocationCode: Code[10])
    var
        Zone: Record Zone;
        NewZone: Record Zone;
    begin
        if not TempCopyLocationBuffer.Zones then
            exit;

        Zone.SetRange("Location Code", FromLocationCode);
        if Zone.FindSet() then
            repeat
                NewZone := Zone;
                NewZone."Location Code" := ToLocationCode;
                NewZone.Insert();
            until Zone.Next() = 0;
    end;

    local procedure CopyBins(FromLocationCode: Code[10]; ToLocationCode: Code[10])
    var
        Bin: Record Bin;
        NewBin: Record Bin;
    begin
        if not TempCopyLocationBuffer.Bins then
            exit;

        // Only copy bins if zones are also copied, as bins depend on zones
        if not TempCopyLocationBuffer.Zones then
            exit;

        Bin.SetRange("Location Code", FromLocationCode);
        if Bin.FindSet() then
            repeat
                NewBin := Bin;
                NewBin."Location Code" := ToLocationCode;
                NewBin.Insert();
            until Bin.Next() = 0;
    end;

    local procedure CopyWarehouseEmployees(FromLocationCode: Code[10]; ToLocationCode: Code[10])
    var
        WarehouseEmployee: Record "Warehouse Employee";
        NewWarehouseEmployee: Record "Warehouse Employee";
    begin
        if not TempCopyLocationBuffer."Warehouse Employees" then
            exit;

        WarehouseEmployee.SetRange("Location Code", FromLocationCode);
        if WarehouseEmployee.FindSet() then
            repeat
                NewWarehouseEmployee := WarehouseEmployee;
                NewWarehouseEmployee."Location Code" := ToLocationCode;
                if not NewWarehouseEmployee.Insert() then; // Ignore if already exists (same user ID)
            until WarehouseEmployee.Next() = 0;
    end;

    local procedure CopyInventoryPostingSetup(FromLocationCode: Code[10]; ToLocationCode: Code[10])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        NewInventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        if not TempCopyLocationBuffer."Inventory Posting Setup" then
            exit;

        InventoryPostingSetup.SetRange("Location Code", FromLocationCode);
        if InventoryPostingSetup.FindSet() then
            repeat
                NewInventoryPostingSetup := InventoryPostingSetup;
                NewInventoryPostingSetup."Location Code" := ToLocationCode;
                if not NewInventoryPostingSetup.Insert() then; // Ignore if already exists (same combination)
            until InventoryPostingSetup.Next() = 0;
    end;

    local procedure CopyTransferRoutes(FromLocationCode: Code[10]; ToLocationCode: Code[10])
    var
        TransferRoute: Record "Transfer Route";
        NewTransferRoute: Record "Transfer Route";
    begin
        if not TempCopyLocationBuffer."Transfer Routes" then
            exit;

        // Copy routes where source location is the transfer-from location
        TransferRoute.SetRange("Transfer-from Code", FromLocationCode);
        if TransferRoute.FindSet() then
            repeat
                NewTransferRoute := TransferRoute;
                NewTransferRoute."Transfer-from Code" := ToLocationCode;
                if not NewTransferRoute.Insert() then; // Ignore if already exists
            until TransferRoute.Next() = 0;

        // Copy routes where source location is the transfer-to location
        TransferRoute.Reset();
        TransferRoute.SetRange("Transfer-to Code", FromLocationCode);
        if TransferRoute.FindSet() then
            repeat
                // Check if this route hasn't already been inserted (in case both from and to match)
                if not ((TransferRoute."Transfer-from Code" = FromLocationCode) and
                        (TransferRoute."Transfer-to Code" = FromLocationCode)) then begin
                    Clear(NewTransferRoute);
                    NewTransferRoute := TransferRoute;
                    NewTransferRoute."Transfer-to Code" := ToLocationCode;
                    if not NewTransferRoute.Insert() then; // Ignore if already exists
                end;
            until TransferRoute.Next() = 0;

        // Copy routes where both from and to are the source location
        TransferRoute.Reset();
        TransferRoute.SetRange("Transfer-from Code", FromLocationCode);
        TransferRoute.SetRange("Transfer-to Code", FromLocationCode);
        if TransferRoute.FindSet() then
            repeat
                Clear(NewTransferRoute);
                NewTransferRoute := TransferRoute;
                NewTransferRoute."Transfer-from Code" := ToLocationCode;
                NewTransferRoute."Transfer-to Code" := ToLocationCode;
                if not NewTransferRoute.Insert() then; // Ignore if already exists
            until TransferRoute.Next() = 0;
    end;

    local procedure ShowNotification(Location: Record Location)
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LocationCopiedNotification: Notification;
    begin
        LocationCopiedNotification.Id := CreateGuid();
        LocationCopiedNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
        LocationCopiedNotification.SetData('LocationCode', NewLocationCode);
        LocationCopiedNotification.Message(StrSubstNo(LocationCopiedMsg, Location.Code));
        LocationCopiedNotification.AddAction(ShowCreatedLocationTxt, CODEUNIT::"Copy Location", 'ShowCreatedLocation');
        NotificationLifecycleMgt.SendNotification(LocationCopiedNotification, Location.RecordId);
    end;

    procedure ShowCreatedLocation(var LocationCopiedNotification: Notification)
    var
        Location: Record Location;
    begin
        if Location.Get(LocationCopiedNotification.GetData('LocationCode')) then
            PAGE.RunModal(PAGE::"Location Card", Location);
    end;

    local procedure ShowCreatedLocation()
    var
        Location: Record Location;
    begin
        if Location.Get(NewLocationCode) then
            PAGE.Run(PAGE::"Location Card", Location);
    end;

    procedure GetNewLocationCode(): Code[10]
    begin
        exit(NewLocationCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyLocation(var CopyLocationBuffer: Record "Copy Location Buffer"; SourceLocation: Record Location; var TargetLocation: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyLocation(SourceLocation: Record Location; var TargetLocation: Record Location; var CopyLocationBuffer: Record "Copy Location Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(Location: Record Location; var NewLocationCode: Code[10]; var IsLocationCopied: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterLocationCopied(var CopyLocationBuffer: Record "Copy Location Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyLocationOnBeforeTargetLocationInsert(SourceLocation: Record Location; var TargetLocation: Record Location; var CopyLocationBuffer: Record "Copy Location Buffer")
    begin
    end;
}
