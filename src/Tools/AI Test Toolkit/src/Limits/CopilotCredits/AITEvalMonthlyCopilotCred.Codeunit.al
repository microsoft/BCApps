// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

codeunit 149039 "AIT Eval Monthly Copilot Cred." implements "AIT Eval Limit Provider"
{
    Access = Internal;

    procedure CheckBeforeRun(AITTestSuite: Record "AIT Test Suite")
    var
        EnvironmentConsumed, CompanyConsumed : Decimal;
        EnvironmentLimit, CompanyLimit : Decimal;
    begin
        if IsEnvironmentLimitReached(EnvironmentConsumed, EnvironmentLimit) then
            Error(EnvironmentCreditLimitExceededErr, EnvironmentLimit, EnvironmentConsumed);

        if IsCompanyLimitReached(CompanyConsumed, CompanyLimit) then
            Error(CompanyCreditLimitExceededErr, CompanyLimit, CompanyConsumed, CompanyName());
    end;

    procedure IsLimitReached(): Boolean
    var
        Consumed, Limit : Decimal;
    begin
        exit(IsEnvironmentLimitReached(Consumed, Limit) or IsCompanyLimitReached(Consumed, Limit));
    end;

    procedure ShowNotifications()
    var
        EnvRecord: Record "AIT Eval Monthly Copilot Cred.";
        CompanyRecord: Record "AIT Eval Monthly Copilot Cred.";
        EnvironmentEnabled, CompanyEnabled : Boolean;
    begin
        EnvRecord.GetOrCreateEnvironmentLimits();
        EnvironmentEnabled := EnvRecord."Enforcement Enabled";

        CompanyRecord.GetOrCreateCompanyLimits();
        CompanyEnabled := CompanyRecord."Enforcement Enabled";

        RecallAllNotifications();

        // Only show "disabled" notification when both are off
        if (not EnvironmentEnabled) and (not CompanyEnabled) then begin
            SendEnforcementDisabledNotification();
            exit;
        end;

        if EnvironmentEnabled then
            ShowEnvironmentNotifications();

        if CompanyEnabled then
            ShowCompanyNotifications();
    end;

    procedure OpenConfigurationPage()
    begin
        Page.Run(Page::"AIT Eval Monthly Copilot Cred.");
    end;

    procedure IsEnvironmentLimitReached(var CopilotCreditConsumed: Decimal; var MonthlyCreditLimit: Decimal): Boolean
    var
        EnvironmentLimitRecord: Record "AIT Eval Monthly Copilot Cred.";
        AgentTestConsumption: Codeunit "Agent Test Consumption";
    begin
        EnvironmentLimitRecord.GetOrCreateEnvironmentLimits();
        MonthlyCreditLimit := EnvironmentLimitRecord."Monthly Credit Limit";

        if not EnvironmentLimitRecord."Enforcement Enabled" then
            exit(false);

        if EnvironmentLimitRecord."Monthly Credit Limit" < 0 then
            exit(false);

        CopilotCreditConsumed := AgentTestConsumption.GetCopilotCreditsForEnvironment(EnvironmentLimitRecord.GetPeriodStartDate());
        exit(CopilotCreditConsumed >= EnvironmentLimitRecord."Monthly Credit Limit");
    end;

    procedure IsCompanyLimitReached(var CopilotCreditConsumed: Decimal; var CompanyCreditLimit: Decimal): Boolean
    var
        CompanyLimitRecord: Record "AIT Eval Monthly Copilot Cred.";
        AgentTestConsumption: Codeunit "Agent Test Consumption";
    begin
        CompanyLimitRecord.GetOrCreateCompanyLimits();
        CompanyCreditLimit := CompanyLimitRecord."Monthly Credit Limit";

        if not CompanyLimitRecord."Enforcement Enabled" then
            exit(false);

        if CompanyLimitRecord."Monthly Credit Limit" < 0 then
            exit(false);

        CopilotCreditConsumed := AgentTestConsumption.GetCopilotCreditsForCurrentCompany(CompanyLimitRecord.GetPeriodStartDate());
        exit(CopilotCreditConsumed >= CompanyLimitRecord."Monthly Credit Limit");
    end;

    procedure GetCreditUsagePercentage(TotalCreditsConsumed: Decimal; MonthlyCreditLimit: Decimal): Decimal
    begin
        if MonthlyCreditLimit <= 0 then
            exit(0);
        exit(Round(TotalCreditsConsumed / MonthlyCreditLimit * 100, 0.1));
    end;

    procedure IsApproachingCreditLimit(CreditUsagePercentage: Decimal): Boolean
    begin
        exit(CreditUsagePercentage >= 80);
    end;

    local procedure ShowEnvironmentNotifications()
    var
        EnvironmentConsumed, EnvironmentLimit, UsagePercentage : Decimal;
    begin
        if IsEnvironmentLimitReached(EnvironmentConsumed, EnvironmentLimit) then begin
            SendEnvironmentCreditLimitNotification();
            exit;
        end;

        if EnvironmentLimit > 0 then begin
            UsagePercentage := GetCreditUsagePercentage(EnvironmentConsumed, EnvironmentLimit);
            if IsApproachingCreditLimit(UsagePercentage) then
                SendEnvironmentCreditWarningNotification(UsagePercentage);
        end;
    end;

    local procedure ShowCompanyNotifications()
    var
        CompanyConsumed, CompanyLimit, UsagePercentage : Decimal;
    begin
        if IsCompanyLimitReached(CompanyConsumed, CompanyLimit) then begin
            SendCompanyCreditLimitNotification();
            exit;
        end;

        if CompanyLimit > 0 then begin
            UsagePercentage := GetCreditUsagePercentage(CompanyConsumed, CompanyLimit);
            if IsApproachingCreditLimit(UsagePercentage) then
                SendCompanyCreditWarningNotification(UsagePercentage);
        end;
    end;

    local procedure RecallAllNotifications()
    begin
        RecallNotification(GetEnvironmentCreditLimitNotificationId());
        RecallNotification(GetEnvironmentCreditWarningNotificationId());

        RecallNotification(GetCompanyCreditLimitNotificationId());
        RecallNotification(GetCompanyCreditWarningNotificationId());

        RecallNotification(GetEnforcementDisabledNotificationId());
    end;

    local procedure RecallNotification(NotificationId: Guid)
    var
        TargetNotification: Notification;
    begin
        TargetNotification.Id := NotificationId;
        if TargetNotification.Recall() then;
    end;

    local procedure SendEnvironmentCreditLimitNotification()
    var
        CreditLimitNotification: Notification;
        EnvCreditLimitReachedMsg: Label 'The environment monthly Copilot credit limit for AI evaluations has been reached. New agent evaluations cannot be started until the limit is increased or the next month begins.';
    begin
        CreditLimitNotification.Id := GetEnvironmentCreditLimitNotificationId();
        CreditLimitNotification.Message := EnvCreditLimitReachedMsg;
        CreditLimitNotification.Scope := NotificationScope::LocalScope;
        CreditLimitNotification.AddAction(ViewCopilotCreditLimitsLbl, Codeunit::"AIT Eval Monthly Copilot Cred.", 'OpenConfigurationPage');
        CreditLimitNotification.Send();
    end;

    local procedure GetEnvironmentCreditLimitNotificationId(): Guid
    begin
        exit('fbb7ec95-3427-400f-9fad-34d6009858c9');
    end;

    local procedure SendEnvironmentCreditWarningNotification(UsagePercentage: Decimal)
    var
        CreditWarningNotification: Notification;
        EnvCreditWarningMsg: Label 'Warning: %1% of the environment monthly Copilot credits for AI evaluations have been consumed. Consider monitoring agent evaluations to avoid reaching the limit.', Comment = '%1 - Usage percentage';
    begin
        CreditWarningNotification.Id := GetEnvironmentCreditWarningNotificationId();
        CreditWarningNotification.Message := StrSubstNo(EnvCreditWarningMsg, UsagePercentage);
        CreditWarningNotification.Scope := NotificationScope::LocalScope;
        CreditWarningNotification.AddAction(ViewCopilotCreditLimitsLbl, Codeunit::"AIT Eval Monthly Copilot Cred.", 'OpenConfigurationPage');
        CreditWarningNotification.Send();
    end;

    local procedure GetEnvironmentCreditWarningNotificationId(): Guid
    begin
        exit('f365e625-24bb-491b-bd85-83d66d5557ae');
    end;

    local procedure SendCompanyCreditLimitNotification()
    var
        CreditLimitNotification: Notification;
        CompanyCreditLimitReachedMsg: Label 'The company monthly Copilot credit limit for AI evaluations has been reached for company %1. New agent evaluations cannot be started in this company until the limit is increased or the next month begins.', Comment = '%1 - Company name';
    begin
        CreditLimitNotification.Id := GetCompanyCreditLimitNotificationId();
        CreditLimitNotification.Message := StrSubstNo(CompanyCreditLimitReachedMsg, CompanyName());
        CreditLimitNotification.Scope := NotificationScope::LocalScope;
        CreditLimitNotification.AddAction(ViewCopilotCreditLimitsLbl, Codeunit::"AIT Eval Monthly Copilot Cred.", 'OpenConfigurationPage');
        CreditLimitNotification.Send();
    end;

    local procedure GetCompanyCreditLimitNotificationId(): Guid
    begin
        exit('ea7ef8aa-1a0d-4dcf-a421-6a1dc844b27d');
    end;

    local procedure SendCompanyCreditWarningNotification(UsagePercentage: Decimal)
    var
        CreditWarningNotification: Notification;
        CompanyCreditWarningMsg: Label 'Warning: %1% of the company monthly Copilot credits for AI evaluations have been consumed in company %2. Consider monitoring agent evaluations to avoid reaching the limit.', Comment = '%1 - Usage percentage, %2 - Company name';
    begin
        CreditWarningNotification.Id := GetCompanyCreditWarningNotificationId();
        CreditWarningNotification.Message := StrSubstNo(CompanyCreditWarningMsg, UsagePercentage, CompanyName());
        CreditWarningNotification.Scope := NotificationScope::LocalScope;
        CreditWarningNotification.AddAction(ViewCopilotCreditLimitsLbl, Codeunit::"AIT Eval Monthly Copilot Cred.", 'OpenConfigurationPage');
        CreditWarningNotification.Send();
    end;

    local procedure GetCompanyCreditWarningNotificationId(): Guid
    begin
        exit('2b664d54-a1f3-4b44-bebd-dc471ef2b146');
    end;

    local procedure SendEnforcementDisabledNotification()
    var
        EnforcementDisabledNotification: Notification;
        EnforcementDisabledMsg: Label 'Copilot credit limits for AI evaluation are disabled. Enable enforcement on the Credit Limits page to set a spending cap when running AI evaluations.';
        DontShowAgainLbl: Label 'Don''t show again';
    begin
        if (IsolatedStorage.Contains(GetEnforcementDisabledNotificationStorageKey())) then
            exit;

        EnforcementDisabledNotification.Id := GetEnforcementDisabledNotificationId();
        EnforcementDisabledNotification.Message := EnforcementDisabledMsg;
        EnforcementDisabledNotification.Scope := NotificationScope::LocalScope;
        EnforcementDisabledNotification.AddAction(ViewCopilotCreditLimitsLbl, Codeunit::"AIT Eval Monthly Copilot Cred.", 'OpenConfigurationPage');
        EnforcementDisabledNotification.AddAction(DontShowAgainLbl, Codeunit::"AIT Eval Monthly Copilot Cred.", 'DoNotShowAgainEnforcementDisabledNotification');
        EnforcementDisabledNotification.Send();
    end;

    procedure DoNotShowAgainEnforcementDisabledNotification(Notification: Notification)
    begin
        IsolatedStorage.Set(GetEnforcementDisabledNotificationStorageKey(), 'true');
    end;

    local procedure GetEnforcementDisabledNotificationStorageKey(): Text
    begin
        exit(CompanyName() + '-' + Format(UserSecurityId()) + '-' + GetEnforcementDisabledNotificationId());
    end;

    local procedure GetEnforcementDisabledNotificationId(): Guid
    begin
        exit('34846289-c097-4189-ac82-afc661588782');
    end;

    procedure OpenConfigurationPage(Notification: Notification)
    begin
        OpenConfigurationPage()
    end;

    [EventSubscriber(ObjectType::Table, Database::"AIT Eval Monthly Copilot Cred.", OnBeforeInsertEvent, '', false, false)]
    local procedure OnBeforeInsertMonthlyCopilotCreditLimits(var Rec: Record "AIT Eval Monthly Copilot Cred.")
    begin
        Rec.VerifyWriteOperationAllowed();
    end;

    [EventSubscriber(ObjectType::Table, Database::"AIT Eval Monthly Copilot Cred.", OnAfterInsertEvent, '', false, false)]
    local procedure OnAfterInsertMonthlyCopilotCreditLimits(var Rec: Record "AIT Eval Monthly Copilot Cred.")
    begin
        Rec.LogInsertedAuditMessage();
    end;

    [EventSubscriber(ObjectType::Table, Database::"AIT Eval Monthly Copilot Cred.", OnBeforeModifyEvent, '', false, false)]
    local procedure OnBeforeModifyMonthlyCopilotCreditLimits(var Rec: Record "AIT Eval Monthly Copilot Cred.")
    begin
        Rec.VerifyWriteOperationAllowed();
    end;

    [EventSubscriber(ObjectType::Table, Database::"AIT Eval Monthly Copilot Cred.", OnAfterModifyEvent, '', false, false)]
    local procedure OnAfterModifyMonthlyCopilotCreditLimits(var Rec: Record "AIT Eval Monthly Copilot Cred.")
    begin
        Rec.LogModifiedAuditMessage();
    end;

    [EventSubscriber(ObjectType::Table, Database::"AIT Eval Monthly Copilot Cred.", OnBeforeDeleteEvent, '', false, false)]
    local procedure OnBeforeDeleteMonthlyCopilotCreditLimits(var Rec: Record "AIT Eval Monthly Copilot Cred.")
    begin
        Rec.VerifyWriteOperationAllowed();
    end;

    [EventSubscriber(ObjectType::Table, Database::"AIT Eval Monthly Copilot Cred.", OnAfterDeleteEvent, '', false, false)]
    local procedure OnAfterDeleteMonthlyCopilotCreditLimits(var Rec: Record "AIT Eval Monthly Copilot Cred.")
    begin
        Rec.LogDeletedAuditMessage();
    end;

    var
        ViewCopilotCreditLimitsLbl: Label 'View credit limits';
        EnvironmentCreditLimitExceededErr: Label 'Cannot start the agent eval suite. The environment monthly credit limit of %1 has been reached. Current environment consumption: %2.', Comment = '%1 = Credit limit, %2 = Credits consumed';
        CompanyCreditLimitExceededErr: Label 'Cannot start the agent eval suite. The company monthly credit limit of %1 has been reached for company %3. Current company consumption: %2.', Comment = '%1 = Credit limit, %2 = Credits consumed, %3 = Company name';
}
