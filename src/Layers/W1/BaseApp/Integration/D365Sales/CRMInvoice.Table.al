// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Integration.Dataverse;

table 5355 "CRM Invoice"
{
    // Dynamics CRM Version: 7.1.0.2040

    Caption = 'CRM Invoice';
    Description = 'Order that has been billed.';
    ExternalName = 'invoice';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; InvoiceId; Guid)
        {
            Caption = 'Invoice';
            Description = 'Unique identifier of the invoice.';
            ExternalAccess = Insert;
            ExternalName = 'invoiceid';
            ExternalType = 'Uniqueidentifier';
        }
        field(2; OpportunityId; Guid)
        {
            Caption = 'Opportunity';
            Description = 'Choose the opportunity that the invoice is related to for reporting and analytics.';
            ExternalName = 'opportunityid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Opportunity".OpportunityId;
        }
        field(3; PriorityCode; Option)
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
        field(4; SalesOrderId; Guid)
        {
            Caption = 'Order';
            Description = 'Choose the order related to the invoice to make sure the order is fulfilled and invoiced correctly.';
            ExternalName = 'salesorderid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Salesorder".SalesOrderId;
        }
        field(5; OwningUser; Guid)
        {
            Caption = 'Owning User';
            Description = 'Unique identifier of the user who owns the invoice.';
            ExternalAccess = Read;
            ExternalName = 'owninguser';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(6; OwningBusinessUnit; Guid)
        {
            Caption = 'Owning Business Unit';
            Description = 'Unique identifier of the business unit that owns the invoice.';
            ExternalAccess = Read;
            ExternalName = 'owningbusinessunit';
            ExternalType = 'Lookup';
            TableRelation = "CRM Businessunit".BusinessUnitId;
        }
        field(7; LastBackofficeSubmit; Date)
        {
            Caption = 'Last Submitted to Back Office';
            Description = 'Enter the date and time when the invoice was last submitted to an accounting or ERP system for processing.';
            ExternalName = 'lastbackofficesubmit';
            ExternalType = 'DateTime';
        }
        field(8; PriceLevelId; Guid)
        {
            Caption = 'Price List';
            Description = 'Choose the price list associated with this record to make sure the products associated with the campaign are offered at the correct prices.';
            ExternalName = 'pricelevelid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Pricelevel".PriceLevelId;
        }
        field(9; AccountId; Guid)
        {
            Caption = 'Account';
            Description = 'Unique identifier of the account with which the invoice is associated.';
            ExternalAccess = Read;
            ExternalName = 'accountid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Account".AccountId;
        }
        field(10; ContactId; Guid)
        {
            Caption = 'Contact';
            Description = 'Unique identifier of the contact associated with the invoice.';
            ExternalAccess = Read;
            ExternalName = 'contactid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Contact".ContactId;
        }
        field(11; InvoiceNumber; Text[100])
        {
            Caption = 'Invoice ID';
            Description = 'Shows the identifying number or code of the invoice.';
            ExternalAccess = Insert;
            ExternalName = 'invoicenumber';
            ExternalType = 'String';
        }
        field(12; Name; Text[2048])
        {
            Caption = 'Name';
            Description = 'Type a descriptive name for the invoice.';
            ExternalName = 'name';
            ExternalType = 'String';
        }
        field(13; Description; BLOB)
        {
            Caption = 'Description';
            Description = 'Type additional information to describe the invoice, such as shipping details or product substitutions.';
            ExternalName = 'description';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(14; DiscountAmount; Decimal)
        {
            Caption = 'Invoice Discount Amount';
            Description = 'Type the discount amount for the invoice if the customer is eligible for special savings.';
            ExternalName = 'discountamount';
            ExternalType = 'Money';
        }
        field(15; FreightAmount; Decimal)
        {
            Caption = 'Freight Amount';
            Description = 'Type the cost of freight or shipping for the products included in the invoice for use in calculating the total amount due.';
            ExternalName = 'freightamount';
            ExternalType = 'Money';
        }
        field(16; TotalAmount; Decimal)
        {
            Caption = 'Total Amount';
            Description = 'Shows the total amount due, calculated as the sum of the products, discount, freight, and taxes for the invoice.';
            ExternalAccess = Modify;
            ExternalName = 'totalamount';
            ExternalType = 'Money';
        }
        field(17; TotalLineItemAmount; Decimal)
        {
            Caption = 'Total Detail Amount';
            Description = 'Shows the sum of all existing and write-in products included on the invoice, based on the specified price list and quantities.';
            ExternalAccess = Modify;
            ExternalName = 'totallineitemamount';
            ExternalType = 'Money';
        }
        field(18; TotalLineItemDiscountAmount; Decimal)
        {
            Caption = 'Total Line Item Discount Amount';
            Description = 'Shows the Manual Discount amounts specified on all products included in the invoice. This value is reflected in the Detail Amount field on the invoice and is added to any discount amount or rate specified on the invoice.';
            ExternalAccess = Modify;
            ExternalName = 'totallineitemdiscountamount';
            ExternalType = 'Money';
        }
        field(19; TotalAmountLessFreight; Decimal)
        {
            Caption = 'Total Pre-Freight Amount';
            Description = 'Shows the total product amount due, minus any discounts. This value is added to freight and tax amounts in the calculation for the total amount due for the invoice.';
            ExternalAccess = Modify;
            ExternalName = 'totalamountlessfreight';
            ExternalType = 'Money';
        }
        field(20; TotalDiscountAmount; Decimal)
        {
            Caption = 'Total Discount Amount';
            Description = 'Shows the total discount amount, based on the discount price and rate entered on the invoice.';
            ExternalAccess = Modify;
            ExternalName = 'totaldiscountamount';
            ExternalType = 'Money';
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
        field(22; TotalTax; Decimal)
        {
            Caption = 'Total Tax';
            Description = 'Shows the total of the Tax amounts specified on all products included in the invoice, included in the Total Amount due calculation for the invoice.';
            ExternalAccess = Modify;
            ExternalName = 'totaltax';
            ExternalType = 'Money';
        }
        field(25; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            Description = 'Shows the date and time when the record was created. The date and time are displayed in the time zone selected in Microsoft Dynamics CRM options.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(26; ModifiedBy; Guid)
        {
            Caption = 'Modified By';
            Description = 'Shows who last updated the record.';
            ExternalAccess = Read;
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(27; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            Description = 'Shows the date and time when the record was last updated. The date and time are displayed in the time zone selected in Microsoft Dynamics CRM options.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
        }
        field(28; StateCode; Option)
        {
            Caption = 'Status';
            Description = 'Shows whether the invoice is active, paid, or canceled. Paid and canceled invoices are read-only and can''t be edited unless they are reactivated.';
            ExternalAccess = Modify;
            ExternalName = 'statecode';
            ExternalType = 'State';
            InitValue = Active;
            OptionCaption = 'Active,Closed (deprecated),Paid,Canceled';
            OptionOrdinalValues = 0, 1, 2, 3;
            OptionMembers = Active,"Closed(deprecated)",Paid,Canceled;
        }
        field(29; StatusCode; Option)
        {
            Caption = 'Status Reason';
            Description = 'Select the invoice''s status.';
            ExternalName = 'statuscode';
            ExternalType = 'Status';
            InitValue = " ";
            OptionCaption = ' ,New,Partially Shipped,Billed,Booked (applies to services),Installed (applies to services),Canceled (deprecated),Paid in Full (deprecated),Complete,Partial,Canceled';
            OptionOrdinalValues = -1, 1, 2, 4, 5, 6, 3, 7, 100001, 100002, 100003;
            OptionMembers = " ",New,PartiallyShipped,Billed,"Booked(appliestoservices)","Installed(appliestoservices)","Canceled(deprecated)","PaidinFull(deprecated)",Complete,Partial,Canceled;
        }
        field(30; ShipTo_Name; Text[200])
        {
            Caption = 'Ship To Name';
            Description = 'Type a name for the customer''s shipping address, such as "Headquarters" or "Field office", to identify the address.';
            ExternalName = 'shipto_name';
            ExternalType = 'String';
        }
        field(31; VersionNumber; BigInteger)
        {
            Caption = 'Version Number';
            Description = 'Version number of the invoice.';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(32; PricingErrorCode; Option)
        {
            Caption = 'Pricing Error ';
            Description = 'Type of pricing error for the invoice.';
            ExternalName = 'pricingerrorcode';
            ExternalType = 'Picklist';
            InitValue = "None";
            OptionCaption = 'None,Detail Error,Missing Price Level,Inactive Price Level,Missing Quantity,Missing Unit Price,Missing Product,Invalid Product,Missing Pricing Code,Invalid Pricing Code,Missing UOM,Product Not In Price Level,Missing Price Level Amount,Missing Price Level Percentage,Missing Price,Missing Current Cost,Missing Standard Cost,Invalid Price Level Amount,Invalid Price Level Percentage,Invalid Price,Invalid Current Cost,Invalid Standard Cost,Invalid Rounding Policy,Invalid Rounding Option,Invalid Rounding Amount,Price Calculation Error,Invalid Discount Type,Discount Type Invalid State,Invalid Discount,Invalid Quantity,Invalid Pricing Precision,Missing Product Default UOM,Missing Product UOM Schedule ,Inactive Discount Type,Invalid Price Level Currency,Price Attribute Out Of Range,Base Currency Attribute Overflow,Base Currency Attribute Underflow';
            OptionOrdinalValues = 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37;
            OptionMembers = "None",DetailError,MissingPriceLevel,InactivePriceLevel,MissingQuantity,MissingUnitPrice,MissingProduct,InvalidProduct,MissingPricingCode,InvalidPricingCode,MissingUOM,ProductNotInPriceLevel,MissingPriceLevelAmount,MissingPriceLevelPercentage,MissingPrice,MissingCurrentCost,MissingStandardCost,InvalidPriceLevelAmount,InvalidPriceLevelPercentage,InvalidPrice,InvalidCurrentCost,InvalidStandardCost,InvalidRoundingPolicy,InvalidRoundingOption,InvalidRoundingAmount,PriceCalculationError,InvalidDiscountType,DiscountTypeInvalidState,InvalidDiscount,InvalidQuantity,InvalidPricingPrecision,MissingProductDefaultUOM,MissingProductUOMSchedule,InactiveDiscountType,InvalidPriceLevelCurrency,PriceAttributeOutOfRange,BaseCurrencyAttributeOverflow,BaseCurrencyAttributeUnderflow;
        }
        field(33; ShipTo_Line1; Text[250])
        {
            Caption = 'Ship To Street 1';
            Description = 'Type the first line of the customer''s shipping address.';
            ExternalName = 'shipto_line1';
            ExternalType = 'String';
        }
        field(34; ShipTo_Line2; Text[250])
        {
            Caption = 'Ship To Street 2';
            Description = 'Type the second line of the customer''s shipping address.';
            ExternalName = 'shipto_line2';
            ExternalType = 'String';
        }
        field(35; ShipTo_Line3; Text[250])
        {
            Caption = 'Ship To Street 3';
            Description = 'Type the third line of the shipping address.';
            ExternalName = 'shipto_line3';
            ExternalType = 'String';
        }
        field(36; ShipTo_City; Text[80])
        {
            Caption = 'Ship To City';
            Description = 'Type the city for the customer''s shipping address.';
            ExternalName = 'shipto_city';
            ExternalType = 'String';
        }
        field(37; ShipTo_StateOrProvince; Text[50])
        {
            Caption = 'Ship To State/Province';
            Description = 'Type the state or province for the shipping address.';
            ExternalName = 'shipto_stateorprovince';
            ExternalType = 'String';
        }
        field(38; ShipTo_Country; Text[80])
        {
            Caption = 'Ship To Country/Region';
            Description = 'Type the country or region for the customer''s shipping address.';
            ExternalName = 'shipto_country';
            ExternalType = 'String';
        }
        field(39; ShipTo_PostalCode; Text[20])
        {
            Caption = 'Ship To ZIP/Postal Code';
            Description = 'Type the ZIP Code or postal code for the shipping address.';
            ExternalName = 'shipto_postalcode';
            ExternalType = 'String';
        }
        field(40; WillCall; Boolean)
        {
            Caption = 'Ship To';
            Description = 'Select whether the products included in the invoice should be shipped to the specified address or held until the customer calls with further pick up or delivery instructions.';
            ExternalName = 'willcall';
            ExternalType = 'Boolean';
        }
        field(41; ShipTo_Telephone; Text[50])
        {
            Caption = 'Ship To Phone';
            Description = 'Type the phone number for the customer''s shipping address.';
            ExternalName = 'shipto_telephone';
            ExternalType = 'String';
        }
        field(42; BillTo_Name; Text[200])
        {
            Caption = 'Bill To Name';
            Description = 'Type a name for the customer''s billing address, such as "Headquarters" or "Field office", to identify the address.';
            ExternalName = 'billto_name';
            ExternalType = 'String';
        }
        field(43; ShipTo_FreightTermsCode; Option)
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
        field(44; ShipTo_Fax; Text[50])
        {
            Caption = 'Ship To Fax';
            Description = 'Type the fax number for the customer''s shipping address.';
            ExternalName = 'shipto_fax';
            ExternalType = 'String';
        }
        field(45; BillTo_Line1; Text[250])
        {
            Caption = 'Bill To Street 1';
            Description = 'Type the first line of the customer''s billing address.';
            ExternalName = 'billto_line1';
            ExternalType = 'String';
        }
        field(46; BillTo_Line2; Text[250])
        {
            Caption = 'Bill To Street 2';
            Description = 'Type the second line of the customer''s billing address.';
            ExternalName = 'billto_line2';
            ExternalType = 'String';
        }
        field(47; BillTo_Line3; Text[250])
        {
            Caption = 'Bill To Street 3';
            Description = 'Type the third line of the billing address.';
            ExternalName = 'billto_line3';
            ExternalType = 'String';
        }
        field(48; BillTo_City; Text[80])
        {
            Caption = 'Bill To City';
            Description = 'Type the city for the customer''s billing address.';
            ExternalName = 'billto_city';
            ExternalType = 'String';
        }
        field(49; BillTo_StateOrProvince; Text[50])
        {
            Caption = 'Bill To State/Province';
            Description = 'Type the state or province for the billing address.';
            ExternalName = 'billto_stateorprovince';
            ExternalType = 'String';
        }
        field(50; BillTo_Country; Text[80])
        {
            Caption = 'Bill To Country/Region';
            Description = 'Type the country or region for the customer''s billing address.';
            ExternalName = 'billto_country';
            ExternalType = 'String';
        }
        field(51; BillTo_PostalCode; Text[20])
        {
            Caption = 'Bill To ZIP/Postal Code';
            Description = 'Type the ZIP Code or postal code for the billing address.';
            ExternalName = 'billto_postalcode';
            ExternalType = 'String';
        }
        field(52; BillTo_Telephone; Text[50])
        {
            Caption = 'Bill To Phone';
            Description = 'Type the phone number for the customer''s billing address.';
            ExternalName = 'billto_telephone';
            ExternalType = 'String';
        }
        field(53; BillTo_Fax; Text[50])
        {
            Caption = 'Bill To Fax';
            Description = 'Type the fax number for the customer''s billing address.';
            ExternalName = 'billto_fax';
            ExternalType = 'String';
        }
        field(54; DiscountPercentage; Decimal)
        {
            Caption = 'Invoice Discount (%)';
            Description = 'Type the discount rate that should be applied to the Detail Amount field, for use in calculating the Pre-Freight Amount and Total Amount values for the invoice.';
            ExternalName = 'discountpercentage';
            ExternalType = 'Decimal';
        }
        field(55; ContactIdName; Text[160])
        {
            CalcFormula = lookup("CRM Contact".FullName where(ContactId = field(ContactId)));
            Caption = 'ContactIdName';
            ExternalAccess = Read;
            ExternalName = 'contactidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(56; AccountIdName; Text[160])
        {
            CalcFormula = lookup("CRM Account".Name where(AccountId = field(AccountId)));
            Caption = 'AccountIdName';
            ExternalAccess = Read;
            ExternalName = 'accountidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(57; OpportunityIdName; Text[2048])
        {
            CalcFormula = lookup("CRM Opportunity".Name where(OpportunityId = field(OpportunityId)));
            Caption = 'OpportunityIdName';
            ExternalAccess = Read;
            ExternalName = 'opportunityidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(58; SalesOrderIdName; Text[2048])
        {
            CalcFormula = lookup("CRM Salesorder".Name where(SalesOrderId = field(SalesOrderId)));
            Caption = 'SalesOrderIdName';
            ExternalAccess = Read;
            ExternalName = 'salesorderidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(59; PriceLevelIdName; Text[100])
        {
            CalcFormula = lookup("CRM Pricelevel".Name where(PriceLevelId = field(PriceLevelId)));
            Caption = 'PriceLevelIdName';
            ExternalAccess = Read;
            ExternalName = 'pricelevelidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(60; CreatedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedBy)));
            Caption = 'CreatedByName';
            ExternalAccess = Read;
            ExternalName = 'createdbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(61; ModifiedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedBy)));
            Caption = 'ModifiedByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(62; CustomerId; Guid)
        {
            Caption = 'Customer';
            Description = 'Select the customer account or contact to provide a quick link to additional customer details, such as account information, activities, and opportunities.';
            ExternalName = 'customerid';
            ExternalType = 'Customer';
            TableRelation = if (CustomerIdType = const(account)) "CRM Account".AccountId
            else
            if (CustomerIdType = const(contact)) "CRM Contact".ContactId;
        }
        field(63; CustomerIdType; Option)
        {
            Caption = 'Customer Type';
            ExternalName = 'customeridtype';
            ExternalType = 'EntityName';
            OptionCaption = ' ,account,contact';
            OptionMembers = " ",account,contact;
        }
        field(64; OwnerId; Guid)
        {
            Caption = 'Owner';
            Description = 'Enter the user or team who is assigned to manage the record. This field is updated every time the record is assigned to a different user.';
            ExternalName = 'ownerid';
            ExternalType = 'Owner';
            TableRelation = if (OwnerIdType = const(systemuser)) "CRM Systemuser".SystemUserId
            else
            if (OwnerIdType = const(team)) "CRM Team".TeamId;
        }
        field(65; OwnerIdType; Option)
        {
            Caption = 'OwnerIdType';
            ExternalName = 'owneridtype';
            ExternalType = 'EntityName';
            OptionCaption = ' ,systemuser,team';
            OptionMembers = " ",systemuser,team;
        }
        field(66; IsPriceLocked; Boolean)
        {
            Caption = 'Prices Locked';
            Description = 'Select whether prices specified on the invoice are locked from any further updates.';
            ExternalAccess = Modify;
            ExternalName = 'ispricelocked';
            ExternalType = 'Boolean';
        }
        field(67; DateDelivered; Date)
        {
            Caption = 'Date Delivered';
            Description = 'Enter the date when the products included in the invoice were delivered.';
            ExternalName = 'datedelivered';
            ExternalType = 'DateTime';
        }
        field(68; DueDate; Date)
        {
            Caption = 'Due Date';
            Description = 'Enter the date by which the invoice should be paid by the customer.';
            ExternalName = 'duedate';
            ExternalType = 'DateTime';
        }
        field(69; TimeZoneRuleVersionNumber; Integer)
        {
            Caption = 'Time Zone Rule Version Number';
            Description = 'For internal use only.';
            ExternalName = 'timezoneruleversionnumber';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(70; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            Description = 'Unique identifier of the data import or data migration that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
        }
        field(71; OverriddenCreatedOn; Date)
        {
            Caption = 'Record Created On';
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
        }
        field(72; ExchangeRate; Decimal)
        {
            Caption = 'Exchange Rate';
            Description = 'Shows the conversion rate of the record''s currency. The exchange rate is used to convert all money fields in the record from the local currency to the system''s default currency.';
            ExternalAccess = Read;
            ExternalName = 'exchangerate';
            ExternalType = 'Decimal';
        }
        field(73; UTCConversionTimeZoneCode; Integer)
        {
            Caption = 'UTC Conversion Time Zone Code';
            Description = 'Time zone code that was in use when the record was created.';
            ExternalName = 'utcconversiontimezonecode';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(74; TransactionCurrencyId; Guid)
        {
            Caption = 'Currency';
            Description = 'Choose the local currency for the record to make sure budgets are reported in the correct currency.';
            ExternalAccess = Insert;
            ExternalName = 'transactioncurrencyid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Transactioncurrency".TransactionCurrencyId;
        }
        field(75; TransactionCurrencyIdName; Text[100])
        {
            CalcFormula = lookup("CRM Transactioncurrency".CurrencyName where(TransactionCurrencyId = field(TransactionCurrencyId)));
            Caption = 'TransactionCurrencyIdName';
            ExternalAccess = Read;
            ExternalName = 'transactioncurrencyidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(76; TotalLineItemAmount_Base; Decimal)
        {
            Caption = 'Total Detail Amount (Base)';
            Description = 'Shows the Detail Amount field converted to the system''s default base currency. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'totallineitemamount_base';
            ExternalType = 'Money';
        }
        field(77; TotalLineItemDiscountAmount_Ba; Decimal)
        {
            Caption = 'Total Line Item Discount Amount (Base)';
            Description = 'Shows the total of the Manual Discount amounts specified on all products included in the invoice. This value is reflected in the Detail Amount field on the invoice and is added to any discount amount or rate specified on the invoice.';
            ExternalAccess = Read;
            ExternalName = 'totallineitemdiscountamount_base';
            ExternalType = 'Money';
        }
        field(78; TotalTax_Base; Decimal)
        {
            Caption = 'Total Tax (Base)';
            Description = 'Shows the Total Tax field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'totaltax_base';
            ExternalType = 'Money';
        }
        field(79; TotalAmountLessFreight_Base; Decimal)
        {
            Caption = 'Total Pre-Freight Amount (Base)';
            Description = 'Shows the Pre-Freight Amount field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'totalamountlessfreight_base';
            ExternalType = 'Money';
        }
        field(80; DiscountAmount_Base; Decimal)
        {
            Caption = 'Invoice Discount Amount (Base)';
            Description = 'Shows the Invoice Discount field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'discountamount_base';
            ExternalType = 'Money';
        }
        field(81; TotalAmount_Base; Decimal)
        {
            Caption = 'Total Amount (Base)';
            Description = 'Shows the Total Amount field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'totalamount_base';
            ExternalType = 'Money';
        }
        field(82; FreightAmount_Base; Decimal)
        {
            Caption = 'Freight Amount (Base)';
            Description = 'Shows the Freight Amount field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'freightamount_base';
            ExternalType = 'Money';
        }
        field(83; TotalDiscountAmount_Base; Decimal)
        {
            Caption = 'Total Discount Amount (Base)';
            Description = 'Shows the Total Discount Amount field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'totaldiscountamount_base';
            ExternalType = 'Money';
        }
        field(84; CreatedOnBehalfBy; Guid)
        {
            Caption = 'Created By (Delegate)';
            Description = 'Shows who created the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(85; CreatedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            Caption = 'CreatedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(86; ModifiedOnBehalfBy; Guid)
        {
            Caption = 'Modified By (Delegate)';
            Description = 'Shows who last updated the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(87; ModifiedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedOnBehalfBy)));
            Caption = 'ModifiedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(88; OwningTeam; Guid)
        {
            Caption = 'Owning Team';
            Description = 'Unique identifier of the team who owns the invoice.';
            ExternalAccess = Read;
            ExternalName = 'owningteam';
            ExternalType = 'Lookup';
            TableRelation = "CRM Team".TeamId;
        }
        field(89; BillTo_Composite; BLOB)
        {
            Caption = 'Bill To Address';
            Description = 'Shows the complete Bill To address.';
            ExternalAccess = Read;
            ExternalName = 'billto_composite';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(90; ShipTo_Composite; BLOB)
        {
            Caption = 'Ship To Address';
            Description = 'Shows the complete Ship To address.';
            ExternalAccess = Read;
            ExternalName = 'shipto_composite';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(91; ProcessId; Guid)
        {
            Caption = 'Process';
            Description = 'Shows the ID of the process.';
            ExternalName = 'processid';
            ExternalType = 'Uniqueidentifier';
        }
        field(92; StageId; Guid)
        {
            Caption = 'Process Stage';
            Description = 'Shows the ID of the stage.';
            ExternalName = 'stageid';
            ExternalType = 'Uniqueidentifier';
        }
        field(93; EntityImageId; Guid)
        {
            Caption = 'Entity Image Id';
            Description = 'For internal use only.';
            ExternalAccess = Read;
            ExternalName = 'entityimageid';
            ExternalType = 'Uniqueidentifier';
        }
        field(94; TraversedPath; Text[250])
        {
            Caption = 'Traversed Path';
            Description = 'For internal use only.';
            ExternalName = 'traversedpath';
            ExternalType = 'String';
        }
        field(95; CompanyId; Guid)
        {
            Caption = 'Company Id';
            Description = 'Unique identifier of the company that owns the invoice.';
            ExternalName = 'bcbi_companyid';
            ExternalType = 'Lookup';
            TableRelation = "CDS Company".CompanyId;
        }
        field(96; PaymentTermsCodeEnum; Enum "CDS Payment Terms Code")
        {
            Caption = 'Payment Terms';
            Description = 'Select the payment terms to indicate when the customer needs to pay the total amount.';
            ExternalName = 'paymenttermscode';
            ExternalType = 'Picklist';
            InitValue = " ";
        }
        field(97; ShippingMethodCodeEnum; Enum "CDS Shipping Agent Code")
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
        key(Key1; InvoiceId)
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
