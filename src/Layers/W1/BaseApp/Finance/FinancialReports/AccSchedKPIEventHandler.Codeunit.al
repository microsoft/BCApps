// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.GeneralLedger.Budget;
using System.Environment;

codeunit 198 "Acc. Sched. KPI Event Handler"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        TempAccSchedKPIWebSrvLine: Record "Acc. Sched. KPI Web Srv. Line" temporary;
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
        PrevAccSchedName: Code[10];
        PrevGlBudgetName: Code[10];

    [EventSubscriber(ObjectType::Table, Database::"Acc. Sched. KPI Web Srv. Setup", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnModifyAccSchedKpiSetup(var Rec: Record "Acc. Sched. KPI Web Srv. Setup"; var xRec: Record "Acc. Sched. KPI Web Srv. Setup"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;
        PrevAccSchedName := '';
        PrevGlBudgetName := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Acc. Sched. KPI Web Srv. Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnInsertAccSchedKpiLine(var Rec: Record "Acc. Sched. KPI Web Srv. Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;
        ResetAccSchedKPIWevSrvSetup();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Acc. Sched. KPI Web Srv. Line", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnModifyAccSchedKpiLine(var Rec: Record "Acc. Sched. KPI Web Srv. Line"; var xRec: Record "Acc. Sched. KPI Web Srv. Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;
        ResetAccSchedKPIWevSrvSetup();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Acc. Sched. KPI Web Srv. Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnDeleteAccSchedKpiLine(var Rec: Record "Acc. Sched. KPI Web Srv. Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;
        ResetAccSchedKPIWevSrvSetup();
        if TempAccSchedKPIWebSrvLine.Get(Rec."Acc. Schedule Name") then
            TempAccSchedKPIWebSrvLine.Delete();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Acc. Schedule Line", 'OnAfterInsertEvent', '', true, true)]
    local procedure OnInsertAccSchedLine(var Rec: Record "Acc. Schedule Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;
        ResetIfAccSchedChanged(Rec."Schedule Name");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Acc. Schedule Line", 'OnAfterModifyEvent', '', true, true)]
    local procedure OnModifyAccSchedLine(var Rec: Record "Acc. Schedule Line"; var xRec: Record "Acc. Schedule Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;
        ResetIfAccSchedChanged(Rec."Schedule Name");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Acc. Schedule Line", 'OnAfterDeleteEvent', '', true, true)]
    local procedure OnDeleteAccSchedLine(var Rec: Record "Acc. Schedule Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;
        ResetIfAccSchedChanged(Rec."Schedule Name");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnDatabaseInsert', '', true, true)]
    local procedure OnInsertGlBudgetEntry(RecRef: RecordRef)
    begin
        if RecRef.Number <> Database::"G/L Budget Entry" then
            exit;

        if RecRef.IsTemporary then
            exit;

        ResetIfGlBudgetChanged(RecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnDatabaseModify', '', true, true)]
    local procedure OnModifyGlBudgetEntry(RecRef: RecordRef)
    begin
        if RecRef.Number <> Database::"G/L Budget Entry" then
            exit;

        if RecRef.IsTemporary then
            exit;

        ResetIfGlBudgetChanged(RecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnDatabaseDelete', '', true, true)]
    local procedure OnDeleteGlBudgetEntry(RecRef: RecordRef)
    begin
        if RecRef.Number <> Database::"G/L Budget Entry" then
            exit;

        if RecRef.IsTemporary then
            exit;

        ResetIfGlBudgetChanged(RecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterGetDatabaseTableTriggerSetup', '', true, true)]
    local procedure EnableGLBudgetEntryTriggers(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
        if TableId <> Database::"G/L Budget Entry" then
            exit;

        AccSchedKPIWebSrvSetup.SetLoadFields("Primary Key");
        AccSchedKPIWebSrvSetup.SetAutoCalcFields(Published);
        if not AccSchedKPIWebSrvSetup.Get() then
            exit;

        if AccSchedKPIWebSrvSetup.Published then begin
            OnDatabaseDelete := true;
            OnDatabaseInsert := true;
            OnDatabaseModify := true;
        end;
    end;

    internal procedure ResetAccSchedKPIWevSrvSetup()
    begin
        if not AccSchedKPIWebSrvSetup.Get() then
            exit;
        if AccSchedKPIWebSrvSetup."Last G/L Entry Included" = 0 then
            exit;
        AccSchedKPIWebSrvSetup.LockTable();
        AccSchedKPIWebSrvSetup.Get();
        AccSchedKPIWebSrvSetup."Last G/L Entry Included" := 0;
        AccSchedKPIWebSrvSetup."Data Last Updated" := 0DT;
        AccSchedKPIWebSrvSetup.Modify();
    end;

    local procedure ResetIfAccSchedChanged(AccSchedName: Code[10])
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        AccSchedKPIWebSrvSetup2: Record "Acc. Sched. KPI Web Srv. Setup";
        AccSchedKPIWebSrvLine: Record "Acc. Sched. KPI Web Srv. Line";
    begin
        if AccSchedName = PrevAccSchedName then
            exit;
        PrevAccSchedName := AccSchedName;
        if not AccSchedKPIWebSrvSetup2.WritePermission() then
            exit;
        if TempAccSchedKPIWebSrvLine.Get(AccSchedName) then begin
            ResetAccSchedKPIWevSrvSetup();
            exit;
        end;

        if AccSchedKPIWebSrvLine.Get(AccSchedName) then begin
            TempAccSchedKPIWebSrvLine := AccSchedKPIWebSrvLine;
            TempAccSchedKPIWebSrvLine.Insert();
            ResetAccSchedKPIWevSrvSetup();
        end;
    end;

    local procedure ResetIfGlBudgetChanged(GLBudgetEntryRecRef: RecordRef)
    var
        GLBudgetEntry: Record "G/L Budget Entry";
        [SecurityFiltering(SecurityFilter::Ignored)]
        AccSchedKPIWebSrvSetup2: Record "Acc. Sched. KPI Web Srv. Setup";
    begin
        GLBudgetEntryRecRef.SetTable(GLBudgetEntry);

        if GLBudgetEntry."Budget Name" = PrevGlBudgetName then
            exit;
        PrevGlBudgetName := GLBudgetEntry."Budget Name";
        if not AccSchedKPIWebSrvSetup2.WritePermission() then
            exit;
        if not AccSchedKPIWebSrvSetup.Get() then
            exit;
        if AccSchedKPIWebSrvSetup."G/L Budget Name" = '' then
            exit;
        if AccSchedKPIWebSrvSetup."G/L Budget Name" = GLBudgetEntry."Budget Name" then
            ResetAccSchedKPIWevSrvSetup();
    end;
}

