// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5371 "CDS Available Virtual Table"
{
    ExternalName = 'dyn365bc_businesscentralentity';
    TableType = CRM;
    Description = 'Contains available Business Central tables in Dataverse.';
    Extensible = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; mserp_businesscentralentityId; GUID)
        {
            ExternalName = 'dyn365bc_businesscentralentityid';
            ExternalType = 'Uniqueidentifier';
            ExternalAccess = Insert;
            Description = 'Unique identifier for table instances';
            Caption = 'Business Central Table';
            DataClassification = SystemMetadata;
        }
        field(2; mserp_physicalname; Text[100])
        {
            ExternalName = 'dyn365bc_physicalname';
            ExternalType = 'String';
            Description = 'The name of the custom table.';
            Caption = 'Name';
            DataClassification = SystemMetadata;
        }
        field(3; mserp_apiroute; Text[100])
        {
            ExternalName = 'dyn365bc_apiroute';
            ExternalType = 'String';
            Description = '';
            Caption = 'API Route';
            DataClassification = SystemMetadata;
        }
        field(4; mserp_cdsentitylogicalname; Text[100])
        {
            ExternalName = 'dyn365bc_cdsentitylogicalname';
            ExternalType = 'String';
            Description = '';
            Caption = 'Dataverse Table Logical Name';
            DataClassification = SystemMetadata;
        }
        field(5; mserp_displayname; Text[200])
        {
            ExternalName = 'dyn365bc_displayname';
            ExternalType = 'String';
            ExternalAccess = Insert;
            Description = 'The display name of the custom table in the current language.';
            Caption = 'Display Name';
            DataClassification = SystemMetadata;
        }
        field(6; mserp_hasbeengenerated; Boolean)
        {
            ExternalName = 'dyn365bc_hasbeengenerated';
            ExternalType = 'Boolean';
            Description = '';
            Caption = 'Visible';
            DataClassification = SystemMetadata;
        }
        field(7; mserp_refresh; Boolean)
        {
            ExternalName = 'dyn365bc_refresh';
            ExternalType = 'Boolean';
            Description = '';
            Caption = 'Refresh';
            DataClassification = SystemMetadata;
        }
    }
    keys
    {
        key(PK; mserp_businesscentralentityId)
        {
            Clustered = true;
        }
        key(Name; mserp_physicalname)
        {
        }
    }
    fieldgroups
    {
        fieldgroup(DropDown; mserp_physicalname)
        {
        }
    }
}