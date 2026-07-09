// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Payroll;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Utilities;
using System.Environment;
using System.Environment.Configuration;
using System.Security.AccessControl;

/// <summary>
/// Manages payroll service registration, selection, and import orchestration.
/// Provides centralized payroll service management with guided setup support.
/// </summary>
/// <remarks>
/// Integrates with Service Connections for payroll service discovery and management.
/// Extensibility: OnRegisterPayrollService, OnImportPayroll events for custom payroll providers.
/// </remarks>
codeunit 1660 "Payroll Management"
{
    Permissions = TableData User = rimd;

    trigger OnRun()
    begin
    end;

    var
        PayrollServiceNotFoundErr: Label 'A payroll service could not be found.';
        PayrollServiceDisabledErr: Label 'Payroll service %1 is disabled.', Comment = '%1 Payroll Service Name';
        SelectPayrollServiceToUseTxt: Label 'Several payroll services are installed and enabled. Select a service you want to use.';
        SelectPayrollServiceToEnableTxt: Label 'Select a payroll service you want to enable and use.';
        EnablePayrollServicesQst: Label 'All payroll services are disabled. Do you want to enable a payroll service?';

    /// <summary>
    /// Determines payroll visibility based on environment type for testing purposes.
    /// </summary>
    /// <returns>True if payroll should be visible in current environment</returns>
    procedure ShowPayrollForTestInNonSaas(): Boolean
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if EnvironmentInfo.IsSaaS() then
            exit(true);
        exit(false);
    end;

    /// <summary>
    /// Initiates payroll import process with service discovery and selection.
    /// Handles service registration, enablement, and import orchestration.
    /// </summary>
    /// <param name="GenJournalLine">Target journal line for payroll data import</param>
    procedure ImportPayroll(var GenJournalLine: Record "Gen. Journal Line")
    var
        TempServiceConnection: Record "Service Connection" temporary;
    begin
        TempServiceConnection.DeleteAll();
        OnRegisterPayrollService(TempServiceConnection);

        if TempServiceConnection.IsEmpty() then
            Error(PayrollServiceNotFoundErr);

        if not EnabledPayrollServiceExists(TempServiceConnection) then
            if Confirm(EnablePayrollServicesQst) then
                EnablePayrollService(TempServiceConnection)
            else
                exit;

        if EnabledPayrollServiceExists(TempServiceConnection) then
            if SelectPayrollService(TempServiceConnection, SelectPayrollServiceToUseTxt) then
                OnImportPayroll(TempServiceConnection, GenJournalLine);
    end;

    local procedure EnabledPayrollServiceExists(var TempServiceConnection: Record "Service Connection" temporary): Boolean
    begin
        TempServiceConnection.SetFilter(
          Status, StrSubstNo('%1|%2', TempServiceConnection.Status::Enabled, TempServiceConnection.Status::Connected));
        exit(TempServiceConnection.FindSet());
    end;

    local procedure EnablePayrollService(var TempServiceConnection: Record "Service Connection" temporary)
    var
        SelectedServiceRecordId: RecordID;
        SelectedServiceName: Text;
    begin
        TempServiceConnection.Reset();
        if SelectPayrollService(TempServiceConnection, SelectPayrollServiceToEnableTxt) then begin
            SelectedServiceRecordId := TempServiceConnection."Record ID";
            SelectedServiceName := TempServiceConnection.Name;
            SetupPayrollService(TempServiceConnection);
            TempServiceConnection.DeleteAll();
            OnRegisterPayrollService(TempServiceConnection);
            if not TempServiceConnection.IsEmpty() then begin
                TempServiceConnection.SetRange("Record ID", SelectedServiceRecordId);
                if not EnabledPayrollServiceExists(TempServiceConnection) then
                    Error(PayrollServiceDisabledErr, SelectedServiceName);
            end else
                Error(PayrollServiceNotFoundErr);
        end;
    end;

    local procedure SelectPayrollService(var TempServiceConnection: Record "Service Connection" temporary; Instruction: Text): Boolean
    var
        ServiceList: Text;
        SelectedServiceIndex: Integer;
    begin
        if TempServiceConnection.Count < 2 then
            exit(TempServiceConnection.FindFirst());

        TempServiceConnection.SetCurrentKey(Name);
        TempServiceConnection.SetAscending(Name, true);
        TempServiceConnection.FindFirst();
        repeat
            if ServiceList = '' then
                ServiceList := ConvertStr(TempServiceConnection.Name, ',', ' ')
            else
                ServiceList := ServiceList + ',' + ConvertStr(TempServiceConnection.Name, ',', ' ');
        until TempServiceConnection.Next() = 0;
        SelectedServiceIndex := StrMenu(ServiceList, 1, Instruction);

        if SelectedServiceIndex > 0 then begin
            TempServiceConnection.FindFirst();
            if SelectedServiceIndex > 1 then
                TempServiceConnection.Next(SelectedServiceIndex - 1);
        end;
        exit(SelectedServiceIndex > 0);
    end;

    local procedure SetupPayrollService(var TempServiceConnection: Record "Service Connection" temporary)
    var
        GuidedExperience: Codeunit "Guided Experience";
        RecordRef: RecordRef;
        RecordRefVariant: Variant;
        GuidedExperienceType: Enum "Guided Experience Type";
    begin
        RecordRef.Get(TempServiceConnection."Record ID");
        if (TempServiceConnection.Status <> TempServiceConnection.Status::Enabled) and
           (TempServiceConnection.Status <> TempServiceConnection.Status::Connected) and
           (TempServiceConnection."Assisted Setup Page ID" <> 0) and
           (GuidedExperience.AssistedSetupExistsAndIsNotComplete(ObjectType::Page, TempServiceConnection."Assisted Setup Page ID"))
        then
            GuidedExperience.Run(GuidedExperienceType::"Assisted Setup", ObjectType::Page, TempServiceConnection."Assisted Setup Page ID")
        else begin
            RecordRefVariant := RecordRef;
            PAGE.RunModal(TempServiceConnection."Page ID", RecordRefVariant);
        end;
    end;

    /// <summary>
    /// Allows payroll service providers to register their services for discovery.
    /// </summary>
    /// <param name="TempServiceConnection">Service connection record for registration</param>
    [IntegrationEvent(false, false)]
    procedure OnRegisterPayrollService(var TempServiceConnection: Record "Service Connection" temporary)
    begin
    end;

    /// <summary>
    /// Enables payroll service providers to implement custom import logic.
    /// </summary>
    /// <param name="TempServiceConnection">Selected service connection for import</param>
    /// <param name="GenJournalLine">Target journal line for imported data</param>
    [IntegrationEvent(false, false)]
    procedure OnImportPayroll(var TempServiceConnection: Record "Service Connection" temporary; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}

