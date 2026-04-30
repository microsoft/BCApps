// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using System.Environment.Configuration;

codeunit 99001506 "Subc. Notification Mgmt."
{
    procedure ShowCreatedProductionOrderConfirmationMessageCode(): Code[50]
    begin
        exit(UpperCase(GetShowCreatedProductionOrderCode()));
    end;

    procedure ShowCreatedSubcontractingOrderConfirmationMessageCode(): Code[50]
    begin
        exit(UpperCase(GetShowCreatedSubContPurchOrderCode()));
    end;

    procedure GetShowCreatedProductionOrderCode(): Code[50]
    begin
        exit('Show Created Production Orders');
    end;

    procedure GetShowCreatedSubContPurchOrderCode(): Code[50]
    begin
        exit('Show Created Subcontracting Orders');
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", OnInitializingNotificationWithDefaultState, '', false, false)]
    local procedure InitializeSubcontractingNotifications()
    begin
        RegisterSubcontrProductionOrderCreatedNotification();
        RegisterSubcontrPurchOrderCreatedNotification();
    end;

    local procedure RegisterSubcontrProductionOrderCreatedNotification()
    var
        MyNotifications: Record "My Notifications";
        MyNotificationsDescriptionTxt: Label 'Show a notification if Production Orders were created for Subcontracting.';
        MyNotificationsNameLbl: Label 'Show Created Production Orders';
    begin
        MyNotifications.InsertDefault(GetGuidProductionOrderCreatedNotification(), MyNotificationsNameLbl, MyNotificationsDescriptionTxt, true);
    end;

    local procedure RegisterSubcontrPurchOrderCreatedNotification()
    var
        MyNotifications: Record "My Notifications";
        MyNotificationsDescriptionTxt: Label 'Show a notification if Subcontracting Orders were created for Subcontracting.';
        MyNotificationsNameLbl: Label 'Show Created Subcontracting Orders';
    begin
        MyNotifications.InsertDefault(GetGuidSubcontractingPOCreatedNotification(), MyNotificationsNameLbl, MyNotificationsDescriptionTxt, true);
    end;

    procedure DisableNotification(var NotificationVar: Notification)
    var
        MyNotifications: Record "My Notifications";
        PageMyNotifications: Page "My Notifications";
    begin
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