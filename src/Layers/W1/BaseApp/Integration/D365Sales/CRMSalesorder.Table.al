// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Integration.Dataverse;

table 5353 "CRM Salesorder"
{
    // Dynamics CRM Version: 7.1.0.2040

    Caption = 'CRM Salesorder';
    DataCaptionFields = Name, OrderNumber;
    Description = 'Quote that has been accepted.';
    ExternalName = 'salesorder';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; SalesOrderId; Guid)
        {
            Caption = 'Order';
            Description = 'Unique identifier of the order.';
            ExternalAccess = Insert;
            ExternalName = 'salesorderid';
            ExternalType = 'Uniqueidentifier';
        }
        field(2; OpportunityId; Guid)
        {
            Caption = 'Opportunity';
            Description = 'Choose the related opportunity so that the data for the order and opportunity are linked for reporting and analytics.';
            ExternalName = 'opportunityid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Opportunity".OpportunityId;
        }
        field(3; QuoteId; Guid)
        {
            Caption = 'Quote';
            Description = 'Choose the related quote so that order data and quote data are linked for reporting and analytics.';
            ExternalName = 'quoteid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Quote".QuoteId;
        }
        field(4; PriorityCode; Option)
        {
            Caption = 'Priority';
            Description = 'Select the priority so that preferred customers or critical issues are handled quickly.';
            ExternalName = 'prioritycode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(5; SubmitStatus; Integer)
        {
            Caption = 'Submitted Status';
            Description = 'Type the code for the submitted status in the fulfillment or shipping center system.';
            ExternalName = 'submitstatus';
            ExternalType = 'Integer';
            MaxValue = 1000000000;
            MinValue = 0;
        }
        field(6; OwningUser; Guid)
        {
            Caption = 'Owning User';
            Description = 'Unique identifier of the user who owns the order.';
            ExternalAccess = Read;
            ExternalName = 'owninguser';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(7; SubmitDate; Date)
        {
            Caption = 'Date Submitted';
            Description = 'Enter the date when the order was submitted to the fulfillment or shipping center.';
            ExternalName = 'submitdate';
            ExternalType = 'DateTime';
        }
        field(8; OwningBusinessUnit; Guid)
        {
            Caption = 'Owning Business Unit';
            Description = 'Shows the business unit that the record owner belongs to.';
            ExternalAccess = Read;
            ExternalName = 'owningbusinessunit';
            ExternalType = 'Lookup';
            TableRelation = "CRM Businessunit".BusinessUnitId;
        }
        field(9; SubmitStatusDescription; BLOB)
        {
            Caption = 'Submitted Status Description';
            Description = 'Type additional details or notes about the order for the fulfillment or shipping center.';
            ExternalName = 'submitstatusdescription';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(10; PriceLevelId; Guid)
        {
            Caption = 'Price List';
            Description = 'Choose the price list associated with this record to make sure the products associated with the campaign are offered at the correct prices.';
            ExternalName = 'pricelevelid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Pricelevel".PriceLevelId;
        }
        field(11; LastBackofficeSubmit; Date)
        {
            Caption = 'Last Submitted to Back Office';
            Description = 'Enter the date and time when the order was last submitted to an accounting or ERP system for processing.';
            ExternalName = 'lastbackofficesubmit';
            ExternalType = 'DateTime';
        }
        field(12; AccountId; Guid)
        {
            Caption = 'Account';
            Description = 'Shows the parent account related to the record. This information is used to link the sales order to the account selected in the Customer field for reporting and analytics.';
            ExternalAccess = Read;
            ExternalName = 'accountid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Account".AccountId;
        }
        field(13; ContactId; Guid)
        {
            Caption = 'Contact';
            Description = 'Shows the parent contact related to the record. This information is used to link the contract to the contact selected in the Customer field for reporting and analytics.';
            ExternalAccess = Read;
            ExternalName = 'contactid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Contact".ContactId;
        }
        field(14; OrderNumber; Text[100])
        {
            Caption = 'Order ID';
            Description = 'Shows the order number for customer reference and to use in search. The number cannot be modified.';
            ExternalAccess = Insert;
            ExternalName = 'ordernumber';
            ExternalType = 'String';
        }
        field(15; Name; Text[2048])
        {
            Caption = 'Name';
            Description = 'Type a descriptive name for the order.';
            ExternalName = 'name';
            ExternalType = 'String';
        }
        field(16; PricingErrorCode; Option)
        {
            Caption = 'Pricing Error ';
            Description = 'Select the type of pricing error, such as a missing or invalid product, or missing quantity.';
            ExternalName = 'pricingerrorcode';
            ExternalType = 'Picklist';
            InitValue = "None";
            OptionCaption = 'None,Detail Error,Missing Price Level,Inactive Price Level,Missing Quantity,Missing Unit Price,Missing Product,Invalid Product,Missing Pricing Code,Invalid Pricing Code,Missing UOM,Product Not In Price Level,Missing Price Level Amount,Missing Price Level Percentage,Missing Price,Missing Current Cost,Missing Standard Cost,Invalid Price Level Amount,Invalid Price Level Percentage,Invalid Price,Invalid Current Cost,Invalid Standard Cost,Invalid Rounding Policy,Invalid Rounding Option,Invalid Rounding Amount,Price Calculation Error,Invalid Discount Type,Discount Type Invalid State,Invalid Discount,Invalid Quantity,Invalid Pricing Precision,Missing Product Default UOM,Missing Product UOM Schedule ,Inactive Discount Type,Invalid Price Level Currency,Price Attribute Out Of Range,Base Currency Attribute Overflow,Base Currency Attribute Underflow';
            OptionOrdinalValues = 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37;
            OptionMembers = "None",DetailError,MissingPriceLevel,InactivePriceLevel,MissingQuantity,MissingUnitPrice,MissingProduct,InvalidProduct,MissingPricingCode,InvalidPricingCode,MissingUOM,ProductNotInPriceLevel,MissingPriceLevelAmount,MissingPriceLevelPercentage,MissingPrice,MissingCurrentCost,MissingStandardCost,InvalidPriceLevelAmount,InvalidPriceLevelPercentage,InvalidPrice,InvalidCurrentCost,InvalidStandardCost,InvalidRoundingPolicy,InvalidRoundingOption,InvalidRoundingAmount,PriceCalculationError,InvalidDiscountType,DiscountTypeInvalidState,InvalidDiscount,InvalidQuantity,InvalidPricingPrecision,MissingProductDefaultUOM,MissingProductUOMSchedule,InactiveDiscountType,InvalidPriceLevelCurrency,PriceAttributeOutOfRange,BaseCurrencyAttributeOverflow,BaseCurrencyAttributeUnderflow;
        }
        field(17; Description; BLOB)
        {
            Caption = 'Description';
            Description = 'Type additional information to describe the order, such as the products or services offered or details about the customer''s product preferences.';
            ExternalName = 'description';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(18; DiscountAmount; Decimal)
        {
            Caption = 'Order Discount Amount';
            Description = 'Type the discount amount for the order if the customer is eligible for special savings.';
            ExternalName = 'discountamount';
            ExternalType = 'Money';
        }
        field(19; FreightAmount; Decimal)
        {
            Caption = 'Freight Amount';
            Description = 'Type the cost of freight or shipping for the products included in the order for use in calculating the Total Amount field.';
            ExternalName = 'freightamount';
            ExternalType = 'Money';
        }
        field(20; TotalAmount; Decimal)
        {
            Caption = 'Total Amount';
            Description = 'Shows the total amount due, calculated as the sum of the products, discounts, freight, and taxes for the order.';
            ExternalAccess = Modify;
            ExternalName = 'totalamount';
            ExternalType = 'Money';
        }
        field(21; TotalLineItemAmount; Decimal)
        {
            Caption = 'Total Detail Amount';
            Description = 'Shows the sum of all existing and write-in products included on the order, based on the specified price list and quantities.';
            ExternalAccess = Modify;
            ExternalName = 'totallineitemamount';
            ExternalType = 'Money';
        }
        field(22; TotalLineItemDiscountAmount; Decimal)
        {
            Caption = 'Total Line Item Discount Amount';
            Description = 'Shows the total of the Manual Discount amounts specified on all products included in the order. This value is reflected in the Detail Amount field on the order and is added to any discount amount or rate specified on the order.';
            ExternalAccess = Modify;
            ExternalName = 'totallineitemdiscountamount';
            ExternalType = 'Money';
        }
        field(23; TotalAmountLessFreight; Decimal)
        {
            Caption = 'Total Pre-Freight Amount';
            Description = 'Shows the total product amount for the order, minus any discounts. This value is added to freight and tax amounts in the calculation for the total amount due for the order.';
            ExternalAccess = Modify;
            ExternalName = 'totalamountlessfreight';
            ExternalType = 'Money';
        }
        field(24; TotalDiscountAmount; Decimal)
        {
            Caption = 'Total Discount Amount';
            Description = 'Shows the total discount amount, based on the discount price and rate entered on the order.';
            ExternalAccess = Modify;
            ExternalName = 'totaldiscountamount';
            ExternalType = 'Money';
        }
        field(25; RequestDeliveryBy; Date)
        {
            Caption = 'Requested Delivery Date';
            Description = 'Enter the delivery date requested by the customer for all products in the order.';
            ExternalName = 'requestdeliveryby';
            ExternalType = 'DateTime';
        }
        field(26; TotalTax; Decimal)
        {
            Caption = 'Total Tax';
            Description = 'Shows the Tax amounts specified on all products included in the order, included in the Total Amount due calculation for the order.';
            ExternalAccess = Modify;
            ExternalName = 'totaltax';
            ExternalType = 'Money';
        }
        field(30; CreatedBy; Guid)
        {
            Caption = 'Created By';
            Description = 'Shows who created the record.';
            ExternalAccess = Read;
            ExternalName = 'createdby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(31; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            Description = 'Shows the date and time when the record was created. The date and time are displayed in the time zone selected in Microsoft Dynamics CRM options.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(32; ModifiedBy; Guid)
        {
            Caption = 'Modified By';
            Description = 'Shows who last updated the record.';
            ExternalAccess = Read;
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(33; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            Description = 'Shows the date and time when the record was last updated. The date and time are displayed in the time zone selected in Microsoft Dynamics CRM options.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
        }
        field(34; StateCode; Option)
        {
            Caption = 'Status';
            Description = 'Shows whether the order is active, submitted, fulfilled, canceled, or invoiced. Only active orders can be edited.';
            ExternalAccess = Modify;
            ExternalName = 'statecode';
            ExternalType = 'State';
            InitValue = Active;
            OptionCaption = 'Active,Submitted,Canceled,Fulfilled,Invoiced';
            OptionOrdinalValues = 0, 1, 2, 3, 4;
            OptionMembers = Active,Submitted,Canceled,Fulfilled,Invoiced;
        }
        field(35; StatusCode; Option)
        {
            Caption = 'Status Reason';
            Description = 'Select the order''s status.';
            ExternalName = 'statuscode';
            ExternalType = 'Status';
            InitValue = " ";
            OptionCaption = ' ,In Progress,No Money,New,Pending,Complete,Partial,Invoiced';
            OptionOrdinalValues = -1, 3, 4, 1, 2, 100001, 100002, 100003;
            OptionMembers = " ",InProgress,NoMoney,New,Pending,Complete,Partial,Invoiced;
        }
        field(36; ShipTo_Name; Text[200])
        {
            Caption = 'Ship To Name';
            Description = 'Type a name for the customer''s shipping address, such as "Headquarters" or "Field office", to identify the address.';
            ExternalName = 'shipto_name';
            ExternalType = 'String';
        }
        field(37; VersionNumber; BigInteger)
        {
            Caption = 'Version Number';
            Description = 'Version number of the order.';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(38; ShipTo_Line1; Text[250])
        {
            Caption = 'Ship To Street 1';
            Description = 'Type the first line of the customer''s shipping address.';
            ExternalName = 'shipto_line1';
            ExternalType = 'String';
        }
        field(39; ShipTo_Line2; Text[250])
        {
            Caption = 'Ship To Street 2';
            Description = 'Type the second line of the customer''s shipping address.';
            ExternalName = 'shipto_line2';
            ExternalType = 'String';
        }
        field(40; ShipTo_Line3; Text[250])
        {
            Caption = 'Ship To Street 3';
            Description = 'Type the third line of the shipping address.';
            ExternalName = 'shipto_line3';
            ExternalType = 'String';
        }
        field(41; ShipTo_City; Text[80])
        {
            Caption = 'Ship To City';
            Description = 'Type the city for the customer''s shipping address.';
            ExternalName = 'shipto_city';
            ExternalType = 'String';
        }
        field(42; ShipTo_StateOrProvince; Text[50])
        {
            Caption = 'Ship To State/Province';
            Description = 'Type the state or province for the shipping address.';
            ExternalName = 'shipto_stateorprovince';
            ExternalType = 'String';
        }
        field(43; ShipTo_Country; Text[80])
        {
            Caption = 'Ship To Country/Region';
            Description = 'Type the country or region for the customer''s shipping address.';
            ExternalName = 'shipto_country';
            ExternalType = 'String';
        }
        field(44; ShipTo_PostalCode; Text[20])
        {
            Caption = 'Ship To ZIP/Postal Code';
            Description = 'Type the ZIP Code or postal code for the shipping address.';
            ExternalName = 'shipto_postalcode';
            ExternalType = 'String';
        }
        field(45; WillCall; Boolean)
        {
            Caption = 'Ship To';
            Description = 'Select whether the products included in the order should be shipped to the specified address or held until the customer calls with further pick-up or delivery instructions.';
            ExternalName = 'willcall';
            ExternalType = 'Boolean';
        }
        field(46; ShipTo_Telephone; Text[50])
        {
            Caption = 'Ship To Phone';
            Description = 'Type the phone number for the customer''s shipping address.';
            ExternalName = 'shipto_telephone';
            ExternalType = 'String';
        }
        field(47; BillTo_Name; Text[200])
        {
            Caption = 'Bill To Name';
            Description = 'Type a name for the customer''s billing address, such as "Headquarters" or "Field office", to identify the address.';
            ExternalName = 'billto_name';
            ExternalType = 'String';
        }
        field(48; ShipTo_FreightTermsCode; Option)
        {
            Caption = 'Ship To Freight Terms';
            Description = 'Select the freight terms to make sure shipping orders are processed correctly.';
            ExternalName = 'shipto_freighttermscode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(49; ShipTo_Fax; Text[50])
        {
            Caption = 'Ship to Fax';
            Description = 'Type the fax number for the customer''s shipping address.';
            ExternalName = 'shipto_fax';
            ExternalType = 'String';
        }
        field(50; BillTo_Line1; Text[250])
        {
            Caption = 'Bill To Street 1';
            Description = 'Type the first line of the customer''s billing address.';
            ExternalName = 'billto_line1';
            ExternalType = 'String';
        }
        field(51; BillTo_Line2; Text[250])
        {
            Caption = 'Bill To Street 2';
            Description = 'Type the second line of the customer''s billing address.';
            ExternalName = 'billto_line2';
            ExternalType = 'String';
        }
        field(52; BillTo_Line3; Text[250])
        {
            Caption = 'Bill To Street 3';
            Description = 'Type the third line of the billing address.';
            ExternalName = 'billto_line3';
            ExternalType = 'String';
        }
        field(53; BillTo_City; Text[80])
        {
            Caption = 'Bill To City';
            Description = 'Type the city for the customer''s billing address.';
            ExternalName = 'billto_city';
            ExternalType = 'String';
        }
        field(54; BillTo_StateOrProvince; Text[50])
        {
            Caption = 'Bill To State/Province';
            Description = 'Type the state or province for the billing address.';
            ExternalName = 'billto_stateorprovince';
            ExternalType = 'String';
        }
        field(55; BillTo_Country; Text[80])
        {
            Caption = 'Bill To Country/Region';
            Description = 'Type the country or region for the customer''s billing address.';
            ExternalName = 'billto_country';
            ExternalType = 'String';
        }
        field(56; BillTo_PostalCode; Text[20])
        {
            Caption = 'Bill To ZIP/Postal Code';
            Description = 'Type the ZIP Code or postal code for the billing address.';
            ExternalName = 'billto_postalcode';
            ExternalType = 'String';
        }
        field(57; BillTo_Telephone; Text[50])
        {
            Caption = 'Bill To Phone';
            Description = 'Type the phone number for the customer''s billing address.';
            ExternalName = 'billto_telephone';
            ExternalType = 'String';
        }
        field(58; BillTo_Fax; Text[50])
        {
            Caption = 'Bill To Fax';
            Description = 'Type the fax number for the customer''s billing address.';
            ExternalName = 'billto_fax';
            ExternalType = 'String';
        }
        field(59; DiscountPercentage; Decimal)
        {
            Caption = 'Order Discount (%)';
            Description = 'Type the discount rate that should be applied to the Detail Amount field to include additional savings for the customer in the order.';
            ExternalName = 'discountpercentage';
            ExternalType = 'Decimal';
        }
        field(60; ContactIdName; Text[160])
        {
            CalcFormula = lookup("CRM Contact".FullName where(ContactId = field(ContactId)));
            Caption = 'ContactIdName';
            ExternalAccess = Read;
            ExternalName = 'contactidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(61; AccountIdName; Text[160])
        {
            CalcFormula = lookup("CRM Account".Name where(AccountId = field(AccountId)));
            Caption = 'AccountIdName';
            ExternalAccess = Read;
            ExternalName = 'accountidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(62; OpportunityIdName; Text[2048])
        {
            CalcFormula = lookup("CRM Opportunity".Name where(OpportunityId = field(OpportunityId)));
            Caption = 'OpportunityIdName';
            ExternalAccess = Read;
            ExternalName = 'opportunityidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(63; QuoteIdName; Text[2048])
        {
            CalcFormula = lookup("CRM Quote".Name where(QuoteId = field(QuoteId)));
            Caption = 'QuoteIdName';
            ExternalAccess = Read;
            ExternalName = 'quoteidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(64; PriceLevelIdName; Text[100])
        {
            CalcFormula = lookup("CRM Pricelevel".Name where(PriceLevelId = field(PriceLevelId)));
            Caption = 'PriceLevelIdName';
            ExternalAccess = Read;
            ExternalName = 'pricelevelidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(65; CreatedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedBy)));
            Caption = 'CreatedByName';
            ExternalAccess = Read;
            ExternalName = 'createdbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(66; ModifiedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedBy)));
            Caption = 'ModifiedByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(67; CustomerId; Guid)
        {
            Caption = 'Customer';
            Description = 'Select the customer account or contact to provide a quick link to additional customer details, such as account information, activities, and opportunities.';
            ExternalName = 'customerid';
            ExternalType = 'Customer';
            TableRelation = if (CustomerIdType = const(account)) "CRM Account".AccountId
            else
            if (CustomerIdType = const(contact)) "CRM Contact".ContactId;
        }
        field(68; CustomerIdType; Option)
        {
            Caption = 'Customer Type';
            ExternalName = 'customeridtype';
            ExternalType = 'EntityName';
            OptionCaption = ' ,account,contact';
            OptionMembers = " ",account,contact;
        }
        field(69; OwnerId; Guid)
        {
            Caption = 'Owner';
            Description = 'Enter the user or team who is assigned to manage the record. This field is updated every time the record is assigned to a different user.';
            ExternalName = 'ownerid';
            ExternalType = 'Owner';
            TableRelation = if (OwnerIdType = const(systemuser)) "CRM Systemuser".SystemUserId
            else
            if (OwnerIdType = const(team)) "CRM Team".TeamId;
        }
        field(70; OwnerIdType; Option)
        {
            Caption = 'OwnerIdType';
            ExternalName = 'owneridtype';
            ExternalType = 'EntityName';
            OptionCaption = ' ,systemuser,team';
            OptionMembers = " ",systemuser,team;
        }
        field(71; BillTo_ContactName; Text[150])
        {
            Caption = 'Bill To Contact Name';
            Description = 'Type the primary contact name at the customer''s billing address.';
            ExternalName = 'billto_contactname';
            ExternalType = 'String';
        }
        field(72; BillTo_AddressId; Guid)
        {
            Caption = 'Bill To Address ID';
            Description = 'Unique identifier of the billing address.';
            ExternalName = 'billto_addressid';
            ExternalType = 'Uniqueidentifier';
        }
        field(73; ShipTo_AddressId; Guid)
        {
            Caption = 'Ship To Address ID';
            Description = 'Unique identifier of the shipping address.';
            ExternalName = 'shipto_addressid';
            ExternalType = 'Uniqueidentifier';
        }
        field(74; IsPriceLocked; Boolean)
        {
            Caption = 'Prices Locked';
            Description = 'Select whether prices specified on the invoice are locked from any further updates.';
            ExternalAccess = Modify;
            ExternalName = 'ispricelocked';
            ExternalType = 'Boolean';
        }
        field(75; DateFulfilled; Date)
        {
            Caption = 'Date Fulfilled';
            Description = 'Enter the date that all or part of the order was shipped to the customer.';
            ExternalName = 'datefulfilled';
            ExternalType = 'DateTime';
        }
        field(76; ShipTo_ContactName; Text[150])
        {
            Caption = 'Ship To Contact Name';
            Description = 'Type the primary contact name at the customer''s shipping address.';
            ExternalName = 'shipto_contactname';
            ExternalType = 'String';
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
            ExternalAccess = Insert;
            ExternalName = 'transactioncurrencyid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Transactioncurrency".TransactionCurrencyId;
        }
        field(79; TimeZoneRuleVersionNumber; Integer)
        {
            Caption = 'Time Zone Rule Version Number';
            Description = 'For internal use only.';
            ExternalName = 'timezoneruleversionnumber';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(80; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            Description = 'Unique identifier of the data import or data migration that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
        }
        field(81; ExchangeRate; Decimal)
        {
            Caption = 'Exchange Rate';
            Description = 'Shows the conversion rate of the record''s currency. The exchange rate is used to convert all money fields in the record from the local currency to the system''s default currency.';
            ExternalAccess = Read;
            ExternalName = 'exchangerate';
            ExternalType = 'Decimal';
        }
        field(82; OverriddenCreatedOn; Date)
        {
            Caption = 'Record Created On';
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
        }
        field(83; TotalLineItemAmount_Base; Decimal)
        {
            Caption = 'Total Detail Amount (Base)';
            Description = 'Shows the Detail Amount field converted to the system''s default base currency. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'totallineitemamount_base';
            ExternalType = 'Money';
        }
        field(84; TotalDiscountAmount_Base; Decimal)
        {
            Caption = 'Total Discount Amount (Base)';
            Description = 'Shows the Total Discount Amount field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'totaldiscountamount_base';
            ExternalType = 'Money';
        }
        field(85; TotalAmountLessFreight_Base; Decimal)
        {
            Caption = 'Total Pre-Freight Amount (Base)';
            Description = 'Shows the Pre-Freight Amount field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'totalamountlessfreight_base';
            ExternalType = 'Money';
        }
        field(86; TotalAmount_Base; Decimal)
        {
            Caption = 'Total Amount (Base)';
            Description = 'Shows the Total Amount field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'totalamount_base';
            ExternalType = 'Money';
        }
        field(87; TransactionCurrencyIdName; Text[100])
        {
            CalcFormula = lookup("CRM Transactioncurrency".CurrencyName where(TransactionCurrencyId = field(TransactionCurrencyId)));
            Caption = 'TransactionCurrencyIdName';
            ExternalAccess = Read;
            ExternalName = 'transactioncurrencyidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(88; DiscountAmount_Base; Decimal)
        {
            Caption = 'Order Discount Amount (Base)';
            Description = 'Shows the Order Discount field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'discountamount_base';
            ExternalType = 'Money';
        }
        field(89; FreightAmount_Base; Decimal)
        {
            Caption = 'Freight Amount (Base)';
            Description = 'Shows the Freight Amount field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'freightamount_base';
            ExternalType = 'Money';
        }
        field(90; TotalLineItemDiscountAmount_Ba; Decimal)
        {
            Caption = 'Total Line Item Discount Amount (Base)';
            Description = 'Shows the Total Line Item Discount Amount field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'totallineitemdiscountamount_base';
            ExternalType = 'Money';
        }
        field(91; TotalTax_Base; Decimal)
        {
            Caption = 'Total Tax (Base)';
            Description = 'Shows the Total Tax field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'totaltax_base';
            ExternalType = 'Money';
        }
        field(92; CreatedOnBehalfBy; Guid)
        {
            Caption = 'Created By (Delegate)';
            Description = 'Shows who created the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(93; CreatedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            Caption = 'CreatedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(94; ModifiedOnBehalfBy; Guid)
        {
            Caption = 'Modified By (Delegate)';
            Description = 'Shows who last updated the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(95; ModifiedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedOnBehalfBy)));
            Caption = 'ModifiedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(96; OwningTeam; Guid)
        {
            Caption = 'Owning Team';
            Description = 'Unique identifier of the team who owns the order.';
            ExternalAccess = Read;
            ExternalName = 'owningteam';
            ExternalType = 'Lookup';
            TableRelation = "CRM Team".TeamId;
        }
        field(97; BillTo_Composite; BLOB)
        {
            Caption = 'Bill To Address';
            Description = 'Shows the complete Bill To address.';
            ExternalAccess = Read;
            ExternalName = 'billto_composite';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(98; ShipTo_Composite; BLOB)
        {
            Caption = 'Ship To Address';
            Description = 'Shows the complete Ship To address.';
            ExternalAccess = Read;
            ExternalName = 'shipto_composite';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(99; ProcessId; Guid)
        {
            Caption = 'Process';
            Description = 'Shows the ID of the process.';
            ExternalName = 'processid';
            ExternalType = 'Uniqueidentifier';
        }
        field(100; StageId; Guid)
        {
            Caption = 'Process Stage';
            Description = 'Shows the ID of the stage.';
            ExternalName = 'stageid';
            ExternalType = 'Uniqueidentifier';
        }
        field(101; EntityImageId; Guid)
        {
            Caption = 'Entity Image Id';
            Description = 'For internal use only.';
            ExternalAccess = Read;
            ExternalName = 'entityimageid';
            ExternalType = 'Uniqueidentifier';
        }
        field(102; TraversedPath; Text[250])
        {
            Caption = 'Traversed Path';
            Description = 'For internal use only.';
            ExternalName = 'traversedpath';
            ExternalType = 'String';
        }
        field(103; CompanyId; Guid)
        {
            Caption = 'Company Id';
            Description = 'Unique identifier of the company that owns the order.';
            ExternalName = 'bcbi_companyid';
            ExternalType = 'Lookup';
            TableRelation = "CDS Company".CompanyId;
        }
        field(104; PaymentTermsCodeEnum; Enum "CDS Payment Terms Code")
        {
            Caption = 'Payment Terms';
            Description = 'Select the payment terms to indicate when the customer needs to pay the total amount.';
            ExternalName = 'paymenttermscode';
            ExternalType = 'Picklist';
            InitValue = " ";
        }
        field(105; ShippingMethodCodeEnum; Enum "CDS Shipping Agent Code")
        {
            Caption = 'Shipping Method';
            Description = 'Select a shipping method for deliveries sent to this address.';
            ExternalName = 'shippingmethodcode';
            ExternalType = 'Picklist';
            InitValue = " ";
        }
        field(106; FreightTermsCodeEnum; Enum "CDS Shipment Method Code")
        {
            Caption = 'Freight Terms';
            Description = 'Select the freight terms to make sure shipping charges are processed correctly.';
            ExternalName = 'freighttermscode';
            ExternalType = 'Picklist';
            InitValue = " ";
        }
        field(107; BusinessCentralOrderNumber; Text[20])
        {
            Caption = 'Business Central Order Number';
            ExternalName = 'bcbi_businesscentralordernumber';
            ExternalType = 'String';
        }
        field(108; BusinessCentralDocumentOccurrenceNumber; Integer)
        {
            Caption = 'Business Central Document Occurrence Number';
            ExternalName = 'bcbi_businesscentraldocumentoccurrencenumber';
            ExternalType = 'Integer';
        }
    }

    keys
    {
        key(Key1; SalesOrderId)
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
