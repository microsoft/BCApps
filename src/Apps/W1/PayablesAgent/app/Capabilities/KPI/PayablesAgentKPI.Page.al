// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;

page 3306 "Payables Agent KPI"
{
    Extensible = false;
    PageType = CardPart;
    ApplicationArea = All;
    SourceTable = Agent;
    SourceTableView = where("Can Access Current Company" = const(true));
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            cuegroup(Summary)
            {
                ShowCaption = false;
                field(AgentTasksReceived; CountKPI.Get("PA KPI Scenario"::"Agent Tasks Received"))
                {
                    ApplicationArea = All;
                    Caption = 'Tasks received';
                    ToolTip = 'Specifies the number of tasks accepted by the agent.';
                }
                field(AgentInvoicesCreated; CountKPI.Get("PA KPI Scenario"::"Purchase Invoices created by Agent"))
                {
                    ApplicationArea = All;
                    Caption = 'Invoices created';
                    ToolTip = 'Specifies the number of purchase invoices created in Payables Agent sessions.';
                }
                field(TimeSavedTasks; TimeSavedTasks)
                {
                    ApplicationArea = All;
                    Caption = 'Time saved on tasks';
                    ToolTip = 'Specifies the estimated time saved by the agent on tasks.';
                    AutoFormatType = 11;
                    AutoFormatExpression = TimeSavedTasksFormatExpression;
                }
                field(TimeSavedInvoices; TimeSavedInvoices)
                {
                    ApplicationArea = All;
                    Caption = 'Time saved on invoices';
                    ToolTip = 'Specifies the estimated time saved by the agent on invoices.';
                    AutoFormatType = 11;
                    AutoFormatExpression = TimeSavedInvoicesFormatExpression;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CountKPI.Set("PA KPI Scenario"::"Agent Tasks Received", PayablesAgentKPI.GetAggregateKPI("PA KPI Scenario"::"Agent Tasks Received").Count);
        CountKPI.Set("PA KPI Scenario"::"Purchase Invoices created by Agent", PayablesAgentKPI.GetAggregateKPI("PA KPI Scenario"::"Purchase Invoices created by Agent").Count);
        TimeSavedTasks := ConvertDurationToText(CountKPI.Get("PA KPI Scenario"::"Agent Tasks Received") * 3, TimeSavedTasksFormatExpression); // Estimated 3 minutes saved per task
        TimeSavedInvoices := ConvertDurationToText(CountKPI.Get("PA KPI Scenario"::"Purchase Invoices created by Agent") * 5, TimeSavedInvoicesFormatExpression); // Estimated 5 minutes saved per invoice
    end;

    var
        PayablesAgentKPI: Record "Payables Agent KPI";
        CountKPI: Dictionary of [Enum "PA KPI Scenario", Integer];
        TimeSavedTasks, TimeSavedInvoices : Decimal;
        TimeSavedTasksFormatExpression, TimeSavedInvoicesFormatExpression : Text;

    local procedure ConvertDurationToText(MinutesSaved: Integer; var ControlAutoFormatExpression: Text): Decimal // Workitem to unify approaches with how SOA implements this: 581118 
    var
        HoursSaved: Decimal;
        DaysSaved: Decimal;
        YearsSaved: Decimal;
        AutoFormatExpressionLbl: Label '<Precision,0:1><Standard Format,0> %1', Locked = true, Comment = '%1 - is the unit hr or min';
        HoursUnitLbl: Label 'h', Comment = 'h represents hours, it will be shown like 23.7 h', MaxLength = 3;
        DaysUnitLbl: Label 'd', Comment = 'd represents days, it will be shown like 23.6 d', MaxLength = 3;
        YearsUnitLbl: Label 'yr', Comment = 'yr represents years, it will be shown like 3.6 yr', MaxLength = 3;
        MinutesUnitLbl: Label 'min', Comment = 'min represents minutes, it will be shown like 23 min', MaxLength = 3;
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