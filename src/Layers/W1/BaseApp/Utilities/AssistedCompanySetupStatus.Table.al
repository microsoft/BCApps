// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AS0002
namespace Microsoft.Utilities;
using System.Environment;

table 1802 "Assisted Company Setup Status"
{
    Caption = 'Assisted Company Setup Status';
    DataPerCompany = false;
    ReplicateData = false;
#pragma warning disable AS0034
    InherentEntitlements = rX;
    InherentPermissions = rX;
#pragma warning restore AS0034
    Permissions = tabledata "Assisted Company Setup Status" = r;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            TableRelation = Company;
        }
        field(2; Enabled; Boolean)
        {
            Caption = 'Enabled';

            trigger OnValidate()
            begin
                OnEnabled("Company Name", Enabled);
            end;
        }
#pragma warning disable AS0072, AS0115
        field(3; "Package Imported"; Boolean)
        {
            Caption = 'Package Imported';
            ObsoleteTag = '25.2';
            ObsoleteReason = 'Changing the way demo data is generated, for more infromation see https://go.microsoft.com/fwlink/?linkid=2288084';
            ObsoleteState = Removed;
        }
        field(4; "Import Failed"; Boolean)
        {
            Caption = 'Import Failed';
            ObsoleteTag = '25.2';
            ObsoleteReason = 'Changing the way demo data is generated, for more infromation see https://go.microsoft.com/fwlink/?linkid=2288084';
            ObsoleteState = Removed;
        }
#pragma warning restore AS0072, AS0115
        field(5; "Company Setup Session ID"; Integer)
        {
            Caption = 'Company Setup Session ID';
        }
        field(6; "Task ID"; Guid)
        {
            Caption = 'Task ID';
        }
        field(7; "Server Instance ID"; Integer)
        {
            Caption = 'Server Instance ID';
            DataClassification = SystemMetadata;
        }
        field(8; "Company Demo Data"; Enum "Company Demo Data Type")
        {
            Caption = 'Company Demo Data';
            DataClassification = SystemMetadata;
        }
    }
    keys
    {
        key(Key1; "Company Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure GetCompanySetupStatusValue(Name: Text[30]) SetupStatus: Enum "Company Setup Status"
    begin
        if "Company Name" <> Name then
            if not Get(Name) then
                exit(Enum::"Company Setup Status"::" ");
        OnGetCompanySetupStatusValue("Company Name", SetupStatus);
    end;

    procedure DrillDownSetupStatus(Name: Text[30])
    begin
        if Get(Name) then
            OnSetupStatusDrillDown("Company Name");
    end;

    procedure SetEnabled(CompanyName: Text[30]; Enable: Boolean; ResetState: Boolean)
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
    begin
        if not AssistedCompanySetupStatus.Get(CompanyName) then begin
            AssistedCompanySetupStatus.Init();
            AssistedCompanySetupStatus.Validate("Company Name", CompanyName);
            AssistedCompanySetupStatus.Validate(Enabled, Enable);
            AssistedCompanySetupStatus.Insert();
        end else begin
            AssistedCompanySetupStatus.Validate(Enabled, Enable);
            AssistedCompanySetupStatus.Modify();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEnabled(SetupCompanyName: Text[30]; AssistedSetupEnabled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCompanySetupStatusValue(Name: Text[30]; var SetupStatus: Enum "Company Setup Status")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetupStatusDrillDown(Name: Text[30])
    begin
    end;

    procedure CopySaaSCompanySetupStatus(CompanyNameFrom: Text[30]; CompanyNameTo: Text[30])
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if not EnvironmentInfo.IsSaaS() then
            exit;

        if AssistedCompanySetupStatus.GetCompanySetupStatusValue(CompanyNameFrom) = Enum::"Company Setup Status"::Completed then begin
            AssistedCompanySetupStatus.Init();
            AssistedCompanySetupStatus."Company Name" := CompanyNameTo;
            if AssistedCompanySetupStatus.Insert() then;
        end;
    end;
}
#pragma warning restore AS0002
