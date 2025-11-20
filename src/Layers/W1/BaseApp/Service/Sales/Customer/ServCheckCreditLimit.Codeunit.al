// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using System.Environment.Configuration;

codeunit 6489 "Serv. Check Credit Limit"
{
    Permissions = TableData "My Notifications" = rimd;

    trigger OnRun()
    begin
    end;

    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ServCheckCreditLimit: Page "Serv. Check Credit Limit";
        InstructionTypeTxt: Label 'Check Cr. Limit';
        GetDetailsTxt: Label 'Show details';
        CreditLimitNotificationMsg: Label 'The customer''s credit limit has been exceeded.';
        CreditLimitNotificationDescriptionTxt: Label 'Show warning when a sales document will exceed the customer''s credit limit.';
        OverdueBalanceNotificationMsg: Label 'This customer has an overdue balance.';
        OverdueBalanceNotificationDescriptionTxt: Label 'Show warning when a sales document is for a customer with an overdue balance.';

    procedure ServiceHeaderCheck(ServiceHeader: Record "Service Header")
    var
        AdditionalContextId: Guid;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceHeaderCheck(ServiceHeader, IsHandled);
        if IsHandled then
            exit;

        if not GuiAllowed then
            exit;

        OnNewCheckRemoveCustomerNotifications(ServiceHeader.RecordId, true);

        OnServiceHeaderCheckOnBeforeShowWarning(ServCheckCreditLimit);
        if ServCheckCreditLimit.ServiceHeaderShowWarningAndGetCause(ServiceHeader, AdditionalContextId) then
            CreateAndSendNotification(ServiceHeader.RecordId, AdditionalContextId, '');
    end;

    procedure ServiceLineCheck(ServiceLine: Record "Service Line")
    var
        ServiceHeader: Record "Service Header";
        AdditionalContextId: Guid;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceLineCheck(ServiceLine, IsHandled);
        if IsHandled then
            exit;

        if not GuiAllowed then
            exit;

        if not ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.") then
            ServiceHeader.Init();
        OnNewCheckRemoveCustomerNotifications(ServiceHeader.RecordId, false);

        OnServiceLineCheckOnBeforeShowWarning(ServCheckCreditLimit);
        if ServCheckCreditLimit.ServiceLineShowWarningAndGetCause(ServiceLine, AdditionalContextId) then
            CreateAndSendNotification(ServiceHeader.RecordId, AdditionalContextId, '');
    end;

    procedure ServiceContractHeaderCheck(ServiceContractHeader: Record "Service Contract Header")
    var
        AdditionalContextId: Guid;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceContractHeaderCheck(ServiceContractHeader, IsHandled);
        if IsHandled then
            exit;

        if not GuiAllowed then
            exit;

        OnNewCheckRemoveCustomerNotifications(ServiceContractHeader.RecordId, true);

        OnServiceContractHeaderCheckOnBeforeShowWarning(ServCheckCreditLimit);
        if ServCheckCreditLimit.ServiceContractHeaderShowWarningAndGetCause(ServiceContractHeader, AdditionalContextId) then
            CreateAndSendNotification(ServiceContractHeader.RecordId, AdditionalContextId, '');
    end;

    procedure GetInstructionType(DocumentType: Code[30]; DocumentNumber: Code[20]): Code[50]
    begin
        exit(CopyStr(StrSubstNo('%1 %2 %3', DocumentType, DocumentNumber, InstructionTypeTxt), 1, 50));
    end;

    procedure ShowNotificationDetails(CreditLimitNotification: Notification)
    var
        CreditLimitNotificationPage: Page "Credit Limit Notification";
    begin
        CreditLimitNotificationPage.SetHeading(CreditLimitNotification.Message);
        CreditLimitNotificationPage.InitializeFromNotificationVar(CreditLimitNotification);
        CreditLimitNotificationPage.RunModal();
    end;

    local procedure CreateAndSendNotification(RecordId: RecordID; AdditionalContextId: Guid; Heading: Text[250])
    var
        NotificationToSend: Notification;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateAndSendNotification(RecordId, AdditionalContextId, Heading, NotificationToSend, IsHandled, ServCheckCreditLimit);
        if IsHandled then
            exit;

        if AdditionalContextId = GetBothNotificationsId() then begin
            CreateAndSendNotification(RecordId, GetCreditLimitNotificationId(), ServCheckCreditLimit.GetHeading());
            CreateAndSendNotification(RecordId, GetOverdueBalanceNotificationId(), ServCheckCreditLimit.GetSecondHeading());
            exit;
        end;

        if Heading = '' then
            Heading := ServCheckCreditLimit.GetHeading();

        case Heading of
            CreditLimitNotificationMsg:
                NotificationToSend.Id(GetCreditLimitNotificationId());
            OverdueBalanceNotificationMsg:
                NotificationToSend.Id(GetOverdueBalanceNotificationId());
            else
                NotificationToSend.Id(CreateGuid());
        end;

        NotificationToSend.Message(Heading);
        NotificationToSend.Scope(NOTIFICATIONSCOPE::LocalScope);
        NotificationToSend.AddAction(GetDetailsTxt, CODEUNIT::"Cust-Check Cr. Limit", 'ShowNotificationDetails');
        ServCheckCreditLimit.PopulateDataOnNotification(NotificationToSend);
        NotificationLifecycleMgt.SendNotificationWithAdditionalContext(NotificationToSend, RecordId, AdditionalContextId);
    end;

    procedure GetCreditLimitNotificationId(): Guid
    begin
        exit('C80FEEDA-802C-4879-B826-34A10FB77087');
    end;

    procedure GetOverdueBalanceNotificationId(): Guid
    begin
        exit('EC8348CB-07C1-499A-9B70-B3B081A33C99');
    end;

    procedure GetBothNotificationsId(): Guid
    begin
        exit('EC8348CB-07C1-499A-9B70-B3B081A33D00');
    end;

    procedure IsCreditLimitNotificationEnabled(Customer: Record Customer): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        exit(MyNotifications.IsEnabledForRecord(GetCreditLimitNotificationId(), Customer));
    end;

    procedure IsOverdueBalanceNotificationEnabled(Customer: Record Customer): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        exit(MyNotifications.IsEnabledForRecord(GetOverdueBalanceNotificationId(), Customer));
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure OnInitializingNotificationWithDefaultState()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefaultWithTableNum(GetCreditLimitNotificationId(),
          CreditLimitNotificationMsg,
          CreditLimitNotificationDescriptionTxt,
          DATABASE::Customer);
        MyNotifications.InsertDefaultWithTableNum(GetOverdueBalanceNotificationId(),
          OverdueBalanceNotificationMsg,
          OverdueBalanceNotificationDescriptionTxt,
          DATABASE::Customer);
    end;

    [IntegrationEvent(false, false)]
    procedure OnNewCheckRemoveCustomerNotifications(RecId: RecordID; RecallCreditOverdueNotif: Boolean)
    begin
    end;

    procedure GetCreditLimitNotificationMsg(): Text
    begin
        exit(CreditLimitNotificationMsg);
    end;

    procedure GetOverdueBalanceNotificationMsg(): Text
    begin
        exit(OverdueBalanceNotificationMsg);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceHeaderCheck(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceLineCheck(var ServiceLine: Record "Service Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateAndSendNotification(RecordId: RecordID; AdditionalContextId: Guid; Heading: Text[250]; NotificationToSend: Notification; var IsHandled: Boolean; var ServCheckCreditLimit: Page "Serv. Check Credit Limit");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServiceHeaderCheckOnBeforeShowWarning(var ServCheckCreditLimit: Page "Serv. Check Credit Limit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServiceLineCheckOnBeforeShowWarning(var ServCheckCreditLimit: Page "Serv. Check Credit Limit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServiceContractHeaderCheckOnBeforeShowWarning(var ServCheckCreditLimit: Page "Serv. Check Credit Limit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceContractHeaderCheck(ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"Check Credit Limit", 'OnAfterCalcTotalOutstandingAmt', '', false, false)]
    local procedure OnAfterCalcTotalOutstandingAmt(var Customer: Record Customer; var Result: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        Customer.CalcFields("Outstanding Serv.Invoices(LCY)", "Outstanding Serv. Orders (LCY)");
        Result += Customer."Outstanding Serv.Invoices(LCY)" + Customer."Outstanding Serv. Orders (LCY)" - ServiceLine.OutstandingInvoiceAmountFromShipment(Customer."No.");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Check Credit Limit", 'OnCalcCreditLimitLCYOnAfterCalcAmounts', '', false, false)]
    local procedure OnCalcCreditLimitLCYOnAfterCalcAmounts(var Customer: Record Customer; var ShippedRetRcdNotIndLCY: Decimal; var CustCreditAmountLCY: Decimal)
    begin
        Customer.CalcFields("Serv Shipped Not Invoiced(LCY)");
        ShippedRetRcdNotIndLCY += Customer."Serv Shipped Not Invoiced(LCY)";
        CustCreditAmountLCY += Customer."Serv Shipped Not Invoiced(LCY)";
    end;
}

