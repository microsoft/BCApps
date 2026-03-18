// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

page 149048 "AIT Credit Limits"
{
    Caption = 'AI Eval Copilot Credit Limits';
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
            group(CreditLimitSetup)
            {
                Caption = 'Monthly Copilot Credit Limits';

                field(MonthlyCreditLimit; MonthlyCreditLimit)
                {
                    Caption = 'Monthly Copilot Credit Limit';
                    ToolTip = 'Specifies the maximum number of Copilot credits that can be consumed by all agent test suites during the current month.';
                    DecimalPlaces = 2 : 5;

                    trigger OnValidate()
                    begin
                        SaveCreditLimitSetup();
                        UpdateComputedFields();
                    end;
                }
                field(EnforcementEnabled; EnforcementEnabled)
                {
                    Caption = 'Enforcement Enabled';
                    ToolTip = 'Specifies whether the credit limit enforcement is enabled. When disabled, suites can consume unlimited credits.';

                    trigger OnValidate()
                    begin
                        SaveCreditLimitSetup();
                    end;
                }
                field(CreditsConsumed; CreditsConsumed)
                {
                    Caption = 'Copilot Credits Consumed';
                    ToolTip = 'Specifies the total number of Copilot credits consumed by all agent test suites during the current month.';
                    Editable = false;
                    DecimalPlaces = 2 : 5;
                }
                field(CreditsAvailable; CreditsAvailable)
                {
                    Caption = 'Copilot Credits Available';
                    ToolTip = 'Specifies the number of Copilot credits remaining for the current month.';
                    Editable = false;
                    DecimalPlaces = 2 : 5;
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
                    Caption = 'Copilot Credits Consumed (Month)';
                    ToolTip = 'Specifies the number of Copilot credits consumed by this test suite during the current month.';
                    Editable = false;
                    DecimalPlaces = 2 : 5;
                }
                field("Suite Credit Limit"; SuiteCreditLimitDisplay)
                {
                    Caption = 'Suite Copilot Credit Limit';
                    ToolTip = 'Specifies the maximum number of Copilot credits that can be consumed by this test suite. Leave empty for no suite-specific limit (global limit still applies).';

                    trigger OnValidate()
                    var
                        NewLimit: Decimal;
                    begin
                        if SuiteCreditLimitDisplay = '' then
                            NewLimit := 0
                        else
                            Evaluate(NewLimit, SuiteCreditLimitDisplay);

                        Rec."Suite Credit Limit" := NewLimit;
                        Rec.Modify(true);
                        UpdateSuiteCreditLimitDisplay();
                    end;
                }
                field(Status; Rec.Status)
                {
                    Editable = false;
                    StyleExpr = StatusStyle;
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
        AITCreditLimitSetup: Record "AIT Credit Limit Setup";
        AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
        MonthlyCreditLimit: Decimal;
        EnforcementEnabled: Boolean;
        CreditsConsumed: Decimal;
        CreditsAvailable: Decimal;
        SuiteCreditsConsumed: Decimal;
        CurrentPeriod: Text;
        StatusStyle: Text;
        SuiteCreditLimitDisplay: Text;
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
        UpdateSuiteCreditLimitDisplay();
        UpdateStatusStyle();
    end;

    local procedure LoadCreditLimitSetup()
    begin
        AITCreditLimitSetup.GetOrCreate();
        MonthlyCreditLimit := AITCreditLimitSetup."Monthly Credit Limit";
        EnforcementEnabled := AITCreditLimitSetup."Enforcement Enabled";
        CurrentPeriod := Format(AITCreditLimitSetup.GetPeriodStartDate()) + ' - ' + Format(AITCreditLimitSetup.GetPeriodEndDate());
    end;

    local procedure SaveCreditLimitSetup()
    begin
        AITCreditLimitSetup.GetOrCreate();
        AITCreditLimitSetup."Monthly Credit Limit" := MonthlyCreditLimit;
        AITCreditLimitSetup."Enforcement Enabled" := EnforcementEnabled;
        AITCreditLimitSetup.Modify();
    end;

    local procedure UpdateComputedFields()
    begin
        CreditsConsumed := GetTotalCreditsConsumedThisMonth();
        if MonthlyCreditLimit > 0 then
            CreditsAvailable := MonthlyCreditLimit - CreditsConsumed
        else
            CreditsAvailable := 0;

        if CreditsAvailable < 0 then
            CreditsAvailable := 0;

        // Set style based on credits available
        if CreditsAvailable <= 0 then
            CreditsAvailableStyle := 'Unfavorable'
        else
            CreditsAvailableStyle := 'Favorable';
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
        exit(AgentTestContextImpl.GetCopilotCreditsForMonth(TestSuiteCode, AITCreditLimitSetup.GetPeriodStartDate()));
    end;

    local procedure UpdateSuiteCreditLimitDisplay()
    begin
        if Rec."Suite Credit Limit" = 0 then
            SuiteCreditLimitDisplay := ''
        else
            SuiteCreditLimitDisplay := Format(Rec."Suite Credit Limit", 0, '<Precision,2:5><Standard Format,0>');
    end;

    local procedure UpdateStatusStyle()
    begin
        case Rec.Status of
            Rec.Status::Running:
                StatusStyle := 'Attention';
            Rec.Status::Completed:
                StatusStyle := 'Favorable';
            Rec.Status::Cancelled:
                StatusStyle := 'Unfavorable';
            Rec.Status::CreditLimitReached:
                StatusStyle := 'Unfavorable';
            else
                StatusStyle := 'Standard';
        end;
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
        foreach SuiteCode in SuitesWithCredits do begin
            if FilterText = '' then
                FilterText := SuiteCode
            else
                FilterText := FilterText + '|' + SuiteCode;
        end;

        if FilterText <> '' then
            Rec.SetFilter(Code, FilterText)
        else
            Rec.SetRange(Code);

        Rec.FilterGroup(0);
    end;
}
