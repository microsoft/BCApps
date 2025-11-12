// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 7207 "CRM BC Virtual Table Config."
{
    ExternalName = 'msdyn_businesscentralvirtualentity';
    TableType = CRM;
    Description = 'CRM Virtual Table Configuration';
    Access = Internal;
    DataClassification = CustomerContent;

    fields
    {
        field(1; msdyn_businesscentralvirtualentityId; GUID)
        {
            ExternalName = 'msdyn_businesscentralvirtualentityid';
            ExternalType = 'Uniqueidentifier';
            ExternalAccess = Insert;
            Description = 'Unique identifier for table instances';
            Caption = 'Business Central Virtual Table';
        }
        field(2; msdyn_name; Text[100])
        {
            ExternalName = 'msdyn_name';
            ExternalType = 'String';
            Caption = 'Name';
        }
        field(3; msdyn_environment; Text[100])
        {
            ExternalName = 'msdyn_environment';
            ExternalType = 'String';
            Description = '';
            Caption = 'Environment';
        }
        field(4; msdyn_apimanagedprefix; Text[8])
        {
            ExternalName = 'msdyn_apimanagedprefix';
            ExternalType = 'String';
            ExternalAccess = Insert;
            Description = '';
            Caption = 'API Managed Prefix';
        }
        field(5; msdyn_apimanagedsolutionname; Text[50])
        {
            ExternalName = 'msdyn_apimanagedsolutionname';
            ExternalType = 'String';
            ExternalAccess = Insert;
            Description = '';
            Caption = 'API Managed Solution Name';
        }
        field(6; msdyn_DefaultCompanyId; GUID)
        {
            ExternalName = 'msdyn_defaultcompanyid';
            ExternalType = 'Lookup';
            Description = 'Unique identifier for Company associated with Business Central Virtual Data Source Configuration.';
            Caption = 'Default Company';
            TableRelation = "CRM Company".cdm_companyId;
        }
        field(7; msdyn_targethost; Text[255])
        {
            ExternalName = 'msdyn_targethost';
            ExternalType = 'String';
            Description = '';
            Caption = 'Target Host';
        }
        field(8; msdyn_odataauthorizationheader; Text[100])
        {
            ExternalName = 'msdyn_odataauthorizationheader';
            ExternalType = 'String';
            Description = '';
            Caption = 'Authorization header (debug)';
        }
        field(9; msdyn_tenantid; Text[150])
        {
            ExternalName = 'msdyn_tenantid';
            ExternalType = 'String';
            Description = '';
            Caption = 'Tenant ID';
        }
        field(10; msdyn_DefaultCompanyIdName; Text[30])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("CrM Company".cdm_CompanyCode where(cdm_companyId = field(msdyn_DefaultCompanyId)));
            ExternalName = 'msdyn_defaultcompanyidname';
            ExternalType = 'String';
            ExternalAccess = Read;
        }
        field(11; msdyn_aadUserId; Text[150])
        {
            ExternalName = 'msdyn_aadUserId';
            ExternalType = 'String';
            Description = '';
            Caption = 'Microsoft Entra user ID';
        }
    }
    keys
    {
        key(PK; msdyn_businesscentralvirtualentityId)
        {
            Clustered = true;
        }
        key(Name; msdyn_name)
        {
        }
    }
    fieldgroups
    {
        fieldgroup(DropDown; msdyn_name)
        {
        }
    }
}