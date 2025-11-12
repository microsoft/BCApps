// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5354 "CRM Salesorderdetail"
{
    // Dynamics CRM Version: 7.1.0.2040

    Caption = 'CRM Salesorderdetail';
    Description = 'Line item in a sales order.';
    ExternalName = 'salesorderdetail';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; SalesOrderDetailId; Guid)
        {
            Caption = 'Order Product';
            Description = 'Unique identifier of the product specified in the order.';
            ExternalAccess = Insert;
            ExternalName = 'salesorderdetailid';
            ExternalType = 'Uniqueidentifier';
        }
        field(2; SalesOrderId; Guid)
        {
            Caption = 'Order';
            Description = 'Shows the order for the product. The ID is used to link product pricing and other details to the total amounts and other information on the order.';
            ExternalName = 'salesorderid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Salesorder".SalesOrderId;
        }
        field(3; SalesRepId; Guid)
        {
            Caption = 'Salesperson';
            Description = 'Choose the user responsible for the sale of the order product.';
            ExternalName = 'salesrepid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(4; IsProductOverridden; Boolean)
        {
            Caption = 'Select Product';
            Description = 'Select whether the product exists in the Microsoft Dynamics CRM product catalog or is a write-in product specific to the order.';
            ExternalAccess = Insert;
            ExternalName = 'isproductoverridden';
            ExternalType = 'Boolean';
        }
        field(5; IsCopied; Boolean)
        {
            Caption = 'Copied';
            Description = 'Select whether the invoice line item is copied from another item or data source.';
            ExternalName = 'iscopied';
            ExternalType = 'Boolean';
        }
        field(6; QuantityShipped; Decimal)
        {
            Caption = 'Quantity Shipped';
            Description = 'Type the amount or quantity of the product that was shipped for the order.';
            ExternalName = 'quantityshipped';
            ExternalType = 'Decimal';
        }
        field(7; LineItemNumber; Integer)
        {
            Caption = 'Line Item Number';
            Description = 'Type the line item number for the order product to easily identify the product in the order and make sure it''s listed in the correct sequence.';
            ExternalName = 'lineitemnumber';
            ExternalType = 'Integer';
            MaxValue = 1000000000;
            MinValue = 0;
        }
        field(8; QuantityBackordered; Decimal)
        {
            Caption = 'Quantity Back Ordered';
            Description = 'Type the amount or quantity of the product that is back ordered for the order.';
            ExternalName = 'quantitybackordered';
            ExternalType = 'Decimal';
        }
        field(9; UoMId; Guid)
        {
            Caption = 'Unit';
            Description = 'Choose the unit of measurement for the base unit quantity for this purchase, such as each or dozen.';
            ExternalName = 'uomid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Uom".UoMId;
        }
        field(10; QuantityCancelled; Decimal)
        {
            Caption = 'Quantity Canceled';
            Description = 'Type the amount or quantity of the product that was canceled.';
            ExternalName = 'quantitycancelled';
            ExternalType = 'Decimal';
        }
        field(11; ProductId; Guid)
        {
            Caption = 'Existing Product';
            Description = 'Choose the product to include on the order to link the product''s pricing and other information to the parent order.';
            ExternalName = 'productid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Product".ProductId;
        }
        field(12; RequestDeliveryBy; Date)
        {
            Caption = 'Requested Delivery Date';
            Description = 'Enter the delivery date requested by the customer for the order product.';
            ExternalName = 'requestdeliveryby';
            ExternalType = 'DateTime';
        }
        field(13; Quantity; Decimal)
        {
            Caption = 'Quantity';
            Description = 'Type the amount or quantity of the product ordered by the customer.';
            ExternalName = 'quantity';
            ExternalType = 'Decimal';
        }
        field(14; PricingErrorCode; Option)
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
        field(15; ManualDiscountAmount; Decimal)
        {
            Caption = 'Manual Discount';
            Description = 'Type the manual discount amount for the order product to deduct any negotiated or other savings from the product total on the order.';
            ExternalName = 'manualdiscountamount';
            ExternalType = 'Money';
        }
        field(16; ProductDescription; Text[250])
        {
            Caption = 'Write-In Product';
            Description = 'Type a name or description to identify the type of write-in product included in the order.';
            ExternalName = 'productdescription';
            ExternalType = 'String';
        }
        field(17; VolumeDiscountAmount; Decimal)
        {
            Caption = 'Volume Discount';
            Description = 'Shows the discount amount per unit if a specified volume is purchased. Configure volume discounts in the Product Catalog in the Settings area.';
            ExternalAccess = Read;
            ExternalName = 'volumediscountamount';
            ExternalType = 'Money';
        }
        field(18; PricePerUnit; Decimal)
        {
            Caption = 'Price Per Unit';
            Description = 'Type the price per unit of the order product. The default is the value in the price list specified on the order for existing products.';
            ExternalName = 'priceperunit';
            ExternalType = 'Money';
        }
        field(19; BaseAmount; Decimal)
        {
            Caption = 'Amount';
            Description = 'Shows the total price of the order product, based on the price per unit, volume discount, and quantity.';
            ExternalAccess = Modify;
            ExternalName = 'baseamount';
            ExternalType = 'Money';
        }
        field(20; ExtendedAmount; Decimal)
        {
            Caption = 'Extended Amount';
            Description = 'Shows the total amount due for the order product, based on the sum of the unit price, quantity, discounts, and tax.';
            ExternalAccess = Modify;
            ExternalName = 'extendedamount';
            ExternalType = 'Money';
        }
        field(21; Description; BLOB)
        {
            Caption = 'Description';
            Description = 'Type additional information to describe the order product, such as manufacturing details or acceptable substitutions.';
            ExternalName = 'description';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(22; IsPriceOverridden; Boolean)
        {
            Caption = 'Pricing';
            Description = 'Select whether the price per unit is fixed at the value in the specified price list or can be overridden by users who have edit rights to the order product.';
            ExternalName = 'ispriceoverridden';
            ExternalType = 'Boolean';
        }
        field(23; ShipTo_Name; Text[200])
        {
            Caption = 'Ship To Name';
            Description = 'Type a name for the customer''s shipping address, such as "Headquarters" or "Field office", to identify the address.';
            ExternalName = 'shipto_name';
            ExternalType = 'String';
        }
        field(24; Tax; Decimal)
        {
            Caption = 'Tax';
            Description = 'Type the tax amount for the order product.';
            ExternalName = 'tax';
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
        field(26; ShipTo_Line1; Text[250])
        {
            Caption = 'Ship To Street 1';
            Description = 'Type the first line of the customer''s shipping address.';
            ExternalName = 'shipto_line1';
            ExternalType = 'String';
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
        field(28; ModifiedBy; Guid)
        {
            Caption = 'Modified By';
            Description = 'Shows who last updated the record.';
            ExternalAccess = Read;
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(29; ShipTo_Line2; Text[250])
        {
            Caption = 'Ship To Street 2';
            Description = 'Type the second line of the customer''s shipping address.';
            ExternalName = 'shipto_line2';
            ExternalType = 'String';
        }
        field(30; ShipTo_Line3; Text[250])
        {
            Caption = 'Ship To Street 3';
            Description = 'Type the third line of the shipping address.';
            ExternalName = 'shipto_line3';
            ExternalType = 'String';
        }
        field(31; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            Description = 'Shows the date and time when the record was last updated. The date and time are displayed in the time zone selected in Microsoft Dynamics CRM options.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
        }
        field(32; ShipTo_City; Text[80])
        {
            Caption = 'Ship To City';
            Description = 'Type the city for the customer''s shipping address.';
            ExternalName = 'shipto_city';
            ExternalType = 'String';
        }
        field(33; ShipTo_StateOrProvince; Text[50])
        {
            Caption = 'Ship To State/Province';
            Description = 'Type the state or province for the shipping address.';
            ExternalName = 'shipto_stateorprovince';
            ExternalType = 'String';
        }
        field(34; ShipTo_Country; Text[80])
        {
            Caption = 'Ship To Country/Region';
            Description = 'Type the country or region for the customer''s shipping address.';
            ExternalName = 'shipto_country';
            ExternalType = 'String';
        }
        field(35; ShipTo_PostalCode; Text[20])
        {
            Caption = 'Ship To ZIP/Postal Code';
            Description = 'Type the ZIP Code or postal code for the shipping address.';
            ExternalName = 'shipto_postalcode';
            ExternalType = 'String';
        }
        field(36; WillCall; Boolean)
        {
            Caption = 'Ship To';
            Description = 'Select whether the order product should be shipped to the specified address or held until the customer calls with further pick up or delivery instructions.';
            ExternalName = 'willcall';
            ExternalType = 'Boolean';
        }
        field(37; ShipTo_Telephone; Text[50])
        {
            Caption = 'Ship To Phone';
            Description = 'Type the phone number for the customer''s shipping address.';
            ExternalName = 'shipto_telephone';
            ExternalType = 'String';
        }
        field(38; ShipTo_Fax; Text[50])
        {
            Caption = 'Ship To Fax';
            Description = 'Type the fax number for the customer''s shipping address.';
            ExternalName = 'shipto_fax';
            ExternalType = 'String';
        }
        field(39; ShipTo_FreightTermsCode; Option)
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
        field(40; ProductIdName; Text[100])
        {
            CalcFormula = lookup("CRM Product".Name where(ProductId = field(ProductId)));
            Caption = 'ProductIdName';
            ExternalAccess = Read;
            ExternalName = 'productidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(41; UoMIdName; Text[100])
        {
            CalcFormula = lookup("CRM Uom".Name where(UoMId = field(UoMId)));
            Caption = 'UoMIdName';
            ExternalAccess = Read;
            ExternalName = 'uomidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(42; SalesRepIdName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(SalesRepId)));
            Caption = 'SalesRepIdName';
            ExternalAccess = Read;
            ExternalName = 'salesrepidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(43; SalesOrderStateCode; Option)
        {
            Caption = 'Order Status';
            Description = 'Shows the status of the order that the order detail is associated with.';
            ExternalAccess = Read;
            ExternalName = 'salesorderstatecode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ';
            OptionOrdinalValues = -1;
            OptionMembers = " ";
        }
        field(44; CreatedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedBy)));
            Caption = 'CreatedByName';
            ExternalAccess = Read;
            ExternalName = 'createdbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(45; ModifiedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedBy)));
            Caption = 'ModifiedByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(46; ShipTo_ContactName; Text[150])
        {
            Caption = 'Ship To Contact Name';
            Description = 'Type the primary contact name at the customer''s shipping address.';
            ExternalName = 'shipto_contactname';
            ExternalType = 'String';
        }
        field(47; VersionNumber; BigInteger)
        {
            Caption = 'Version Number';
            Description = 'Version number of the sales order detail.';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(48; OwningBusinessUnit; Guid)
        {
            Caption = 'Owning Business Unit';
            Description = 'Unique identifier of the business unit that owns the order product.';
            ExternalAccess = Read;
            ExternalName = 'owningbusinessunit';
            ExternalType = 'Uniqueidentifier';
        }
        field(49; OwningUser; Guid)
        {
            Caption = 'Owning User';
            Description = 'Unique identifier of the user who owns the order product.';
            ExternalAccess = Read;
            ExternalName = 'owninguser';
            ExternalType = 'Uniqueidentifier';
        }
        field(50; SalesOrderIsPriceLocked; Boolean)
        {
            Caption = 'Order Is Price Locked';
            Description = 'Tells whether product pricing is locked for the order.';
            ExternalAccess = Read;
            ExternalName = 'salesorderispricelocked';
            ExternalType = 'Boolean';
        }
        field(51; ShipTo_AddressId; Guid)
        {
            Caption = 'Ship To Address ID';
            Description = 'Unique identifier of the shipping address.';
            ExternalName = 'shipto_addressid';
            ExternalType = 'Uniqueidentifier';
        }
        field(52; TimeZoneRuleVersionNumber; Integer)
        {
            Caption = 'Time Zone Rule Version Number';
            Description = 'For internal use only.';
            ExternalName = 'timezoneruleversionnumber';
            ExternalType = 'Integer';
            MinValue = -1;
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
        field(55; ExchangeRate; Decimal)
        {
            Caption = 'Exchange Rate';
            Description = 'Shows the conversion rate of the record''s currency. The exchange rate is used to convert all money fields in the record from the local currency to the system''s default currency.';
            ExternalAccess = Read;
            ExternalName = 'exchangerate';
            ExternalType = 'Decimal';
        }
        field(56; OverriddenCreatedOn; Date)
        {
            Caption = 'Record Created On';
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
        }
        field(57; TransactionCurrencyId; Guid)
        {
            Caption = 'Currency';
            Description = 'Choose the local currency for the record to make sure budgets are reported in the correct currency.';
            ExternalAccess = Read;
            ExternalName = 'transactioncurrencyid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Transactioncurrency".TransactionCurrencyId;
        }
        field(58; BaseAmount_Base; Decimal)
        {
            Caption = 'Amount (Base)';
            Description = 'Shows the Amount field converted to the system''s default base currency. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'baseamount_base';
            ExternalType = 'Money';
        }
        field(59; PricePerUnit_Base; Decimal)
        {
            Caption = 'Price Per Unit (Base)';
            Description = 'Shows the Price Per Unit field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'priceperunit_base';
            ExternalType = 'Money';
        }
        field(60; TransactionCurrencyIdName; Text[100])
        {
            CalcFormula = lookup("CRM Transactioncurrency".CurrencyName where(TransactionCurrencyId = field(TransactionCurrencyId)));
            Caption = 'TransactionCurrencyIdName';
            ExternalAccess = Read;
            ExternalName = 'transactioncurrencyidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(61; VolumeDiscountAmount_Base; Decimal)
        {
            Caption = 'Volume Discount (Base)';
            Description = 'Shows the Volume Discount field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'volumediscountamount_base';
            ExternalType = 'Money';
        }
        field(62; ExtendedAmount_Base; Decimal)
        {
            Caption = 'Extended Amount (Base)';
            Description = 'Shows the Extended Amount field converted to the system''s default base currency. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'extendedamount_base';
            ExternalType = 'Money';
        }
        field(63; Tax_Base; Decimal)
        {
            Caption = 'Tax (Base)';
            Description = 'Shows the Tax field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'tax_base';
            ExternalType = 'Money';
        }
        field(64; ManualDiscountAmount_Base; Decimal)
        {
            Caption = 'Manual Discount (Base)';
            Description = 'Shows the Manual Discount field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'manualdiscountamount_base';
            ExternalType = 'Money';
        }
        field(65; OwnerId; Guid)
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
        field(66; OwnerIdType; Option)
        {
            Caption = 'OwnerIdType';
            ExternalAccess = Read;
            ExternalName = 'owneridtype';
            ExternalType = 'EntityName';
            OptionCaption = ' ,systemuser,team';
            OptionMembers = " ",systemuser,team;
        }
        field(67; CreatedOnBehalfBy; Guid)
        {
            Caption = 'Created By (Delegate)';
            Description = 'Shows who created the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(68; CreatedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            Caption = 'CreatedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(69; ModifiedOnBehalfBy; Guid)
        {
            Caption = 'Modified By (Delegate)';
            Description = 'Shows who last updated the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(70; ModifiedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedOnBehalfBy)));
            Caption = 'ModifiedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(71; SequenceNumber; Integer)
        {
            Caption = 'Sequence Number';
            Description = 'Shows the ID of the data that maintains the sequence.';
            ExternalName = 'sequencenumber';
            ExternalType = 'Integer';
        }
        field(72; ParentBundleId; Guid)
        {
            Caption = 'Parent Bundle';
            Description = 'Choose the parent bundle associated with this product';
            ExternalAccess = Insert;
            ExternalName = 'parentbundleid';
            ExternalType = 'Uniqueidentifier';
        }
        field(73; ProductTypeCode; Option)
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
        field(74; PropertyConfigurationStatus; Option)
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
        field(75; ProductAssociationId; Guid)
        {
            Caption = 'Bundle Item Association';
            Description = 'Unique identifier of the product line item association with bundle in the sales order';
            ExternalAccess = Insert;
            ExternalName = 'productassociationid';
            ExternalType = 'Uniqueidentifier';
        }
        field(76; BusinessCentralLineNumber; Integer)
        {
            ExternalName = 'bcbi_businesscentrallinenumber';
            ExternalType = 'Integer';
            Caption = 'BC Line Number';
        }
    }

    keys
    {
        key(Key1; SalesOrderDetailId)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

