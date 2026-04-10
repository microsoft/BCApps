// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5397 "CDS Teammembership"
{
    // Dynamics CRM Version: 9.1.0.10123

    ExternalName = 'teammembership';
    ExternalSchema = 'teammembership_association';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; TeamMembershipId; Guid)
        {
            Description = 'For internal use only.';
            ExternalAccess = Insert;
            ExternalName = 'teammembershipid';
            ExternalType = 'Uniqueidentifier';
            DataClassification = SystemMetadata;
        }
        field(2; TeamId; Guid)
        {
            ExternalAccess = Read;
            ExternalName = 'teamid';
            ExternalType = 'Uniqueidentifier';
            TableRelation = "CRM Team";
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(3; SystemUserId; Guid)
        {
            ExternalAccess = Read;
            ExternalName = 'systemuserid';
            ExternalType = 'Uniqueidentifier';
            TableRelation = "CRM Systemuser";
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(4; VersionNumber; BigInteger)
        {
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; TeamMembershipId)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

