// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Agents;

using System.AI;

page 4349 "Agent AI Consumption Overview"
{
    PageType = Worksheet;
    SourceTable = "Agent AI Consumption Buffer";
    SourceTableTemporary = true;
    SourceTableView = sorting("Consumption DateTime", Id) order(descending);
    Caption = 'Agent AI consumption overview';
    ApplicationArea = All;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            label(ConsumptionNotice)
            {
                Caption = 'Only accessible tasks in the current company are shown. Completed credits exclude pending pricing. No entries yet does not confirm zero usage.';
            }
            group(Filters)
            {
                Visible = ShowDates;
                Editable = true;
                field(StartDateControl; StartDate)
                {
                    Caption = 'Start date';
                    ToolTip = 'Specifies the first date included in the consumption overview.';
                    trigger OnValidate()
                    begin
                        Reload();
                    end;
                }
                field(EndDateControl; EndDate)
                {
                    Caption = 'End date';
                    ToolTip = 'Specifies the last date included in the consumption overview.';
                    trigger OnValidate()
                    begin
                        Reload();
                    end;
                }
            }
            repeater(Entries)
            {
                Editable = false;
                field(CreatedAt; Rec."Consumption DateTime") { ToolTip = 'Specifies when the consumption occurred.'; }
                field(ResourceName; Rec."Resource Name") { ToolTip = 'Specifies the resource that consumed AI credits.'; }
                field(TaskId; Rec."Task ID")
                {
                    ToolTip = 'Specifies the agent task associated with the consumption.';
                    trigger OnDrillDown()
                    var
                        Overview: Codeunit "Agent Consumption Overview";
                    begin
                        Overview.OpenAgentTaskConsumptionOverview(Rec."Task ID");
                    end;
                }
                field(Company; Rec."Company Name") { ToolTip = 'Specifies the company in which consumption occurred.'; }
                field(ReportingState; Rec."Reporting State") { ToolTip = 'Specifies whether pricing is pending, claimed, or completed.'; }
                field(AICredits; Rec."AI Credits")
                {
                    BlankZero = true;
                    ToolTip = 'Specifies completed AI credits. Pending pricing is not a finalized zero charge.';
                }
                field(PricingPending; Rec."Pricing Pending") { ToolTip = 'Specifies that credits for this entry are not yet finalized.'; }
                field(Description; DescriptionText) { Caption = 'Description'; ToolTip = 'Specifies the description of the consumed work.'; }
            }
            group(Totals)
            {
                Editable = false;
                field(CompletedCredits; TotalCredits)
                {
                    Caption = 'Completed AI credits';
                    AutoFormatType = 0;
                    ToolTip = 'Specifies the completed AI credits in the current filtered view, excluding pending pricing.';
                }
                field(PendingEntries; PendingCount) { Caption = 'Entries awaiting pricing'; ToolTip = 'Specifies the number of entries awaiting completed pricing in the current filtered view.'; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RefreshConsumption)
            {
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Refresh the consumption and asynchronously calculated credits.';
                trigger OnAction()
                begin
                    Reload();
                end;
            }
            action(LegacyHistory)
            {
                Caption = 'Legacy consumption';
                Image = History;
                ToolTip = 'Open historical Copilot credit consumption without combining the two credit units.';
                trigger OnAction()
                var
                    LegacyConsumption: Record "Agent Task Consumption";
                begin
                    if TaskFilter <> '' then
                        LegacyConsumption.SetFilter("Task ID", TaskFilter);
                    if not IsNullGuid(AgentUserId) then
                        LegacyConsumption.SetRange("Agent User Security ID", AgentUserId);
                    Page.Run(Page::"Agent Consumption Overview", LegacyConsumption);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Quota: Codeunit "Copilot Quota";
        DisabledErr: Label 'The new AI monetization integration is not enabled.';
    begin
        if not Quota.IsNewMonetizationEnabled() then
            Error(DisabledErr);
        ShowDates := TaskFilter = '';
        if ShowDates then begin
            StartDate := CalcDate('<-CM>', Today());
            EndDate := Today();
        end;
        LoadEntries();
    end;

    trigger OnAfterGetRecord()
    var
        DescriptionStream: InStream;
    begin
        Clear(DescriptionText);
        Rec.Description.CreateInStream(DescriptionStream, TextEncoding::UTF8);
        DescriptionStream.ReadText(DescriptionText);
    end;

    trigger OnAfterGetCurrRecord()
    var
        Entries: Record "Agent AI Consumption Buffer" temporary;
    begin
        TotalCredits := 0;
        PendingCount := 0;
        Entries.Copy(Rec, true);
        if Entries.FindSet() then
            repeat
                TotalCredits += Entries."AI Credits";
                if Entries."Pricing Pending" then
                    PendingCount += 1;
            until Entries.Next() = 0;
    end;

    internal procedure SetContext(NewTaskFilter: Text; NewAgentUserId: Guid)
    begin
        TaskFilter := NewTaskFilter;
        AgentUserId := NewAgentUserId;
    end;

    local procedure Reload()
    var
        InvalidDatesErr: Label 'The start date must not be after the end date.';
    begin
        if (EndDate <> 0D) and (StartDate > EndDate) then
            Error(InvalidDatesErr);
        LoadEntries();
        CurrPage.Update(false);
    end;

    local procedure LoadEntries()
    var
        Consumption: Codeunit "Agent AI Consumption";
        CurrentView: Text;
    begin
        CurrentView := Rec.GetView(false);
        TotalCredits := 0;
        PendingCount := 0;
        Consumption.LoadEntries(Rec, TaskFilter, AgentUserId, StartDate, EndDate);
        Rec.SetView(CurrentView);
    end;

    var
        TaskFilter: Text;
        AgentUserId: Guid;
        StartDate: Date;
        EndDate: Date;
        ShowDates: Boolean;
        DescriptionText: Text;
        TotalCredits: Decimal;
        PendingCount: Integer;
}
