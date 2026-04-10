// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5394 "CDS Solution"
{
    // Dynamics CRM Version: 9.1.0.10123

    Caption = 'Solution';
    Description = 'A solution which contains CRM customizations.';
    ExternalName = 'solution';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; VersionNumber; BigInteger)
        {
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(2; SolutionId; Guid)
        {
            Caption = 'Solution Identifier';
            Description = 'Unique identifier of the solution.';
            ExternalAccess = Insert;
            ExternalName = 'solutionid';
            ExternalType = 'Uniqueidentifier';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(3; InstalledOn; DateTime)
        {
            Caption = 'Installed On';
            Description = 'Date and time when the solution was installed/upgraded.';
            ExternalAccess = Read;
            ExternalName = 'installedon';
            ExternalType = 'DateTime';
            DataClassification = SystemMetadata;
        }
        field(4; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            Description = 'Date and time when the solution was created.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
            DataClassification = SystemMetadata;
        }
        field(5; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            Description = 'Date and time when the solution was last modified.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
            DataClassification = SystemMetadata;
        }
        field(6; IsVisible; Boolean)
        {
            Caption = 'Is Visible Outside Platform';
            Description = 'Indicates whether the solution is visible outside of the platform.';
            ExternalAccess = Read;
            ExternalName = 'isvisible';
            ExternalType = 'Boolean';
            DataClassification = SystemMetadata;
        }
        field(7; Description; Text[250])
        {
            Caption = 'Description';
            Description = 'Description of the solution.';
            ExternalName = 'description';
            ExternalType = 'String';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(8; IsManaged; Boolean)
        {
            Caption = 'Package Type';
            Description = 'Indicates whether the solution is managed or unmanaged.';
            ExternalAccess = Read;
            ExternalName = 'ismanaged';
            ExternalType = 'Boolean';
            DataClassification = SystemMetadata;
        }
        field(9; UniqueName; Text[65])
        {
            Caption = 'Name';
            Description = 'The unique name of this solution';
            ExternalAccess = Insert;
            ExternalName = 'uniquename';
            ExternalType = 'String';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(10; FriendlyName; Text[250])
        {
            Caption = 'Display Name';
            Description = 'User display name for the solution.';
            ExternalName = 'friendlyname';
            ExternalType = 'String';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(11; Version; Text[250])
        {
            Caption = 'Version';
            Description = 'Solution version, used to identify a solution for upgrades and hotfixes.';
            ExternalName = 'version';
            ExternalType = 'String';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(12; PinpointSolutionId; BigInteger)
        {
            Description = 'Identifier of the solution in Microsoft Pinpoint.';
            ExternalAccess = Read;
            ExternalName = 'pinpointsolutionid';
            ExternalType = 'BigInt';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(13; PinpointSolutionDefaultLocale; Text[16])
        {
            Description = 'Default locale of the solution in Microsoft Pinpoint.';
            ExternalAccess = Read;
            ExternalName = 'pinpointsolutiondefaultlocale';
            ExternalType = 'String';
            DataClassification = SystemMetadata;
        }
        field(14; PinpointPublisherId; BigInteger)
        {
            Description = 'Identifier of the publisher of this solution in Microsoft Pinpoint.';
            ExternalAccess = Read;
            ExternalName = 'pinpointpublisherid';
            ExternalType = 'BigInt';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(15; PinpointAssetId; Text[250])
        {
            ExternalAccess = Read;
            ExternalName = 'pinpointassetid';
            ExternalType = 'String';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(16; SolutionPackageVersion; Text[250])
        {
            Caption = 'Solution Package Version';
            Description = 'Solution package source organization version';
            ExternalName = 'solutionpackageversion';
            ExternalType = 'String';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(17; ParentSolutionId; Guid)
        {
            Caption = 'Parent Solution';
            Description = 'Unique identifier of the parent solution. Should only be non-null if this solution is a patch.';
            ExternalAccess = Read;
            ExternalName = 'parentsolutionid';
            ExternalType = 'Lookup';
            TableRelation = "CDS Solution".SolutionId;
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(18; SolutionType; Option)
        {
            Caption = 'Solution Type';
            Description = 'Solution Type';
            ExternalAccess = Insert;
            ExternalName = 'solutiontype';
            ExternalType = 'Picklist';
            InitValue = "None";
            OptionCaption = 'None,Snapshot,Internal';
            OptionOrdinalValues = 0, 1, 2;
            OptionMembers = "None",Snapshot,Internal;
            DataClassification = SystemMetadata;
        }
        field(19; UpdatedOn; DateTime)
        {
            Caption = 'Updated On';
            Description = 'Date and time when the solution was updated.';
            ExternalAccess = Read;
            ExternalName = 'updatedon';
            ExternalType = 'DateTime';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; SolutionId)
        {
            Clustered = true;
        }
        key(Key2; FriendlyName)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; FriendlyName)
        {
        }
    }
}

