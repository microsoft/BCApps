// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// The interface for running database activity monitor.
/// </summary>
codeunit 6282 "Database Activity Monitor Impl"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure Start()
    begin
        SetDatabaseActivityMonitor(true);
        Commit();
    end;

    procedure Stop()
    begin
        SetDatabaseActivityMonitor(false);
        Commit();
    end;

    procedure IsMonitorActive(): Boolean
    begin
        exit(GetDatabaseActivityMonitor());
    end;

    procedure IsMonitoringTable(TableId: Integer): Boolean
    var
        DatabaseActivityMonitorSetup: Record "Database Act. Monitor Setup";
        DatabaseActMonitorLine: Record "Database Act. Monitor Line";
    begin
        if DatabaseActivityMonitorSetup.Get() then begin
            if DatabaseActivityMonitorSetup."Log All Tables" then
                exit(true);

            exit(DatabaseActMonitorLine.Get(TableId));
        end;

        exit(false);
    end;

    procedure IsInitialized(): Boolean
    var
        DatabaseActivityLog: Record "Database Activity Log";
    begin
        exit(not DatabaseActivityLog.IsEmpty());
    end;

    procedure ClearLog()
    var
        DatabaseActivityLog: Record "Database Activity Log";
    begin
        DatabaseActivityLog.DeleteAll();
    end;

    procedure GetDatabaseActivityMonitor(): Boolean;
    var
        DatabaseActivityMonitorSetup: Record "Database Act. Monitor Setup";
        IsActive: Boolean;
    begin
        IsActive := false;

        if DatabaseActivityMonitorSetup.Get() then
            IsActive := DatabaseActivityMonitorSetup."Monitor Active"
        else begin
            DatabaseActivityMonitorSetup.Init();
            DatabaseActivityMonitorSetup.Validate("Monitor Active", IsActive);
            DatabaseActivityMonitorSetup.Insert(true);
        end;

        exit(IsActive);
    end;

    /*
         trigger OnClosePage()
        begin
            if ChangeLogSettingsUpdated then
                if Confirm(RestartSessionQst) then
                    RestartSession();
        end;

        local procedure ConfirmActivationOfChangeLog()
        var
            EnvironmentInfo: Codeunit "Environment Information";
            ConfirmManagement: Codeunit "Confirm Management";
        begin
            if not Rec."Change Log Activated" then
                exit;
            if not EnvironmentInfo.IsSaaS() then
                exit;
            if not ConfirmManagement.GetResponseOrDefault(ActivateChangeLogQst, true) then
                Error('');
        end;
        
    local procedure RestartSession()
    var
        SessionSetting: SessionSettings;
    begin
        SessionSetting.Init();
        SessionSetting.RequestSessionUpdate(false);
    end;
        
    var
        ActivateChangeLogQst: Label 'Turning on Database Activity Monitor will slow things down, especially if you are monitoring all tables. Do you want to start?';
        RestartSessionQst: Label 'Changes are displayed on the Change Log Entries page after the user''s session has restarted. Do you want to restart the session now?';
        ChangeLogSettingsUpdated: Boolean;
        */


    procedure SetDatabaseActivityMonitor(DatabaseActivityMonitorActivated: Boolean): Boolean;
    var
        DatabaseActivityMonitorSetup: Record "Database Act. Monitor Setup";
        OldValue: Boolean;
    begin
        OldValue := false;

        if DatabaseActivityMonitorSetup.Get() then begin
            OldValue := DatabaseActivityMonitorSetup."Monitor Active";
            DatabaseActivityMonitorSetup.Validate("Monitor Active", DatabaseActivityMonitorActivated);
            DatabaseActivityMonitorSetup.Modify(true);
        end else begin
            DatabaseActivityMonitorSetup.Validate("Monitor Active", DatabaseActivityMonitorActivated);
            DatabaseActivityMonitorSetup.Insert(true);
            Commit();
        end;

        exit(OldValue);
    end;

}