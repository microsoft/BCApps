// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5364 "CRM Businessunit"
{
    // Dynamics CRM Version: 7.1.0.2040

    Caption = 'CRM Businessunit';
    Description = 'Business, division, or department in the Microsoft Dynamics CRM database.';
    ExternalName = 'businessunit';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; BusinessUnitId; Guid)
        {
            Caption = 'Business Unit';
            Description = 'Unique identifier of the business unit.';
            ExternalAccess = Insert;
            ExternalName = 'businessunitid';
            ExternalType = 'Uniqueidentifier';
        }
        field(2; OrganizationId; Guid)
        {
            Caption = 'Organization';
            Description = 'Unique identifier of the organization associated with the business unit.';
            ExternalAccess = Read;
            ExternalName = 'organizationid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Organization".OrganizationId;
        }
        field(3; Name; Text[160])
        {
            Caption = 'Name';
            Description = 'Name of the business unit.';
            ExternalName = 'name';
            ExternalType = 'String';
        }
        field(4; Description; BLOB)
        {
            Caption = 'Description';
            Description = 'Description of the business unit.';
            ExternalName = 'description';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(5; DivisionName; Text[100])
        {
            Caption = 'Division';
            Description = 'Name of the division to which the business unit belongs.';
            ExternalName = 'divisionname';
            ExternalType = 'String';
        }
        field(6; FileAsName; Text[100])
        {
            Caption = 'File as Name';
            Description = 'Alternative name under which the business unit can be filed.';
            ExternalName = 'fileasname';
            ExternalType = 'String';
        }
        field(7; TickerSymbol; Text[10])
        {
            Caption = 'Ticker Symbol';
            Description = 'Stock exchange ticker symbol for the business unit.';
            ExternalName = 'tickersymbol';
            ExternalType = 'String';
        }
        field(8; StockExchange; Text[20])
        {
            Caption = 'Stock Exchange';
            Description = 'Stock exchange on which the business is listed.';
            ExternalName = 'stockexchange';
            ExternalType = 'String';
        }
        field(9; UTCOffset; Integer)
        {
            Caption = 'UTC Offset';
            Description = 'UTC offset for the business unit. This is the difference between local time and standard Coordinated Universal Time.';
            ExternalName = 'utcoffset';
            ExternalType = 'Integer';
            MaxValue = 1500;
            MinValue = -1500;
        }
        field(10; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            Description = 'Date and time when the business unit was created.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(11; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            Description = 'Date and time when the business unit was last modified.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
        }
        field(12; CreditLimit; Decimal)
        {
            Caption = 'Credit Limit';
            Description = 'Credit limit for the business unit.';
            ExternalName = 'creditlimit';
            ExternalType = 'Double';
        }
        field(13; CostCenter; Text[100])
        {
            Caption = 'Cost Center';
            Description = 'Name of the business unit cost center.';
            ExternalName = 'costcenter';
            ExternalType = 'String';
        }
        field(14; WebSiteUrl; Text[200])
        {
            Caption = 'Website';
            Description = 'Website URL for the business unit.';
            ExtendedDatatype = URL;
            ExternalName = 'websiteurl';
            ExternalType = 'String';
        }
        field(15; FtpSiteUrl; Text[200])
        {
            Caption = 'FTP Site';
            Description = 'FTP site URL for the business unit.';
            ExtendedDatatype = URL;
            ExternalName = 'ftpsiteurl';
            ExternalType = 'String';
        }
        field(16; EMailAddress; Text[100])
        {
            Caption = 'Email';
            Description = 'Email address for the business unit.';
            ExtendedDatatype = EMail;
            ExternalName = 'emailaddress';
            ExternalType = 'String';
        }
        field(17; InheritanceMask; Integer)
        {
            Caption = 'Inheritance Mask';
            Description = 'Inheritance mask for the business unit.';
            ExternalAccess = Insert;
            ExternalName = 'inheritancemask';
            ExternalType = 'Integer';
            MaxValue = 1000000000;
            MinValue = 0;
        }
        field(18; CreatedBy; Guid)
        {
            Caption = 'Created By';
            Description = 'Unique identifier of the user who created the business unit.';
            ExternalAccess = Read;
            ExternalName = 'createdby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(19; ModifiedBy; Guid)
        {
            Caption = 'Modified By';
            Description = 'Unique identifier of the user who last modified the business unit.';
            ExternalAccess = Read;
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(20; WorkflowSuspended; Boolean)
        {
            Caption = 'Workflow Suspended';
            Description = 'Information about whether workflow or sales process rules have been suspended.';
            ExternalName = 'workflowsuspended';
            ExternalType = 'Boolean';
        }
        field(21; ParentBusinessUnitId; Guid)
        {
            Caption = 'Parent Business';
            Description = 'Unique identifier for the parent business unit.';
            ExternalName = 'parentbusinessunitid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Businessunit".BusinessUnitId;
        }
        field(22; IsDisabled; Boolean)
        {
            Caption = 'Is Disabled';
            Description = 'Information about whether the business unit is enabled or disabled.';
            ExternalAccess = Read;
            ExternalName = 'isdisabled';
            ExternalType = 'Boolean';
        }
        field(23; DisabledReason; Text[250])
        {
            Caption = 'Disable Reason';
            Description = 'Reason for disabling the business unit.';
            ExternalAccess = Read;
            ExternalName = 'disabledreason';
            ExternalType = 'String';
        }
        field(24; VersionNumber; BigInteger)
        {
            Caption = 'Version number';
            Description = 'Version number of the business unit.';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(25; ParentBusinessUnitIdName; Text[160])
        {
            CalcFormula = lookup("CRM Businessunit".Name where(BusinessUnitId = field(ParentBusinessUnitId)));
            Caption = 'ParentBusinessUnitIdName';
            ExternalAccess = Read;
            ExternalName = 'parentbusinessunitidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(26; Address1_AddressId; Guid)
        {
            Caption = 'Address 1: ID';
            Description = 'Unique identifier for address 1.';
            ExternalName = 'address1_addressid';
            ExternalType = 'Uniqueidentifier';
        }
        field(27; Address1_AddressTypeCode; Option)
        {
            Caption = 'Address 1: Address Type';
            Description = 'Type of address for address 1, such as billing, shipping, or primary address.';
            ExternalName = 'address1_addresstypecode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(28; Address1_Name; Text[100])
        {
            Caption = 'Address 1: Name';
            Description = 'Name to enter for address 1.';
            ExternalName = 'address1_name';
            ExternalType = 'String';
        }
        field(29; Address1_Line1; Text[250])
        {
            Caption = 'Bill To Street 1';
            Description = 'First line for entering address 1 information.';
            ExternalName = 'address1_line1';
            ExternalType = 'String';
        }
        field(30; Address1_Line2; Text[250])
        {
            Caption = 'Bill To Street 2';
            Description = 'Second line for entering address 1 information.';
            ExternalName = 'address1_line2';
            ExternalType = 'String';
        }
        field(31; Address1_Line3; Text[250])
        {
            Caption = 'Bill To Street 3';
            Description = 'Third line for entering address 1 information.';
            ExternalName = 'address1_line3';
            ExternalType = 'String';
        }
        field(32; Address1_City; Text[80])
        {
            Caption = 'Bill To City';
            Description = 'City name for address 1.';
            ExternalName = 'address1_city';
            ExternalType = 'String';
        }
        field(33; Address1_StateOrProvince; Text[50])
        {
            Caption = 'Bill To State/Province';
            Description = 'State or province for address 1.';
            ExternalName = 'address1_stateorprovince';
            ExternalType = 'String';
        }
        field(34; Address1_County; Text[50])
        {
            Caption = 'Address 1: County';
            Description = 'County name for address 1.';
            ExternalName = 'address1_county';
            ExternalType = 'String';
        }
        field(35; Address1_Country; Text[80])
        {
            Caption = 'Bill To Country/Region';
            Description = 'Country/region name for address 1.';
            ExternalName = 'address1_country';
            ExternalType = 'String';
        }
        field(36; Address1_PostOfficeBox; Text[20])
        {
            Caption = 'Address 1: Post Office Box';
            Description = 'Post office box number for address 1.';
            ExternalName = 'address1_postofficebox';
            ExternalType = 'String';
        }
        field(37; Address1_PostalCode; Text[20])
        {
            Caption = 'Bill To ZIP/Postal Code';
            Description = 'ZIP Code or postal code for address 1.';
            ExternalName = 'address1_postalcode';
            ExternalType = 'String';
        }
        field(38; Address1_UTCOffset; Integer)
        {
            Caption = 'Address 1: UTC Offset';
            Description = 'UTC offset for address 1. This is the difference between local time and standard Coordinated Universal Time.';
            ExternalName = 'address1_utcoffset';
            ExternalType = 'Integer';
            MaxValue = 1500;
            MinValue = -1500;
        }
        field(39; Address1_UPSZone; Text[4])
        {
            Caption = 'Address 1: UPS Zone';
            Description = 'United Parcel Service (UPS) zone for address 1.';
            ExternalName = 'address1_upszone';
            ExternalType = 'String';
        }
        field(40; Address1_Latitude; Decimal)
        {
            Caption = 'Address 1: Latitude';
            Description = 'Latitude for address 1.';
            ExternalName = 'address1_latitude';
            ExternalType = 'Double';
        }
        field(41; Address1_Telephone1; Text[50])
        {
            Caption = 'Main Phone';
            Description = 'First telephone number associated with address 1.';
            ExternalName = 'address1_telephone1';
            ExternalType = 'String';
        }
        field(42; Address1_Longitude; Decimal)
        {
            Caption = 'Address 1: Longitude';
            Description = 'Longitude for address 1.';
            ExternalName = 'address1_longitude';
            ExternalType = 'Double';
        }
        field(43; Address1_ShippingMethodCode; Option)
        {
            Caption = 'Address 1: Shipping Method';
            Description = 'Method of shipment for address 1.';
            ExternalName = 'address1_shippingmethodcode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(44; Address1_Telephone2; Text[50])
        {
            Caption = 'Other Phone';
            Description = 'Second telephone number associated with address 1.';
            ExternalName = 'address1_telephone2';
            ExternalType = 'String';
        }
        field(45; Address1_Telephone3; Text[50])
        {
            Caption = 'Address 1: Telephone 3';
            Description = 'Third telephone number associated with address 1.';
            ExternalName = 'address1_telephone3';
            ExternalType = 'String';
        }
        field(46; Address1_Fax; Text[50])
        {
            Caption = 'Address 1: Fax';
            Description = 'Fax number for address 1.';
            ExternalName = 'address1_fax';
            ExternalType = 'String';
        }
        field(47; Address2_AddressId; Guid)
        {
            Caption = 'Address 2: ID';
            Description = 'Unique identifier for address 2.';
            ExternalName = 'address2_addressid';
            ExternalType = 'Uniqueidentifier';
        }
        field(48; Address2_AddressTypeCode; Option)
        {
            Caption = 'Address 2: Address Type';
            Description = 'Type of address for address 2, such as billing, shipping, or primary address.';
            ExternalName = 'address2_addresstypecode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(49; Address2_Name; Text[100])
        {
            Caption = 'Address 2: Name';
            Description = 'Name to enter for address 2.';
            ExternalName = 'address2_name';
            ExternalType = 'String';
        }
        field(50; Address2_Line1; Text[250])
        {
            Caption = 'Ship To Street 1';
            Description = 'First line for entering address 2 information.';
            ExternalName = 'address2_line1';
            ExternalType = 'String';
        }
        field(51; Address2_Line2; Text[250])
        {
            Caption = 'Ship To Street 2';
            Description = 'Second line for entering address 2 information.';
            ExternalName = 'address2_line2';
            ExternalType = 'String';
        }
        field(52; Address2_Line3; Text[250])
        {
            Caption = 'Ship To Street 3';
            Description = 'Third line for entering address 2 information.';
            ExternalName = 'address2_line3';
            ExternalType = 'String';
        }
        field(53; Address2_City; Text[80])
        {
            Caption = 'Ship To City';
            Description = 'City name for address 2.';
            ExternalName = 'address2_city';
            ExternalType = 'String';
        }
        field(54; Address2_StateOrProvince; Text[50])
        {
            Caption = 'Ship To State/Province';
            Description = 'State or province for address 2.';
            ExternalName = 'address2_stateorprovince';
            ExternalType = 'String';
        }
        field(55; Address2_County; Text[50])
        {
            Caption = 'Address 2: County';
            Description = 'County name for address 2.';
            ExternalName = 'address2_county';
            ExternalType = 'String';
        }
        field(56; Address2_Country; Text[80])
        {
            Caption = 'Ship To Country/Region';
            Description = 'Country/region name for address 2.';
            ExternalName = 'address2_country';
            ExternalType = 'String';
        }
        field(57; Address2_PostOfficeBox; Text[20])
        {
            Caption = 'Address 2: Post Office Box';
            Description = 'Post office box number for address 2.';
            ExternalName = 'address2_postofficebox';
            ExternalType = 'String';
        }
        field(58; Address2_PostalCode; Text[20])
        {
            Caption = 'Ship To ZIP/Postal Code';
            Description = 'ZIP Code or postal code for address 2.';
            ExternalName = 'address2_postalcode';
            ExternalType = 'String';
        }
        field(59; Address2_UTCOffset; Integer)
        {
            Caption = 'Address 2: UTC Offset';
            Description = 'UTC offset for address 2. This is the difference between local time and standard Coordinated Universal Time.';
            ExternalName = 'address2_utcoffset';
            ExternalType = 'Integer';
            MaxValue = 1500;
            MinValue = -1500;
        }
        field(60; Address2_UPSZone; Text[4])
        {
            Caption = 'Address 2: UPS Zone';
            Description = 'United Parcel Service (UPS) zone for address 2.';
            ExternalName = 'address2_upszone';
            ExternalType = 'String';
        }
        field(61; Address2_Latitude; Decimal)
        {
            Caption = 'Address 2: Latitude';
            Description = 'Latitude for address 2.';
            ExternalName = 'address2_latitude';
            ExternalType = 'Double';
        }
        field(62; Address2_Telephone1; Text[50])
        {
            Caption = 'Address 2: Telephone 1';
            Description = 'First telephone number associated with address 2.';
            ExternalName = 'address2_telephone1';
            ExternalType = 'String';
        }
        field(63; Address2_Longitude; Decimal)
        {
            Caption = 'Address 2: Longitude';
            Description = 'Longitude for address 2.';
            ExternalName = 'address2_longitude';
            ExternalType = 'Double';
        }
        field(64; Address2_ShippingMethodCode; Option)
        {
            Caption = 'Address 2: Shipping Method';
            Description = 'Method of shipment for address 2.';
            ExternalName = 'address2_shippingmethodcode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(65; Address2_Telephone2; Text[50])
        {
            Caption = 'Address 2: Telephone 2';
            Description = 'Second telephone number associated with address 2.';
            ExternalName = 'address2_telephone2';
            ExternalType = 'String';
        }
        field(66; Address2_Telephone3; Text[50])
        {
            Caption = 'Address 2: Telephone 3';
            Description = 'Third telephone number associated with address 2.';
            ExternalName = 'address2_telephone3';
            ExternalType = 'String';
        }
        field(67; Address2_Fax; Text[50])
        {
            Caption = 'Address 2: Fax';
            Description = 'Fax number for address 2.';
            ExternalName = 'address2_fax';
            ExternalType = 'String';
        }
        field(68; CreatedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedBy)));
            Caption = 'CreatedByName';
            ExternalAccess = Read;
            ExternalName = 'createdbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(69; ModifiedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedBy)));
            Caption = 'ModifiedByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(70; OrganizationIdName; Text[160])
        {
            CalcFormula = lookup("CRM Organization".Name where(OrganizationId = field(OrganizationId)));
            Caption = 'OrganizationIdName';
            ExternalAccess = Read;
            ExternalName = 'organizationidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(71; OverriddenCreatedOn; Date)
        {
            Caption = 'Record Created On';
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
        }
        field(72; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            Description = 'Unique identifier of the data import or data migration that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
        }
        field(73; CreatedOnBehalfBy; Guid)
        {
            Caption = 'Created By (Delegate)';
            Description = 'Unique identifier of the delegate user who created the businessunit.';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(74; CreatedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            Caption = 'CreatedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(75; ModifiedOnBehalfBy; Guid)
        {
            Caption = 'Modified By (Delegate)';
            Description = 'Unique identifier of the delegate user who last modified the businessunit.';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(76; ModifiedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedOnBehalfBy)));
            Caption = 'ModifiedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(77; TransactionCurrencyId; Guid)
        {
            Caption = 'Currency';
            Description = 'Unique identifier of the currency associated with the businessunit.';
            ExternalName = 'transactioncurrencyid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Transactioncurrency".TransactionCurrencyId;
        }
        field(78; TransactionCurrencyIdName; Text[100])
        {
            CalcFormula = lookup("CRM Transactioncurrency".CurrencyName where(TransactionCurrencyId = field(TransactionCurrencyId)));
            Caption = 'TransactionCurrencyIdName';
            ExternalAccess = Read;
            ExternalName = 'transactioncurrencyidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(79; ExchangeRate; Decimal)
        {
            Caption = 'Exchange Rate';
            Description = 'Exchange rate for the currency associated with the businessunit with respect to the base currency.';
            ExternalAccess = Read;
            ExternalName = 'exchangerate';
            ExternalType = 'Decimal';
        }
    }

    keys
    {
        key(Key1; BusinessUnitId)
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

