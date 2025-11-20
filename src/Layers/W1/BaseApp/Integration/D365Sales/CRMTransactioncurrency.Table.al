// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;


table 5345 "CRM Transactioncurrency"
{
    // Dynamics CRM Version: 7.1.0.2040

    Caption = 'Dataverse Transactioncurrency';
    Description = 'Currency in which a financial transaction is carried out.';
    ExternalName = 'transactioncurrency';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; StatusCode; Option)
        {
            Caption = 'Status Reason';
            Description = 'Reason for the status of the transaction currency.';
            ExternalName = 'statuscode';
            ExternalType = 'Status';
            InitValue = " ";
            OptionCaption = ' ,Active,Inactive';
            OptionOrdinalValues = -1, 1, 2;
            OptionMembers = " ",Active,Inactive;
        }
        field(2; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            Description = 'Date and time when the transaction currency was last modified.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
        }
        field(3; StateCode; Option)
        {
            Caption = 'Status';
            Description = 'Status of the transaction currency.';
            ExternalAccess = Modify;
            ExternalName = 'statecode';
            ExternalType = 'State';
            InitValue = Active;
            OptionCaption = 'Active,Inactive';
            OptionOrdinalValues = 0, 1;
            OptionMembers = Active,Inactive;
        }
        field(4; VersionNumber; BigInteger)
        {
            Caption = 'Version Number';
            Description = 'Version number of the transaction currency.';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(5; ModifiedBy; Guid)
        {
            Caption = 'Modified By';
            Description = 'Unique identifier of the user who last modified the transaction currency.';
            ExternalAccess = Read;
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(6; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            Description = 'Unique identifier of the data import or data migration that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
        }
        field(7; OverriddenCreatedOn; Date)
        {
            Caption = 'Record Created On';
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
        }
        field(8; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            Description = 'Date and time when the transaction currency was created.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(9; TransactionCurrencyId; Guid)
        {
            Caption = 'Transaction Currency';
            Description = 'Unique identifier of the transaction currency.';
            ExternalAccess = Insert;
            ExternalName = 'transactioncurrencyid';
            ExternalType = 'Uniqueidentifier';
        }
        field(10; ExchangeRate; Decimal)
        {
            Caption = 'Exchange Rate';
            Description = 'Exchange rate between the transaction currency and the base currency.';
            ExternalName = 'exchangerate';
            ExternalType = 'Decimal';
        }
        field(11; CurrencySymbol; Text[10])
        {
            Caption = 'Currency Symbol';
            Description = 'Symbol for the transaction currency.';
            ExternalName = 'currencysymbol';
            ExternalType = 'String';
        }
        field(12; CurrencyName; Text[100])
        {
            Caption = 'Currency Name';
            Description = 'Name of the transaction currency.';
            ExternalName = 'currencyname';
            ExternalType = 'String';
        }
        field(13; CreatedBy; Guid)
        {
            Caption = 'Created By';
            Description = 'Unique identifier of the user who created the transaction currency.';
            ExternalAccess = Read;
            ExternalName = 'createdby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(14; ISOCurrencyCode; Text[5])
        {
            Caption = 'Currency Code';
            Description = 'ISO currency code for the transaction currency.';
            ExternalAccess = Insert;
            ExternalName = 'isocurrencycode';
            ExternalType = 'String';
        }
        field(15; OrganizationId; Guid)
        {
            Caption = 'Organization';
            Description = 'Unique identifier of the organization associated with the transaction currency.';
            ExternalAccess = Read;
            ExternalName = 'organizationid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Organization".OrganizationId;
        }
        field(16; ModifiedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedBy)));
            Caption = 'ModifiedByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(17; CreatedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedBy)));
            Caption = 'CreatedByName';
            ExternalAccess = Read;
            ExternalName = 'createdbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(18; CurrencyPrecision; Integer)
        {
            Caption = 'Currency Precision';
            Description = 'Number of decimal places that can be used for currency.';
            ExternalName = 'currencyprecision';
            ExternalType = 'Integer';
            MaxValue = 4;
            MinValue = 0;
        }
        field(19; CreatedOnBehalfBy; Guid)
        {
            Caption = 'Created By (Delegate)';
            Description = 'Unique identifier of the delegate user who created the transactioncurrency.';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(20; CreatedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            Caption = 'CreatedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(21; ModifiedOnBehalfBy; Guid)
        {
            Caption = 'Modified By (Delegate)';
            Description = 'Unique identifier of the delegate user who last modified the transactioncurrency.';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(22; ModifiedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedOnBehalfBy)));
            Caption = 'ModifiedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(23; EntityImageId; Guid)
        {
            Caption = 'Entity Image Id';
            Description = 'For internal use only.';
            ExternalAccess = Read;
            ExternalName = 'entityimageid';
            ExternalType = 'Uniqueidentifier';
        }
    }

    keys
    {
        key(Key1; TransactionCurrencyId)
        {
            Clustered = true;
        }
        key(Key2; CurrencyName)
        {
        }
        key(Key3; ISOCurrencyCode)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; CurrencyName)
        {
        }
    }
}

