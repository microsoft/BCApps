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
    SourceTable = "AIT Eval Suite Usage Buffer";
    SourceTableTemporary = true;
    SourceTableView = where(Consumed = filter(<> 0));
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
            }
            repeater(AgentSuites)
            {
                Caption = 'Agent Test Suites';

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
                field(SuiteCreditsConsumed; Rec.Consumed)
                {
                    AutoFormatType = 0;
                    Caption = 'Copilot Credits Consumed (Month)';
                    ToolTip = 'Specifies the number of Copilot credits consumed by this test suite during the current month.';
                    Editable = false;
                    DecimalPlaces = 2 : 5;
                }
            }
            group(Footer)
            {
                ShowCaption = false;
                field(CurrentPeriod; CurrentPeriod)
                {
                    Caption = 'Current Period';
                    ToolTip = 'Specifies the date range for the current tracking period.';
                    Editable = false;
                }
                field(CreditsConsumed; CopilotCreditsConsumed)
                {
                    AutoFormatType = 0;
                    Caption = 'Copilot Credits Consumed';
                    ToolTip = 'Specifies the total number of Copilot credits consumed by all agent test suites during the current month, including credits from deleted suites.';
                    Editable = false;
                    DecimalPlaces = 2 : 5;
                }
                field(DeletedSuiteCredits; DeletedSuiteCreditsConsumed)
                {
                    AutoFormatType = 0;
                    Caption = 'Credits from Deleted Suites';
                    ToolTip = 'Specifies Copilot credits consumed this month by suites that have since been deleted. These credits are included in the total but are not shown in the list above.';
                    Editable = false;
                    DecimalPlaces = 2 : 5;
                    Visible = DeletedSuiteCreditsConsumed > 0;
                }
                field(CreditsAvailable; CopilotCreditsAvailable)
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
        AITEvalMonthlyCopilotCreditLimitRecord: Record "AIT Eval Monthly Copilot Cred.";
        AITEvalMonthlyCopilotCreditLimit: Codeunit "AIT Eval Monthly Copilot Cred.";
        MonthlyCreditLimit: Decimal;
        CopilotCreditsConsumed: Decimal;
        CopilotCreditsAvailable: Decimal;
        DeletedSuiteCreditsConsumed: Decimal;
        LoadedDataCopilotCreditsConsumed: Decimal;
        EnforcementEnabled: Boolean;
        CreditsUsagePercentage: Text;
        CurrentPeriod: Text;
        CreditsAvailableStyle: Text;

    trigger OnOpenPage()
    begin
        RefreshPage();
    end;

    local procedure RefreshPage()
    begin
        LoadCreditLimitSetup();
        LoadBufferData();
        UpdateComputedFields();
        CurrPage.Update(false);
    end;

    local procedure LoadCreditLimitSetup()
    begin
        AITEvalMonthlyCopilotCreditLimitRecord.GetOrCreate();
        MonthlyCreditLimit := AITEvalMonthlyCopilotCreditLimitRecord."Monthly Credit Limit";
        EnforcementEnabled := AITEvalMonthlyCopilotCreditLimitRecord."Enforcement Enabled";
        CurrentPeriod := Format(AITEvalMonthlyCopilotCreditLimitRecord.GetPeriodStartDate()) + ' - ' + Format(AITEvalMonthlyCopilotCreditLimitRecord.GetPeriodEndDate());
    end;

    local procedure SaveCreditLimitSetup()
    begin
        AITEvalMonthlyCopilotCreditLimitRecord.GetOrCreate();
        AITEvalMonthlyCopilotCreditLimitRecord."Monthly Credit Limit" := MonthlyCreditLimit;
        AITEvalMonthlyCopilotCreditLimitRecord."Enforcement Enabled" := EnforcementEnabled;
        AITEvalMonthlyCopilotCreditLimitRecord.Modify();
    end;

    local procedure LoadBufferData()
    var
        AITTestSuite: Record "AIT Test Suite";
        TempAIEvalSuiteUsageBuffer: Record "AIT Eval Suite Usage Buffer";
        AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
        SortOrder: Integer;
    begin
        Rec.Reset();
        Rec.DeleteAll();
        LoadedDataCopilotCreditsConsumed := 0;

        // Load all agent test suites and their credit consumption for the current period into the buffer.
        AITTestSuite.SetRange("Test Type", AITTestSuite."Test Type"::Agent);
        if AITTestSuite.FindSet() then
            repeat
                SortOrder += 1;
                TempAIEvalSuiteUsageBuffer.Index := SortOrder;
                TempAIEvalSuiteUsageBuffer."Suite Code" := AITTestSuite.Code;
                TempAIEvalSuiteUsageBuffer."Suite Description" := AITTestSuite.Description;
                TempAIEvalSuiteUsageBuffer.Consumed := AgentTestContextImpl.GetCopilotCreditsForPeriod(AITTestSuite.Code, AITEvalMonthlyCopilotCreditLimitRecord.GetPeriodStartDate());
                TempAIEvalSuiteUsageBuffer.Insert();
                LoadedDataCopilotCreditsConsumed += TempAIEvalSuiteUsageBuffer.Consumed;
            until AITTestSuite.Next() = 0;

        // Sort the buffer by consumed credits in descending order.
        SortOrder := 0;
        TempAIEvalSuiteUsageBuffer.SetCurrentKey(Consumed);
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
        UsagePercent: Decimal;
        LimitReached: Boolean;
    begin
        // Get total consumption.
        LimitReached := AITEvalMonthlyCopilotCreditLimit.IsLimitReached(CopilotCreditsConsumed, MonthlyCreditLimit);

        // Get orphan consumption.
        DeletedSuiteCreditsConsumed := CopilotCreditsConsumed - LoadedDataCopilotCreditsConsumed;
        if DeletedSuiteCreditsConsumed < 0 then
            DeletedSuiteCreditsConsumed := 0;

        if MonthlyCreditLimit > 0 then begin
            CopilotCreditsAvailable := MonthlyCreditLimit - CopilotCreditsConsumed;
            UsagePercent := AITEvalMonthlyCopilotCreditLimit.GetCreditUsagePercentage(CopilotCreditsConsumed, MonthlyCreditLimit);
            CreditsUsagePercentage := Format(UsagePercent, 0, '<Precision,1:1><Standard Format,0>') + '%';
        end else begin
            CopilotCreditsAvailable := 0;
            CreditsUsagePercentage := '';
        end;

        if CopilotCreditsAvailable < 0 then
            CopilotCreditsAvailable := 0;

        if LimitReached then
            CreditsAvailableStyle := Format(PageStyle::Unfavorable)
        else
            if AITEvalMonthlyCopilotCreditLimit.IsApproachingCreditLimit(UsagePercent) then
                CreditsAvailableStyle := Format(PageStyle::Attention)
            else
                CreditsAvailableStyle := Format(PageStyle::Favorable);
    end;
}