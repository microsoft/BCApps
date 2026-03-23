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
        if IsLimitReached(TotalCreditsConsumed, MonthlyCreditLimit) then begin
            Error(GlobalCreditLimitExceededErr, MonthlyCreditLimit, TotalCreditsConsumed);
        end;
    end;

    procedure IsLimitReached(): Boolean
    var
        TotalCreditsConsumed, MonthlyCreditLimit : Decimal;
    begin
        exit(IsLimitReached(TotalCreditsConsumed, MonthlyCreditLimit));
    end;

    procedure HandleLimitReached(var AITTestSuite: Record "AIT Test Suite")
    var
        AITTestMethodLine: Record "AIT Test Method Line";
        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
    begin
        AITTestSuiteMgt.SetRunStatus(AITTestSuite, AITTestSuite.Status::CreditLimitReached);

        AITTestMethodLine.SetRange("Test Suite Code", AITTestSuite.Code);
        AITTestMethodLine.SetRange(Status, AITTestMethodLine.Status::Running);
        AITTestMethodLine.ModifyAll(Status, AITTestMethodLine.Status::Skipped, true);

        AITTestMethodLine.SetRange(Status, AITTestMethodLine.Status::Starting);
        AITTestMethodLine.ModifyAll(Status, AITTestMethodLine.Status::Skipped, true);

        AITTestMethodLine.SetRange(Status, AITTestMethodLine.Status::" ");
        AITTestMethodLine.ModifyAll(Status, AITTestMethodLine.Status::Skipped, true);
    end;

    procedure ShowNotifications()
    begin
        if not IsEnforcementEnabled() then
            ShowNotficitationsWhenEnforcementDiabled()
        else
            ShowNotificationsWhenEnforcementEnabled();
    end;

    procedure OpenSetupPage()
    begin
        Page.Run(Page::"AIT Eval Monthly Copilot Cred.");
    end;

    local procedure IsLimitReached(var CopilotCreditConsumed: Decimal; var MonthlyCreditLimit: Decimal): Boolean
    var
        AITCreditLimitSetup: Record "AIT Credit Limit Setup";
        AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
    begin
        AITCreditLimitSetup.GetOrCreate();

        if not AITCreditLimitSetup."Enforcement Enabled" then
            exit(false);

        if AITCreditLimitSetup."Monthly Credit Limit" <= 0 then
            exit(false);

        MonthlyCreditLimit := AITCreditLimitSetup."Monthly Credit Limit";
        CopilotCreditConsumed := AgentTestContextImpl.GetTotalCreditsConsumedThisMonth(AITCreditLimitSetup.GetPeriodStartDate());
        exit(CopilotCreditConsumed >= AITCreditLimitSetup."Monthly Credit Limit");
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
        AITCreditLimitSetup: Record "AIT Credit Limit Setup";
    begin
        AITCreditLimitSetup.GetOrCreate();
        exit(AITCreditLimitSetup."Enforcement Enabled");
    end;

    local procedure ShowNotficitationsWhenEnforcementDiabled()
    var
        EnforcementDisabledNotification, GlobalWarningNotification, GlobalLimitNotification : Notification;
        EnforcementDisabledMsg: Label 'Copilot credit limit enforcement is disabled. Eval execution costs are not bounded. Enable enforcement on the Credit Limits page to set a spending cap.';
    begin
        EnforcementDisabledNotification.Id := GetEnforcementDisabledNotificationId();
        EnforcementDisabledNotification.Message := EnforcementDisabledMsg;
        EnforcementDisabledNotification.Scope := NotificationScope::LocalScope;
        EnforcementDisabledNotification.AddAction(ViewCopilotCreditLimitsLbl, Codeunit::"AIT Eval Monthly Copilot Cred.", GetOpenSetupPageMethodName());
        EnforcementDisabledNotification.Send();

        // Recall limit/warning notifications since enforcement is off
        GlobalLimitNotification.Id := GetCreditLimitNotificationId();
        GlobalLimitNotification.Recall();

        GlobalWarningNotification.Id := GetCreditWarningNotificationId();
        GlobalWarningNotification.Recall();
    end;

    local procedure ShowNotificationsWhenEnforcementEnabled()
    var
        EnforcementDisabledNotification, CreditWarningNotification, CreditLimitNotification : Notification;
        CreditLimitReachedMsg: Label 'The monthly Copilot credit limit has been reached. New agent tests cannot be started until the limit is increased or the next month begins.';
        CreditWarningMsg: Label 'Warning: %1% of the monthly Copilot credits have been consumed. Consider monitoring usage to avoid reaching the limit.', Comment = '%1 - Usage percentage';
        TotalCreditsConsumed, MonthlyCreditLimit, UsagePercentage : Decimal;
    begin
        EnforcementDisabledNotification.Id := GetEnforcementDisabledNotificationId();
        CreditWarningNotification.Id := GetCreditWarningNotificationId();
        CreditLimitNotification.Id := GetCreditLimitNotificationId();

        // Recall the disabled notification
        EnforcementDisabledNotification.Id := GetEnforcementDisabledNotificationId();
        EnforcementDisabledNotification.Recall();

        if IsLimitReached(TotalCreditsConsumed, MonthlyCreditLimit) then begin
            // Show credit limit notification when limit is reached
            CreditLimitNotification.Message := CreditLimitReachedMsg;
            CreditLimitNotification.Scope := NotificationScope::LocalScope;
            CreditLimitNotification.AddAction(ViewCopilotCreditLimitsLbl, Codeunit::"AIT Eval Monthly Copilot Cred.", GetOpenSetupPageMethodName());
            CreditLimitNotification.Send();

            // Recall warning notification if limit is exceeded
            CreditWarningNotification.Recall();
            exit;
        end;

        // Recall credit limit notification since limit is not reached
        CreditLimitNotification.Recall();

        UsagePercentage := GetCreditUsagePercentage(TotalCreditsConsumed, MonthlyCreditLimit);
        if IsApproachingCreditLimit(UsagePercentage) then begin
            // Show warning notification when approaching credit limit
            CreditWarningNotification.Message := StrSubstNo(CreditWarningMsg, UsagePercentage);
            CreditWarningNotification.Scope := NotificationScope::LocalScope;
            CreditWarningNotification.AddAction(ViewCopilotCreditLimitsLbl, Codeunit::"AIT Eval Monthly Copilot Cred.", GetOpenSetupPageMethodName());
            CreditWarningNotification.Send();
            exit;
        end;

        // Recall warning notification if not approaching limit
        CreditWarningNotification.Recall();
    end;

    local procedure GetCreditLimitNotificationId(): Guid
    begin
        exit('fbb7ec95-3427-400f-9fad-34d6009858c9');
    end;

    local procedure GetCreditWarningNotificationId(): Guid
    begin
        exit('f365e625-24bb-491b-bd85-83d66d5557ae');
    end;

    local procedure GetEnforcementDisabledNotificationId(): Guid
    begin
        exit('b2acb24d-dbc8-4bda-99c9-8bed0d470fd8');
    end;

    local procedure GetOpenSetupPageMethodName(): Text
    begin
        exit('OpenSetupPage');
    end;

    local procedure OpenSetupPage(Notification: Notification)
    begin
        OpenSetupPage()
    end;

    var
        ViewCopilotCreditLimitsLbl: Label 'View credit limits';
        GlobalCreditLimitExceededErr: Label 'Cannot start the agent eval suite. The monthly credit limit for evals of %1 has been reached. Current consumption: %2.', Comment = '%1 = Credit limit, %2 = Credits consumed';
}
