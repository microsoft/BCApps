// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using System.Environment.Configuration;

codeunit 99001506 "Subc. Notification Mgmt."
{
    var
        ProdOrdNotificationDescriptionTxt: Label 'Show a notification if Production Orders were created for Subcontracting.';
        ProdOrdNotificationNameLbl: Label 'Show Created Production Orders';
        SubcOrdNotificationDescriptionTxt: Label 'Show a notification if Subcontracting Orders were created for Subcontracting.';
        SubcOrdNotificationNameLbl: Label 'Show Created Subcontracting Orders';
#if not CLEAN29
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#endif

    procedure ShowCreatedProductionOrderConfirmationMessageCode(): Code[50]
    begin
#if not CLEAN29
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
            exit('');
#endif
        exit(UpperCase(GetShowCreatedProductionOrderCode()));
    end;

    procedure ShowCreatedSubcontractingOrderConfirmationMessageCode(): Code[50]
    begin
#if not CLEAN29
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
            exit('');
#endif
        exit(UpperCase(GetShowCreatedSubContPurchOrderCode()));
    end;

    procedure GetShowCreatedProductionOrderCode(): Code[50]
    begin
#if not CLEAN29
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
            exit('');
#endif
        exit('Show Created Production Orders');
    end;

    procedure GetShowCreatedSubContPurchOrderCode(): Code[50]
    begin
#if not CLEAN29
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
            exit('');
#endif
        exit('Show Created Subcontracting Orders');
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", OnInitializingNotificationWithDefaultState, '', false, false)]
    local procedure InitializeSubcontractingNotifications()
    begin
#if not CLEAN29
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
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
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
            exit;
#endif
        PageMyNotifications.InitializeNotificationsWithDefaultState();
        MyNotifications.Disable(NotificationVar.Id());
    end;

    procedure GetGuidProductionOrderCreatedNotification(): Guid
    begin
#if not CLEAN29
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
            exit;
#endif
        exit('{5d564aca-ce60-4345-ba68-e1e50976a346}');
    end;

    procedure GetGuidSubcontractingPOCreatedNotification(): Guid
    begin
#if not CLEAN29
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
            exit;
#endif
        exit('{f7b10c9e-071a-4455-a048-d17b29ef764c}');
    end;
}