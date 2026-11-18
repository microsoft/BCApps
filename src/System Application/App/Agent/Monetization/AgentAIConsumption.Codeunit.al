// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Agents;

using System.Environment.Consumption;

codeunit 4349 "Agent AI Consumption"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Agent Task" = r,
                  tabledata "AI Consumption Log Entry" = r;

    procedure LoadEntries(var Buffer: Record "Agent AI Consumption Buffer" temporary; TaskFilter: Text; AgentUserId: Guid; StartDate: Date; EndDate: Date)
    var
        AgentTask: Record "Agent Task";
        Consumption: Record "AI Consumption Log Entry";
        AuthorizedTasks: Dictionary of [BigInteger, Guid];
        ExecutingAgentId: Guid;
    begin
        Buffer.Reset();
        Buffer.DeleteAll();
        if TaskFilter <> '' then
            AgentTask.SetFilter(ID, TaskFilter);
        if not IsNullGuid(AgentUserId) then
            AgentTask.SetRange("Agent User Security ID", AgentUserId);

        // The virtual task provider enforces task authorization and company boundaries.
        if AgentTask.FindSet() then
            repeat
                AuthorizedTasks.Add(AgentTask.ID, AgentTask."Agent User Security ID");
            until AgentTask.Next() = 0;

        if AuthorizedTasks.Count() = 0 then
            exit;

        SetConsumptionReadFields(Consumption);
        Consumption.SetRange("Company Name", CompanyName());
        if TaskFilter <> '' then
            Consumption.SetFilter("Agent Task Id", TaskFilter);
        if StartDate <> 0D then
            Consumption.SetFilter("Consumption DateTime", '>=%1', CreateDateTime(StartDate, 0T));
        if EndDate <> 0D then
            Consumption.SetRange("Consumption DateTime", CreateDateTime(StartDate, 0T), CreateDateTime(EndDate, 235959.999T));
        if Consumption.FindSet() then
            repeat
                if AuthorizedTasks.Get(Consumption."Agent Task Id", ExecutingAgentId) then
                    if ExecutingAgentId = Consumption."Executing User Security Id" then
                        AddEntry(Consumption, Buffer);
            until Consumption.Next() = 0;
    end;

    procedure AddEntry(var Consumption: Record "AI Consumption Log Entry"; var Buffer: Record "Agent AI Consumption Buffer" temporary)
    begin
        Buffer.Init();
        Buffer.Id := Consumption.Id;
        Buffer."Task ID" := Consumption."Agent Task Id";
        Buffer."Consumption DateTime" := Consumption."Consumption DateTime";
        Buffer."Resource Name" := Consumption."Resource Name";
        Buffer."Company Name" := Consumption."Company Name";
        Buffer."Reporting State" := CopyStr(Format(Consumption."Reporting State"), 1, MaxStrLen(Buffer."Reporting State"));
        Buffer."Pricing Pending" := Consumption."Reporting State" <> Consumption."Reporting State"::Completed;
        Buffer."AI Credits" := 0;
        if not Buffer."Pricing Pending" then
            Buffer."AI Credits" := Consumption."AI Credits";
        if not Consumption.IsTemporary() then
            Consumption.CalcFields(Description);
        Buffer.Description := Consumption.Description;
        Buffer.Insert();
    end;

    procedure TryGetTaskCredits(TaskId: BigInteger; TaskCompany: Text[30]; var Credits: Decimal; var PricingPending: Boolean; var HasEntries: Boolean): Boolean
    var
        AgentTask: Record "Agent Task";
        Consumption: Record "AI Consumption Log Entry";
    begin
        Credits := 0;
        PricingPending := true;
        HasEntries := false;
        // The authorized virtual provider is scoped to the session company, not ChangeCompany.
        if (TaskCompany <> '') and (TaskCompany <> CompanyName()) then
            exit(false);
        AgentTask.SetRange(ID, TaskId);
        if not AgentTask.FindFirst() then
            exit(false);

        SetConsumptionFilters(Consumption, AgentTask);
        if Consumption.FindSet() then begin
            HasEntries := true;
            PricingPending := false;
            repeat
                if Consumption."Reporting State" = Consumption."Reporting State"::Completed then
                    Credits += Consumption."AI Credits"
                else
                    PricingPending := true;
            until Consumption.Next() = 0;
        end;
        exit(true);
    end;

    local procedure SetConsumptionFilters(var Consumption: Record "AI Consumption Log Entry"; var AgentTask: Record "Agent Task")
    begin
        Consumption.Reset();
        SetConsumptionReadFields(Consumption);
        Consumption.SetRange("Agent Task Id", AgentTask.ID);
        Consumption.SetRange("Executing User Security Id", AgentTask."Agent User Security ID");
        Consumption.SetRange("Company Name", AgentTask.CurrentCompany());
    end;

    local procedure SetConsumptionReadFields(var Consumption: Record "AI Consumption Log Entry")
    begin
        Consumption.SetLoadFields(Id, "Agent Task Id", "Executing User Security Id", "Company Name", "Consumption DateTime", "Resource Name", "Reporting State", "AI Credits");
    end;
}
