// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5388 "CRM Post Configuration"
{
    // Dynamics CRM Version: 9.1.0.1096

    Caption = 'Post Configuration';
    Description = 'Enable or disable entities for Activity Feeds and Yammer collaboration.';
    ExternalName = 'msdyn_postconfig';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; msdyn_PostConfigId; Guid)
        {
            Caption = 'Post Configuration';
            DataClassification = SystemMetadata;
            Description = 'Unique identifier of the post configuration for this rule.';
            ExternalAccess = Insert;
            ExternalName = 'msdyn_postconfigid';
            ExternalType = 'Uniqueidentifier';
        }
        field(2; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            DataClassification = SystemMetadata;
            Description = 'Date and time when the record was created.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(3; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            DataClassification = SystemMetadata;
            Description = 'Date and time when the record was modified.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
        }
        field(4; statecode; Option)
        {
            Caption = 'Status';
            DataClassification = SystemMetadata;
            Description = 'Status of the Post Configuration';
            ExternalAccess = Modify;
            ExternalName = 'statecode';
            ExternalType = 'State';
            InitValue = " ";
            OptionCaption = ' ,Active,Inactive';
            OptionOrdinalValues = -1, 0, 1;
            OptionMembers = " ",Active,Inactive;
        }
        field(5; statuscode; Option)
        {
            Caption = 'Status Reason';
            DataClassification = SystemMetadata;
            Description = 'Reason for the status of the Post Configuration';
            ExternalName = 'statuscode';
            ExternalType = 'Status';
            InitValue = " ";
            OptionCaption = ' ,Active,Inactive';
            OptionOrdinalValues = -1, 1, 2;
            OptionMembers = " ",Active,Inactive;
        }
        field(6; VersionNumber; BigInteger)
        {
            Caption = 'Version Number';
            DataClassification = SystemMetadata;
            Description = 'Version Number';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(7; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            DataClassification = SystemMetadata;
            Description = 'Sequence number of the import that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
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
        field(9; TimeZoneRuleVersionNumber; Integer)
        {
            Caption = 'Time Zone Rule Version Number';
            DataClassification = SystemMetadata;
            Description = 'For internal use only.';
            ExternalName = 'timezoneruleversionnumber';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(10; UTCConversionTimeZoneCode; Integer)
        {
            Caption = 'UTC Conversion Time Zone Code';
            DataClassification = SystemMetadata;
            Description = 'Time zone code that was in use when the record was created.';
            ExternalName = 'utcconversiontimezonecode';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(11; msdyn_EntityDisplayName; Text[100])
        {
            Caption = 'Entity Display Name';
            DataClassification = SystemMetadata;
            Description = 'Display name of the entity configured by this object.';
            ExternalName = 'msdyn_entitydisplayname';
            ExternalType = 'String';
        }
        field(12; msdyn_ConfigureWall; Boolean)
        {
            Caption = 'Wall Enabled';
            DataClassification = SystemMetadata;
            Description = 'Enables or disables the wall on the entity form.';
            ExternalName = 'msdyn_configurewall';
            ExternalType = 'Boolean';
        }
        field(13; msdyn_EntityName; Text[100])
        {
            Caption = 'Entity Name';
            DataClassification = SystemMetadata;
            Description = 'Logical name of the entity configured by this object.';
            ExternalName = 'msdyn_entityname';
            ExternalType = 'String';
        }
        field(14; msdyn_FollowingViewId; Text[100])
        {
            Caption = 'Following View Id';
            DataClassification = SystemMetadata;
            Description = 'Identifier for the view of records that a user follows.';
            ExternalName = 'msdyn_followingviewid';
            ExternalType = 'String';
        }
        field(15; msdyn_FollowingViewId2; Text[100])
        {
            Caption = 'Following View Id 2';
            DataClassification = SystemMetadata;
            Description = 'Identifier for the view of records that a user follows.';
            ExternalName = 'msdyn_followingviewid2';
            ExternalType = 'String';
        }
        field(16; msdyn_Otc; Integer)
        {
            Caption = 'Object Type Code';
            DataClassification = SystemMetadata;
            Description = 'Object Type Code of the entity';
            ExternalName = 'msdyn_otc';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(17; msdyn_Status; BLOB)
        {
            Caption = 'Configuration Status';
            DataClassification = SystemMetadata;
            Description = 'Information about the success or failure of the configuration.';
            ExternalName = 'msdyn_status';
            ExternalType = 'Memo';
            SubType = Memo;
        }
    }

    keys
    {
        key(Key1; msdyn_PostConfigId)
        {
            Clustered = true;
        }
        key(Key2; msdyn_EntityDisplayName)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; msdyn_EntityDisplayName)
        {
        }
    }
}

