// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Integration.D365Sales;

table 5398 "CDS Field Security Profile"
{
    ExternalName = 'fieldsecurityprofile';
    TableType = CRM;
    Description = 'Profile which defines access level for secured attributes';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Description; BLOB)
        {
            ExternalName = 'description';
            ExternalType = 'Memo';
            Description = 'Description of the Profile';
            Caption = 'Description';
            Subtype = Memo;
            DataClassification = SystemMetadata;
        }
        field(3; FieldSecurityProfileId; GUID)
        {
            ExternalName = 'fieldsecurityprofileid';
            ExternalType = 'Uniqueidentifier';
            ExternalAccess = Insert;
            Description = 'Unique identifier of the profile.';
            Caption = 'Field Security Profile';
            DataClassification = SystemMetadata;
        }
        field(4; CreatedBy; GUID)
        {
            ExternalName = 'createdby';
            ExternalType = 'Lookup';
            ExternalAccess = Read;
            Description = 'Unique identifier of the user who created the profile.';
            Caption = 'Created By';
            TableRelation = "CRM Systemuser".SystemUserId;
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(7; CreatedOn; Datetime)
        {
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
            ExternalAccess = Read;
            Description = 'Date and time when the profile was created.';
            Caption = 'Created On';
            DataClassification = SystemMetadata;
        }
        field(8; CreatedOnBehalfBy; GUID)
        {
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            ExternalAccess = Read;
            Description = 'Unique identifier of the delegate user who created the role.';
            Caption = 'Created By Impersonator';
            TableRelation = "CRM Systemuser".SystemUserId;
            DataClassification = SystemMetadata;
        }
        field(11; ModifiedBy; GUID)
        {
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            ExternalAccess = Read;
            Description = 'Unique identifier of the user who last modified the profile.';
            Caption = 'Modified By';
            TableRelation = "CRM Systemuser".SystemUserId;
            DataClassification = SystemMetadata;
        }
        field(14; ModifiedOn; Datetime)
        {
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
            ExternalAccess = Read;
            Description = 'Date and time when the profile was last modified.';
            Caption = 'Modified On';
            DataClassification = SystemMetadata;
        }
        field(15; ModifiedOnBehalfBy; GUID)
        {
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            ExternalAccess = Read;
            Description = 'Unique identifier of the delegate user who last modified the profile.';
            Caption = 'Modified By (Delegate)';
            TableRelation = "CRM Systemuser".SystemUserId;
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(18; Name; Text[100])
        {
            ExternalName = 'name';
            ExternalType = 'String';
            Description = 'Name of the profile.';
            Caption = 'Name';
            DataClassification = SystemMetadata;
        }
        field(20; SolutionId; GUID)
        {
            ExternalName = 'solutionid';
            ExternalType = 'Uniqueidentifier';
            ExternalAccess = Read;
            Description = 'Unique identifier of the associated solution.';
            Caption = 'Solution';
            DataClassification = SystemMetadata;
        }
        field(22; OverwriteTime; Date)
        {
            ExternalName = 'overwritetime';
            ExternalType = 'DateTime';
            ExternalAccess = Read;
            Description = 'For internal use only.';
            Caption = 'Record Overwrite Time';
            DataClassification = SystemMetadata;
        }
        field(23; ComponentState; Option)
        {
            ExternalName = 'componentstate';
            ExternalType = 'Picklist';
            ExternalAccess = Read;
            Description = 'For internal use only.';
            Caption = 'Component State';
            InitValue = " ";
            OptionMembers = " ",Published,Unpublished,Deleted,DeletedUnpublished;
            OptionOrdinalValues = -1, 0, 1, 2, 3;
            DataClassification = SystemMetadata;
        }
        field(24; FieldSecurityProfileIdUnique; GUID)
        {
            ExternalName = 'fieldsecurityprofileidunique';
            ExternalType = 'Uniqueidentifier';
            ExternalAccess = Read;
            Description = 'For internal use only.';
            Caption = 'Field Security Profile';
            DataClassification = SystemMetadata;
        }
        field(25; VersionNumber; BigInteger)
        {
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
            ExternalAccess = Read;
            DataClassification = SystemMetadata;
        }
        field(26; OrganizationId; GUID)
        {
            ExternalName = 'organizationid';
            ExternalType = 'Lookup';
            ExternalAccess = Read;
            Description = 'Unique identifier of the associated organization.';
            Caption = 'Organization';
            TableRelation = "CRM Organization".OrganizationId;
            DataClassification = SystemMetadata;
        }
        field(28; IsManaged; Boolean)
        {
            ExternalName = 'ismanaged';
            ExternalType = 'Boolean';
            ExternalAccess = Read;
            Description = 'Indicates whether the solution component is part of a managed solution.';
            Caption = 'Is Managed';
            DataClassification = SystemMetadata;
        }
    }
    keys
    {
        key(PK; FieldSecurityProfileId)
        {
            Clustered = true;
        }
        key(Name; Name)
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
