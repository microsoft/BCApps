// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

page 149048 "AIT Eval Monthly Copilot Cred."
{
    Caption = 'AI Eval Monthly Copilot Credit Limits';
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "AIT Test Suite";
    SourceTableView = where("Test Type" = const(Agent));
    InsertAllowed = false;
    DeleteAllowed = false;
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            label(EnforcementExplanation)
            {
                Caption = 'Credit limits control when new AI evaluations can be started. Once the limit is reached, new evaluations cannot be started, but evaluations already in progress are allowed to finish.';
                Style = Subordinate;
            }
            group(CreditLimitSetup)
            {
                ShowCaption = false;
                field(EnforcementEnabled; EnforcementEnabled)
                {
                    Caption = 'Limits Enabled';
                    ToolTip = 'Specifies whether the credit limit enforcement is enabled. When disabled, suites can consume unlimited credits.';

                    trigger OnValidate()
                    begin
                        SaveCreditLimitSetup();
                        CurrPage.Update(false);
                    end;
                }
                field(MonthlyCreditLimit; MonthlyCreditLimit)
                {
                    AutoFormatType = 0;
                    Caption = 'Monthly Copilot Credit Limit';
                    ToolTip = 'Specifies the maximum number of Copilot credits that can be consumed by all agent test suites during the current month.';
                    DecimalPlaces = 2 : 5;
                    Editable = EnforcementEnabled;

                    trigger OnValidate()
                    begin
                        SaveCreditLimitSetup();
                        UpdateComputedFields();
                    end;
                }
                field(CreditsConsumed; CreditsConsumed)
                {
                    AutoFormatType = 0;
                    Caption = 'Copilot Credits Consumed';
                    ToolTip = 'Specifies the total number of Copilot credits consumed by all agent test suites during the current month.';
                    Editable = false;
                    DecimalPlaces = 2 : 5;
                }
                field(CreditsAvailable; CreditsAvailable)
                {
                    AutoFormatType = 0;
                    Caption = 'Copilot Credits Available';
                    ToolTip = 'Specifies the number of Copilot credits remaining for the current month.';
                    Editable = false;
                    DecimalPlaces = 2 : 5;
                    StyleExpr = CreditsAvailableStyle;
                }
                field(CreditsUsagePercentage; CreditsUsagePercentage)
                {
                    Caption = 'Usage %';
                    ToolTip = 'Specifies the percentage of the monthly Copilot credit limit that has been consumed.';
                    Editable = false;
                    StyleExpr = CreditsAvailableStyle;
                }
                field(CurrentPeriod; CurrentPeriod)
                {
                    Caption = 'Current Period';
                    ToolTip = 'Specifies the date range for the current tracking period.';
                    Editable = false;
                }
            }
            repeater(AgentSuites)
            {
                Caption = 'Agent Test Suites';

                field("Code"; Rec."Code")
                {
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"AIT Test Suite", Rec);
                    end;
                }
                field(Description; Rec.Description)
                {
                    Editable = false;
                }
                field(SuiteCreditsConsumed; SuiteCreditsConsumed)
                {
                    AutoFormatType = 0;
                    Caption = 'Copilot Credits Consumed (Month)';
                    ToolTip = 'Specifies the number of Copilot credits consumed by this test suite during the current month.';
                    Editable = false;
                    DecimalPlaces = 2 : 5;
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
                    LoadCreditLimitSetup();
                    UpdateComputedFields();
                    CurrPage.Update(false);
                end;
            }
            action(ToggleShowAll)
            {
                Caption = 'Show all suites';
                ToolTip = 'Toggle between showing all agent test suites or only those that have consumed Copilot credits.';
                Image = Filter;
                Visible = not ShowAllSuites;

                trigger OnAction()
                begin
                    ShowAllSuites := not ShowAllSuites;
                    ApplySuiteFilter();
                    CurrPage.Update(false);
                end;
            }
            action(ToggleShowExecuted)
            {
                Caption = 'Show only executed suites';
                ToolTip = 'Toggle between showing all agent test suites or only those that have consumed Copilot credits.';
                Image = Filter;
                Visible = ShowAllSuites;

                trigger OnAction()
                begin
                    ShowAllSuites := not ShowAllSuites;
                    ApplySuiteFilter();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            actionref(Refresh_Promoted; Refresh)
            {
            }
            actionref(ToggleShowAll_Promoted; ToggleShowAll)
            {
            }
            actionref(ToggleShowExecuted_Promoted; ToggleShowExecuted)
            {
            }
        }
    }

    var
        AITEvalMonthlyCopilotCreditLimits: Record "AIT Eval Monthly Copilot Cred.";
        AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
        MonthlyCreditLimit: Decimal;
        EnforcementEnabled: Boolean;
        CreditsConsumed: Decimal;
        CreditsAvailable: Decimal;
        CreditsUsagePercentage: Text;
        SuiteCreditsConsumed: Decimal;
        CurrentPeriod: Text;
        CreditsAvailableStyle: Text;
        ShowAllSuites: Boolean;
        SuitesWithCredits: List of [Code[100]];

    trigger OnOpenPage()
    begin
        LoadCreditLimitSetup();
        UpdateComputedFields();
        BuildSuitesWithCreditsList();
        ApplySuiteFilter();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateSuiteCreditsConsumed();
    end;

    local procedure LoadCreditLimitSetup()
    begin
        AITEvalMonthlyCopilotCreditLimits.GetOrCreate();
        MonthlyCreditLimit := AITEvalMonthlyCopilotCreditLimits."Monthly Credit Limit";
        EnforcementEnabled := AITEvalMonthlyCopilotCreditLimits."Enforcement Enabled";
        CurrentPeriod := Format(AITEvalMonthlyCopilotCreditLimits.GetPeriodStartDate()) + ' - ' + Format(AITEvalMonthlyCopilotCreditLimits.GetPeriodEndDate());
    end;

    local procedure SaveCreditLimitSetup()
    begin
        AITEvalMonthlyCopilotCreditLimits.GetOrCreate();
        AITEvalMonthlyCopilotCreditLimits."Monthly Credit Limit" := MonthlyCreditLimit;
        AITEvalMonthlyCopilotCreditLimits."Enforcement Enabled" := EnforcementEnabled;
        AITEvalMonthlyCopilotCreditLimits.Modify();
    end;

    local procedure UpdateComputedFields()
    var
        UsagePercent: Decimal;
    begin
        CreditsConsumed := GetTotalCreditsConsumedThisMonth();
        if MonthlyCreditLimit > 0 then begin
            CreditsAvailable := MonthlyCreditLimit - CreditsConsumed;
            UsagePercent := Round(CreditsConsumed / MonthlyCreditLimit * 100, 0.1);
            CreditsUsagePercentage := Format(UsagePercent, 0, '<Precision,1:1><Standard Format,0>') + '%';
        end else begin
            CreditsAvailable := 0;
            CreditsUsagePercentage := '';
        end;

        if CreditsAvailable < 0 then
            CreditsAvailable := 0;

        if UsagePercent >= 100 then
            CreditsAvailableStyle := Format(PageStyle::Unfavorable)
        else
            if UsagePercent >= 80 then
                CreditsAvailableStyle := Format(PageStyle::Attention)
            else
                CreditsAvailableStyle := Format(PageStyle::Favorable);
    end;

    local procedure GetTotalCreditsConsumedThisMonth(): Decimal
    var
        AITTestSuite: Record "AIT Test Suite";
        TotalCredits: Decimal;
    begin
        AITTestSuite.SetRange("Test Type", AITTestSuite."Test Type"::Agent);
        if AITTestSuite.FindSet() then
            repeat
                TotalCredits += GetSuiteCreditsConsumedThisMonth(AITTestSuite.Code);
            until AITTestSuite.Next() = 0;

        exit(TotalCredits);
    end;

    local procedure UpdateSuiteCreditsConsumed()
    begin
        SuiteCreditsConsumed := GetSuiteCreditsConsumedThisMonth(Rec.Code);
    end;

    local procedure GetSuiteCreditsConsumedThisMonth(TestSuiteCode: Code[100]): Decimal
    begin
        // Get credits consumed for this suite in the current month
        // We filter by all versions since the start of the month
        exit(AgentTestContextImpl.GetCopilotCreditsForPeriod(TestSuiteCode, AITEvalMonthlyCopilotCreditLimits.GetPeriodStartDate()));
    end;

    local procedure BuildSuitesWithCreditsList()
    var
        AITTestSuite: Record "AIT Test Suite";
        SuiteCredits: Decimal;
    begin
        Clear(SuitesWithCredits);

        AITTestSuite.SetRange("Test Type", AITTestSuite."Test Type"::Agent);
        if AITTestSuite.FindSet() then
            repeat
                SuiteCredits := GetSuiteCreditsConsumedThisMonth(AITTestSuite.Code);
                if SuiteCredits > 0 then
                    SuitesWithCredits.Add(AITTestSuite.Code);
            until AITTestSuite.Next() = 0;
    end;

    local procedure ApplySuiteFilter()
    var
        FilterText: Text;
        SuiteCode: Code[100];
    begin
        Rec.FilterGroup(2);

        if ShowAllSuites or (SuitesWithCredits.Count() = 0) then begin
            Rec.SetRange(Code);
            Rec.FilterGroup(0);
            exit;
        end;

        // Build filter for suites with credits consumed
        foreach SuiteCode in SuitesWithCredits do
            if FilterText = '' then
                FilterText := SuiteCode
            else
                FilterText := FilterText + '|' + SuiteCode;

        if FilterText <> '' then
            Rec.SetFilter(Code, FilterText)
        else
            Rec.SetRange(Code);

        Rec.FilterGroup(0);
    end;
}
