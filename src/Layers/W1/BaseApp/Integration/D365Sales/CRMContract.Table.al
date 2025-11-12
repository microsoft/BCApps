// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5357 "CRM Contract"
{
    // Dynamics CRM Version: 7.1.0.2040

    Caption = 'CRM Contract';
    Description = 'Agreement to provide customer service during a specified amount of time or number of cases.';
    ExternalName = 'contract';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ContractId; Guid)
        {
            Caption = 'Contract';
            Description = 'Unique identifier of the contract.';
            ExternalAccess = Insert;
            ExternalName = 'contractid';
            ExternalType = 'Uniqueidentifier';
        }
        field(2; OwningBusinessUnit; Guid)
        {
            Caption = 'Owning Business Unit';
            Description = 'Unique identifier of the business unit that owns the contract.';
            ExternalAccess = Read;
            ExternalName = 'owningbusinessunit';
            ExternalType = 'Lookup';
            TableRelation = "CRM Businessunit".BusinessUnitId;
        }
        field(3; ContractServiceLevelCode; Option)
        {
            Caption = 'Service Level';
            Description = 'Select the level of service that should be provided for the contract based on your company''s definition of bronze, silver, or gold.';
            ExternalName = 'contractservicelevelcode';
            ExternalType = 'Picklist';
            InitValue = Gold;
            OptionCaption = 'Gold,Silver,Bronze';
            OptionOrdinalValues = 1, 2, 3;
            OptionMembers = Gold,Silver,Bronze;
        }
        field(4; ServiceAddress; Guid)
        {
            Caption = 'Contract Address';
            Description = 'Choose the address for the customer account or contact where the services are provided.';
            ExternalName = 'serviceaddress';
            ExternalType = 'Lookup';
            TableRelation = "CRM Customeraddress".CustomerAddressId;
        }
        field(5; BillToAddress; Guid)
        {
            Caption = 'Bill To Address';
            Description = 'Choose which address to send the invoice to.';
            ExternalName = 'billtoaddress';
            ExternalType = 'Lookup';
            TableRelation = "CRM Customeraddress".CustomerAddressId;
        }
        field(6; OwningUser; Guid)
        {
            Caption = 'Owning User';
            Description = 'Unique identifier of the user who owns the contract.';
            ExternalAccess = Read;
            ExternalName = 'owninguser';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(7; ContactId; Guid)
        {
            Caption = 'Contact';
            Description = 'Unique identifier of the contact specified for the contract.';
            ExternalAccess = Read;
            ExternalName = 'contactid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Contact".ContactId;
        }
        field(8; AccountId; Guid)
        {
            Caption = 'Account';
            Description = 'Unique identifier of the account with which the contract is associated.';
            ExternalAccess = Read;
            ExternalName = 'accountid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Account".AccountId;
        }
        field(9; BillingAccountId; Guid)
        {
            Caption = 'Billing Account';
            Description = 'Unique identifier of the account to which the contract is to be billed.';
            ExternalAccess = Read;
            ExternalName = 'billingaccountid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Account".AccountId;
        }
        field(10; ContractNumber; Text[100])
        {
            Caption = 'Contract ID';
            Description = 'Shows the number for the contract for customer reference and searching capabilities. You cannot modify this number.';
            ExternalAccess = Insert;
            ExternalName = 'contractnumber';
            ExternalType = 'String';
        }
        field(11; BillingContactId; Guid)
        {
            Caption = 'Billing Contact';
            Description = 'Unique identifier of the contact to whom the contract is to be billed.';
            ExternalAccess = Read;
            ExternalName = 'billingcontactid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Contact".ContactId;
        }
        field(12; ActiveOn; Date)
        {
            Caption = 'Contract Start Date';
            Description = 'Enter the date when the contract becomes active.';
            ExternalName = 'activeon';
            ExternalType = 'DateTime';
        }
        field(13; ExpiresOn; Date)
        {
            Caption = 'Contract End Date';
            Description = 'Enter the date when the contract expires.';
            ExternalName = 'expireson';
            ExternalType = 'DateTime';
        }
        field(14; CancelOn; Date)
        {
            Caption = 'Cancellation Date';
            Description = 'Shows the date and time when the contract was canceled.';
            ExternalAccess = Read;
            ExternalName = 'cancelon';
            ExternalType = 'DateTime';
        }
        field(15; Title; Text[100])
        {
            Caption = 'Contract Name';
            Description = 'Type a title or name for the contract that indicates the purpose of the contract.';
            ExternalName = 'title';
            ExternalType = 'String';
        }
        field(16; ContractLanguage; BLOB)
        {
            Caption = 'Description';
            Description = 'Type additional information about the contract, such as the products or services provided to the customer.';
            ExternalName = 'contractlanguage';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(17; BillingStartOn; Date)
        {
            Caption = 'Billing Start Date';
            Description = 'Enter the start date for the contract''s billing period to indicate the period for which the customer must pay for a service. This defaults to the same date that is selected in the Contract Start Date field.';
            ExternalName = 'billingstarton';
            ExternalType = 'DateTime';
        }
        field(18; EffectivityCalendar; Text[168])
        {
            Caption = 'Support Calendar';
            Description = 'Days of the week and times during which customer service support is available for the duration of the contract.';
            ExternalName = 'effectivitycalendar';
            ExternalType = 'String';
        }
        field(19; BillingEndOn; Date)
        {
            Caption = 'Billing End Date';
            Description = 'Enter the end date for the contract''s billing period to indicate the period for which the customer must pay for a service.';
            ExternalName = 'billingendon';
            ExternalType = 'DateTime';
        }
        field(20; BillingFrequencyCode; Option)
        {
            Caption = 'Billing Frequency';
            Description = 'Select the billing schedule of the contract to indicate how often the customer should be invoiced.';
            ExternalName = 'billingfrequencycode';
            ExternalType = 'Picklist';
            InitValue = Monthly;
            OptionCaption = 'Monthly,Bimonthly,Quarterly,Semiannually,Annually';
            OptionOrdinalValues = 1, 2, 3, 4, 5;
            OptionMembers = Monthly,Bimonthly,Quarterly,Semiannually,Annually;
        }
        field(21; CreatedBy; Guid)
        {
            Caption = 'Created By';
            Description = 'Shows who created the record.';
            ExternalAccess = Read;
            ExternalName = 'createdby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(22; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            Description = 'Shows the date and time when the record was created. The date and time are displayed in the time zone selected in Microsoft Dynamics CRM options.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(23; ModifiedBy; Guid)
        {
            Caption = 'Modified By';
            Description = 'Shows who last updated the record.';
            ExternalAccess = Read;
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(24; AllotmentTypeCode; Option)
        {
            Caption = 'Allotment Type';
            Description = 'Type of allotment that the contract supports.';
            ExternalName = 'allotmenttypecode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Number of Cases,Time,Coverage Dates';
            OptionOrdinalValues = -1, 1, 2, 3;
            OptionMembers = " ",NumberofCases,Time,CoverageDates;
        }
        field(25; UseDiscountAsPercentage; Boolean)
        {
            Caption = 'Discount';
            Description = 'Select whether the discounts entered on contract lines for this contract should be entered as a percentage or a fixed dollar value.';
            ExternalAccess = Insert;
            ExternalName = 'usediscountaspercentage';
            ExternalType = 'Boolean';
        }
        field(26; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            Description = 'Shows the date and time when the record was last updated. The date and time are displayed in the time zone selected in Microsoft Dynamics CRM options.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
        }
        field(27; TotalPrice; Decimal)
        {
            Caption = 'Total Price';
            Description = 'Shows the total service charge for the contract, before any discounts are credited. This is calculated as the sum of values in the Total Price field for each existing contract line related to the contract.';
            ExternalAccess = Read;
            ExternalName = 'totalprice';
            ExternalType = 'Money';
        }
        field(28; VersionNumber; BigInteger)
        {
            Caption = 'Version Number';
            Description = 'Version number of the contract.';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(29; TotalDiscount; Decimal)
        {
            Caption = 'Total Discount';
            Description = 'Shows the total discount applied to the contract''s service charges, calculated as the sum of values in the Discount fields for each existing contract line related to the contract.';
            ExternalAccess = Read;
            ExternalName = 'totaldiscount';
            ExternalType = 'Money';
        }
        field(30; StateCode; Option)
        {
            Caption = 'Status';
            Description = 'Shows whether the contract is in draft, invoiced, active, on hold, canceled, or expired. You can edit only the contracts that are in draft status.';
            ExternalAccess = Modify;
            ExternalName = 'statecode';
            ExternalType = 'State';
            InitValue = Draft;
            OptionCaption = 'Draft,Invoiced,Active,On Hold,Canceled,Expired';
            OptionOrdinalValues = 0, 1, 2, 3, 4, 5;
            OptionMembers = Draft,Invoiced,Active,OnHold,Canceled,Expired;
        }
        field(31; NetPrice; Decimal)
        {
            Caption = 'Net Price';
            Description = 'Shows the total charge to the customer for the service contract, calculated as the sum of values in the Net field for each existing contract line related to the contract.';
            ExternalAccess = Read;
            ExternalName = 'netprice';
            ExternalType = 'Money';
        }
        field(32; StatusCode; Option)
        {
            Caption = 'Status Reason';
            Description = 'Select the contract''s status.';
            ExternalName = 'statuscode';
            ExternalType = 'Status';
            InitValue = " ";
            OptionCaption = ' ,Draft,Invoiced,Active,On Hold,Canceled,Expired';
            OptionOrdinalValues = -1, 1, 2, 3, 4, 5, 6;
            OptionMembers = " ",Draft,Invoiced,Active,OnHold,Canceled,Expired;
        }
        field(33; OriginatingContract; Guid)
        {
            Caption = 'Originating Contract';
            Description = 'Choose the original contract that this contract was created from. This information is used to track renewal history.';
            ExternalAccess = Insert;
            ExternalName = 'originatingcontract';
            ExternalType = 'Lookup';
            TableRelation = "CRM Contract".ContractId;
        }
        field(34; Duration; Integer)
        {
            Caption = 'Duration';
            Description = 'Shows for the duration of the contract, in days, based on the contract start and end dates.';
            ExternalAccess = Read;
            ExternalName = 'duration';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(35; ContactIdName; Text[160])
        {
            CalcFormula = lookup("CRM Contact".FullName where(ContactId = field(ContactId)));
            Caption = 'ContactIdName';
            ExternalAccess = Read;
            ExternalName = 'contactidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(36; AccountIdName; Text[160])
        {
            CalcFormula = lookup("CRM Account".Name where(AccountId = field(AccountId)));
            Caption = 'AccountIdName';
            ExternalAccess = Read;
            ExternalName = 'accountidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(37; BillingContactIdName; Text[160])
        {
            CalcFormula = lookup("CRM Contact".FullName where(ContactId = field(BillingContactId)));
            Caption = 'BillingContactIdName';
            ExternalAccess = Read;
            ExternalName = 'billingcontactidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(38; BillingAccountIdName; Text[160])
        {
            CalcFormula = lookup("CRM Account".Name where(AccountId = field(BillingAccountId)));
            Caption = 'BillingAccountIdName';
            ExternalAccess = Read;
            ExternalName = 'billingaccountidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(39; OriginatingContractName; Text[100])
        {
            CalcFormula = lookup("CRM Contract".Title where(ContractId = field(OriginatingContract)));
            Caption = 'OriginatingContractName';
            ExternalAccess = Read;
            ExternalName = 'originatingcontractname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(40; BillToAddressName; Text[200])
        {
            CalcFormula = lookup("CRM Customeraddress".Name where(CustomerAddressId = field(BillToAddress)));
            Caption = 'BillToAddressName';
            Description = 'Name of the address that is to be billed for the contract.';
            ExternalAccess = Read;
            ExternalName = 'billtoaddressname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(41; ServiceAddressName; Text[200])
        {
            CalcFormula = lookup("CRM Customeraddress".Name where(CustomerAddressId = field(ServiceAddress)));
            Caption = 'ServiceAddressName';
            ExternalAccess = Read;
            ExternalName = 'serviceaddressname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(42; ContractTemplateAbbreviation; Text[20])
        {
            Caption = 'Template Abbreviation';
            Description = 'Shows the abbreviation of the contract template selected when the contract is created.';
            ExternalAccess = Read;
            ExternalName = 'contracttemplateabbreviation';
            ExternalType = 'String';
        }
        field(43; CreatedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedBy)));
            Caption = 'CreatedByName';
            ExternalAccess = Read;
            ExternalName = 'createdbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(44; ModifiedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedBy)));
            Caption = 'ModifiedByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(45; CustomerId; Guid)
        {
            Caption = 'Customer';
            Description = 'Select the customer account or contact to provide a quick link to additional customer details, such as address, phone number, activities, and orders.';
            ExternalName = 'customerid';
            ExternalType = 'Customer';
            TableRelation = if (CustomerIdType = const(account)) "CRM Account".AccountId
            else
            if (CustomerIdType = const(contact)) "CRM Contact".ContactId;
        }
        field(46; CustomerIdType; Option)
        {
            Caption = 'Customer Type';
            ExternalName = 'customeridtype';
            ExternalType = 'EntityName';
            OptionCaption = ' ,account,contact';
            OptionMembers = " ",account,contact;
        }
        field(47; BillingCustomerId; Guid)
        {
            Caption = 'Bill To Customer';
            Description = 'Select the customer account or contact to which the contract should be billed to provide a quick link to address and other customer details.';
            ExternalName = 'billingcustomerid';
            ExternalType = 'Customer';
            TableRelation = if (BillingCustomerIdType = const(account)) "CRM Account".AccountId
            else
            if (BillingCustomerIdType = const(contact)) "CRM Contact".ContactId;
        }
        field(48; BillingCustomerIdType; Option)
        {
            Caption = 'Bill To Customer Type';
            ExternalName = 'billingcustomeridtype';
            ExternalType = 'EntityName';
            OptionCaption = ' ,account,contact';
            OptionMembers = " ",account,contact;
        }
        field(49; OwnerId; Guid)
        {
            Caption = 'Owner';
            Description = 'Enter the user or team who is assigned to manage the record. This field is updated every time the record is assigned to a different user.';
            ExternalName = 'ownerid';
            ExternalType = 'Owner';
            TableRelation = if (OwnerIdType = const(systemuser)) "CRM Systemuser".SystemUserId
            else
            if (OwnerIdType = const(team)) "CRM Team".TeamId;
        }
        field(50; OwnerIdType; Option)
        {
            Caption = 'OwnerIdType';
            ExternalName = 'owneridtype';
            ExternalType = 'EntityName';
            OptionCaption = ' ,systemuser,team';
            OptionMembers = " ",systemuser,team;
        }
        field(51; TimeZoneRuleVersionNumber; Integer)
        {
            Caption = 'Time Zone Rule Version Number';
            Description = 'For internal use only.';
            ExternalName = 'timezoneruleversionnumber';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(52; OverriddenCreatedOn; Date)
        {
            Caption = 'Record Created On';
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
        }
        field(53; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            Description = 'Unique identifier of the data import or data migration that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
        }
        field(54; UTCConversionTimeZoneCode; Integer)
        {
            Caption = 'UTC Conversion Time Zone Code';
            Description = 'Time zone code that was in use when the record was created.';
            ExternalName = 'utcconversiontimezonecode';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(55; TransactionCurrencyId; Guid)
        {
            Caption = 'Currency';
            Description = 'Choose the local currency for the record to make sure budgets are reported in the correct currency.';
            ExternalAccess = Insert;
            ExternalName = 'transactioncurrencyid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Transactioncurrency".TransactionCurrencyId;
        }
        field(56; ExchangeRate; Decimal)
        {
            Caption = 'Exchange Rate';
            Description = 'Shows the conversion rate of the record''s currency. The exchange rate is used to convert all money fields in the record from the local currency to the system''s default currency.';
            ExternalAccess = Read;
            ExternalName = 'exchangerate';
            ExternalType = 'Decimal';
        }
        field(57; TotalDiscount_Base; Decimal)
        {
            Caption = 'Total Discount (Base)';
            Description = 'Shows the Total Discount field converted to the system''s default base currency for reporting purposes. The calculations use the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'totaldiscount_base';
            ExternalType = 'Money';
        }
        field(58; NetPrice_Base; Decimal)
        {
            Caption = 'Net Price (Base)';
            Description = 'Shows the Net Price field converted to the system''s default base currency for reporting purposes. The calculations use the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'netprice_base';
            ExternalType = 'Money';
        }
        field(59; TransactionCurrencyIdName; Text[100])
        {
            CalcFormula = lookup("CRM Transactioncurrency".CurrencyName where(TransactionCurrencyId = field(TransactionCurrencyId)));
            Caption = 'TransactionCurrencyIdName';
            ExternalAccess = Read;
            ExternalName = 'transactioncurrencyidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(60; TotalPrice_Base; Decimal)
        {
            Caption = 'Total Price (Base)';
            Description = 'Shows the Total Price field converted to the system''s default base currency for reporting purposes. The calculations use the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'totalprice_base';
            ExternalType = 'Money';
        }
        field(61; CreatedOnBehalfBy; Guid)
        {
            Caption = 'Created By (Delegate)';
            Description = 'Shows who created the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(62; CreatedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            Caption = 'CreatedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(63; ModifiedOnBehalfBy; Guid)
        {
            Caption = 'Modified By (Delegate)';
            Description = 'Shows who last updated the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(64; ModifiedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedOnBehalfBy)));
            Caption = 'ModifiedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(65; OwningTeam; Guid)
        {
            Caption = 'Owning Team';
            Description = 'Unique identifier of the team who owns the contract.';
            ExternalAccess = Read;
            ExternalName = 'owningteam';
            ExternalType = 'Lookup';
            TableRelation = "CRM Team".TeamId;
        }
        field(66; EntityImageId; Guid)
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
        key(Key1; ContractId)
        {
            Clustered = true;
        }
        key(Key2; Title)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Title)
        {
        }
    }
}

