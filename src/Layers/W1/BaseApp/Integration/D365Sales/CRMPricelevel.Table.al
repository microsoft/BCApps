// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5346 "CRM Pricelevel"
{
    // Dynamics CRM Version: 7.1.0.2040

    Caption = 'CRM Pricelevel';
    Description = 'Entity that defines pricing levels.';
    ExternalName = 'pricelevel';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; PriceLevelId; Guid)
        {
            Caption = 'Price List';
            Description = 'Unique identifier of the price list.';
            ExternalAccess = Insert;
            ExternalName = 'pricelevelid';
            ExternalType = 'Uniqueidentifier';
        }
        field(2; OrganizationId; Guid)
        {
            Caption = 'Organization';
            Description = 'Unique identifier of the organization associated with the price list.';
            ExternalAccess = Read;
            ExternalName = 'organizationid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Organization".OrganizationId;
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
            Description = 'Name of the price list.';
            ExternalName = 'name';
            ExternalType = 'String';
        }
        field(4; Description; BLOB)
        {
            Caption = 'Description';
            Description = 'Description of the price list.';
            ExternalName = 'description';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(5; ShippingMethodCode; Option)
        {
            Caption = 'Shipping Method';
            Description = 'Method of shipment for products in the price list.';
            ExternalName = 'shippingmethodcode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(6; BeginDate; Date)
        {
            Caption = 'Start Date';
            Description = 'Date on which the price list becomes effective.';
            ExternalName = 'begindate';
            ExternalType = 'DateTime';
        }
        field(7; PaymentMethodCode; Option)
        {
            Caption = 'Payment Method ';
            Description = 'Payment terms to use with the price list.';
            ExternalName = 'paymentmethodcode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(8; FreightTermsCode; Option)
        {
            Caption = 'Freight Terms';
            Description = 'Freight terms for the price list.';
            ExternalName = 'freighttermscode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(9; EndDate; Date)
        {
            Caption = 'End Date';
            Description = 'Date that is the last day the price list is valid.';
            ExternalName = 'enddate';
            ExternalType = 'DateTime';
        }
        field(10; CreatedBy; Guid)
        {
            Caption = 'Created By';
            Description = 'Unique identifier of the user who created the price list.';
            ExternalAccess = Read;
            ExternalName = 'createdby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(11; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            Description = 'Date and time when the price list was created.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(12; ModifiedBy; Guid)
        {
            Caption = 'Modified By';
            Description = 'Unique identifier of the user who last modified the price list.';
            ExternalAccess = Read;
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(13; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            Description = 'Date and time when the price list was last modified.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
        }
        field(14; StateCode; Option)
        {
            Caption = 'Status ';
            Description = 'Status of the price list.';
            ExternalAccess = Modify;
            ExternalName = 'statecode';
            ExternalType = 'State';
            InitValue = Active;
            OptionCaption = 'Active,Inactive';
            OptionOrdinalValues = 0, 1;
            OptionMembers = Active,Inactive;
        }
        field(15; VersionNumber; BigInteger)
        {
            Caption = 'Version Number';
            Description = 'Version number of the price level.';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(16; StatusCode; Option)
        {
            Caption = 'Status Reason';
            Description = 'Reason for the status of the price list.';
            ExternalName = 'statuscode';
            ExternalType = 'Status';
            InitValue = " ";
            OptionCaption = ' ,Active,Inactive';
            OptionOrdinalValues = -1, 100001, 100002;
            OptionMembers = " ",Active,Inactive;
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
        field(18; ModifiedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedBy)));
            Caption = 'ModifiedByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(19; OrganizationIdName; Text[160])
        {
            CalcFormula = lookup("CRM Organization".Name where(OrganizationId = field(OrganizationId)));
            Caption = 'OrganizationIdName';
            ExternalAccess = Read;
            ExternalName = 'organizationidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(20; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            Description = 'Unique identifier of the data import or data migration that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
        }
        field(21; TransactionCurrencyId; Guid)
        {
            Caption = 'Currency';
            Description = 'Unique identifier of the currency associated with the price level.';
            ExternalAccess = Insert;
            ExternalName = 'transactioncurrencyid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Transactioncurrency".TransactionCurrencyId;
        }
        field(22; OverriddenCreatedOn; Date)
        {
            Caption = 'Record Created On';
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
        }
        field(23; TimeZoneRuleVersionNumber; Integer)
        {
            Caption = 'Time Zone Rule Version Number';
            Description = 'For internal use only.';
            ExternalName = 'timezoneruleversionnumber';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(24; UTCConversionTimeZoneCode; Integer)
        {
            Caption = 'UTC Conversion Time Zone Code';
            Description = 'Time zone code that was in use when the record was created.';
            ExternalName = 'utcconversiontimezonecode';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(25; TransactionCurrencyIdName; Text[100])
        {
            CalcFormula = lookup("CRM Transactioncurrency".CurrencyName where(TransactionCurrencyId = field(TransactionCurrencyId)));
            Caption = 'TransactionCurrencyIdName';
            ExternalAccess = Read;
            ExternalName = 'transactioncurrencyidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(26; CreatedOnBehalfBy; Guid)
        {
            Caption = 'Created By (Delegate)';
            Description = 'Unique identifier of the delegate user who created the pricelevel.';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(27; CreatedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            Caption = 'CreatedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(28; ModifiedOnBehalfBy; Guid)
        {
            Caption = 'Modified By (Delegate)';
            Description = 'Unique identifier of the delegate user who last modified the pricelevel.';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(29; ModifiedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedOnBehalfBy)));
            Caption = 'ModifiedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(30; ExchangeRate; Decimal)
        {
            Caption = 'Exchange Rate';
            Description = 'Shows the conversion rate of the record''s currency. The exchange rate is used to convert all money fields in the record from the local currency to the system''s default currency.';
            ExternalAccess = Read;
            ExternalName = 'exchangerate';
            ExternalType = 'Decimal';
        }
        field(31; CompanyId; Guid)
        {
            Caption = 'Company Id';
            Description = 'Unique identifier of the company that owns the price level.';
            ExternalName = 'bcbi_companyid';
            ExternalType = 'Lookup';
            TableRelation = "CDS Company".CompanyId;
        }
    }

    keys
    {
        key(Key1; PriceLevelId)
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

