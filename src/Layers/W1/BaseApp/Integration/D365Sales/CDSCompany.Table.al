// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5393 "CDS Company"
{
    // Dynamics CRM Version: 9.1.0.10123

    Caption = 'Company';
    Description = 'A legal entity formed to carry on a business.';
    ExternalName = 'bcbi_company';
    LookupPageId = "CDS Companies";
    DrillDownPageId = "CDS Companies";
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; CompanyId; Guid)
        {
            Caption = 'Company';
            Description = 'Unique identifier for company or legal entity instances';
            ExternalAccess = Insert;
            ExternalName = 'bcbi_companyid';
            ExternalType = 'Uniqueidentifier';
            DataClassification = SystemMetadata;
        }
        field(2; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            Description = 'Date and time when the record was created.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
            DataClassification = SystemMetadata;
        }
        field(3; CreatedBy; Guid)
        {
            Caption = 'Created By';
            Description = 'Unique identifier of the user who created the record.';
            ExternalAccess = Read;
            ExternalName = 'createdby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(4; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            Description = 'Date and time when the record was modified.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
            DataClassification = SystemMetadata;
        }
        field(5; ModifiedBy; Guid)
        {
            Caption = 'Modified By';
            Description = 'Unique identifier of the user who modified the record.';
            ExternalAccess = Read;
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(6; CreatedOnBehalfBy; Guid)
        {
            Caption = 'Created By (Delegate)';
            Description = 'Unique identifier of the delegate user who created the record.';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(7; ModifiedOnBehalfBy; Guid)
        {
            Caption = 'Modified By (Delegate)';
            Description = 'Unique identifier of the delegate user who modified the record.';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(8; OwnerId; Guid)
        {
            Caption = 'Owner';
            Description = 'Owner Id';
            ExternalName = 'ownerid';
            ExternalType = 'Owner';
            TableRelation = if (OwnerIdType = const(systemuser)) "CRM Systemuser".SystemUserId
            else
            if (OwnerIdType = const(team)) "CRM Team".TeamId;
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(9; OwnerIdType; Option)
        {
            Description = 'Owner Id Type';
            ExternalName = 'owneridtype';
            ExternalType = 'EntityName';
            OptionMembers = " ",systemuser,team;
            DataClassification = SystemMetadata;
        }
        field(10; OwningBusinessUnit; Guid)
        {
            Caption = 'Owning Business Unit';
            Description = 'Unique identifier for the business unit that owns the record';
            ExternalAccess = Read;
            ExternalName = 'owningbusinessunit';
            ExternalType = 'Lookup';
            TableRelation = "CRM Businessunit".BusinessUnitId;
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(11; OwningUser; Guid)
        {
            Caption = 'Owning User';
            Description = 'Unique identifier for the user that owns the record.';
            ExternalAccess = Read;
            ExternalName = 'owninguser';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(12; OwningTeam; Guid)
        {
            Caption = 'Owning Team';
            Description = 'Unique identifier for the team that owns the record.';
            ExternalAccess = Read;
            ExternalName = 'owningteam';
            ExternalType = 'Lookup';
            TableRelation = "CRM Team".TeamId;
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(13; statecode; Option)
        {
            Caption = 'Status';
            Description = 'Status of the Company';
            ExternalAccess = Modify;
            ExternalName = 'statecode';
            ExternalType = 'State';
            InitValue = " ";
            OptionCaption = ' ,Active,Inactive';
            OptionOrdinalValues = -1, 0, 1;
            OptionMembers = " ",Active,Inactive;
            DataClassification = SystemMetadata;
        }
        field(14; statuscode; Option)
        {
            Caption = 'Status Reason';
            Description = 'Reason for the status of the Company';
            ExternalName = 'statuscode';
            ExternalType = 'Status';
            InitValue = " ";
            OptionCaption = ' ,Active,Inactive';
            OptionOrdinalValues = -1, 1, 2;
            OptionMembers = " ",Active,Inactive;
            DataClassification = SystemMetadata;
        }
        field(15; VersionNumber; BigInteger)
        {
            Caption = 'Version Number';
            Description = 'Version Number';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
            DataClassification = SystemMetadata;
        }
        field(16; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            Description = 'Sequence number of the import that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
            DataClassification = SystemMetadata;
        }
        field(17; OverriddenCreatedOn; DateTime)
        {
            Caption = 'Record Created On';
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
            DataClassification = SystemMetadata;
        }
        field(18; TimeZoneRuleVersionNumber; Integer)
        {
            Caption = 'Time Zone Rule Version Number';
            Description = 'For internal use only.';
            ExternalName = 'timezoneruleversionnumber';
            ExternalType = 'Integer';
            MinValue = -1;
            DataClassification = SystemMetadata;
        }
        field(19; UTCConversionTimeZoneCode; Integer)
        {
            Caption = 'UTC Conversion Time Zone Code';
            Description = 'Time zone code that was in use when the record was created.';
            ExternalName = 'utcconversiontimezonecode';
            ExternalType = 'Integer';
            MinValue = -1;
            DataClassification = SystemMetadata;
        }
        field(20; ExternalId; Text[36])
        {
            Caption = 'External ID';
            Description = 'External unique identifier of the Company';
            ExternalName = 'bcbi_externalid';
            ExternalType = 'String';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(21; DefaultOwningTeam; Guid)
        {
            Caption = 'Default owning team ID';
            Description = 'Specifies which team should own new records created which are related to this company by default.';
            ExternalName = 'bcbi_defaultowningteam';
            ExternalType = 'Lookup';
            TableRelation = "CRM Team".TeamId;
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(22; Name; Text[30])
        {
            Caption = 'Name';
            Description = 'The name of the company or legal entity';
            ExternalName = 'bcbi_name';
            ExternalType = 'String';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(23; DefaultOwningTeamName; Text[160])
        {
            CalcFormula = lookup("CRM Team".Name where(TeamId = field(DefaultOwningTeam)));
            Caption = 'Default owning team name';
            ExternalAccess = Read;
            ExternalName = 'bcbi_defaultowningteamname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(24; CreatedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedBy)));
            Caption = 'CreatedByName';
            ExternalAccess = Read;
            ExternalName = 'createdbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(25; ModifiedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedBy)));
            Caption = 'ModifiedByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(26; CreatedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            Caption = 'CreatedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(27; ModifiedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedOnBehalfBy)));
            Caption = 'ModifiedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; CompanyId)
        {
            Clustered = true;
        }
        key(Key2; ExternalId)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; CompanyId, Name, ExternalId)
        {
        }
    }
}

