// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Setup;
using System.Text;

codeunit 6512 "Item Tracking CaptionClass Mgt"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        InventorySetup: Record "Inventory Setup";
        PackageTxt: Label 'Package';
        PackageNoTxt: Label '%1 No.', Comment = '%1 = item tracking dimension name, by default - Package No.';
        NewPackageNoTxt: Label 'New %1 No.', Comment = '%1 = item tracking dimension name, by default - Package No.';
        PackageNoFilterTxt: Label '%1 No. Filter', Comment = '%1 = item tracking dimension name, by default - Package No.';
        PackageNoRequiredTxt: Label '%1 No. Required', Comment = '%1 = item tracking dimension name, by default - Package No.';
        PackageNoInfoRequiredTxt: Label '%1 No. Info. Required', Comment = '%1 = item tracking dimension name, by default - Package No.';
        PackageNoMatchTxt: Label '%1 No. Match', Comment = '%1 = item tracking dimension name, by default - Package No.';
        PackageSpecificTrackingTxt: Label '%1 Specific Tracking', Comment = '%1 = item tracking dimension name, by default - Package No.';
        PackageWarehouseTrackingTxt: Label '%1 Warehouse Tracking', Comment = '%1 = item tracking dimension name, by default - Package No.';
        PackageInfoInboundMustExistTxt: Label '%1 Info. Inbound Must Exist', Comment = '%1 = item tracking dimension name, by default - Package No.';
        PackageInfoOutboundMustExistTxt: Label '%1 Info. Outbound Must Exist', Comment = '%1 = item tracking dimension name, by default - Package No.';
        PackagePurchaseInboundTrackingTxt: Label '%1 Purchase Inbound Tracking', Comment = '%1 = item tracking dimension name, by default - Package No.';
        PackagePurchOutboundTrackingTxt: Label '%1 Purchase Outbound Tracking', Comment = '%1 = item tracking dimension name, by default - Package No.';
        PackageSalesInboundTrackingTxt: Label '%1 Sales Inbound Tracking', Comment = '%1 = item tracking dimension name, by default - Package No.';
        PackageSalesOutboundTrackingTxt: Label '%1 Sales Outbound Tracking', Comment = '%1 = item tracking dimension name, by default - Package No.';
        PackagePosInboundTrackingTxt: Label '%1 Pos. Adj. Inbound Tracking', Comment = '%1 = item tracking dimension name, by default - Package No.';
        PackagePosOutboundTrackingTxt: Label '%1 Pos. Adj. Outbound Tracking', Comment = '%1 = item tracking dimension name, by default - Package No.';
        PackageNegInboundTrackingTxt: Label '%1 Neg. Adj. Inbound Tracking', Comment = '%1 = item tracking dimension name, by default - Package No.';
        PackageNegOutboundTrackingTxt: Label '%1 Neg. Adj. Outbound Tracking', Comment = '%1 = item tracking dimension name, by default - Package No.';
        PackageTransferTrackingTxt: Label '%1 Transfer Tracking', Comment = '%1 = item tracking dimension name, by default - Package No.';
        PackageManufInboundTrackingTxt: Label '%1 Manuf. Inbound Tracking', Comment = '%1 = item tracking dimension name, by default - Package No.';
        PackageManufOutboundTrackingTxt: Label '%1 Manuf. Outbound Tracking', Comment = '%1 = item tracking dimension name, by default - Package No.';
        PackageAssemblyInboundTrackingTxt: Label '%1 Assembly Inbound Tracking', Comment = '%1 = item tracking dimension name, by default - Package No.';
        PackageAssemblyOutboundTrackingTxt: Label '%1 Assembly Outbound Tracking', Comment = '%1 = item tracking dimension name, by default - Package No.';
        PackageAvailabilityTxt: Label 'Availability, %1 No.', Comment = '%1 = item tracking dimension name, by default - Package No.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Caption Class", 'OnResolveCaptionClass', '', true, true)]
    local procedure ResolveCaptionClass(CaptionArea: Text; CaptionExpr: Text; Language: Integer; var Caption: Text; var Resolved: Boolean)
    begin
        if CaptionArea = '6' then
            Caption := ItemTrackingCaptionClassTranslate(CaptionExpr, Resolved);
    end;

    local procedure ItemTrackingCaptionClassTranslate(CaptionExpr: Text; var IsResolved: Boolean): Text
    var
        ResolvedExpr: Text;
    begin
        // Caption Type = 1 - Package No.
        // Caption Type = 2 - New Package No.
        // Caption Type = 3 - Package No. Filter
        // Caption Type = 4 - Package No. Required
        // Caption Type = 5 - Package No. Info. Required
        // Caption Type = 6 - Package No. Match

        if InventorySetup.Get() then;

        IsResolved := true;
        case CaptionExpr of
            '1':
                exit(ResolveCaption(PackageNoTxt));
            '2':
                exit(ResolveCaption(NewPackageNoTxt));
            '3':
                exit(ResolveCaption(PackageNoFilterTxt));
            '4':
                exit(ResolveCaption(PackageNoRequiredTxt));
            '5':
                exit(ResolveCaption(PackageNoInfoRequiredTxt));
            '6':
                exit(ResolveCaption(PackageNoMatchTxt));
            '70':
                exit(ResolveCaption(PackageSpecificTrackingTxt));
            '71':
                exit(ResolveCaption(PackageWarehouseTrackingTxt));
            '73':
                exit(ResolveCaption(PackageInfoInboundMustExistTxt));
            '74':
                exit(ResolveCaption(PackageInfoOutboundMustExistTxt));
            '75':
                exit(ResolveCaption(PackagePurchaseInboundTrackingTxt));
            '76':
                exit(ResolveCaption(PackagePurchOutboundTrackingTxt));
            '77':
                exit(ResolveCaption(PackageSalesInboundTrackingTxt));
            '78':
                exit(ResolveCaption(PackageSalesOutboundTrackingTxt));
            '79':
                exit(ResolveCaption(PackagePosInboundTrackingTxt));
            '80':
                exit(ResolveCaption(PackagePosOutboundTrackingTxt));
            '81':
                exit(ResolveCaption(PackageNegInboundTrackingTxt));
            '82':
                exit(ResolveCaption(PackageNegOutboundTrackingTxt));
            '83':
                exit(ResolveCaption(PackageTransferTrackingTxt));
            '84':
                exit(ResolveCaption(PackageManufInboundTrackingTxt));
            '85':
                exit(ResolveCaption(PackageManufOutboundTrackingTxt));
            '86':
                exit(ResolveCaption(PackageAssemblyInboundTrackingTxt));
            '87':
                exit(ResolveCaption(PackageAssemblyOutboundTrackingTxt));
            '88':
                exit(ResolveCaption(PackageAvailabilityTxt));
            else begin
                IsResolved := false;
                OnItemTrackingCaptionClassTranslate(CaptionExpr, ResolvedExpr, IsResolved);
                if IsResolved then
                    exit(ResolvedExpr);
            end;
        end;
        IsResolved := false;
        exit(PackageNoTxt);
    end;

    local procedure ResolveCaption(CaptionString: Text) Result: Text
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeResolveCaption(InventorySetup, CaptionString, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if InventorySetup."Package Caption" <> '' then
            exit(StrSubstNo(CaptionString, InventorySetup."Package Caption"));
        exit(StrSubstNo(CaptionString, PackageTxt));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemTrackingCaptionClassTranslate(CaptionExpr: Text; var ResolvedExpr: Text; var IsResolved: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResolveCaption(var InventorySetup: Record "Inventory Setup"; CaptionString: Text; var Result: Text; var IsHandled: Boolean)
    begin
    end;
}
