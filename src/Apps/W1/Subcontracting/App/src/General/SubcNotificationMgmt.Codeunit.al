// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Purchases.Vendor;
using System.Environment.Configuration;

codeunit 20506 "Subc. Notification Mgmt."
{
    var
#if not CLEAN29
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
#endif
        ProdOrdNotificationDescriptionTxt: Label 'Show a notification if Production Orders were created for Subcontracting.';
        ProdOrdNotificationNameLbl: Label 'Show Created Production Orders';
        SubcOrdNotificationDescriptionTxt: Label 'Show a notification if Subcontracting Orders were created for Subcontracting.';
        SubcOrdNotificationNameLbl: Label 'Show Created Subcontracting Orders';
        MissingSubcontractingLocationMsg: Label 'Vendor %1 has no subcontracting location. This location is used to track components and work-in-process (WIP) items at the subcontractor. Choose a Subcontracting Location Code on the vendor before using this work center for subcontracting.', Comment = '%1 = Vendor No.';
        OpenVendorCardLbl: Label 'Open Vendor Card';
        VendorNoTok: Label 'VendorNo', Locked = true;

    internal procedure ShowMissingSubcontractingLocationNotification(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
        MissingSubcontractingLocationNotification: Notification;
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        MissingSubcontractingLocationNotification.Id := GetMissingSubcontractingLocationNotificationId();
        if MissingSubcontractingLocationNotification.Recall() then;

        if VendorNo = '' then
            exit;

        Vendor.SetLoadFields("Subc. Location Code");
        if not Vendor.Get(VendorNo) then
            exit;
        if Vendor."Subc. Location Code" <> '' then
            exit;

        MissingSubcontractingLocationNotification.Message := StrSubstNo(MissingSubcontractingLocationMsg, VendorNo);
        MissingSubcontractingLocationNotification.Scope := NotificationScope::LocalScope;
        MissingSubcontractingLocationNotification.SetData(VendorNoTok, VendorNo);
        MissingSubcontractingLocationNotification.AddAction(OpenVendorCardLbl, Codeunit::"Subc. Notification Mgmt.", 'OpenVendorCard');
        MissingSubcontractingLocationNotification.Send();
    end;

    internal procedure OpenVendorCard(MissingSubcontractingLocationNotification: Notification)
    var
        Vendor: Record Vendor;
        VendorNo: Code[20];
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if not Evaluate(VendorNo, MissingSubcontractingLocationNotification.GetData(VendorNoTok)) then
            exit;
        if Vendor.Get(VendorNo) then
            Page.Run(Page::"Vendor Card", Vendor);
    end;

    local procedure GetMissingSubcontractingLocationNotificationId(): Guid
    begin
        exit('{8A4B9A58-21EC-49DD-A3A5-C7E81F745B6D}');
    end;

    procedure ShowCreatedProductionOrderConfirmationMessageCode(): Code[50]
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit('');
#endif
        exit(UpperCase(GetShowCreatedProductionOrderCode()));
    end;

    procedure ShowCreatedSubcontractingOrderConfirmationMessageCode(): Code[50]
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit('');
#endif
        exit(UpperCase(GetShowCreatedSubContPurchOrderCode()));
    end;

    procedure GetShowCreatedProductionOrderCode(): Code[50]
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit('');
#endif
        exit('Show Created Production Orders');
    end;

    procedure GetShowCreatedSubContPurchOrderCode(): Code[50]
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit('');
#endif
        exit('Show Created Subcontracting Orders');
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", OnInitializingNotificationWithDefaultState, '', false, false)]
    local procedure InitializeSubcontractingNotifications()
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        RegisterSubcontrProductionOrderCreatedNotification();
        RegisterSubcontrPurchOrderCreatedNotification();
    end;

    local procedure RegisterSubcontrProductionOrderCreatedNotification()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(GetGuidProductionOrderCreatedNotification(), ProdOrdNotificationNameLbl, ProdOrdNotificationDescriptionTxt, true);
    end;

    local procedure RegisterSubcontrPurchOrderCreatedNotification()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(GetGuidSubcontractingPOCreatedNotification(), SubcOrdNotificationNameLbl, SubcOrdNotificationDescriptionTxt, true);
    end;

    procedure DisableNotification(var NotificationVar: Notification)
    var
        MyNotifications: Record "My Notifications";
        PageMyNotifications: Page "My Notifications";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        PageMyNotifications.InitializeNotificationsWithDefaultState();
        MyNotifications.Disable(NotificationVar.Id());
    end;

    procedure GetGuidProductionOrderCreatedNotification(): Guid
    begin
        exit('{5d564aca-ce60-4345-ba68-e1e50976a346}');
    end;

    procedure GetGuidSubcontractingPOCreatedNotification(): Guid
    begin
        exit('{f7b10c9e-071a-4455-a048-d17b29ef764c}');
    end;
}
