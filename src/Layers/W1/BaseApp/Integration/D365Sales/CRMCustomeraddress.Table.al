// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Integration.Dataverse;

table 5360 "CRM Customeraddress"
{
    // Dynamics CRM Version: 7.1.0.2040

    Caption = 'CRM Customeraddress';
    Description = 'Address and shipping information. Used to store additional addresses for an account or contact.';
    ExternalName = 'customeraddress';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ParentId; Guid)
        {
            Caption = 'Parent';
            Description = 'Choose the customer''s address.';
            ExternalName = 'parentid';
            ExternalType = 'Lookup';
            TableRelation = if (ParentIdTypeCode = const(account)) "CRM Account".AccountId
            else
            if (ParentIdTypeCode = const(contact)) "CRM Contact".ContactId;
        }
        field(2; CustomerAddressId; Guid)
        {
            Caption = 'Address';
            Description = 'Unique identifier of the customer address.';
            ExternalAccess = Insert;
            ExternalName = 'customeraddressid';
            ExternalType = 'Uniqueidentifier';
        }
        field(3; AddressNumber; Integer)
        {
            Caption = 'Address Number';
            Description = 'Shows the number of the address, to indicate whether the address is the primary, secondary, or other address for the customer.';
            ExternalName = 'addressnumber';
            ExternalType = 'Integer';
            MaxValue = 1000000000;
            MinValue = 0;
        }
        field(4; AddressTypeCode; Option)
        {
            Caption = 'Address Type';
            Description = 'Select the address type, such as primary or billing.';
            ExternalName = 'addresstypecode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Bill To,Ship To,Primary,Other';
            OptionOrdinalValues = -1, 1, 2, 3, 4;
            OptionMembers = " ",BillTo,ShipTo,Primary,Other;
        }
        field(5; Name; Text[200])
        {
            Caption = 'Address Name';
            Description = 'Type a descriptive name for the customer''s address, such as Corporate Headquarters.';
            ExternalName = 'name';
            ExternalType = 'String';
        }
        field(6; PrimaryContactName; Text[150])
        {
            Caption = 'Address Contact';
            Description = 'Type the name of the primary contact person for the customer''s address.';
            ExternalName = 'primarycontactname';
            ExternalType = 'String';
        }
        field(7; Line1; Text[250])
        {
            Caption = 'Street 1';
            Description = 'Type the first line of the customer''s address to help identify the location.';
            ExternalName = 'line1';
            ExternalType = 'String';
        }
        field(8; Line2; Text[250])
        {
            Caption = 'Street 2';
            Description = 'Type the second line of the customer''s address.';
            ExternalName = 'line2';
            ExternalType = 'String';
        }
        field(9; Line3; Text[250])
        {
            Caption = 'Street 3';
            Description = 'Type the third line of the customer''s address.';
            ExternalName = 'line3';
            ExternalType = 'String';
        }
        field(10; City; Text[80])
        {
            Caption = 'City';
            Description = 'Type the city for the customer''s address to help identify the location.';
            ExternalName = 'city';
            ExternalType = 'String';
        }
        field(11; StateOrProvince; Text[50])
        {
            Caption = 'State/Province';
            Description = 'Type the state or province of the customer''s address.';
            ExternalName = 'stateorprovince';
            ExternalType = 'String';
        }
        field(12; County; Text[50])
        {
            Caption = 'County';
            Description = 'Type the county for the customer''s address.';
            ExternalName = 'county';
            ExternalType = 'String';
        }
        field(13; Country; Text[80])
        {
            Caption = 'Country/Region';
            Description = 'Type the country or region for the customer''s address.';
            ExternalName = 'country';
            ExternalType = 'String';
        }
        field(14; PostOfficeBox; Text[20])
        {
            Caption = 'Post Office Box';
            Description = 'Type the post office box number of the customer''s address.';
            ExternalName = 'postofficebox';
            ExternalType = 'String';
        }
        field(15; PostalCode; Text[20])
        {
            Caption = 'ZIP/Postal Code';
            Description = 'Type the ZIP Code or postal code for the address.';
            ExternalName = 'postalcode';
            ExternalType = 'String';
        }
        field(16; UTCOffset; Integer)
        {
            Caption = 'UTC Offset';
            Description = 'Select the time zone for the address.';
            ExternalName = 'utcoffset';
            ExternalType = 'Integer';
            MaxValue = 1500;
            MinValue = -1500;
        }
        field(17; FreightTermsCode; Option)
        {
            Caption = 'Freight Terms';
            Description = 'Select the freight terms to make sure shipping charges are processed correctly.';
            ExternalName = 'freighttermscode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,FOB,No Charge';
            OptionOrdinalValues = -1, 1, 2;
            OptionMembers = " ",FOB,NoCharge;
        }
        field(18; UPSZone; Text[4])
        {
            Caption = 'UPS Zone';
            Description = 'Type the UPS zone of the customer''s address to make sure shipping charges are calculated correctly and deliveries are made promptly, if shipped by UPS.';
            ExternalName = 'upszone';
            ExternalType = 'String';
        }
        field(19; Latitude; Decimal)
        {
            Caption = 'Latitude';
            Description = 'Type the latitude value for the customer''s address, for use in mapping and other applications.';
            ExternalName = 'latitude';
            ExternalType = 'Double';
        }
        field(20; Telephone1; Text[50])
        {
            Caption = 'Main Phone';
            Description = 'Type the primary phone number for the customer''s address.';
            ExternalName = 'telephone1';
            ExternalType = 'String';
        }
        field(21; Longitude; Decimal)
        {
            Caption = 'Longitude';
            Description = 'Type the longitude value for the customer''s address, for use in mapping and other applications.';
            ExternalName = 'longitude';
            ExternalType = 'Double';
        }
        field(23; Telephone2; Text[50])
        {
            Caption = 'Phone 2';
            Description = 'Type a second phone number for the customer''s address.';
            ExternalName = 'telephone2';
            ExternalType = 'String';
        }
        field(24; Telephone3; Text[50])
        {
            Caption = 'Telephone 3';
            Description = 'Type a third phone number for the customer''s address.';
            ExternalName = 'telephone3';
            ExternalType = 'String';
        }
        field(25; Fax; Text[50])
        {
            Caption = 'Fax';
            Description = 'Type the fax number associated with the customer''s address.';
            ExternalName = 'fax';
            ExternalType = 'String';
        }
        field(26; VersionNumber; BigInteger)
        {
            Caption = 'Version Number';
            Description = 'Version number of the customer address.';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(27; CreatedBy; Guid)
        {
            Caption = 'Created By';
            Description = 'Shows who created the record.';
            ExternalAccess = Read;
            ExternalName = 'createdby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(28; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            Description = 'Shows the date and time when the record was created. The date and time are displayed in the time zone selected in Microsoft Dynamics CRM options.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(29; ModifiedBy; Guid)
        {
            Caption = 'Modified By';
            Description = 'Shows who last updated the record.';
            ExternalAccess = Read;
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(30; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            Description = 'Shows the date and time when the record was last updated. The date and time are displayed in the time zone selected in Microsoft Dynamics CRM options.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
        }
        field(31; CreatedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedBy)));
            Caption = 'CreatedByName';
            ExternalAccess = Read;
            ExternalName = 'createdbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(32; ModifiedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedBy)));
            Caption = 'ModifiedByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(33; OwningBusinessUnit; Guid)
        {
            Caption = 'Owning Business Unit';
            Description = 'Shows the business unit that the record owner belongs to.';
            ExternalAccess = Read;
            ExternalName = 'owningbusinessunit';
            ExternalType = 'Lookup';
            TableRelation = "CRM Businessunit".BusinessUnitId;
        }
        field(34; OwningUser; Guid)
        {
            Caption = 'Owner';
            Description = 'Unique identifier of the user who owns the customer address.';
            ExternalAccess = Read;
            ExternalName = 'owninguser';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(35; TimeZoneRuleVersionNumber; Integer)
        {
            Caption = 'Time Zone Rule Version Number';
            Description = 'For internal use only.';
            ExternalName = 'timezoneruleversionnumber';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(36; OverriddenCreatedOn; Date)
        {
            Caption = 'Record Created On';
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
        }
        field(37; UTCConversionTimeZoneCode; Integer)
        {
            Caption = 'UTC Conversion Time Zone Code';
            Description = 'Time zone code that was in use when the record was created.';
            ExternalName = 'utcconversiontimezonecode';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(38; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            Description = 'Unique identifier of the data import or data migration that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
        }
        field(39; OwnerIdType; Option)
        {
            Caption = 'OwnerIdType';
            ExternalAccess = Read;
            ExternalName = 'owneridtype';
            ExternalType = 'EntityName';
            OptionCaption = ' ,systemuser,team';
            OptionMembers = " ",systemuser,team;
        }
        field(40; OwnerId; Guid)
        {
            Caption = 'Owner';
            Description = 'Enter the user or team who is assigned to manage the record. This field is updated every time the record is assigned to a different user.';
            ExternalAccess = Read;
            ExternalName = 'ownerid';
            ExternalType = 'Owner';
            TableRelation = if (OwnerIdType = const(systemuser)) "CRM Systemuser".SystemUserId
            else
            if (OwnerIdType = const(team)) "CRM Team".TeamId;
        }
        field(41; ParentIdTypeCode; Option)
        {
            Caption = 'Parent Object Type';
            ExternalName = 'parentidtypecode';
            ExternalType = 'EntityName';
            OptionCaption = ' ,account,contact';
            OptionMembers = " ",account,contact;
        }
        field(42; CreatedOnBehalfBy; Guid)
        {
            Caption = 'Created By (Delegate)';
            Description = 'Shows who created the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(43; CreatedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            Caption = 'CreatedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(44; ModifiedOnBehalfBy; Guid)
        {
            Caption = 'Modified By (Delegate)';
            Description = 'Shows who last updated the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(45; ModifiedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedOnBehalfBy)));
            Caption = 'ModifiedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(46; TransactionCurrencyId; Guid)
        {
            Caption = 'Currency';
            Description = 'Choose the local currency for the record to make sure budgets are reported in the correct currency.';
            ExternalName = 'transactioncurrencyid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Transactioncurrency".TransactionCurrencyId;
        }
        field(47; TransactionCurrencyIdName; Text[100])
        {
            CalcFormula = lookup("CRM Transactioncurrency".CurrencyName where(TransactionCurrencyId = field(TransactionCurrencyId)));
            Caption = 'TransactionCurrencyIdName';
            ExternalAccess = Read;
            ExternalName = 'transactioncurrencyidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(48; ExchangeRate; Decimal)
        {
            Caption = 'Exchange Rate';
            Description = 'Shows the conversion rate of the record''s currency. The exchange rate is used to convert all money fields in the record from the local currency to the system''s default currency.';
            ExternalAccess = Read;
            ExternalName = 'exchangerate';
            ExternalType = 'Decimal';
        }
        field(49; Composite; BLOB)
        {
            Caption = 'Address';
            Description = 'Shows the complete address.';
            ExternalAccess = Read;
            ExternalName = 'composite';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(50; ShippingMethodCodeEnum; Enum "CDS Shipping Agent Code")
        {
            Caption = 'Shipping Method';
            Description = 'Select a shipping method for deliveries sent to this address.';
            ExternalName = 'shippingmethodcode';
            ExternalType = 'Picklist';
            InitValue = " ";
        }
    }

    keys
    {
        key(Key1; CustomerAddressId)
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
