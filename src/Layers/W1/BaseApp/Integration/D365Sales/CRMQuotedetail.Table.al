// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5352 "CRM Quotedetail"
{
    // Dynamics CRM Version: 7.1.0.2040

    Caption = 'CRM Quotedetail';
    Description = 'Product line item in a quote. The details include such information as product ID, description, quantity, and cost.';
    ExternalName = 'quotedetail';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; QuoteDetailId; Guid)
        {
            Caption = 'Quote Product';
            Description = 'Unique identifier of the product line item in the quote.';
            ExternalAccess = Insert;
            ExternalName = 'quotedetailid';
            ExternalType = 'Uniqueidentifier';
        }
        field(2; QuoteId; Guid)
        {
            Caption = 'Quote';
            Description = 'Unique identifier of the quote for the quote product.';
            ExternalName = 'quoteid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Quote".QuoteId;
        }
        field(3; SalesRepId; Guid)
        {
            Caption = 'Salesperson';
            Description = 'Choose the user responsible for the sale of the quote product.';
            ExternalName = 'salesrepid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(4; LineItemNumber; Integer)
        {
            Caption = 'Line Item Number';
            Description = 'Type the line item number for the quote product to easily identify the product in the quote and make sure it''s listed in the correct order.';
            ExternalName = 'lineitemnumber';
            ExternalType = 'Integer';
            MaxValue = 1000000000;
            MinValue = 0;
        }
        field(5; UoMId; Guid)
        {
            Caption = 'Unit';
            Description = 'Choose the unit of measurement for the base unit quantity for this purchase, such as each or dozen.';
            ExternalName = 'uomid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Uom".UoMId;
        }
        field(6; ProductId; Guid)
        {
            Caption = 'Existing Product';
            Description = 'Choose the product to include on the quote to link the product''s pricing and other information to the quote.';
            ExternalName = 'productid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Product".ProductId;
        }
        field(7; RequestDeliveryBy; Date)
        {
            Caption = 'Requested Delivery Date';
            Description = 'Enter the delivery date requested by the customer for the quote product.';
            ExternalName = 'requestdeliveryby';
            ExternalType = 'DateTime';
        }
        field(8; Quantity; Decimal)
        {
            Caption = 'Quantity';
            Description = 'Type the amount or quantity of the product requested by the customer.';
            ExternalName = 'quantity';
            ExternalType = 'Decimal';
        }
        field(9; PricingErrorCode; Option)
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
        field(10; ManualDiscountAmount; Decimal)
        {
            Caption = 'Manual Discount';
            Description = 'Type the manual discount amount for the quote product to deduct any negotiated or other savings from the product total on the quote.';
            ExternalName = 'manualdiscountamount';
            ExternalType = 'Money';
        }
        field(11; ProductDescription; Text[250])
        {
            Caption = 'Write-In Product';
            Description = 'Type a name or description to identify the type of write-in product included in the quote.';
            ExternalName = 'productdescription';
            ExternalType = 'String';
        }
        field(12; VolumeDiscountAmount; Decimal)
        {
            Caption = 'Volume Discount';
            Description = 'Shows the discount amount per unit if a specified volume is purchased. Configure volume discounts in the Product Catalog in the Settings area.';
            ExternalAccess = Read;
            ExternalName = 'volumediscountamount';
            ExternalType = 'Money';
        }
        field(13; PricePerUnit; Decimal)
        {
            Caption = 'Price Per Unit';
            Description = 'Type the price per unit of the quote product. The default is to the value in the price list specified on the quote for existing products.';
            ExternalName = 'priceperunit';
            ExternalType = 'Money';
        }
        field(14; BaseAmount; Decimal)
        {
            Caption = 'Amount';
            Description = 'Shows the total price of the quote product, based on the price per unit, volume discount, and quantity.';
            ExternalAccess = Modify;
            ExternalName = 'baseamount';
            ExternalType = 'Money';
        }
        field(15; ExtendedAmount; Decimal)
        {
            Caption = 'Extended Amount';
            Description = 'Shows the total amount due for the quote product, based on the sum of the unit price, quantity, discounts ,and tax.';
            ExternalAccess = Modify;
            ExternalName = 'extendedamount';
            ExternalType = 'Money';
        }
        field(16; Description; BLOB)
        {
            Caption = 'Description';
            Description = 'Type additional information to describe the quote product, such as manufacturing details or acceptable substitutions.';
            ExternalName = 'description';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(17; ShipTo_Name; Text[200])
        {
            Caption = 'Ship To Name';
            Description = 'Type a name for the customer''s shipping address, such as "Headquarters" or "Field office", to identify the address.';
            ExternalName = 'shipto_name';
            ExternalType = 'String';
        }
        field(18; IsPriceOverridden; Boolean)
        {
            Caption = 'Price Overridden';
            Description = 'Select whether the price per unit is fixed at the value in the specified price list or can be overridden by users who have edit rights to the quote product.';
            ExternalName = 'ispriceoverridden';
            ExternalType = 'Boolean';
        }
        field(19; Tax; Decimal)
        {
            Caption = 'Tax';
            Description = 'Type the tax amount for the quote product.';
            ExternalName = 'tax';
            ExternalType = 'Money';
        }
        field(20; ShipTo_Line1; Text[250])
        {
            Caption = 'Ship To Street 1';
            Description = 'Type the first line of the customer''s shipping address.';
            ExternalName = 'shipto_line1';
            ExternalType = 'String';
        }
        field(21; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            Description = 'Shows the date and time when the record was created. The date and time are displayed in the time zone selected in Microsoft Dynamics CRM options.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(22; ShipTo_Line2; Text[250])
        {
            Caption = 'Ship To Street 2';
            Description = 'Type the second line of the customer''s shipping address.';
            ExternalName = 'shipto_line2';
            ExternalType = 'String';
        }
        field(23; CreatedBy; Guid)
        {
            Caption = 'Created By';
            Description = 'Shows who created the record.';
            ExternalAccess = Read;
            ExternalName = 'createdby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(24; ModifiedBy; Guid)
        {
            Caption = 'Modified By';
            Description = 'Shows who last updated the record.';
            ExternalAccess = Read;
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(25; ShipTo_Line3; Text[250])
        {
            Caption = 'Ship To Street 3';
            Description = 'Type the third line of the shipping address.';
            ExternalName = 'shipto_line3';
            ExternalType = 'String';
        }
        field(26; ShipTo_City; Text[80])
        {
            Caption = 'Ship To City';
            Description = 'Type the city for the customer''s shipping address.';
            ExternalName = 'shipto_city';
            ExternalType = 'String';
        }
        field(27; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            Description = 'Shows the date and time when the record was last updated. The date and time are displayed in the time zone selected in Microsoft Dynamics CRM options.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
        }
        field(28; ShipTo_StateOrProvince; Text[50])
        {
            Caption = 'Ship To State/Province';
            Description = 'Type the state or province for the shipping address.';
            ExternalName = 'shipto_stateorprovince';
            ExternalType = 'String';
        }
        field(29; ShipTo_Country; Text[80])
        {
            Caption = 'Ship To Country/Region';
            Description = 'Type the country or region for the customer''s shipping address.';
            ExternalName = 'shipto_country';
            ExternalType = 'String';
        }
        field(30; ShipTo_PostalCode; Text[20])
        {
            Caption = 'Ship To ZIP/Postal Code';
            Description = 'Type the ZIP Code or postal code for the shipping address.';
            ExternalName = 'shipto_postalcode';
            ExternalType = 'String';
        }
        field(31; WillCall; Boolean)
        {
            Caption = 'Ship To';
            Description = 'Select whether the quote product should be shipped to the specified address or held until the customer calls with further pick up or delivery instructions.';
            ExternalName = 'willcall';
            ExternalType = 'Boolean';
        }
        field(32; IsProductOverridden; Boolean)
        {
            Caption = 'Select Product';
            Description = 'Select whether the product exists in the Microsoft Dynamics CRM product catalog or is a write-in product specific to the quote.';
            ExternalAccess = Insert;
            ExternalName = 'isproductoverridden';
            ExternalType = 'Boolean';
        }
        field(33; ShipTo_Telephone; Text[50])
        {
            Caption = 'Ship To Phone';
            Description = 'Type the phone number for the customer''s shipping address.';
            ExternalName = 'shipto_telephone';
            ExternalType = 'String';
        }
        field(34; ShipTo_Fax; Text[50])
        {
            Caption = 'Ship To Fax';
            Description = 'Type the fax number for the customer''s shipping address.';
            ExternalName = 'shipto_fax';
            ExternalType = 'String';
        }
        field(35; ShipTo_FreightTermsCode; Option)
        {
            Caption = 'Freight Terms';
            Description = 'Select the freight terms to make sure shipping orders are processed correctly.';
            ExternalName = 'shipto_freighttermscode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,FOB,No Charge';
            OptionOrdinalValues = -1, 1, 2;
            OptionMembers = " ",FOB,NoCharge;
        }
        field(36; ProductIdName; Text[100])
        {
            CalcFormula = lookup("CRM Product".Name where(ProductId = field(ProductId)));
            Caption = 'ProductIdName';
            ExternalAccess = Read;
            ExternalName = 'productidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(37; UoMIdName; Text[100])
        {
            CalcFormula = lookup("CRM Uom".Name where(UoMId = field(UoMId)));
            Caption = 'UoMIdName';
            ExternalAccess = Read;
            ExternalName = 'uomidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(38; SalesRepIdName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(SalesRepId)));
            Caption = 'SalesRepIdName';
            ExternalAccess = Read;
            ExternalName = 'salesrepidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(39; QuoteStateCode; Option)
        {
            Caption = 'Quote Status';
            Description = 'Status of the quote product.';
            ExternalAccess = Read;
            ExternalName = 'quotestatecode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ';
            OptionOrdinalValues = -1;
            OptionMembers = " ";
        }
        field(40; CreatedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedBy)));
            Caption = 'CreatedByName';
            ExternalAccess = Read;
            ExternalName = 'createdbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(41; ModifiedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedBy)));
            Caption = 'ModifiedByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(42; OwningUser; Guid)
        {
            Caption = 'Owning User';
            Description = 'Unique identifier of the user who owns the quote detail.';
            ExternalAccess = Read;
            ExternalName = 'owninguser';
            ExternalType = 'Uniqueidentifier';
        }
        field(43; ShipTo_AddressId; Guid)
        {
            Caption = 'Ship To Address ID';
            Description = 'Unique identifier of the shipping address.';
            ExternalName = 'shipto_addressid';
            ExternalType = 'Uniqueidentifier';
        }
        field(44; ShipTo_ContactName; Text[150])
        {
            Caption = 'Ship To Contact Name';
            Description = 'Type the primary contact name at the customer''s shipping address.';
            ExternalName = 'shipto_contactname';
            ExternalType = 'String';
        }
        field(45; OwningBusinessUnit; Guid)
        {
            Caption = 'Owning Business Unit';
            Description = 'Unique identifier of the business unit that owns the quote detail.';
            ExternalAccess = Read;
            ExternalName = 'owningbusinessunit';
            ExternalType = 'Uniqueidentifier';
        }
        field(46; VersionNumber; BigInteger)
        {
            Caption = 'Version Number';
            Description = 'Version number of the quote detail.';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(47; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            Description = 'Unique identifier of the data import or data migration that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
        }
        field(48; UTCConversionTimeZoneCode; Integer)
        {
            Caption = 'UTC Conversion Time Zone Code';
            Description = 'Time zone code that was in use when the record was created.';
            ExternalName = 'utcconversiontimezonecode';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(49; OverriddenCreatedOn; Date)
        {
            Caption = 'Record Created On';
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
        }
        field(50; TransactionCurrencyId; Guid)
        {
            Caption = 'Currency';
            Description = 'Choose the local currency for the record to make sure budgets are reported in the correct currency.';
            ExternalAccess = Read;
            ExternalName = 'transactioncurrencyid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Transactioncurrency".TransactionCurrencyId;
        }
        field(51; ExchangeRate; Decimal)
        {
            Caption = 'Exchange Rate';
            Description = 'Shows the conversion rate of the record''s currency. The exchange rate is used to convert all money fields in the record from the local currency to the system''s default currency.';
            ExternalAccess = Read;
            ExternalName = 'exchangerate';
            ExternalType = 'Decimal';
        }
        field(52; TimeZoneRuleVersionNumber; Integer)
        {
            Caption = 'Time Zone Rule Version Number';
            Description = 'For internal use only.';
            ExternalName = 'timezoneruleversionnumber';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(53; Tax_Base; Decimal)
        {
            Caption = 'Tax (Base)';
            Description = 'Shows the Tax field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'tax_base';
            ExternalType = 'Money';
        }
        field(54; ExtendedAmount_Base; Decimal)
        {
            Caption = 'Extended Amount (Base)';
            Description = 'Shows the Extended Amount field converted to the system''s default base currency. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'extendedamount_base';
            ExternalType = 'Money';
        }
        field(55; PricePerUnit_Base; Decimal)
        {
            Caption = 'Price Per Unit (Base)';
            Description = 'Shows the Price Per Unit field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'priceperunit_base';
            ExternalType = 'Money';
        }
        field(56; TransactionCurrencyIdName; Text[100])
        {
            CalcFormula = lookup("CRM Transactioncurrency".CurrencyName where(TransactionCurrencyId = field(TransactionCurrencyId)));
            Caption = 'TransactionCurrencyIdName';
            ExternalAccess = Read;
            ExternalName = 'transactioncurrencyidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(57; BaseAmount_Base; Decimal)
        {
            Caption = 'Amount (Base)';
            Description = 'Shows the Amount field converted to the system''s default base currency. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'baseamount_base';
            ExternalType = 'Money';
        }
        field(58; ManualDiscountAmount_Base; Decimal)
        {
            Caption = 'Manual Discount (Base)';
            Description = 'Shows the Manual Discount field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'manualdiscountamount_base';
            ExternalType = 'Money';
        }
        field(59; VolumeDiscountAmount_Base; Decimal)
        {
            Caption = 'Volume Discount (Base)';
            Description = 'Shows the discount amount per unit if a specified volume is purchased. Configure volume discounts in the Product Catalog in the Settings area.';
            ExternalAccess = Read;
            ExternalName = 'volumediscountamount_base';
            ExternalType = 'Money';
        }
        field(60; OwnerId; Guid)
        {
            Caption = 'Owner';
            Description = 'Unique identifier of the user or team who owns the quote detail.';
            ExternalAccess = Read;
            ExternalName = 'ownerid';
            ExternalType = 'Owner';
            TableRelation = if (OwnerIdType = const(systemuser)) "CRM Systemuser".SystemUserId
            else
            if (OwnerIdType = const(team)) "CRM Team".TeamId;
        }
        field(61; OwnerIdType; Option)
        {
            Caption = 'OwnerIdType';
            ExternalAccess = Read;
            ExternalName = 'owneridtype';
            ExternalType = 'EntityName';
            OptionCaption = ' ,systemuser,team';
            OptionMembers = " ",systemuser,team;
        }
        field(62; CreatedOnBehalfBy; Guid)
        {
            Caption = 'Created By (Delegate)';
            Description = 'Shows who created the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(63; CreatedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            Caption = 'CreatedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(64; ModifiedOnBehalfBy; Guid)
        {
            Caption = 'Modified By (Delegate)';
            Description = 'Shows who last updated the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(65; ModifiedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedOnBehalfBy)));
            Caption = 'ModifiedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(66; SequenceNumber; Integer)
        {
            Caption = 'Sequence Number';
            Description = 'Unique identifier of the data that maintains the sequence.';
            ExternalName = 'sequencenumber';
            ExternalType = 'Integer';
        }
        field(67; PropertyConfigurationStatus; Option)
        {
            Caption = 'Property Configuration';
            Description = 'Status of the property configuration.';
            ExternalName = 'propertyconfigurationstatus';
            ExternalType = 'Picklist';
            InitValue = NotConfigured;
            OptionCaption = 'Edit,Rectify,NotConfigured';
            OptionOrdinalValues = 0, 1, 2;
            OptionMembers = Edit,Rectify,NotConfigured;
        }
        field(68; ProductAssociationId; Guid)
        {
            Caption = 'Bundle Item Association';
            Description = 'Unique identifier of the product line item association with bundle in the quote';
            ExternalAccess = Insert;
            ExternalName = 'productassociationid';
            ExternalType = 'Uniqueidentifier';
        }
        field(69; ParentBundleId; Guid)
        {
            Caption = 'Parent Bundle';
            Description = 'Choose the parent bundle associated with this product';
            ExternalAccess = Insert;
            ExternalName = 'parentbundleid';
            ExternalType = 'Uniqueidentifier';
        }
        field(70; ProductTypeCode; Option)
        {
            Caption = 'Product type';
            Description = 'Product Type';
            ExternalAccess = Insert;
            ExternalName = 'producttypecode';
            ExternalType = 'Picklist';
            InitValue = Product;
            OptionCaption = 'Product,Bundle,Required Bundle Product,Optional Bundle Product';
            OptionOrdinalValues = 1, 2, 3, 4;
            OptionMembers = Product,Bundle,RequiredBundleProduct,OptionalBundleProduct;
        }
    }

    keys
    {
        key(Key1; QuoteDetailId)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

