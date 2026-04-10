// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5366 "CRM Discounttype"
{
    // Dynamics CRM Version: 7.1.0.2040

    Caption = 'CRM Discounttype';
    Description = 'Type of discount specified as either a percentage or an amount.';
    ExternalName = 'discounttype';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; DiscountTypeId; Guid)
        {
            Caption = 'Discount List';
            Description = 'Unique identifier of the discount list.';
            ExternalAccess = Insert;
            ExternalName = 'discounttypeid';
            ExternalType = 'Uniqueidentifier';
        }
        field(2; OrganizationId; Guid)
        {
            Caption = 'Organization';
            Description = 'Unique identifier of the organization associated with the discount list.';
            ExternalAccess = Read;
            ExternalName = 'organizationid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Organization".OrganizationId;
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
            Description = 'Name of the discount list.';
            ExternalName = 'name';
            ExternalType = 'String';
        }
        field(4; Description; BLOB)
        {
            Caption = 'Description';
            Description = 'Description of the discount list.';
            ExternalName = 'description';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(5; IsAmountType; Boolean)
        {
            Caption = 'Type';
            Description = 'Information about whether the discount list amounts are specified as monetary amounts or percentages.';
            ExternalAccess = Insert;
            ExternalName = 'isamounttype';
            ExternalType = 'Boolean';
        }
        field(6; StateCode; Option)
        {
            Caption = 'Status';
            Description = 'Status of the discount list.';
            ExternalAccess = Modify;
            ExternalName = 'statecode';
            ExternalType = 'State';
            InitValue = Active;
            OptionCaption = 'Active,Inactive';
            OptionOrdinalValues = 0, 1;
            OptionMembers = Active,Inactive;
        }
        field(7; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            Description = 'Date and time when the discount list was created.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(8; CreatedBy; Guid)
        {
            Caption = 'Created By';
            Description = 'Unique identifier of the user who created the discount list.';
            ExternalAccess = Read;
            ExternalName = 'createdby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(9; ModifiedBy; Guid)
        {
            Caption = 'Modified By';
            Description = 'Unique identifier of the user who last modified the discount list.';
            ExternalAccess = Read;
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(10; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            Description = 'Date and time when the discount list was last modified.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
        }
        field(11; VersionNumber; BigInteger)
        {
            Caption = 'Version Number';
            Description = 'Version number of the discount type.';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(12; StatusCode; Option)
        {
            Caption = 'Status Reason';
            Description = 'Reason for the status of the discount list.';
            ExternalName = 'statuscode';
            ExternalType = 'Status';
            InitValue = " ";
            OptionCaption = ' ,Active,Inactive';
            OptionOrdinalValues = -1, 100001, 100002;
            OptionMembers = " ",Active,Inactive;
        }
        field(13; CreatedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedBy)));
            Caption = 'CreatedByName';
            ExternalAccess = Read;
            ExternalName = 'createdbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(14; ModifiedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedBy)));
            Caption = 'ModifiedByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(15; OrganizationIdName; Text[160])
        {
            CalcFormula = lookup("CRM Organization".Name where(OrganizationId = field(OrganizationId)));
            Caption = 'OrganizationIdName';
            ExternalAccess = Read;
            ExternalName = 'organizationidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(16; OverriddenCreatedOn; Date)
        {
            Caption = 'Record Created On';
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
        }
        field(17; TransactionCurrencyId; Guid)
        {
            Caption = 'Currency';
            Description = 'Unique identifier of the currency associated with the discount type.';
            ExternalAccess = Insert;
            ExternalName = 'transactioncurrencyid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Transactioncurrency".TransactionCurrencyId;
        }
        field(18; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            Description = 'Unique identifier of the data import or data migration that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
        }
        field(19; TransactionCurrencyIdName; Text[100])
        {
            CalcFormula = lookup("CRM Transactioncurrency".CurrencyName where(TransactionCurrencyId = field(TransactionCurrencyId)));
            Caption = 'TransactionCurrencyIdName';
            ExternalAccess = Read;
            ExternalName = 'transactioncurrencyidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(20; CreatedOnBehalfBy; Guid)
        {
            Caption = 'Created By (Delegate)';
            Description = 'Unique identifier of the delegate user who created the discounttype.';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(21; CreatedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            Caption = 'CreatedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(22; ModifiedOnBehalfBy; Guid)
        {
            Caption = 'Modified By (Delegate)';
            Description = 'Unique identifier of the delegate user who last modified the discounttype.';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(23; ModifiedOnBehalfByName; Text[200])
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
        key(Key1; DiscountTypeId)
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

