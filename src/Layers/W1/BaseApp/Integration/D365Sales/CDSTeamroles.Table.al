// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5396 "CDS Teamroles"
{
    // Dynamics CRM Version: 9.1.0.10123

    ExternalName = 'teamroles';
    ExternalSchema = 'teamroles_association';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; TeamRoleId; Guid)
        {
            Description = 'For internal use only.';
            ExternalAccess = Insert;
            ExternalName = 'teamroleid';
            ExternalType = 'Uniqueidentifier';
            DataClassification = SystemMetadata;
        }
        field(2; RoleId; Guid)
        {
            ExternalAccess = Read;
            ExternalName = 'roleid';
            ExternalType = 'Uniqueidentifier';
            TableRelation = "CRM Role";
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(3; VersionNumber; BigInteger)
        {
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
            DataClassification = SystemMetadata;
        }
        field(4; TeamId; Guid)
        {
            ExternalAccess = Read;
            ExternalName = 'teamid';
            ExternalType = 'Uniqueidentifier';
            TableRelation = "CRM Team";
            DataClassification = EndUserPseudonymousIdentifiers;
        }
    }

    keys
    {
        key(Key1; TeamRoleId)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

