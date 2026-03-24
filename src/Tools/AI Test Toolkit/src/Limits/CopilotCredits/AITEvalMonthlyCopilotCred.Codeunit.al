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
        TotalCreditsConsumed, MonthlyCreditLimit : Decimal;
    begin
        if IsLimitReached(TotalCreditsConsumed, MonthlyCreditLimit) then
            Error(GlobalCreditLimitExceededErr, MonthlyCreditLimit, TotalCreditsConsumed);
    end;

    procedure IsLimitReached(): Boolean
    var
        TotalCreditsConsumed, MonthlyCreditLimit : Decimal;
    begin
        exit(IsLimitReached(TotalCreditsConsumed, MonthlyCreditLimit));
    end;

    procedure ShowNotifications()
    begin
        if not IsEnforcementEnabled() then
            ShowNotificationsWhenEnforcementDiabled()
        else
            ShowNotificationsWhenEnforcementEnabled();
    end;

    procedure OpenConfigurationPage()
    begin
        Page.Run(Page::"AIT Eval Monthly Copilot Cred.");
    end;

    local procedure IsLimitReached(var CopilotCreditConsumed: Decimal; var MonthlyCreditLimit: Decimal): Boolean
    var
        AITEvalMonthlyCopilotCreditsLimit: Record "AIT Eval Monthly Copilot Cred.";
        AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
    begin
        AITEvalMonthlyCopilotCreditsLimit.GetOrCreate();

        if not AITEvalMonthlyCopilotCreditsLimit."Enforcement Enabled" then
            exit(false);

        if AITEvalMonthlyCopilotCreditsLimit."Monthly Credit Limit" <= 0 then
            exit(false);

        MonthlyCreditLimit := AITEvalMonthlyCopilotCreditsLimit."Monthly Credit Limit";
        CopilotCreditConsumed := AgentTestContextImpl.GetCopilotCreditsForPeriod(AITEvalMonthlyCopilotCreditsLimit.GetPeriodStartDate());
        exit(CopilotCreditConsumed >= AITEvalMonthlyCopilotCreditsLimit."Monthly Credit Limit");
    end;

    local procedure GetCreditUsagePercentage(TotalCreditsConsumed: Decimal; MonthlyCreditLimit: Decimal): Decimal
    begin
        exit(Round(TotalCreditsConsumed / MonthlyCreditLimit * 100, 0.1));
    end;

    local procedure IsApproachingCreditLimit(CreditUsagePercentage: Decimal): Boolean
    begin
        exit(CreditUsagePercentage >= 80);
    end;

    local procedure IsEnforcementEnabled(): Boolean
    var
        AITEvalMonthlyCopilotCreditsLimit: Record "AIT Eval Monthly Copilot Cred.";
    begin
        AITEvalMonthlyCopilotCreditsLimit.GetOrCreate();
        exit(AITEvalMonthlyCopilotCreditsLimit."Enforcement Enabled");
    end;

    local procedure ShowNotificationsWhenEnforcementDiabled()
    begin
        RecallAllNotifications();

        SendEnforcementDisabledNotification();
    end;

    local procedure ShowNotificationsWhenEnforcementEnabled()
    var
        TotalCreditsConsumed, MonthlyCreditLimit, UsagePercentage : Decimal;
    begin
        RecallAllNotifications();

        if IsLimitReached(TotalCreditsConsumed, MonthlyCreditLimit) then begin
            SendCreditLimitNotification();
            exit;
        end;

        UsagePercentage := GetCreditUsagePercentage(TotalCreditsConsumed, MonthlyCreditLimit);
        if IsApproachingCreditLimit(UsagePercentage) then begin
            SendCreditWarningNotification(UsagePercentage);
            exit;
        end;
    end;

    local procedure RecallAllNotifications()
    begin
        RecallCreditLimitNotification();
        RecallCreditWarningNotification();
        RecallEnforcementDisabledNotification();
    end;

    local procedure SendCreditLimitNotification()
    var
        CreditLimitNotification: Notification;
        CreditLimitReachedMsg: Label 'The monthly Copilot credit limit for AI evaluations has been reached. New agent evaluations cannot be started until the limit is increased or the next month begins.';
    begin
        CreditLimitNotification.Id := GetCreditLimitNotificationId();
        CreditLimitNotification.Message := CreditLimitReachedMsg;
        CreditLimitNotification.Scope := NotificationScope::LocalScope;
        CreditLimitNotification.AddAction(ViewCopilotCreditLimitsLbl, Codeunit::"AIT Eval Monthly Copilot Cred.", 'OpenConfigurationPage');
        CreditLimitNotification.Send();
    end;

    local procedure RecallCreditLimitNotification()
    var
        CreditLimitNotification: Notification;
    begin
        CreditLimitNotification.Id := GetCreditLimitNotificationId();
        if CreditLimitNotification.Recall() then;
    end;

    local procedure GetCreditLimitNotificationId(): Guid
    begin
        exit('fbb7ec95-3427-400f-9fad-34d6009858c9');
    end;

    local procedure SendCreditWarningNotification(UsagePercentage: Decimal)
    var
        CreditWarningNotification: Notification;
        CreditWarningMsg: Label 'Warning: %1% of the monthly Copilot credits for AI evaluations have been consumed. Consider monitoring agent evaluations to avoid reaching the limit.', Comment = '%1 - Usage percentage';
    begin
        CreditWarningNotification.Id := GetCreditWarningNotificationId();
        CreditWarningNotification.Message := StrSubstNo(CreditWarningMsg, UsagePercentage);
        CreditWarningNotification.Scope := NotificationScope::LocalScope;
        CreditWarningNotification.AddAction(ViewCopilotCreditLimitsLbl, Codeunit::"AIT Eval Monthly Copilot Cred.", 'OpenConfigurationPage');
        CreditWarningNotification.Send();
    end;

    local procedure RecallCreditWarningNotification()
    var
        CreditWarningNotification: Notification;
    begin
        CreditWarningNotification.Id := GetCreditWarningNotificationId();
        if CreditWarningNotification.Recall() then;
    end;

    local procedure GetCreditWarningNotificationId(): Guid
    begin
        exit('f365e625-24bb-491b-bd85-83d66d5557ae');
    end;

    local procedure SendEnforcementDisabledNotification()
    var
        EnforcementDisabledNotification: Notification;
        EnforcementDisabledMsg: Label 'Copilot credit limits for AI evaluation are disabled. Enable enforcement on the Credit Limits page to set a spending cap.';
    begin
        EnforcementDisabledNotification.Id := GetEnforcementDisabledNotificationId();
        EnforcementDisabledNotification.Message := EnforcementDisabledMsg;
        EnforcementDisabledNotification.Scope := NotificationScope::LocalScope;
        EnforcementDisabledNotification.AddAction(ViewCopilotCreditLimitsLbl, Codeunit::"AIT Eval Monthly Copilot Cred.", 'OpenConfigurationPage');
        EnforcementDisabledNotification.Send();
    end;

    local procedure RecallEnforcementDisabledNotification()
    var
        EnforcementDisabledNotification: Notification;
    begin
        EnforcementDisabledNotification.Id := GetEnforcementDisabledNotificationId();
        if EnforcementDisabledNotification.Recall() then;
    end;

    local procedure GetEnforcementDisabledNotificationId(): Guid
    begin
        exit('b2acb24d-dbc8-4bda-99c9-8bed0d470fd8');
    end;

    procedure OpenConfigurationPage(Notification: Notification)
    begin
        OpenConfigurationPage()
    end;

    var
        ViewCopilotCreditLimitsLbl: Label 'View credit limits';
        GlobalCreditLimitExceededErr: Label 'Cannot start the agent eval suite. The monthly credit limit for evals of %1 has been reached. Current consumption: %2.', Comment = '%1 = Credit limit, %2 = Credits consumed';
}
