// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Integration.Dataverse;

table 5351 "CRM Quote"
{
    // Dynamics CRM Version: 7.1.0.2040

    Caption = 'CRM Quote';
    Description = 'Formal offer for products and/or services, proposed at specific prices and related payment terms, which is sent to a prospective customer.';
    ExternalName = 'quote';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; QuoteId; Guid)
        {
            Caption = 'Quote';
            Description = 'Unique identifier of the quote.';
            ExternalAccess = Insert;
            ExternalName = 'quoteid';
            ExternalType = 'Uniqueidentifier';
        }
        field(2; OwningBusinessUnit; Guid)
        {
            Caption = 'Owning Business Unit';
            Description = 'Unique identifier of the business unit that owns the quote.';
            ExternalAccess = Read;
            ExternalName = 'owningbusinessunit';
            ExternalType = 'Lookup';
            TableRelation = "CRM Businessunit".BusinessUnitId;
        }
        field(3; OwningUser; Guid)
        {
            Caption = 'Owning User';
            Description = 'Unique identifier of the user who owns the quote.';
            ExternalAccess = Read;
            ExternalName = 'owninguser';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(4; PriceLevelId; Guid)
        {
            Caption = 'Price List';
            Description = 'Choose the price list associated with this record to make sure the products associated with the campaign are offered at the correct prices.';
            ExternalName = 'pricelevelid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Pricelevel".PriceLevelId;
        }
        field(5; OpportunityId; Guid)
        {
            Caption = 'Opportunity';
            Description = 'Choose the opportunity that the quote is related to for reporting and analytics.';
            ExternalName = 'opportunityid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Opportunity".OpportunityId;
        }
        field(6; AccountId; Guid)
        {
            Caption = 'Account';
            Description = 'Unique identifier of the account with which the quote is associated.';
            ExternalAccess = Read;
            ExternalName = 'accountid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Account".AccountId;
        }
        field(7; ContactId; Guid)
        {
            Caption = 'Contact';
            Description = 'Unique identifier of the contact associated with the quote.';
            ExternalAccess = Read;
            ExternalName = 'contactid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Contact".ContactId;
        }
        field(8; QuoteNumber; Text[100])
        {
            Caption = 'Quote ID';
            Description = 'Shows the quote number for customer reference and searching capabilities. The number cannot be modified.';
            ExternalAccess = Insert;
            ExternalName = 'quotenumber';
            ExternalType = 'String';
        }
        field(9; RevisionNumber; Integer)
        {
            Caption = 'Revision ID';
            Description = 'Shows the version number of the quote for revision history tracking.';
            ExternalAccess = Read;
            ExternalName = 'revisionnumber';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(10; Name; Text[2048])
        {
            Caption = 'Name';
            Description = 'Type a descriptive name for the quote.';
            ExternalName = 'name';
            ExternalType = 'String';
        }
        field(11; PricingErrorCode; Option)
        {
            Caption = 'Pricing Error ';
            Description = 'Pricing error for the quote.';
            ExternalName = 'pricingerrorcode';
            ExternalType = 'Picklist';
            InitValue = "None";
            OptionCaption = 'None,Detail Error,Missing Price Level,Inactive Price Level,Missing Quantity,Missing Unit Price,Missing Product,Invalid Product,Missing Pricing Code,Invalid Pricing Code,Missing UOM,Product Not In Price Level,Missing Price Level Amount,Missing Price Level Percentage,Missing Price,Missing Current Cost,Missing Standard Cost,Invalid Price Level Amount,Invalid Price Level Percentage,Invalid Price,Invalid Current Cost,Invalid Standard Cost,Invalid Rounding Policy,Invalid Rounding Option,Invalid Rounding Amount,Price Calculation Error,Invalid Discount Type,Discount Type Invalid State,Invalid Discount,Invalid Quantity,Invalid Pricing Precision,Missing Product Default UOM,Missing Product UOM Schedule ,Inactive Discount Type,Invalid Price Level Currency,Price Attribute Out Of Range,Base Currency Attribute Overflow,Base Currency Attribute Underflow';
            OptionOrdinalValues = 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37;
            OptionMembers = "None",DetailError,MissingPriceLevel,InactivePriceLevel,MissingQuantity,MissingUnitPrice,MissingProduct,InvalidProduct,MissingPricingCode,InvalidPricingCode,MissingUOM,ProductNotInPriceLevel,MissingPriceLevelAmount,MissingPriceLevelPercentage,MissingPrice,MissingCurrentCost,MissingStandardCost,InvalidPriceLevelAmount,InvalidPriceLevelPercentage,InvalidPrice,InvalidCurrentCost,InvalidStandardCost,InvalidRoundingPolicy,InvalidRoundingOption,InvalidRoundingAmount,PriceCalculationError,InvalidDiscountType,DiscountTypeInvalidState,InvalidDiscount,InvalidQuantity,InvalidPricingPrecision,MissingProductDefaultUOM,MissingProductUOMSchedule,InactiveDiscountType,InvalidPriceLevelCurrency,PriceAttributeOutOfRange,BaseCurrencyAttributeOverflow,BaseCurrencyAttributeUnderflow;
        }
        field(12; Description; BLOB)
        {
            Caption = 'Description';
            Description = 'Type additional information to describe the quote, such as the products or services offered or details about the customer''s product preferences.';
            ExternalName = 'description';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(13; DiscountAmount; Decimal)
        {
            Caption = 'Quote Discount Amount';
            Description = 'Type the discount amount for the quote if the customer is eligible for special savings.';
            ExternalName = 'discountamount';
            ExternalType = 'Money';
        }
        field(14; FreightAmount; Decimal)
        {
            Caption = 'Freight Amount';
            Description = 'Type the cost of freight or shipping for the products included in the quote for use in calculating the Total Amount field.';
            ExternalName = 'freightamount';
            ExternalType = 'Money';
        }
        field(15; TotalAmount; Decimal)
        {
            Caption = 'Total Amount';
            Description = 'Shows the total amount due, calculated as the sum of the products, discounts, freight, and taxes for the quote.';
            ExternalAccess = Modify;
            ExternalName = 'totalamount';
            ExternalType = 'Money';
        }
        field(16; TotalLineItemAmount; Decimal)
        {
            Caption = 'Total Detail Amount';
            Description = 'Shows the sum of all existing and write-in products included on the quote, based on the specified price list and quantities.';
            ExternalAccess = Modify;
            ExternalName = 'totallineitemamount';
            ExternalType = 'Money';
        }
        field(17; TotalLineItemDiscountAmount; Decimal)
        {
            Caption = 'Total Line Item Discount Amount';
            Description = 'Shows the total of the Manual Discount amounts specified on all products included in the quote. This value is reflected in the Detail Amount field on the quote and is added to any discount amount or rate specified on the quote';
            ExternalAccess = Modify;
            ExternalName = 'totallineitemdiscountamount';
            ExternalType = 'Money';
        }
        field(18; TotalAmountLessFreight; Decimal)
        {
            Caption = 'Total Pre-Freight Amount';
            Description = 'Shows the total product amount for the quote, minus any discounts. This value is added to freight and tax amounts in the calculation for the total amount due for the quote.';
            ExternalAccess = Modify;
            ExternalName = 'totalamountlessfreight';
            ExternalType = 'Money';
        }
        field(19; EffectiveFrom; Date)
        {
            Caption = 'Effective From';
            Description = 'Enter the date when the quote pricing is effective or was first communicated to the customer.';
            ExternalName = 'effectivefrom';
            ExternalType = 'DateTime';
        }
        field(20; TotalTax; Decimal)
        {
            Caption = 'Total Tax';
            Description = 'Shows the total of the Tax amounts specified on all products included in the quote, included in the Total Amount due calculation for the quote.';
            ExternalAccess = Modify;
            ExternalName = 'totaltax';
            ExternalType = 'Money';
        }
        field(21; TotalDiscountAmount; Decimal)
        {
            Caption = 'Total Discount Amount';
            Description = 'Shows the total discount amount, based on the discount price and rate entered on the quote.';
            ExternalAccess = Modify;
            ExternalName = 'totaldiscountamount';
            ExternalType = 'Money';
        }
        field(22; EffectiveTo; Date)
        {
            Caption = 'Effective To';
            Description = 'Enter the expiration date or last day the quote pricing is effective for the customer.';
            ExternalName = 'effectiveto';
            ExternalType = 'DateTime';
        }
        field(23; ExpiresOn; Date)
        {
            Caption = 'Due By';
            Description = 'Enter the date a decision or order is due from the customer to indicate the expiration date of the quote.';
            ExternalName = 'expireson';
            ExternalType = 'DateTime';
        }
        field(24; ClosedOn; Date)
        {
            Caption = 'Closed On';
            Description = 'Enter the date when the quote was closed to indicate the expiration, revision, or cancellation date.';
            ExternalName = 'closedon';
            ExternalType = 'DateTime';
        }
        field(25; RequestDeliveryBy; Date)
        {
            Caption = 'Requested Delivery Date';
            Description = 'Enter the delivery date requested by the customer for all products in the quote.';
            ExternalName = 'requestdeliveryby';
            ExternalType = 'DateTime';
        }
        field(29; CreatedBy; Guid)
        {
            Caption = 'Created By';
            Description = 'Shows who created the record.';
            ExternalAccess = Read;
            ExternalName = 'createdby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(30; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            Description = 'Shows the date and time when the record was created. The date and time are displayed in the time zone selected in Microsoft Dynamics CRM options.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(31; ModifiedBy; Guid)
        {
            Caption = 'Modified By';
            Description = 'Shows who last updated the record.';
            ExternalAccess = Read;
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(32; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            Description = 'Shows the date and time when the record was last updated. The date and time are displayed in the time zone selected in Microsoft Dynamics CRM options.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
        }
        field(33; StateCode; Option)
        {
            Caption = 'Status';
            Description = 'Shows whether the quote is draft, active, won, or closed. Only draft quotes can be edited.';
            ExternalAccess = Modify;
            ExternalName = 'statecode';
            ExternalType = 'State';
            InitValue = Draft;
            OptionCaption = 'Draft,Active,Won,Closed';
            OptionOrdinalValues = 0, 1, 2, 3;
            OptionMembers = Draft,Active,Won,Closed;
        }
        field(34; StatusCode; Option)
        {
            Caption = 'Status Reason';
            Description = 'Select the quote''s status.';
            ExternalName = 'statuscode';
            ExternalType = 'Status';
            InitValue = " ";
            OptionCaption = ' ,In Progress,Open,Won,Lost,Canceled,Revised,In Progress1';
            OptionOrdinalValues = -1, 2, 3, 4, 5, 6, 7, 1;
            OptionMembers = " ",InProgress,Open,Won,Lost,Canceled,Revised,InProgress1;
        }
        field(35; ShipTo_Name; Text[200])
        {
            Caption = 'Ship To Name';
            Description = 'Type a name for the customer''s shipping address, such as "Headquarters" or "Field office", to identify the address.';
            ExternalName = 'shipto_name';
            ExternalType = 'String';
        }
        field(36; VersionNumber; BigInteger)
        {
            Caption = 'Version Number';
            Description = 'Version number of the quote.';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(37; ShipTo_Line1; Text[250])
        {
            Caption = 'Ship To Street 1';
            Description = 'Type the first line of the customer''s shipping address.';
            ExternalName = 'shipto_line1';
            ExternalType = 'String';
        }
        field(38; ShipTo_Line2; Text[250])
        {
            Caption = 'Ship To Street 2';
            Description = 'Type the second line of the customer''s shipping address.';
            ExternalName = 'shipto_line2';
            ExternalType = 'String';
        }
        field(39; ShipTo_Line3; Text[250])
        {
            Caption = 'Ship To Street 3';
            Description = 'Type the third line of the shipping address.';
            ExternalName = 'shipto_line3';
            ExternalType = 'String';
        }
        field(40; ShipTo_City; Text[80])
        {
            Caption = 'Ship To City';
            Description = 'Type the city for the customer''s shipping address.';
            ExternalName = 'shipto_city';
            ExternalType = 'String';
        }
        field(41; ShipTo_StateOrProvince; Text[50])
        {
            Caption = 'Ship To State/Province';
            Description = 'Type the state or province for the shipping address.';
            ExternalName = 'shipto_stateorprovince';
            ExternalType = 'String';
        }
        field(42; ShipTo_Country; Text[80])
        {
            Caption = 'Ship To Country/Region';
            Description = 'Type the country or region for the customer''s shipping address.';
            ExternalName = 'shipto_country';
            ExternalType = 'String';
        }
        field(43; ShipTo_PostalCode; Text[20])
        {
            Caption = 'Ship To ZIP/Postal Code';
            Description = 'Type the ZIP Code or postal code for the shipping address.';
            ExternalName = 'shipto_postalcode';
            ExternalType = 'String';
        }
        field(44; WillCall; Boolean)
        {
            Caption = 'Ship To';
            Description = 'Select whether the products included in the quote should be shipped to the specified address or held until the customer calls with further pick up or delivery instructions.';
            ExternalName = 'willcall';
            ExternalType = 'Boolean';
        }
        field(45; ShipTo_Telephone; Text[50])
        {
            Caption = 'Ship To Phone';
            Description = 'Type the phone number for the customer''s shipping address.';
            ExternalName = 'shipto_telephone';
            ExternalType = 'String';
        }
        field(46; BillTo_Name; Text[200])
        {
            Caption = 'Bill To Name';
            Description = 'Type a name for the customer''s billing address, such as "Headquarters" or "Field office", to identify the address.';
            ExternalName = 'billto_name';
            ExternalType = 'String';
        }
        field(47; ShipTo_FreightTermsCode; Option)
        {
            Caption = 'Ship To Freight Terms';
            Description = 'Select the freight terms to make sure shipping orders are processed correctly.';
            ExternalName = 'shipto_freighttermscode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Default Value';
            OptionOrdinalValues = -1, 1;
            OptionMembers = " ",DefaultValue;
        }
        field(48; ShipTo_Fax; Text[50])
        {
            Caption = 'Ship To Fax';
            Description = 'Type the fax number for the customer''s shipping address.';
            ExternalName = 'shipto_fax';
            ExternalType = 'String';
        }
        field(49; BillTo_Line1; Text[250])
        {
            Caption = 'Bill To Street 1';
            Description = 'Type the first line of the customer''s billing address.';
            ExternalName = 'billto_line1';
            ExternalType = 'String';
        }
        field(50; BillTo_Line2; Text[250])
        {
            Caption = 'Bill To Street 2';
            Description = 'Type the second line of the customer''s billing address.';
            ExternalName = 'billto_line2';
            ExternalType = 'String';
        }
        field(51; BillTo_Line3; Text[250])
        {
            Caption = 'Bill To Street 3';
            Description = 'Type the third line of the billing address.';
            ExternalName = 'billto_line3';
            ExternalType = 'String';
        }
        field(52; BillTo_City; Text[80])
        {
            Caption = 'Bill To City';
            Description = 'Type the city for the customer''s billing address.';
            ExternalName = 'billto_city';
            ExternalType = 'String';
        }
        field(53; BillTo_StateOrProvince; Text[50])
        {
            Caption = 'Bill To State/Province';
            Description = 'Type the state or province for the billing address.';
            ExternalName = 'billto_stateorprovince';
            ExternalType = 'String';
        }
        field(54; BillTo_Country; Text[80])
        {
            Caption = 'Bill To Country/Region';
            Description = 'Type the country or region for the customer''s billing address.';
            ExternalName = 'billto_country';
            ExternalType = 'String';
        }
        field(55; BillTo_PostalCode; Text[20])
        {
            Caption = 'Bill To ZIP/Postal Code';
            Description = 'Type the ZIP Code or postal code for the billing address.';
            ExternalName = 'billto_postalcode';
            ExternalType = 'String';
        }
        field(56; BillTo_Telephone; Text[50])
        {
            Caption = 'Bill To Phone';
            Description = 'Type the phone number for the customer''s billing address.';
            ExternalName = 'billto_telephone';
            ExternalType = 'String';
        }
        field(57; BillTo_Fax; Text[50])
        {
            Caption = 'Bill To Fax';
            Description = 'Type the fax number for the customer''s billing address.';
            ExternalName = 'billto_fax';
            ExternalType = 'String';
        }
        field(58; DiscountPercentage; Decimal)
        {
            Caption = 'Quote Discount (%)';
            Description = 'Type the discount rate that should be applied to the Detail Amount field to include additional savings for the customer in the quote.';
            ExternalName = 'discountpercentage';
            ExternalType = 'Decimal';
        }
        field(59; ContactIdName; Text[160])
        {
            CalcFormula = lookup("CRM Contact".FullName where(ContactId = field(ContactId)));
            Caption = 'ContactIdName';
            ExternalAccess = Read;
            ExternalName = 'contactidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(60; AccountIdName; Text[160])
        {
            CalcFormula = lookup("CRM Account".Name where(AccountId = field(AccountId)));
            Caption = 'AccountIdName';
            ExternalAccess = Read;
            ExternalName = 'accountidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(61; OpportunityIdName; Text[2048])
        {
            CalcFormula = lookup("CRM Opportunity".Name where(OpportunityId = field(OpportunityId)));
            Caption = 'OpportunityIdName';
            ExternalAccess = Read;
            ExternalName = 'opportunityidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(62; PriceLevelIdName; Text[100])
        {
            CalcFormula = lookup("CRM Pricelevel".Name where(PriceLevelId = field(PriceLevelId)));
            Caption = 'PriceLevelIdName';
            ExternalAccess = Read;
            ExternalName = 'pricelevelidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(63; CreatedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedBy)));
            Caption = 'CreatedByName';
            ExternalAccess = Read;
            ExternalName = 'createdbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(64; ModifiedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedBy)));
            Caption = 'ModifiedByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(65; CustomerId; Guid)
        {
            Caption = 'Potential Customer';
            Description = 'Select the customer account or contact to provide a quick link to additional customer details, such as account information, activities, and opportunities.';
            ExternalName = 'customerid';
            ExternalType = 'Customer';
            TableRelation = if (CustomerIdType = const(account)) "CRM Account".AccountId
            else
            if (CustomerIdType = const(contact)) "CRM Contact".ContactId;
        }
        field(66; CustomerIdType; Option)
        {
            Caption = 'Potential Customer Type';
            ExternalName = 'customeridtype';
            ExternalType = 'EntityName';
            OptionCaption = ' ,account,contact';
            OptionMembers = " ",account,contact;
        }
        field(67; OwnerId; Guid)
        {
            Caption = 'Owner';
            Description = 'Enter the user or team who is assigned to manage the record. This field is updated every time the record is assigned to a different user.';
            ExternalName = 'ownerid';
            ExternalType = 'Owner';
            TableRelation = if (OwnerIdType = const(systemuser)) "CRM Systemuser".SystemUserId
            else
            if (OwnerIdType = const(team)) "CRM Team".TeamId;
        }
        field(68; OwnerIdType; Option)
        {
            Caption = 'OwnerIdType';
            ExternalName = 'owneridtype';
            ExternalType = 'EntityName';
            OptionCaption = ' ,systemuser,team';
            OptionMembers = " ",systemuser,team;
        }
        field(69; ShipTo_AddressId; Guid)
        {
            Caption = 'Ship To Address ID';
            Description = 'Unique identifier of the shipping address.';
            ExternalName = 'shipto_addressid';
            ExternalType = 'Uniqueidentifier';
        }
        field(70; ShipTo_ContactName; Text[150])
        {
            Caption = 'Ship To Contact Name';
            Description = 'Type the primary contact name at the customer''s shipping address.';
            ExternalName = 'shipto_contactname';
            ExternalType = 'String';
        }
        field(71; BillTo_AddressId; Guid)
        {
            Caption = 'Bill To Address ID';
            Description = 'Unique identifier of the billing address.';
            ExternalName = 'billto_addressid';
            ExternalType = 'Uniqueidentifier';
        }
        field(72; BillTo_ContactName; Text[150])
        {
            Caption = 'Bill To Contact Name';
            Description = 'Type the primary contact name at the customer''s billing address.';
            ExternalName = 'billto_contactname';
            ExternalType = 'String';
        }
        field(73; TimeZoneRuleVersionNumber; Integer)
        {
            Caption = 'Time Zone Rule Version Number';
            Description = 'For internal use only.';
            ExternalName = 'timezoneruleversionnumber';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(74; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            Description = 'Unique identifier of the data import or data migration that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
        }
        field(75; ExchangeRate; Decimal)
        {
            Caption = 'Exchange Rate';
            Description = 'Shows the conversion rate of the record''s currency. The exchange rate is used to convert all money fields in the record from the local currency to the system''s default currency.';
            ExternalAccess = Read;
            ExternalName = 'exchangerate';
            ExternalType = 'Decimal';
        }
        field(76; OverriddenCreatedOn; Date)
        {
            Caption = 'Record Created On';
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
        }
        field(77; UTCConversionTimeZoneCode; Integer)
        {
            Caption = 'UTC Conversion Time Zone Code';
            Description = 'Time zone code that was in use when the record was created.';
            ExternalName = 'utcconversiontimezonecode';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(78; TransactionCurrencyId; Guid)
        {
            Caption = 'Currency';
            Description = 'Choose the local currency for the record to make sure budgets are reported in the correct currency.';
            ExternalName = 'transactioncurrencyid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Transactioncurrency".TransactionCurrencyId;
        }
        field(79; TotalLineItemDiscountAmount_Ba; Decimal)
        {
            Caption = 'Total Line Item Discount Amount (Base)';
            Description = 'Shows the Total Line Item Discount Amount field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'totallineitemdiscountamount_base';
            ExternalType = 'Money';
        }
        field(80; TransactionCurrencyIdName; Text[100])
        {
            CalcFormula = lookup("CRM Transactioncurrency".CurrencyName where(TransactionCurrencyId = field(TransactionCurrencyId)));
            Caption = 'TransactionCurrencyIdName';
            ExternalAccess = Read;
            ExternalName = 'transactioncurrencyidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(81; TotalAmountLessFreight_Base; Decimal)
        {
            Caption = 'Total Pre-Freight Amount (Base)';
            Description = 'Shows the Pre-Freight Amount converted field to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'totalamountlessfreight_base';
            ExternalType = 'Money';
        }
        field(82; DiscountAmount_Base; Decimal)
        {
            Caption = 'Quote Discount Amount (Base)';
            Description = 'Shows the Discount Amount field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'discountamount_base';
            ExternalType = 'Money';
        }
        field(83; FreightAmount_Base; Decimal)
        {
            Caption = 'Freight Amount (Base)';
            Description = 'Shows the Freight Amount field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'freightamount_base';
            ExternalType = 'Money';
        }
        field(84; TotalAmount_Base; Decimal)
        {
            Caption = 'Total Amount (Base)';
            Description = 'Shows the Total Amount field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'totalamount_base';
            ExternalType = 'Money';
        }
        field(85; TotalDiscountAmount_Base; Decimal)
        {
            Caption = 'Total Discount Amount (Base)';
            Description = 'Shows the Total Discount Amount converted field to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'totaldiscountamount_base';
            ExternalType = 'Money';
        }
        field(86; TotalTax_Base; Decimal)
        {
            Caption = 'Total Tax (Base)';
            Description = 'Shows the Total Tax field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'totaltax_base';
            ExternalType = 'Money';
        }
        field(87; TotalLineItemAmount_Base; Decimal)
        {
            Caption = 'Total Detail Amount (Base)';
            Description = 'Shows the Detail Amount field converted to the system''s default base currency. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'totallineitemamount_base';
            ExternalType = 'Money';
        }
        field(88; CreatedOnBehalfBy; Guid)
        {
            Caption = 'Created By (Delegate)';
            Description = 'Shows who created the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(89; CreatedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            Caption = 'CreatedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(90; ModifiedOnBehalfBy; Guid)
        {
            Caption = 'Modified By (Delegate)';
            Description = 'Shows who last updated the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(91; ModifiedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedOnBehalfBy)));
            Caption = 'ModifiedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(92; OwningTeam; Guid)
        {
            Caption = 'Owning Team';
            Description = 'Unique identifier of the team who owns the quote.';
            ExternalAccess = Read;
            ExternalName = 'owningteam';
            ExternalType = 'Lookup';
            TableRelation = "CRM Team".TeamId;
        }
        field(93; BillTo_Composite; BLOB)
        {
            Caption = 'Bill To Address';
            Description = 'Shows the complete Bill To address.';
            ExternalAccess = Read;
            ExternalName = 'billto_composite';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(94; ShipTo_Composite; BLOB)
        {
            Caption = 'Ship To Address';
            Description = 'Shows the complete Ship To address.';
            ExternalAccess = Read;
            ExternalName = 'shipto_composite';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(95; ProcessId; Guid)
        {
            Caption = 'Process';
            Description = 'Shows the ID of the process.';
            ExternalName = 'processid';
            ExternalType = 'Uniqueidentifier';
        }
        field(96; StageId; Guid)
        {
            Caption = 'Process Stage';
            Description = 'Shows the ID of the stage.';
            ExternalName = 'stageid';
            ExternalType = 'Uniqueidentifier';
        }
        field(97; TraversedPath; Text[250])
        {
            Caption = 'Traversed Path';
            Description = 'For internal use only.';
            ExternalName = 'traversedpath';
            ExternalType = 'String';
        }
        field(98; CompanyId; Guid)
        {
            Caption = 'Company Id';
            Description = 'Unique identifier of the company that owns the quote.';
            ExternalName = 'bcbi_companyid';
            ExternalType = 'Lookup';
            TableRelation = "CDS Company".CompanyId;
        }
        field(99; PaymentTermsCodeEnum; Enum "CDS Payment Terms Code")
        {
            Caption = 'Payment Terms';
            Description = 'Select the payment terms to indicate when the customer needs to pay the total amount.';
            ExternalName = 'paymenttermscode';
            ExternalType = 'Picklist';
            InitValue = " ";
        }
        field(100; ShippingMethodCodeEnum; Enum "CDS Shipping Agent Code")
        {
            Caption = 'Shipping Method';
            Description = 'Select a shipping method for deliveries sent to this address.';
            ExternalName = 'shippingmethodcode';
            ExternalType = 'Picklist';
            InitValue = " ";
        }
        field(101; FreightTermsCodeEnum; Enum "CDS Shipment Method Code")
        {
            Caption = 'Freight Terms';
            Description = 'Select the freight terms to make sure shipping charges are processed correctly.';
            ExternalName = 'freighttermscode';
            ExternalType = 'Picklist';
            InitValue = " ";
        }
    }

    keys
    {
        key(Key1; QuoteId)
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
