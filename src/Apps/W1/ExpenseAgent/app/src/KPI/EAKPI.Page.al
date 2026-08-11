// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Agents;

page 7074 "EA KPI"
{
    Caption = 'Expense Agent';
    PageType = CardPart;
    ApplicationArea = All;
    SourceTable = "EA KPI";
    RefreshOnActivate = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(content)
        {
            cuegroup(Summary)
            {
                ShowCaption = false;
                field(FileReceived; Rec."File Received")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total number of files received in the emails from the shared mailbox.';
                }
                field(Expenses; Rec."Total Expenses Created")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total number of expenses created by the Expense Agent.';

                    trigger OnDrillDown()
                    var
                        EAKPIEntry: Record "EA KPI Entry";
                    begin
                        EAKPIEntry.SetRange("Created by User ID", GetEntraAppUserIdForDrillDown());
                        EAKPIEntry.SetRange("Record Type", EAKPIEntry."Record Type"::Expense);
                        Page.Run(Page::"EA KPI Entries", EAKPIEntry);
                    end;
                }
                field(ExpenseReports; Rec."Total Expense Reports Created")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total number of expense reports created by the Expense Agent.';

                    trigger OnDrillDown()
                    var
                        EAKPIEntry: Record "EA KPI Entry";
                    begin
                        EAKPIEntry.SetRange("Created by User ID", GetEntraAppUserIdForDrillDown());
                        EAKPIEntry.SetRange("Record Type", EAKPIEntry."Record Type"::"Expense Report");
                        Page.Run(Page::"EA KPI Entries", EAKPIEntry);
                    end;
                }
                field(ExpenseReportLines; Rec."Total Exp Report Lines Created")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total number of expense report lines created by the Expense Agent.';

                    trigger OnDrillDown()
                    var
                        EAKPIEntry: Record "EA KPI Entry";
                    begin
                        EAKPIEntry.SetRange("Created by User ID", GetEntraAppUserIdForDrillDown());
                        EAKPIEntry.SetRange("Record Type", EAKPIEntry."Record Type"::"Expense Report Line");
                        Page.Run(Page::"EA KPI Entries", EAKPIEntry);
                    end;
                }
                field(ERLCreatedWithItemization; Rec."Total ERL Cr. with Itemization")
                {
                    ApplicationArea = All;
                    Caption = 'Of which itemized';
                    ToolTip = 'Specifies how many of the report lines created by the Expense Agent include itemization. This is a subset of the report lines created.';

                    trigger OnDrillDown()
                    var
                        EAKPIEntry: Record "EA KPI Entry";
                    begin
                        EAKPIEntry.SetRange("Created by User ID", GetEntraAppUserIdForDrillDown());
                        EAKPIEntry.SetRange("Record Type", EAKPIEntry."Record Type"::"Expense Report Line");
                        EAKPIEntry.SetRange("Has Itemization", true);
                        Page.Run(Page::"EA KPI Entries", EAKPIEntry);
                    end;
                }
                field(TimeSavedExpenseReportMin; TimeSavedExpenseReport)
                {
                    ApplicationArea = All;
                    Caption = 'Time saved on expense reports';
                    AutoFormatType = 11;
                    AutoFormatExpression = ExpenseReportTimeAutoFormatExpression;
                    ToolTip = 'Specifies the total time saved by the agent on expense reports. The time saved is calculated as 3 minutes per expense report line plus 2 minutes per line with itemization.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetSafe();
        VerifyUserHasAccessToAgent();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        TimeSavedExpenseReport := GetTimeSavedExpenseReport(ExpenseReportTimeAutoFormatExpression);
    end;

    var
        TimeSavedExpenseReport: Decimal;
        ExpenseReportTimeAutoFormatExpression: Text;
        AutoFormatExpressionLbl: Label '<Precision,0:1><Standard Format,0> %1', Locked = true, Comment = '%1 - is the unit hr or min';
        HoursUnitLbl: Label 'h', Comment = 'h represents hours, it will be shown like 23.7 h', MaxLength = 3;
        DaysUnitLbl: Label 'd', Comment = 'd represents days, it will be shown like 23.6 d', MaxLength = 3;
        YearsUnitLbl: Label 'yr', Comment = 'yr represents years, it will be shown like 3.6 yr', MaxLength = 3;
        MinutesUnitLbl: Label 'min', Comment = 'min represents minutes, it will be shown like 23 min', MaxLength = 3;

    local procedure VerifyUserHasAccessToAgent()
    var
        Agent: Record Agent;
    begin
        // Verify user has access to the agent
        Agent.Get(Rec."User Security ID");
    end;

    local procedure GetEntraAppUserIdForDrillDown(): Guid
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
        EntraAppUserId: Guid;
        ExpenseAgentUserId: Guid;
    begin
        // Resolve the Entra app's user security id at drill-down time so the filter is
        // not affected by drift in EA KPI."User Security ID" (e.g., if the agent has been
        // recreated). Falls back to the EA KPI's stored value if the AAD app record is
        // not available (e.g., outside SaaS).
        if ExpenseAgentAPIValidation.TryGetExpenseAgentUserId(ExpenseAgentUserId) then
            EntraAppUserId := ExpenseAgentUserId;

        exit(EntraAppUserId);
    end;

    local procedure GetTimeSavedExpenseReport(var ControlAutoFormatExpression: Text): Decimal
    var
        MinutesSaved: Integer;
    begin
        // Estimate: 3 minutes per expense report line + 2 minutes per line with itemization
        MinutesSaved := (Rec."Total Exp Report Lines Created" * 3) + (Rec."Total ERL Cr. with Itemization" * 2);
        exit(ConvertDurationToText(MinutesSaved, ControlAutoFormatExpression));
    end;

    local procedure ConvertDurationToText(MinutesSaved: Integer; var ControlAutoFormatExpression: Text): Decimal
    var
        HoursSaved: Decimal;
        DaysSaved: Decimal;
        YearsSaved: Decimal;
    begin
        ControlAutoFormatExpression := StrSubstNo(AutoFormatExpressionLbl, MinutesUnitLbl);

        if MinutesSaved < 60 then
            exit(MinutesSaved);

        ControlAutoFormatExpression := StrSubstNo(AutoFormatExpressionLbl, HoursUnitLbl);

        // Under 100 hours we track with 0.1 increment, over 100 hours we track with 0.5 increment.
        // This is to show more progress in the beginning. With larger numbers it feels odd to track with small increments.
        if MinutesSaved < 6000 then
            HoursSaved := Round(MinutesSaved / 60, 0.1)
        else
            HoursSaved := Round(MinutesSaved / 60, 0.5);

        if HoursSaved < 1000 then
            exit(HoursSaved);

        // Under 100 days we track with 0.1 increment, over 100 days we report full days.
        DaysSaved := Round(HoursSaved / 24, 0.1);
        ControlAutoFormatExpression := StrSubstNo(AutoFormatExpressionLbl, DaysUnitLbl);
        if DaysSaved < 100 then
            exit(DaysSaved)
        else
            DaysSaved := Round(DaysSaved, 1);

        if DaysSaved < 1000 then
            exit(DaysSaved);

        // Years are always reported with 0.01 increment.
        YearsSaved := Round(DaysSaved / 365, 0.01);
        ControlAutoFormatExpression := StrSubstNo(AutoFormatExpressionLbl, YearsUnitLbl);
        exit(YearsSaved);
    end;
}