// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Agents;
using System.Environment.Configuration;
using System.Globalization;

page 6942 "Expense Agent Setup API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense Agent Setup';
    EntitySetCaption = 'Expense Agent Setup';
    EntityName = 'expenseAgentSetup';
    EntitySetName = 'expenseAgentSetup';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    DataAccessIntent = ReadOnly;
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = "Expense Agent Setup";
    AboutText = 'Provides access to the Expense Agent Setup configuration';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(useRules; Rec."Use Rules")
                {
                    Caption = 'Use Rules';
                }
                field(submitterRunEvaluation; Rec."Submitter-run Evaluation")
                {
                    Caption = 'Allow Submitters to Evaluate Policies';
                }
                field(enableAgent; Rec."Enable Agent")
                {
                    Caption = 'Enable Agent';
                }
                field(exchangeRateForExpenses; Rec."Exchange Rate for Expenses")
                {
                    Caption = 'Exchange Rate for Expenses';
                }
                field(allowPrepaymentCashAdvance; Rec."Allow Prepayment-Cash Advance")
                {
                    Caption = 'Prepayment-Cash Advance Allowed';
                }
                field(allowGrpOfTransInReport; Rec."Allow Grp. of Trans. in Report")
                {
                    Caption = 'Allow Grouping of Transactions in Report';
                }
#if not CLEAN29
                field(expReportRoundingPrecision; Rec."Exp. Report Rounding Precision")
                {
                    Caption = 'Expense Report Rounding Precision';
                    ObsoleteState = Pending;
                    ObsoleteTag = '29.0';
                    ObsoleteReason = 'This field is no longer required and will be removed in a future release.';
                }
                field(expenseReportRoundingType; Rec."Expense Report Rounding Type")
                {
                    Caption = 'Expense Report Rounding Type';
                    ObsoleteState = Pending;
                    ObsoleteTag = '29.0';
                    ObsoleteReason = 'This field is no longer required and will be removed in a future release.';
                }
#endif
                field(doNotAllowExpOlderThan; Rec."Do Not Allow Exp. Older Than")
                {
                    Caption = 'Do Not Allow Expenses Older Than';
                }
                field(ifExpIsOlderThanAllowed; Rec."If Exp. Is Older Than Allowed")
                {
                    Caption = 'If Expense Is Older Than Allowed';
                }
                field(checkCategorySubCatUsage; Rec."Check Category/SubCat. Usage")
                {
                    Caption = 'Check Category/Subcategory Usage';
                }
                field(enableAntiCorpStatement; Rec."Enable Anti-Corp. Statement")
                {
                    Caption = 'Display Anti-Corruption Attestation';
                }
                field(expenseReportsNos; Rec."Expense Reports Nos.")
                {
                    Caption = 'Expense Reports Nos.';
                }
                field(expenseNos; Rec."Expense Nos.")
                {
                    Caption = 'Expenses Nos.';
                }
                field(postedExpenseReportsNos; Rec."Posted Expense Reports Nos.")
                {
                    Caption = 'Posted Expense Reports Nos.';
                }
                field(standardRateOfMileage; Rec."Standard Rate of Mileage")
                {
                    Caption = 'Standard Rate of Mileage';
                }
                field(defaultMileageUOM; Rec."Default Mileage UOM")
                {
                    Caption = 'Default Mileage UOM';
                }
                field(onlyShortestRoute; Rec."Only Shortest Route")
                {
                    Caption = 'Only Shortest Route';
                    ToolTip = 'Specifies whether only the shortest route is shown for mileage expenses.';
                }
                field(fullPerDiemCalculation; Rec."Full Per-Diem Calculation")
                {
                    Caption = 'Full Per-Diem Calculations';
                }
                field(reductionForBreakfastPercent; Rec."Reduction for Breakfast %")
                {
                    Caption = 'Reduction for Breakfast %';
                }
#if not CLEAN29
                field(perDiemRoundingPrecision; Rec."Per Diem Rounding Precision")
                {
                    Caption = 'Per Diem Rounding Precision';
                    ObsoleteState = Pending;
                    ObsoleteTag = '29.0';
                    ObsoleteReason = 'This field is no longer required and will be removed in a future release.';
                }
#endif
                field(reductionForLunchPercent; Rec."Reduction for Lunch %")
                {
                    Caption = 'Reduction for Lunch %';
                }
                field(minimumHoursForPerDiem; Rec."Minimum Hours for Per Diem")
                {
                    Caption = 'Minimum Hours for Per Diem';
                }
                field(reductionForDinnerPercent; Rec."Reduction for Dinner %")
                {
                    Caption = 'Reduction for Dinner %';
                }
                field(timeToleranceForCalendar; Rec."Time Tolerance for Calendar")
                {
                    Caption = 'Time Tolerance for Calendar';
                }
                field(expenseReportGrouping; Rec."Expense Report Grouping")
                {
                    Caption = 'Expense Report Grouping';
                }
                field(noreplyEmailAccountId; Rec."Noreply Email Account ID")
                {
                    Caption = 'Noreply Email Account ID';
                }
                field(noreplyEmailConnector; Rec."Noreply Email Connector")
                {
                    Caption = 'Noreply Email Connector';
                }
                field(noreplyEmailAddress; Rec."Noreply Email Address")
                {
                    Caption = 'Noreply Email Address';
                }
                field(systemCommunicationChannel; Rec."System Communication Channel")
                {
                    Caption = 'System Communication Channel';
                }
                field(emailAddress; Rec."Email Address")
                {
                    Caption = 'Inbound Email Address';
                    ToolTip = 'Specifies the inbound email address used by the Expense Agent to receive receipts. Surfaced in service-side notifications such as the welcome email.';
                }
                field(enableProjectFields; Rec."Enable Project Fields")
                {
                    Caption = 'Enable Project Fields';
                }
                field(projectVisibility; Rec."Project Visibility")
                {
                    Caption = 'Project Visibility';
                }
                field(agentLanguageCode; AgentLanguageCode)
                {
                    Caption = 'Agent Language Code';
                    ToolTip = 'Specifies the language that the agent uses for task details and outgoing messages.';
                }
                field(agentTimeZone; AgentTimeZone)
                {
                    Caption = 'Agent Time Zone';
                    ToolTip = 'Specifies the time zone configured for the agent user.';
                }
                field(agentRegionalFormatId; AgentRegionalFormatId)
                {
                    Caption = 'Agent Regional Format ID';
                    ToolTip = 'Specifies the regional format (locale) identifier configured for the agent user.';
                }

                part(expenseAgentAccessControls; "Expense Agent Access Ctrl API")
                {
                    EntityName = 'expenseAgentAccessControl';
                    EntitySetName = 'expenseAgentAccessControls';
                }
            }
        }
    }

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
    end;

    trigger OnAfterGetRecord()
    begin
        Clear(AgentLanguageCode);
        Clear(AgentTimeZone);
        Clear(AgentRegionalFormatId);
        if IsNullGuid(Rec."User Security ID") then
            exit;
        if not TryGetAgentUserSettings(Rec."User Security ID") then begin
            Clear(AgentLanguageCode);
            Clear(AgentTimeZone);
            Clear(AgentRegionalFormatId);
        end;
    end;

    [TryFunction]
    local procedure TryGetAgentUserSettings(AgentUserSecurityID: Guid)
    var
        TempUserSettings: Record "User Settings" temporary;
        Agent: Codeunit Agent;
        Language: Codeunit Language;
    begin
        Agent.GetUserSettings(AgentUserSecurityID, TempUserSettings);
        AgentLanguageCode := Language.GetLanguageCode(TempUserSettings."Language ID");
        AgentTimeZone := TempUserSettings."Time Zone";
        AgentRegionalFormatId := TempUserSettings."Locale ID";
    end;

    var
        AgentLanguageCode: Code[10];
        AgentTimeZone: Text[180];
        AgentRegionalFormatId: Integer;
}
