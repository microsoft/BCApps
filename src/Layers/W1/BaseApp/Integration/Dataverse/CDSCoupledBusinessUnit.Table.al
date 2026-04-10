// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

table 7201 "CDS Coupled Business Unit"
{
    Access = Internal;
    Caption = 'Dataverse Coupled Business Unit';
    DataPerCompany = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Company Id"; Guid)
        {
            Caption = 'Company ID';
            DataClassification = SystemMetadata;
            Editable = false;

            trigger OnValidate()
            var
                CDSCoupledBusinesUnit: Record "CDS Coupled Business Unit";
            begin
                CDSCoupledBusinesUnit.SetRange("Company Id", "Company Id");
                if CDSCoupledBusinesUnit.FindFirst() then
                    if SystemId <> CDSCoupledBusinesUnit.SystemId then begin
                        if not Confirm(CompanyAlreadyCoupledQst) then
                            Error('');
                        Session.LogMessage('0000DRI', CompanyAlreadyCoupledTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                    end;
            end;
        }
        field(2; "Business Unit Id"; Guid)
        {
            Caption = 'Business Unit ID';
            DataClassification = SystemMetadata;
            Editable = false;

            trigger OnValidate()
            var
                CDSCoupledBusinesUnit: Record "CDS Coupled Business Unit";
            begin
                CDSCoupledBusinesUnit.SetRange("Business Unit Id", "Business Unit Id");
                if CDSCoupledBusinesUnit.FindFirst() then
                    if SystemId <> CDSCoupledBusinesUnit.SystemId then begin
                        if not Confirm(BusinessUnitAlreadyCoupledQst) then
                            Error('');
                        Session.LogMessage('0000DRH', BusinessUnitAlreadyCoupledTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                    end;
            end;
        }
    }

    keys
    {
        key(Key1; "Company Id")
        {
            Clustered = true;
        }
        key(Key2; "Business Unit Id")
        {
        }
    }

    var
        BusinessUnitAlreadyCoupledQst: Label 'The specified business unit in Dataverse is coupled to another Business Central company. Coupling with multiple companies can cause synchronization errors.\\Do you want to continue anyway?';
        CompanyAlreadyCoupledQst: Label 'The specified Business Central company is coupled to another business unit in Dataverse. Coupling with multiple business units can cause synchronization errors.\\Do you want to continue anyway?';
        BusinessUnitAlreadyCoupledTxt: Label 'The specified business unit in Dataverse is coupled to another Business Central company.';
        CompanyAlreadyCoupledTxt: Label 'The specified Business Central company is coupled to another business unit in Dataverse.';
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;
}
