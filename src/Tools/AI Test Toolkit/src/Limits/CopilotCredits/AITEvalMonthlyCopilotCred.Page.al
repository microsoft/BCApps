// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Agents;

page 149048 "AIT Eval Monthly Copilot Cred."
{
    Caption = 'AI Eval Monthly Copilot Credit Limits';
    PageType = Worksheet;
    ApplicationArea = All;
    SourceTable = "AIT Eval Suite Usage Buffer";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            label(EnforcementExplanation)
            {
                Caption = 'Credit limits control whether new AI evaluations can be started. Once the limit is reached, no new evaluations can begin, but evaluations already in progress are allowed to complete.';
                Style = Subordinate;
            }
            grid(LimitSetup)
            {
                ShowCaption = false;
                GridLayout = Columns;

                group(EnvironmentLimitSetup)
                {
                    Caption = 'Environment Limit';
                    Enabled = CurrentUserIsAgentAdminForAllCompanies;

                    field(EnvironmentLimitEnabled; EnvironmentEnforcementEnabled)
                    {
                        Caption = 'Enabled';
                        ToolTip = 'Specifies whether the environment-level credit limit enforcement is enabled. When disabled, there is no environment-wide spending cap.';
                        Enabled = CurrentUserIsAgentAdminForAllCompanies;

                        trigger OnValidate()
                        begin
                            SaveEnvironmentCreditLimitSetup();
                            CurrPage.Update(false);
                        end;
                    }
                    field(EnvironmentMonthlyCreditLimit; EnvironmentMonthlyCreditLimit)
                    {
                        AutoFormatType = 0;
                        Caption = 'Monthly Copilot Credit Limit';
                        ToolTip = 'Specifies the maximum number of Copilot credits that can be consumed by all agent test suites across all companies in this environment during the current month.';
                        DecimalPlaces = 2 : 5;
                        Editable = EnvironmentEnforcementEnabled and CurrentUserIsAgentAdminForAllCompanies;

                        trigger OnValidate()
                        begin
                            SaveEnvironmentCreditLimitSetup();
                            UpdateComputedFields();
                        end;
                    }
                }
                group(CompanyLimitSetup)
                {
                    Caption = 'Company Limit';
                    Enabled = CurrentUserIsAgentAdminForCurrentCompany;

                    field(CompanyLimitEnabled; CompanyEnforcementEnabled)
                    {
                        Caption = 'Enabled';
                        ToolTip = 'Specifies whether the company-level credit limit enforcement is enabled. When disabled, there is no per-company spending cap.';
                        Enabled = CurrentUserIsAgentAdminForCurrentCompany;

                        trigger OnValidate()
                        begin
                            SaveCompanyCreditLimit();
                            CurrPage.Update(false);
                        end;
                    }
                    field(CompanyMonthlyCreditLimitField; CompanyMonthlyCreditLimit)
                    {
                        AutoFormatType = 0;
                        Caption = 'Monthly Copilot Credit Limit';
                        ToolTip = 'Specifies the maximum number of Copilot credits that can be consumed by agent test suites in the current company during the current month.';
                        DecimalPlaces = 2 : 5;
                        Editable = CompanyEnforcementEnabled and CurrentUserIsAgentAdminForCurrentCompany;

                        trigger OnValidate()
                        begin
                            SaveCompanyCreditLimit();
                            UpdateComputedFields();
                        end;
                    }
                }
            }
            repeater(AgentSuites)
            {
                Caption = 'Agent test suites in this company';

                field("Code"; Rec."Suite Code")
                {
                    Editable = false;

                    trigger OnDrillDown()
                    var
                        AITTestSuite: Record "AIT Test Suite";
                    begin
                        if AITTestSuite.Get(Rec."Suite Code") then
                            Page.Run(Page::"AIT Test Suite", AITTestSuite);
                    end;
                }
                field(Description; Rec."Suite Description")
                {
                    Editable = false;
                }
                field(SuiteEnvCreditsConsumed; Rec."Environment Consumed")
                {
                    AutoFormatType = 0;
                    Caption = 'Copilot Credits Consumed (Environment)';
                    ToolTip = 'Specifies the number of Copilot credits consumed by this test suite across all companies in the environment during the current month.';
                    Editable = false;
                    DecimalPlaces = 2 : 5;
                }
                field(SuiteCompanyCreditsConsumed; Rec."Company Consumed")
                {
                    AutoFormatType = 0;
                    Caption = 'Copilot Credits Consumed (Company)';
                    ToolTip = 'Specifies the number of Copilot credits consumed by this test suite in the current company during the current month.';
                    Editable = false;
                    DecimalPlaces = 2 : 5;
                }
            }
            grid(UsageSummary)
            {
                ShowCaption = false;
                GridLayout = Columns;

                group(EnvironmentUsageSummary)
                {
                    Caption = 'Environment Usage';

                    field(EnvCreditsConsumed; EnvironmentCopilotCreditsConsumed)
                    {
                        AutoFormatType = 0;
                        Caption = 'Copilot Credits Consumed';
                        ToolTip = 'Specifies the total number of Copilot credits consumed by all agent test suites across all companies in this environment during the current month.';
                        Editable = false;
                        DecimalPlaces = 2 : 5;
                    }
                    field(EnvDeletedSuiteCredits; EnvironmentDeletedSuiteCreditsConsumed)
                    {
                        AutoFormatType = 0;
                        Caption = 'Copilot Credits from Deleted Suites';
                        ToolTip = 'Specifies Copilot credits consumed this month by suites that have since been deleted. These credits are included in the environment total but are not shown in the list above.';
                        Editable = false;
                        DecimalPlaces = 2 : 5;
                        Visible = EnvironmentDeletedSuiteCreditsConsumed > 0;
                    }
                    field(EnvCreditsAvailable; EnvironmentCopilotCreditsAvailable)
                    {
                        AutoFormatType = 0;
                        Caption = 'Copilot Credits Available';
                        ToolTip = 'Specifies the number of Copilot credits remaining for the environment during the current month.';
                        Editable = false;
                        DecimalPlaces = 2 : 5;
                        StyleExpr = EnvironmentCreditsAvailableStyle;
                    }
                    field(EnvCreditsUsagePercentage; EnvironmentCreditsUsagePercentage)
                    {
                        Caption = 'Copilot Credits Usage %';
                        ToolTip = 'Specifies the percentage of the environment monthly Copilot credit limit that has been consumed.';
                        Editable = false;
                        StyleExpr = EnvironmentCreditsAvailableStyle;
                    }
                }
                group(CompanyUsageSummary)
                {
                    Caption = 'Company Usage';

                    field(CompanyCreditsConsumed; CompanyCopilotCreditsConsumed)
                    {
                        AutoFormatType = 0;
                        Caption = 'Copilot Credits Consumed';
                        ToolTip = 'Specifies the total number of Copilot credits consumed by agent test suites in the current company during the current month.';
                        Editable = false;
                        DecimalPlaces = 2 : 5;
                    }
                    field(CompanyDeletedSuiteCredits; CompanyDeletedSuiteCreditsConsumed)
                    {
                        AutoFormatType = 0;
                        Caption = 'Copilot Credits from Deleted Suites';
                        ToolTip = 'Specifies Copilot credits consumed this month by suites that have since been deleted. These credits are included in the environment total but are not shown in the list above.';
                        Editable = false;
                        DecimalPlaces = 2 : 5;
                        Visible = CompanyDeletedSuiteCreditsConsumed > 0;
                    }
                    field(CompanyCreditsAvailable; CompanyCopilotCreditsAvailable)
                    {
                        AutoFormatType = 0;
                        Caption = 'Copilot Credits Available';
                        ToolTip = 'Specifies the number of Copilot credits remaining for the current company during the current month.';
                        Editable = false;
                        DecimalPlaces = 2 : 5;
                        StyleExpr = CompanyCreditsAvailableStyle;
                    }
                    field(CompanyCreditsUsagePercentage; CompanyCreditsUsagePercentage)
                    {
                        Caption = 'Copilot Credits Usage %';
                        ToolTip = 'Specifies the percentage of the company monthly Copilot credit limit that has been consumed.';
                        Editable = false;
                        StyleExpr = CompanyCreditsAvailableStyle;
                    }
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Refresh)
            {
                Caption = 'Refresh';
                ToolTip = 'Refreshes the credit consumption data.';
                Image = Refresh;

                trigger OnAction()
                begin
                    RefreshPage();
                end;
            }
        }
        area(Promoted)
        {
            actionref(Refresh_Promoted; Refresh)
            {
            }
        }
    }

    var
        EnvironmentLimitRecord: Record "AIT Eval Monthly Copilot Cred.";
        CompanyLimitRecord: Record "AIT Eval Monthly Copilot Cred.";
        AITEvalMonthlyCopilotCreditLimit: Codeunit "AIT Eval Monthly Copilot Cred.";
        EnvironmentMonthlyCreditLimit, CompanyMonthlyCreditLimit : Decimal;
        EnvironmentCopilotCreditsConsumed, CompanyCopilotCreditsConsumed : Decimal;
        EnvironmentCopilotCreditsAvailable, CompanyCopilotCreditsAvailable : Decimal;
        EnvironmentDeletedSuiteCreditsConsumed, CompanyDeletedSuiteCreditsConsumed : Decimal;
        EnvironmentLoadedDataCopilotCreditsConsumed, CompanyLoadedDataCopilotCreditsConsumed : Decimal;
        EnvironmentEnforcementEnabled, CompanyEnforcementEnabled : Boolean;
        CurrentUserIsAgentAdminForAllCompanies, CurrentUserIsAgentAdminForCurrentCompany : Boolean;
        EnvironmentCreditsUsagePercentage, CompanyCreditsUsagePercentage : Text;
        EnvironmentCreditsAvailableStyle, CompanyCreditsAvailableStyle : Text;
        PageCaptionSourceLbl: Label 'AI Eval Monthly Copilot Credit Limits - %1 - %2', Comment = '%1 = Period Start, %2 = Period End';
        NegativeCreditLimitErr: Label 'Monthly credit limit cannot be negative.';

    trigger OnOpenPage()
    begin
        RefreshPage();
    end;

    local procedure RefreshPage()
    begin
        LoadCurrentUserIsAgentAdmin();
        LoadCreditLimitSetup();
        LoadBufferData();
        UpdatePageCaption();
        UpdateComputedFields();
        CurrPage.Update(false);
    end;

    local procedure UpdatePageCaption()
    begin
        CurrPage.Caption := StrSubstNo(PageCaptionSourceLbl, Format(EnvironmentLimitRecord.GetPeriodStartDate()), Format(EnvironmentLimitRecord.GetPeriodEndDate()));
    end;

    local procedure LoadCurrentUserIsAgentAdmin()
    var
        AgentSystemPermissions: Codeunit "Agent System Permissions";
    begin
        CurrentUserIsAgentAdminForCurrentCompany := AgentSystemPermissions.CurrentUserHasCanManageAllAgentsPermission();
        CurrentUserIsAgentAdminForAllCompanies := AgentSystemPermissions.CurrentUserHasCanManageAllAgentsInAllCompaniesPermission();
    end;

    local procedure LoadCreditLimitSetup()
    begin
        EnvironmentLimitRecord.GetOrCreateEnvironmentLimits();
        EnvironmentMonthlyCreditLimit := EnvironmentLimitRecord."Monthly Credit Limit";
        EnvironmentEnforcementEnabled := EnvironmentLimitRecord."Enforcement Enabled";

        CompanyLimitRecord.GetOrCreateCompanyLimits();
        CompanyMonthlyCreditLimit := CompanyLimitRecord."Monthly Credit Limit";
        CompanyEnforcementEnabled := CompanyLimitRecord."Enforcement Enabled";
    end;

    local procedure SaveEnvironmentCreditLimitSetup()
    begin
        ValidateMonthlyCreditLimit(EnvironmentMonthlyCreditLimit);

        EnvironmentLimitRecord.GetOrCreateEnvironmentLimits();
        EnvironmentLimitRecord."Monthly Credit Limit" := EnvironmentMonthlyCreditLimit;
        EnvironmentLimitRecord."Enforcement Enabled" := EnvironmentEnforcementEnabled;
        EnvironmentLimitRecord.Modify();
    end;

    local procedure SaveCompanyCreditLimit()
    begin
        ValidateMonthlyCreditLimit(CompanyMonthlyCreditLimit);

        CompanyLimitRecord.GetOrCreateCompanyLimits();
        CompanyLimitRecord."Monthly Credit Limit" := CompanyMonthlyCreditLimit;
        CompanyLimitRecord."Enforcement Enabled" := CompanyEnforcementEnabled;
        CompanyLimitRecord.Modify();
    end;

    local procedure ValidateMonthlyCreditLimit(NewLimit: Decimal)
    begin
        if NewLimit < 0 then
            Error(NegativeCreditLimitErr);
    end;

    local procedure LoadBufferData()
    var
        AITTestSuite: Record "AIT Test Suite";
        TempAIEvalSuiteUsageBuffer: Record "AIT Eval Suite Usage Buffer";
        AgentTestConsumption: Codeunit "Agent Test Consumption";
        PeriodStartDate: Date;
        SortOrder: Integer;
        EnvironmentConsumed: Decimal;
        CompanyConsumed: Decimal;
    begin
        Rec.Reset();
        Rec.DeleteAll();
        EnvironmentLoadedDataCopilotCreditsConsumed := 0;
        CompanyLoadedDataCopilotCreditsConsumed := 0;
        PeriodStartDate := EnvironmentLimitRecord.GetPeriodStartDate();

        // Load all agent test suites and their credit consumption for the current period into the buffer.
        AITTestSuite.SetRange("Test Type", AITTestSuite."Test Type"::Agent);
        if AITTestSuite.FindSet() then
            repeat
                EnvironmentConsumed := AgentTestConsumption.GetSuiteCreditsForEnvironment(AITTestSuite.Code, PeriodStartDate);
                CompanyConsumed := AgentTestConsumption.GetSuiteCreditsForCurrentCompany(AITTestSuite.Code, PeriodStartDate);

                if (EnvironmentConsumed <> 0) or (CompanyConsumed <> 0) then begin
                    SortOrder += 1;
                    TempAIEvalSuiteUsageBuffer.Index := SortOrder;
                    TempAIEvalSuiteUsageBuffer."Suite Code" := AITTestSuite.Code;
                    TempAIEvalSuiteUsageBuffer."Suite Description" := AITTestSuite.Description;
                    TempAIEvalSuiteUsageBuffer."Environment Consumed" := EnvironmentConsumed;
                    TempAIEvalSuiteUsageBuffer."Company Consumed" := CompanyConsumed;
                    TempAIEvalSuiteUsageBuffer.Insert();

                    EnvironmentLoadedDataCopilotCreditsConsumed += EnvironmentConsumed;
                    CompanyLoadedDataCopilotCreditsConsumed += CompanyConsumed;
                end;
            until AITTestSuite.Next() = 0;

        // Sort the buffer by consumed credits in descending order.
        SortOrder := 0;
        TempAIEvalSuiteUsageBuffer.SetCurrentKey("Environment Consumed");
#pragma warning disable AA0233, AA0181
        if TempAIEvalSuiteUsageBuffer.FindLast() then
            repeat
                SortOrder += 1;
                Rec := TempAIEvalSuiteUsageBuffer;
                Rec.Index := SortOrder;
                Rec.Insert();
            until TempAIEvalSuiteUsageBuffer.Next(-1) = 0;
#pragma warning restore AA0233, AA0181

        if Rec.FindFirst() then;
    end;

    local procedure UpdateComputedFields()
    var
        EnvUsagePercent, CompanyUsagePercent : Decimal;
        EnvLimitReached, CompanyLimitReached : Boolean;
    begin
        // Environment usage (across all companies)
        EnvLimitReached := AITEvalMonthlyCopilotCreditLimit.IsEnvironmentLimitReached(EnvironmentCopilotCreditsConsumed, EnvironmentMonthlyCreditLimit);

        EnvironmentDeletedSuiteCreditsConsumed := EnvironmentCopilotCreditsConsumed - EnvironmentLoadedDataCopilotCreditsConsumed;
        if EnvironmentDeletedSuiteCreditsConsumed < 0 then
            EnvironmentDeletedSuiteCreditsConsumed := 0;

        if EnvironmentMonthlyCreditLimit > 0 then begin
            EnvironmentCopilotCreditsAvailable := EnvironmentMonthlyCreditLimit - EnvironmentCopilotCreditsConsumed;
            EnvUsagePercent := AITEvalMonthlyCopilotCreditLimit.GetCreditUsagePercentage(EnvironmentCopilotCreditsConsumed, EnvironmentMonthlyCreditLimit);
            EnvironmentCreditsUsagePercentage := Format(EnvUsagePercent, 0, '<Precision,1:1><Standard Format,0>') + '%';
        end else begin
            EnvironmentCopilotCreditsAvailable := 0;
            EnvironmentCreditsUsagePercentage := '';
        end;

        if EnvironmentCopilotCreditsAvailable < 0 then
            EnvironmentCopilotCreditsAvailable := 0;

        if EnvLimitReached then
            EnvironmentCreditsAvailableStyle := Format(PageStyle::Unfavorable)
        else
            if AITEvalMonthlyCopilotCreditLimit.IsApproachingCreditLimit(EnvUsagePercent) then
                EnvironmentCreditsAvailableStyle := Format(PageStyle::Attention)
            else
                EnvironmentCreditsAvailableStyle := Format(PageStyle::Favorable);

        // Company usage (current company only)
        CompanyLimitReached := AITEvalMonthlyCopilotCreditLimit.IsCompanyLimitReached(CompanyCopilotCreditsConsumed, CompanyMonthlyCreditLimit);

        CompanyDeletedSuiteCreditsConsumed := CompanyCopilotCreditsConsumed - CompanyLoadedDataCopilotCreditsConsumed;
        if CompanyDeletedSuiteCreditsConsumed < 0 then
            CompanyDeletedSuiteCreditsConsumed := 0;

        if CompanyMonthlyCreditLimit > 0 then begin
            CompanyCopilotCreditsAvailable := CompanyMonthlyCreditLimit - CompanyCopilotCreditsConsumed;
            CompanyUsagePercent := AITEvalMonthlyCopilotCreditLimit.GetCreditUsagePercentage(CompanyCopilotCreditsConsumed, CompanyMonthlyCreditLimit);
            CompanyCreditsUsagePercentage := Format(CompanyUsagePercent, 0, '<Precision,1:1><Standard Format,0>') + '%';
        end else begin
            CompanyCopilotCreditsAvailable := 0;
            CompanyCreditsUsagePercentage := '';
        end;

        if CompanyCopilotCreditsAvailable < 0 then
            CompanyCopilotCreditsAvailable := 0;

        if CompanyLimitReached then
            CompanyCreditsAvailableStyle := Format(PageStyle::Unfavorable)
        else
            if AITEvalMonthlyCopilotCreditLimit.IsApproachingCreditLimit(CompanyUsagePercent) then
                CompanyCreditsAvailableStyle := Format(PageStyle::Attention)
            else
                CompanyCreditsAvailableStyle := Format(PageStyle::Favorable);
    end;
}