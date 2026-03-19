// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

codeunit 149039 "AIT Eval Monthly Copilot Cred." implements "AIT Eval Limit Provider"
{
    Access = Internal;

    procedure CheckBeforeRun(AITTestSuite: Record "AIT Test Suite"): Boolean
    var
        AITCreditLimitSetup: Record "AIT Credit Limit Setup";
        AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
        TotalCreditsConsumed: Decimal;
    begin
        if IsLimitReached() then begin
            Error(GlobalCreditLimitExceededErr, AITCreditLimitSetup."Monthly Credit Limit", TotalCreditsConsumed);
            exit(false);
        end;

        exit(true);
    end;

    procedure IsLimitReached(): Boolean
    var
        AITCreditLimitSetup: Record "AIT Credit Limit Setup";
        AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
        TotalCreditsConsumed: Decimal;
    begin
        AITCreditLimitSetup.GetOrCreate();

        if not AITCreditLimitSetup."Enforcement Enabled" then
            exit(false);

        if AITCreditLimitSetup."Monthly Credit Limit" <= 0 then
            exit(false);

        TotalCreditsConsumed := AgentTestContextImpl.GetTotalCreditsConsumedThisMonth(AITCreditLimitSetup.GetPeriodStartDate());
        exit(TotalCreditsConsumed >= AITCreditLimitSetup."Monthly Credit Limit");
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

        AITTestMethodLine.SetRange("Test Suite Code", AITTestSuite.Code);
        AITTestMethodLine.SetRange(Status, AITTestMethodLine.Status::Starting);
        AITTestMethodLine.ModifyAll(Status, AITTestMethodLine.Status::Skipped, true);

        AITTestMethodLine.SetRange(Status, AITTestMethodLine.Status::" ");
        AITTestMethodLine.ModifyAll(Status, AITTestMethodLine.Status::Skipped, true);
    end;

    procedure ShowNotifications()
    var
        GlobalLimitNotification: Notification;
        GlobalWarningNotification: Notification;
        EnforcementDisabledNotification: Notification;
        UsagePercentage: Decimal;
        GlobalCreditLimitReachedMsg: Label 'The monthly Copilot credit limit has been reached. New agent tests cannot be started until the limit is increased or the next month begins.';
        GlobalCreditWarningMsg: Label 'Warning: %1% of the monthly Copilot credits have been consumed. Consider monitoring usage to avoid reaching the limit.', Comment = '%1 - Usage percentage';
        EnforcementDisabledMsg: Label 'Copilot credit limit enforcement is disabled. Eval execution costs are not bounded. Enable enforcement on the Credit Limits page to set a spending cap.';
        ViewCopilotCreditLimitsLbl: Label 'View credit limits';
    begin
        // Show notification when enforcement is disabled
        if not IsEnforcementEnabled() then begin
            EnforcementDisabledNotification.Id := GetEnforcementDisabledNotificationId();
            EnforcementDisabledNotification.Message := EnforcementDisabledMsg;
            EnforcementDisabledNotification.Scope := NotificationScope::LocalScope;
            EnforcementDisabledNotification.AddAction(ViewCopilotCreditLimitsLbl, Codeunit::"AIT Eval Monthly Copilot Cred.", 'OpenSetupPage');
            EnforcementDisabledNotification.Send();

            // Recall limit/warning notifications since enforcement is off
            GlobalLimitNotification.Id := GetGlobalCreditLimitNotificationId();
            GlobalLimitNotification.Recall();

            GlobalWarningNotification.Id := GetGlobalCreditWarningNotificationId();
            GlobalWarningNotification.Recall();
            exit;
        end;

        // Enforcement is enabled — recall the disabled notification
        EnforcementDisabledNotification.Id := GetEnforcementDisabledNotificationId();
        EnforcementDisabledNotification.Recall();

        // Check and show global credit limit notification
        if IsLimitReached() then begin
            GlobalLimitNotification.Id := GetGlobalCreditLimitNotificationId();
            GlobalLimitNotification.Message := GlobalCreditLimitReachedMsg;
            GlobalLimitNotification.Scope := NotificationScope::LocalScope;
            GlobalLimitNotification.AddAction(ViewCopilotCreditLimitsLbl, Codeunit::"AIT Eval Monthly Copilot Cred.", 'OpenSetupPage');
            GlobalLimitNotification.Send();

            // Recall warning if limit is exceeded
            GlobalWarningNotification.Id := GetGlobalCreditWarningNotificationId();
            GlobalWarningNotification.Recall();
        end else begin
            GlobalLimitNotification.Id := GetGlobalCreditLimitNotificationId();
            GlobalLimitNotification.Recall();

            // Check for 80% warning
            // TODO(qutreson) computing it twice, not ideal.
            if IsApproachingCreditLimit() then begin
                UsagePercentage := GetCreditUsagePercentage();
                GlobalWarningNotification.Id := GetGlobalCreditWarningNotificationId();
                GlobalWarningNotification.Message := StrSubstNo(GlobalCreditWarningMsg, UsagePercentage);
                GlobalWarningNotification.Scope := NotificationScope::LocalScope;
                GlobalWarningNotification.AddAction(ViewCopilotCreditLimitsLbl, Codeunit::"AIT Eval Monthly Copilot Cred.", 'OpenSetupPage');
                GlobalWarningNotification.Send();
            end else begin
                GlobalWarningNotification.Id := GetGlobalCreditWarningNotificationId();
                GlobalWarningNotification.Recall();
            end;
        end;
    end;

    procedure OpenSetupPage()
    begin
        Page.Run(Page::"AIT Eval Monthly Copilot Cred.");
    end;

    local procedure OpenSetupPage(Notification: Notification)
    begin
        OpenSetupPage()
    end;

    local procedure GetCreditUsagePercentage(): Decimal
    var
        AITCreditLimitSetup: Record "AIT Credit Limit Setup";
        AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
        TotalCreditsConsumed: Decimal;
    begin
        AITCreditLimitSetup.GetOrCreate();

        if not AITCreditLimitSetup."Enforcement Enabled" then
            exit(0);

        if AITCreditLimitSetup."Monthly Credit Limit" <= 0 then
            exit(0);

        TotalCreditsConsumed := AgentTestContextImpl.GetTotalCreditsConsumedThisMonth(AITCreditLimitSetup.GetPeriodStartDate());
        exit(Round(TotalCreditsConsumed / AITCreditLimitSetup."Monthly Credit Limit" * 100, 0.1));
    end;

    local procedure IsApproachingCreditLimit(): Boolean
    begin
        exit(GetCreditUsagePercentage() >= 80);
    end;

    local procedure IsEnforcementEnabled(): Boolean
    var
        AITCreditLimitSetup: Record "AIT Credit Limit Setup";
    begin
        AITCreditLimitSetup.GetOrCreate();
        exit(AITCreditLimitSetup."Enforcement Enabled");
    end;

    local procedure GetGlobalCreditLimitNotificationId(): Guid
    begin
        exit('fbb7ec95-3427-400f-9fad-34d6009858c9');
    end;

    local procedure GetGlobalCreditWarningNotificationId(): Guid
    begin
        exit('f365e625-24bb-491b-bd85-83d66d5557ae');
    end;

    local procedure GetEnforcementDisabledNotificationId(): Guid
    begin
        exit('b2acb24d-dbc8-4bda-99c9-8bed0d470fd8');
    end;

    var
        GlobalCreditLimitExceededErr: Label 'Cannot start the agent eval suite. The monthly credit limit for evals of %1 has been reached. Current consumption: %2.', Comment = '%1 = Credit limit, %2 = Credits consumed';
}
