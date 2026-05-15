// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.PowerBIReports;

using Microsoft.Foundation.Company;
using System.Integration.PowerBI;

codeunit 36950 "Installation Handler"
{
    Access = Internal;
    Subtype = Install;

    var
        Initialization: Codeunit Initialization;

    trigger OnInstallAppPerCompany()
    begin
        Initialization.SetupDefaultsForPowerBIReportsIfNotInitialized();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure OnCompanyInitialize()
    begin
        Initialization.SetupDefaultsForPowerBIReportsIfNotInitialized();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PBI Deployment Events", 'OnAfterDeleteAllDeploymentRecords', '', false, false)]
    local procedure OnAfterDeleteAllDeploymentRecords(InCompany: Text[30])
    var
        PowerBIReportsSetup: Record "PowerBI Reports Setup";
        ReportSetup: Interface "PBI Report Setup";
        RecRef: RecordRef;
        EmptyGuid: Guid;
        Ordinal: Integer;
    begin
        if InCompany = '' then
            exit;
        if not PowerBIReportsSetup.ChangeCompany(InCompany) then
            exit;
        if not PowerBIReportsSetup.FindFirst() then
            exit;
        RecRef.GetTable(PowerBIReportsSetup);
        foreach Ordinal in Enum::"PBI Report Setup".Ordinals() do begin
            ReportSetup := Enum::"PBI Report Setup".FromInteger(Ordinal);
            RecRef.Field(ReportSetup.GetSetupReportIdFieldNo()).Value := EmptyGuid;
            RecRef.Field(ReportSetup.GetSetupReportNameFieldNo()).Value := '';
        end;
        RecRef.Modify();
    end;
}
