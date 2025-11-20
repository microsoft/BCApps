// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5359 "CRM Team"
{
    // Dynamics CRM Version: 7.1.0.2040

    Caption = 'CRM Team';
    Description = 'Collection of system users that routinely collaborate. Teams can be used to simplify record sharing and provide team members with common access to organization data when team members belong to different Business Units.';
    ExternalName = 'team';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; TeamId; Guid)
        {
            Caption = 'Team';
            Description = 'Unique identifier for the team.';
            ExternalAccess = Insert;
            ExternalName = 'teamid';
            ExternalType = 'Uniqueidentifier';
        }
        field(2; OrganizationId; Guid)
        {
            Caption = 'Organization ';
            Description = 'Unique identifier of the organization associated with the team.';
            ExternalAccess = Read;
            ExternalName = 'organizationid';
            ExternalType = 'Uniqueidentifier';
        }
        field(3; BusinessUnitId; Guid)
        {
            Caption = 'Business Unit';
            Description = 'Unique identifier of the business unit with which the team is associated.';
            ExternalName = 'businessunitid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Businessunit".BusinessUnitId;
        }
        field(4; Name; Text[160])
        {
            Caption = 'Team Name';
            Description = 'Name of the team.';
            ExternalName = 'name';
            ExternalType = 'String';
        }
        field(5; Description; BLOB)
        {
            Caption = 'Description';
            Description = 'Description of the team.';
            ExternalName = 'description';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(6; EMailAddress; Text[100])
        {
            Caption = 'Email';
            Description = 'Email address for the team.';
            ExtendedDatatype = EMail;
            ExternalName = 'emailaddress';
            ExternalType = 'String';
        }
        field(7; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            Description = 'Date and time when the team was created.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(8; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            Description = 'Date and time when the team was last modified.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
        }
        field(9; CreatedBy; Guid)
        {
            Caption = 'Created By';
            Description = 'Unique identifier of the user who created the team.';
            ExternalAccess = Read;
            ExternalName = 'createdby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(10; ModifiedBy; Guid)
        {
            Caption = 'Modified By';
            Description = 'Unique identifier of the user who last modified the team.';
            ExternalAccess = Read;
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(11; VersionNumber; BigInteger)
        {
            Caption = 'Version number';
            Description = 'Version number of the team.';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(12; CreatedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedBy)));
            Caption = 'CreatedByName';
            ExternalAccess = Read;
            ExternalName = 'createdbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(13; ModifiedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedBy)));
            Caption = 'ModifiedByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(14; BusinessUnitIdName; Text[160])
        {
            CalcFormula = lookup("CRM Businessunit".Name where(BusinessUnitId = field(BusinessUnitId)));
            Caption = 'BusinessUnitIdName';
            ExternalAccess = Read;
            ExternalName = 'businessunitidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(15; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            Description = 'Unique identifier of the data import or data migration that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
        }
        field(16; OverriddenCreatedOn; Date)
        {
            Caption = 'Record Created On';
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
        }
        field(17; AdministratorId; Guid)
        {
            Caption = 'Administrator';
            Description = 'Unique identifier of the user primary responsible for the team.';
            ExternalName = 'administratorid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(18; IsDefault; Boolean)
        {
            Caption = 'Is Default';
            Description = 'Information about whether the team is a default business unit team.';
            ExternalAccess = Read;
            ExternalName = 'isdefault';
            ExternalType = 'Boolean';
        }
        field(19; AdministratorIdName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(AdministratorId)));
            Caption = 'AdministratorIdName';
            ExternalAccess = Read;
            ExternalName = 'administratoridname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(20; YomiName; Text[160])
        {
            Caption = 'Yomi Name';
            Description = 'Pronunciation of the full name of the team, written in phonetic hiragana or katakana characters.';
            ExternalName = 'yominame';
            ExternalType = 'String';
        }
        field(21; CreatedOnBehalfBy; Guid)
        {
            Caption = 'Created By (Delegate)';
            Description = 'Unique identifier of the delegate user who created the team.';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(22; CreatedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            Caption = 'CreatedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(23; ModifiedOnBehalfBy; Guid)
        {
            Caption = 'Modified By (Delegate)';
            Description = 'Unique identifier of the delegate user who last modified the team.';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(24; ModifiedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedOnBehalfBy)));
            Caption = 'ModifiedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(25; TraversedPath; Text[250])
        {
            Caption = 'Traversed Path';
            Description = 'For internal use only.';
            ExternalName = 'traversedpath';
            ExternalType = 'String';
        }
        field(26; TransactionCurrencyId; Guid)
        {
            Caption = 'Currency';
            Description = 'Unique identifier of the currency associated with the team.';
            ExternalName = 'transactioncurrencyid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Transactioncurrency".TransactionCurrencyId;
        }
        field(27; TransactionCurrencyIdName; Text[100])
        {
            CalcFormula = lookup("CRM Transactioncurrency".CurrencyName where(TransactionCurrencyId = field(TransactionCurrencyId)));
            Caption = 'TransactionCurrencyIdName';
            ExternalAccess = Read;
            ExternalName = 'transactioncurrencyidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(28; ExchangeRate; Decimal)
        {
            Caption = 'Exchange Rate';
            Description = 'Exchange rate for the currency associated with the team with respect to the base currency.';
            ExternalAccess = Read;
            ExternalName = 'exchangerate';
            ExternalType = 'Decimal';
        }
        field(29; TeamType; Option)
        {
            Caption = 'Team Type';
            Description = 'Select the team type.';
            ExternalAccess = Insert;
            ExternalName = 'teamtype';
            ExternalType = 'Picklist';
            InitValue = Owner;
            OptionCaption = 'Owner,Access';
            OptionOrdinalValues = 0, 1;
            OptionMembers = Owner,Access;
        }
        field(30; RegardingObjectId; Guid)
        {
            Caption = 'Regarding Object Id';
            Description = 'Choose the record that the team relates to.';
            ExternalAccess = Insert;
            ExternalName = 'regardingobjectid';
            ExternalType = 'Lookup';
            TableRelation = if (RegardingObjectTypeCode = const(opportunity)) "CRM Opportunity".OpportunityId;
        }
        field(31; SystemManaged; Boolean)
        {
            Caption = 'Is System Managed';
            Description = 'Select whether the team will be managed by the system.';
            ExternalAccess = Read;
            ExternalName = 'systemmanaged';
            ExternalType = 'Boolean';
        }
        field(32; RegardingObjectTypeCode; Option)
        {
            Caption = 'Regarding Object Type';
            Description = 'Type of the associated record for team - used for system managed access teams only.';
            ExternalAccess = Insert;
            ExternalName = 'regardingobjecttypecode';
            ExternalType = 'EntityName';
            OptionCaption = ' ,opportunity';
            OptionMembers = " ",opportunity;
        }
        field(33; StageId; Guid)
        {
            Caption = 'Process Stage';
            Description = 'Shows the ID of the stage.';
            ExternalName = 'stageid';
            ExternalType = 'Uniqueidentifier';
        }
        field(34; ProcessId; Guid)
        {
            Caption = 'Process';
            Description = 'Shows the ID of the process.';
            ExternalName = 'processid';
            ExternalType = 'Uniqueidentifier';
        }
    }

    keys
    {
        key(Key1; TeamId)
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

