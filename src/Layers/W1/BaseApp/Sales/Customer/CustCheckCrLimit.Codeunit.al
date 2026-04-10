// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using System.Environment.Configuration;

/// <summary>
/// Checks customer credit limits and overdue balances, sending notifications when thresholds are exceeded.
/// </summary>
codeunit 312 "Cust-Check Cr. Limit"
{
    Permissions = TableData "My Notifications" = rimd;

    trigger OnRun()
    begin
    end;

    var
        InstructionMgt: Codeunit "Instruction Mgt.";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        CustCheckCreditLimit: Page "Check Credit Limit";
        InstructionTypeTxt: Label 'Check Cr. Limit';
        GetDetailsTxt: Label 'Show details';
        CreditLimitNotificationMsg: Label 'The customer''s credit limit has been exceeded.';
        CreditLimitNotificationDescriptionTxt: Label 'Show warning when a sales document will exceed the customer''s credit limit.';
        OverdueBalanceNotificationMsg: Label 'This customer has an overdue balance.';
        OverdueBalanceNotificationDescriptionTxt: Label 'Show warning when a sales document is for a customer with an overdue balance.';

    /// <summary>
    /// Checks customer credit limit for a general journal line and sends notification if exceeded.
    /// </summary>
    /// <param name="GenJnlLine">Specifies the general journal line to check credit limit for.</param>
    procedure GenJnlLineCheck(GenJnlLine: Record "Gen. Journal Line")
    var
        SalesHeader: Record "Sales Header";
        AdditionalContextId: Guid;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGenJnlLineCheck(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        if not GuiAllowed then
            exit;

        if not SalesHeader.Get(GenJnlLine."Document Type", GenJnlLine."Document No.") then
            SalesHeader.Init();
        OnNewCheckRemoveCustomerNotifications(SalesHeader.RecordId, true);

        if CustCheckCreditLimit.GenJnlLineShowWarningAndGetCause(GenJnlLine, AdditionalContextId) then
            CreateAndSendNotification(SalesHeader.RecordId, AdditionalContextId, '');
    end;

    /// <summary>
    /// Checks customer credit limit for a sales header and sends notification if exceeded.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header to check credit limit for.</param>
    /// <returns>True if the credit limit is exceeded, otherwise false.</returns>
    procedure SalesHeaderCheck(var SalesHeader: Record "Sales Header") CreditLimitExceeded: Boolean
    var
        AdditionalContextId: Guid;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesHeaderCheck(SalesHeader, IsHandled, CreditLimitExceeded);
        if IsHandled then
            exit(CreditLimitExceeded);

        if GuiAllowed then begin
            OnNewCheckRemoveCustomerNotifications(SalesHeader.RecordId, true);

            OnSalesHeaderCheckOnBeforeShowWarning(CustCheckCreditLimit);
            if not CustCheckCreditLimit.SalesHeaderShowWarningAndGetCause(SalesHeader, AdditionalContextId) then
                SalesHeader.CustomerCreditLimitNotExceeded()
            else begin
                CreditLimitExceeded := true;

                if InstructionMgt.IsEnabled(GetInstructionType(Format(SalesHeader."Document Type"), SalesHeader."No.")) then
                    CreateAndSendNotification(SalesHeader.RecordId, AdditionalContextId, '');

                SalesHeader.CustomerCreditLimitExceeded(CustCheckCreditLimit.GetNotificationId());
            end;
        end;
    end;

    /// <summary>
    /// Checks customer credit limit for a sales line and sends notification if exceeded.
    /// </summary>
    /// <param name="SalesLine">Specifies the sales line to check credit limit for.</param>
    /// <returns>True if the credit limit is exceeded, otherwise false.</returns>
    procedure SalesLineCheck(SalesLine: Record "Sales Line") CreditLimitExceeded: Boolean
    var
        SalesHeader: Record "Sales Header";
        AdditionalContextId: Guid;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesLineCheck(SalesLine, IsHandled, CreditLimitExceeded);
        if IsHandled then
            exit(CreditLimitExceeded);

        if not SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then
            SalesHeader.Init();

        if GuiAllowed then
            OnNewCheckRemoveCustomerNotifications(SalesHeader.RecordId, false);

        OnSalesLineCheckOnBeforeShowWarning(CustCheckCreditLimit);
        if not CustCheckCreditLimit.SalesLineShowWarningAndGetCause(SalesLine, AdditionalContextId) then
            SalesHeader.CustomerCreditLimitNotExceeded()
        else begin
            CreditLimitExceeded := true;

            if GuiAllowed then
                if InstructionMgt.IsEnabled(GetInstructionType(Format(SalesLine."Document Type"), SalesLine."Document No.")) then
                    CreateAndSendNotification(SalesHeader.RecordId, AdditionalContextId, '');

            SalesHeader.CustomerCreditLimitExceeded(CustCheckCreditLimit.GetNotificationId());
        end;
    end;




    /// <summary>
    /// Generates an instruction type code for credit limit checking based on document type and number.
    /// </summary>
    /// <param name="DocumentType">Specifies the document type code.</param>
    /// <param name="DocumentNumber">Specifies the document number.</param>
    /// <returns>The instruction type code for the credit limit check.</returns>
    procedure GetInstructionType(DocumentType: Code[30]; DocumentNumber: Code[20]): Code[50]
    begin
        exit(CopyStr(StrSubstNo('%1 %2 %3', DocumentType, DocumentNumber, InstructionTypeTxt), 1, 50));
    end;

    /// <summary>
    /// Checks customer credit limit when converting a blanket sales order to a sales order.
    /// </summary>
    /// <param name="SalesOrderHeader">Specifies the sales order header created from the blanket order.</param>
    procedure BlanketSalesOrderToOrderCheck(SalesOrderHeader: Record "Sales Header")
    var
        AdditionalContextId: Guid;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBlanketSalesOrderToOrderCheck(SalesOrderHeader, IsHandled);
        if IsHandled then
            exit;

        if not GuiAllowed then
            exit;

        OnNewCheckRemoveCustomerNotifications(SalesOrderHeader.RecordId, true);

        OnBlanketSalesOrderToOrderCheckOnBeforeSalesHeaderShowWarning(CustCheckCreditLimit);
        if CustCheckCreditLimit.SalesHeaderShowWarningAndGetCause(SalesOrderHeader, AdditionalContextId) then
            CreateAndSendNotification(SalesOrderHeader.RecordId, AdditionalContextId, '');
    end;

    /// <summary>
    /// Displays the credit limit notification details page with information from the notification.
    /// </summary>
    /// <param name="CreditLimitNotification">Specifies the notification containing credit limit details.</param>
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
        OnBeforeCreateAndSendNotification(RecordId, AdditionalContextId, Heading, NotificationToSend, IsHandled, CustCheckCreditLimit);
        if IsHandled then
            exit;

        if AdditionalContextId = GetBothNotificationsId() then begin
            CreateAndSendNotification(RecordId, GetCreditLimitNotificationId(), CustCheckCreditLimit.GetHeading());
            CreateAndSendNotification(RecordId, GetOverdueBalanceNotificationId(), CustCheckCreditLimit.GetSecondHeading());
            exit;
        end;

        if Heading = '' then
            Heading := CustCheckCreditLimit.GetHeading();

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
        CustCheckCreditLimit.PopulateDataOnNotification(NotificationToSend);
        NotificationLifecycleMgt.SendNotificationWithAdditionalContext(NotificationToSend, RecordId, AdditionalContextId);
    end;

    /// <summary>
    /// Retrieves the unique identifier for the credit limit notification.
    /// </summary>
    /// <returns>The GUID identifier for the credit limit notification.</returns>
    procedure GetCreditLimitNotificationId(): Guid
    begin
        exit('C80FEEDA-802C-4879-B826-34A10FB77087');
    end;

    /// <summary>
    /// Retrieves the unique identifier for the overdue balance notification.
    /// </summary>
    /// <returns>The GUID identifier for the overdue balance notification.</returns>
    procedure GetOverdueBalanceNotificationId(): Guid
    begin
        exit('EC8348CB-07C1-499A-9B70-B3B081A33C99');
    end;

    /// <summary>
    /// Retrieves the unique identifier for combined credit limit and overdue balance notifications.
    /// </summary>
    /// <returns>The GUID identifier for both notifications combined.</returns>
    procedure GetBothNotificationsId(): Guid
    begin
        exit('EC8348CB-07C1-499A-9B70-B3B081A33D00');
    end;

    /// <summary>
    /// Checks if the credit limit notification is enabled for the specified customer.
    /// </summary>
    /// <param name="Customer">Specifies the customer record to check notification settings for.</param>
    /// <returns>True if the credit limit notification is enabled, otherwise false.</returns>
    procedure IsCreditLimitNotificationEnabled(Customer: Record Customer): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        exit(MyNotifications.IsEnabledForRecord(GetCreditLimitNotificationId(), Customer));
    end;

    /// <summary>
    /// Checks if the overdue balance notification is enabled for the specified customer.
    /// </summary>
    /// <param name="Customer">Specifies the customer record to check notification settings for.</param>
    /// <returns>True if the overdue balance notification is enabled, otherwise false.</returns>
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

    /// <summary>
    /// Raises an event to remove existing customer credit and overdue notifications before sending new ones.
    /// </summary>
    /// <param name="RecId">Specifies the record ID associated with the notifications to remove.</param>
    /// <param name="RecallCreditOverdueNotif">Specifies whether to recall credit and overdue notifications.</param>
    [IntegrationEvent(false, false)]
    procedure OnNewCheckRemoveCustomerNotifications(RecId: RecordID; RecallCreditOverdueNotif: Boolean)
    begin
    end;

    /// <summary>
    /// Retrieves the message text displayed for credit limit notifications.
    /// </summary>
    /// <returns>The credit limit notification message text.</returns>
    procedure GetCreditLimitNotificationMsg(): Text
    begin
        exit(CreditLimitNotificationMsg);
    end;

    /// <summary>
    /// Retrieves the message text displayed for overdue balance notifications.
    /// </summary>
    /// <returns>The overdue balance notification message text.</returns>
    procedure GetOverdueBalanceNotificationMsg(): Text
    begin
        exit(OverdueBalanceNotificationMsg);
    end;

    /// <summary>
    /// Raised before checking the credit limit for a general journal line.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line to check.</param>
    /// <param name="IsHandled">Set to true to skip the default credit limit check.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlLineCheck(GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before checking the credit limit for a sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header to check.</param>
    /// <param name="IsHandled">Set to true to skip the default credit limit check.</param>
    /// <param name="CreditLimitExceeded">Returns whether the credit limit is exceeded.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesHeaderCheck(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; var CreditLimitExceeded: Boolean);
    begin
    end;



    /// <summary>
    /// Raised before creating and sending a credit limit notification.
    /// </summary>
    /// <param name="RecordId">The record ID associated with the notification.</param>
    /// <param name="AdditionalContextId">The additional context identifier for the notification.</param>
    /// <param name="Heading">The heading text for the notification.</param>
    /// <param name="NotificationToSend">The notification object to send.</param>
    /// <param name="IsHandled">Set to true to skip the default notification creation.</param>
    /// <param name="CustCheckCreditLimit">The credit limit check page for retrieving notification data.</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateAndSendNotification(RecordId: RecordID; AdditionalContextId: Guid; Heading: Text[250]; NotificationToSend: Notification; var IsHandled: Boolean; var CustCheckCreditLimit: Page "Check Credit Limit");
    begin
    end;

    /// <summary>
    /// Raised before checking the credit limit for a sales line.
    /// </summary>
    /// <param name="SalesLine">The sales line to check.</param>
    /// <param name="IsHandled">Set to true to skip the default credit limit check.</param>
    /// <param name="CreditLimitExceeded">Returns whether the credit limit is exceeded.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineCheck(var SalesLine: Record "Sales Line"; var IsHandled: Boolean; var CreditLimitExceeded: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before showing the credit limit warning for a sales header.
    /// </summary>
    /// <param name="CustCheckCreditLimit">The credit limit check page to configure.</param>
    [IntegrationEvent(false, false)]
    local procedure OnSalesHeaderCheckOnBeforeShowWarning(var CustCheckCreditLimit: Page "Check Credit Limit")
    begin
    end;

    /// <summary>
    /// Raised before showing the credit limit warning for a sales line.
    /// </summary>
    /// <param name="CustCheckCreditLimit">The credit limit check page to configure.</param>
    [IntegrationEvent(false, false)]
    local procedure OnSalesLineCheckOnBeforeShowWarning(var CustCheckCreditLimit: Page "Check Credit Limit")
    begin
    end;

#if not CLEAN27
    [Obsolete('Moved to codeunit Serv. Check Credit Limit', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnServiceHeaderCheckOnBeforeShowWarning(var CustCheckCreditLimit: Page "Check Credit Limit")
    begin
    end;

    [Obsolete('Moved to codeunit Serv. Check Credit Limit', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnServiceLineCheckOnBeforeShowWarning(var CustCheckCreditLimit: Page "Check Credit Limit")
    begin
    end;

    [Obsolete('Moved to codeunit Serv. Check Credit Limit', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnServiceContractHeaderCheckOnBeforeShowWarning(var CustCheckCreditLimit: Page "Check Credit Limit")
    begin
    end;
#endif

    /// <summary>
    /// Raised before showing the credit limit warning when converting a blanket order to a sales order.
    /// </summary>
    /// <param name="CustCheckCreditLimit">The credit limit check page to configure.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBlanketSalesOrderToOrderCheckOnBeforeSalesHeaderShowWarning(var CustCheckCreditLimit: Page "Check Credit Limit")
    begin
    end;

    /// <summary>
    /// Raised before checking the credit limit when converting a blanket order to a sales order.
    /// </summary>
    /// <param name="SalesHeader">The sales header created from the blanket order.</param>
    /// <param name="IsHandled">Set to true to skip the default credit limit check.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeBlanketSalesOrderToOrderCheck(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

}
