// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

#if not CLEAN30
using Microsoft.Bank.Reports;
#endif
using Microsoft.Utilities;
using System.Privacy;

codeunit 10847 "FR Financial Schedule Mgt."
{
    TableNo = "FR Financial Schedule Line";

    trigger OnRun()
    begin
    end;

    var
        DefaultScheduleNameTxt: Label 'DEFAULT';
        DefaultScheduleDescriptionTxt: Label 'Default Schedule';
        NotEnabledErr: Label 'Enable Reports FR before using French financial schedules.';
        MigrationRequiredErr: Label 'Migrate the legacy French financial schedules through the Reports FR feature data update before using this page or report.';
        MaintenanceRequiredErr: Label 'No French financial schedule exists. A user with financial schedule maintenance permission must create one.';

    procedure IsEnabled(): Boolean
    var
        Migration: Codeunit "FR Fin. Schedule Migration";
#if not CLEAN30
#pragma warning disable AL0432
        ReportsFR: Codeunit "Reports FR";
#pragma warning restore AL0432
#endif
    begin
        if Migration.IsMigrated() then
            exit(true);
#if not CLEAN30
        exit(ReportsFR.IsEnabled());
#else
        exit(true);
#endif
    end;

    procedure EnsureAvailable()
    var
        Migration: Codeunit "FR Fin. Schedule Migration";
    begin
        if not IsEnabled() then
            Error(NotEnabledErr);
        if not Migration.IsMigrated() then
            Error(MigrationRequiredErr);
    end;

    procedure ClassifyFinancialSchedules()
    var
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
    begin
        DataClassificationMgt.SetTableFieldsToNormal(Database::"FR Financial Schedule Name");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"FR Financial Schedule Line");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Class. Eval. Data Country", 'OnAfterClassifyCountrySpecificTables', '', false, false)]
    local procedure ClassifyCountryTables()
    begin
        ClassifyFinancialSchedules();
    end;

    procedure OpenSchedule(var CurrentSchedName: Code[10]; var AccSchedLine: Record "FR Financial Schedule Line")
    begin
        EnsureAvailable();
        CheckTemplateName(CurrentSchedName);
        AccSchedLine.FilterGroup(2);
        AccSchedLine.SetRange("Schedule Name", CurrentSchedName);
        AccSchedLine.FilterGroup(0);
    end;

    procedure CheckTemplateName(var CurrentSchedName: Code[10])
    var
        AccSchedName: Record "FR Financial Schedule Name";
    begin
        EnsureAvailable();
        if not AccSchedName.Get(CurrentSchedName) then begin
            if not AccSchedName.FindFirst() then begin
                if not AccSchedName.WritePermission() then
                    Error(MaintenanceRequiredErr);
                AccSchedName.Init();
                AccSchedName.Name := DefaultScheduleNameTxt;
                AccSchedName.Description := DefaultScheduleDescriptionTxt;
                AccSchedName.Insert();
            end;
            CurrentSchedName := AccSchedName.Name;
        end;
    end;

    procedure CheckName(CurrentSchedName: Code[10])
    var
        AccSchedName: Record "FR Financial Schedule Name";
    begin
        AccSchedName.Get(CurrentSchedName);
    end;

    procedure SetName(CurrentSchedName: Code[10]; var AccSchedLine: Record "FR Financial Schedule Line")
    begin
        AccSchedLine.FilterGroup(2);
        AccSchedLine.SetRange("Schedule Name", CurrentSchedName);
        AccSchedLine.FilterGroup(0);
        if AccSchedLine.Find('-') then;
    end;

    procedure LookupName(CurrentSchedName: Code[10]; var EntrdSchedName: Text): Boolean
    var
        AccSchedName: Record "FR Financial Schedule Name";
    begin
        AccSchedName.Name := CurrentSchedName;
        if PAGE.RunModal(0, AccSchedName) <> ACTION::LookupOK then
            exit(false);

        EntrdSchedName := AccSchedName.Name;
        exit(true);
    end;

#if not CLEAN30
#pragma warning disable AL0432
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FR AccSchedManagement", 'OnIsReportsFREnabled', '', false, false)]
    local procedure SetLegacyFeatureState(var Enabled: Boolean)
    begin
        Enabled := IsEnabled();
    end;

    [EventSubscriber(ObjectType::Page, Page::"FR Account Schedule Names", 'OnBeforeOpenFinancialScheduleNames', '', false, false)]
    local procedure OpenReplacementNames(ScheduleName: Record "FR Acc. Schedule Name"; var Handled: Boolean)
    var
        ReplacementName: Record "FR Financial Schedule Name";
        ReplacementPage: Page "FR Financial Schedule Names";
    begin
        if Handled or not IsEnabled() then
            exit;
        EnsureAvailable();
        ReplacementName.SetView(ScheduleName.GetView(false));
        ReplacementPage.SetTableView(ReplacementName);
        ReplacementPage.RunModal();
        Handled := true;
    end;

    [EventSubscriber(ObjectType::Page, Page::"FR Account Schedule", 'OnBeforeOpenFinancialSchedule', '', false, false)]
    local procedure OpenReplacementSchedule(ScheduleName: Code[10]; ScheduleLine: Record "FR Acc. Schedule Line"; var Handled: Boolean)
    var
        ReplacementLine: Record "FR Financial Schedule Line";
        ReplacementPage: Page "FR Financial Schedule";
    begin
        if Handled or not IsEnabled() then
            exit;
        EnsureAvailable();
        ReplacementLine.SetView(ScheduleLine.GetView(false));
        ReplacementPage.SetTableView(ReplacementLine);
        ReplacementPage.SetAccSchedName(ScheduleName);
        ReplacementPage.RunModal();
        Handled := true;
    end;
#pragma warning restore AL0432
#endif
}
