// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5389 "CRM Role"
{
    // Dynamics CRM Version: 9.1.0.1450

    Caption = 'Security Role';
    Description = 'Grouping of security privileges. Users are assigned roles that authorize their access to the Microsoft CRM system.';
    ExternalName = 'role';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; RoleId; Guid)
        {
            Caption = 'Role';
            DataClassification = SystemMetadata;
            Description = 'Unique identifier of the role.';
            ExternalAccess = Insert;
            ExternalName = 'roleid';
            ExternalType = 'Uniqueidentifier';
        }
        field(2; OrganizationId; Guid)
        {
            Caption = 'Organization';
            DataClassification = SystemMetadata;
            Description = 'Unique identifier of the organization associated with the role.';
            ExternalAccess = Read;
            ExternalName = 'organizationid';
            ExternalType = 'Uniqueidentifier';
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
            DataClassification = SystemMetadata;
            Description = 'Name of the role.';
            ExternalName = 'name';
            ExternalType = 'String';
        }
        field(4; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            DataClassification = SystemMetadata;
            Description = 'Date and time when the role was created.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(5; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            DataClassification = SystemMetadata;
            Description = 'Date and time when the role was last modified.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
        }
        field(6; VersionNumber; BigInteger)
        {
            Caption = 'Version number';
            DataClassification = SystemMetadata;
            Description = 'Version number of the role.';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(7; ParentRoleId; Guid)
        {
            Caption = 'Parent Role';
            DataClassification = SystemMetadata;
            Description = 'Unique identifier of the parent role.';
            ExternalAccess = Read;
            ExternalName = 'parentroleid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Role".RoleId;
        }
        field(8; OverriddenCreatedOn; DateTime)
        {
            Caption = 'Record Created On';
            DataClassification = SystemMetadata;
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
        }
        field(9; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            DataClassification = SystemMetadata;
            Description = 'Unique identifier of the data import or data migration that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
        }
        field(10; OverwriteTime; DateTime)
        {
            Caption = 'Record Overwrite Time';
            DataClassification = SystemMetadata;
            Description = 'For internal use only.';
            ExternalAccess = Read;
            ExternalName = 'overwritetime';
            ExternalType = 'DateTime';
        }
        field(11; ComponentState; Option)
        {
            Caption = 'Component State';
            DataClassification = SystemMetadata;
            Description = 'For internal use only.';
            ExternalAccess = Read;
            ExternalName = 'componentstate';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Published,Unpublished,Deleted,Deleted Unpublished';
            OptionOrdinalValues = -1, 0, 1, 2, 3;
            OptionMembers = " ",Published,Unpublished,Deleted,DeletedUnpublished;
        }
        field(12; SolutionId; Guid)
        {
            Caption = 'Solution';
            DataClassification = SystemMetadata;
            Description = 'Unique identifier of the associated solution.';
            ExternalAccess = Read;
            ExternalName = 'solutionid';
            ExternalType = 'Uniqueidentifier';
        }
        field(13; RoleIdUnique; Guid)
        {
            Caption = 'Unique Id';
            DataClassification = SystemMetadata;
            Description = 'For internal use only.';
            ExternalAccess = Read;
            ExternalName = 'roleidunique';
            ExternalType = 'Uniqueidentifier';
        }
        field(14; ParentRootRoleId; Guid)
        {
            Caption = 'Parent Root Role';
            DataClassification = SystemMetadata;
            Description = 'Unique identifier of the parent root role.';
            ExternalAccess = Read;
            ExternalName = 'parentrootroleid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Role".RoleId;
        }
        field(15; IsManaged; Boolean)
        {
            Caption = 'State';
            DataClassification = SystemMetadata;
            Description = 'Indicates whether the solution component is part of a managed solution.';
            ExternalAccess = Read;
            ExternalName = 'ismanaged';
            ExternalType = 'Boolean';
        }
        field(16; RoleTemplateId; Guid)
        {
            Caption = 'Role Template ID';
            DataClassification = SystemMetadata;
            Description = 'Unique identifier of the role template that is associated with the role.';
            ExternalAccess = Read;
            ExternalName = 'roletemplateid';
            ExternalType = 'Lookup';
        }
        field(17; BusinessUnitId; Guid)
        {
            Caption = 'Business Unit';
            Description = 'Unique identifier of the business unit with which the role is associated.';
            ExternalName = 'businessunitid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Businessunit".BusinessUnitId;
            DataClassification = OrganizationIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; RoleId)
        {
            Clustered = true;
        }
        key(Key2; Name)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Name)
        {
        }
    }
}

