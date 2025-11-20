// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5356 "CRM Invoicedetail"
{
    // Dynamics CRM Version: 7.1.0.2040

    Caption = 'CRM Invoicedetail';
    Description = 'Line item in an invoice containing detailed billing information for a product.';
    ExternalName = 'invoicedetail';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; InvoiceDetailId; Guid)
        {
            Caption = 'Invoice Product';
            Description = 'Unique identifier of the invoice product line item.';
            ExternalAccess = Insert;
            ExternalName = 'invoicedetailid';
            ExternalType = 'Uniqueidentifier';
        }
        field(2; SalesRepId; Guid)
        {
            Caption = 'Salesperson';
            Description = 'Choose the user responsible for the sale of the invoice product.';
            ExternalName = 'salesrepid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(3; IsProductOverridden; Boolean)
        {
            Caption = 'Select Product';
            Description = 'Select whether the product exists in the Microsoft Dynamics CRM product catalog or is a write-in product specific to the parent invoice.';
            ExternalAccess = Insert;
            ExternalName = 'isproductoverridden';
            ExternalType = 'Boolean';
        }
        field(4; LineItemNumber; Integer)
        {
            Caption = 'Line Item Number';
            Description = 'Type the line item number for the invoice product to easily identify the product in the invoice and make sure it''s listed in the correct order.';
            ExternalName = 'lineitemnumber';
            ExternalType = 'Integer';
            MaxValue = 1000000000;
            MinValue = 0;
        }
        field(5; IsCopied; Boolean)
        {
            Caption = 'Copied';
            Description = 'Select whether the invoice product is copied from another item or data source.';
            ExternalName = 'iscopied';
            ExternalType = 'Boolean';
        }
        field(6; InvoiceId; Guid)
        {
            Caption = 'Invoice ID';
            Description = 'Unique identifier of the invoice associated with the invoice product line item.';
            ExternalName = 'invoiceid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Invoice".InvoiceId;
        }
        field(7; QuantityBackordered; Decimal)
        {
            Caption = 'Quantity Back Ordered';
            Description = 'Type the amount or quantity of the product that is back ordered for the invoice.';
            ExternalName = 'quantitybackordered';
            ExternalType = 'Decimal';
        }
        field(8; UoMId; Guid)
        {
            Caption = 'Unit';
            Description = 'Choose the unit of measurement for the base unit quantity for this purchase, such as each or dozen.';
            ExternalName = 'uomid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Uom".UoMId;
        }
        field(9; ProductId; Guid)
        {
            Caption = 'Existing Product';
            Description = 'Choose the product to include on the invoice.';
            ExternalName = 'productid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Product".ProductId;
        }
        field(10; ActualDeliveryOn; Date)
        {
            Caption = 'Delivered On';
            Description = 'Enter the date when the invoiced product was delivered to the customer.';
            ExternalName = 'actualdeliveryon';
            ExternalType = 'DateTime';
        }
        field(11; Quantity; Decimal)
        {
            Caption = 'Quantity';
            Description = 'Type the amount or quantity of the product included in the invoice''s total amount due.';
            ExternalName = 'quantity';
            ExternalType = 'Decimal';
        }
        field(12; ManualDiscountAmount; Decimal)
        {
            Caption = 'Manual Discount';
            Description = 'Type the manual discount amount for the invoice product to deduct any negotiated or other savings from the product total.';
            ExternalName = 'manualdiscountamount';
            ExternalType = 'Money';
        }
        field(13; ProductDescription; Text[250])
        {
            Caption = 'Write-In Product';
            Description = 'Type a name or description to identify the type of write-in product included in the invoice.';
            ExternalName = 'productdescription';
            ExternalType = 'String';
        }
        field(14; VolumeDiscountAmount; Decimal)
        {
            Caption = 'Volume Discount';
            Description = 'Shows the discount amount per unit if a specified volume is purchased. Configure volume discounts in the Product Catalog in the Settings area.';
            ExternalAccess = Read;
            ExternalName = 'volumediscountamount';
            ExternalType = 'Money';
        }
        field(15; PricePerUnit; Decimal)
        {
            Caption = 'Price Per Unit';
            Description = 'Type the price per unit of the invoice product. The default is the value in the price list specified on the parent invoice for existing products.';
            ExternalName = 'priceperunit';
            ExternalType = 'Money';
        }
        field(16; BaseAmount; Decimal)
        {
            Caption = 'Amount';
            Description = 'Shows the total price of the invoice product, based on the price per unit, volume discount, and quantity.';
            ExternalAccess = Modify;
            ExternalName = 'baseamount';
            ExternalType = 'Money';
        }
        field(17; QuantityCancelled; Decimal)
        {
            Caption = 'Quantity Canceled';
            Description = 'Type the amount or quantity of the product that was canceled for the invoice line item.';
            ExternalName = 'quantitycancelled';
            ExternalType = 'Decimal';
        }
        field(18; ShippingTrackingNumber; Text[100])
        {
            Caption = 'Shipment Tracking Number';
            Description = 'Type a tracking number for shipment of the invoiced product.';
            ExternalName = 'shippingtrackingnumber';
            ExternalType = 'String';
        }
        field(19; ExtendedAmount; Decimal)
        {
            Caption = 'Extended Amount';
            Description = 'Shows the total amount due for the invoice product, based on the sum of the unit price, quantity, discounts, and tax.';
            ExternalAccess = Modify;
            ExternalName = 'extendedamount';
            ExternalType = 'Money';
        }
        field(20; Description; BLOB)
        {
            Caption = 'Description';
            Description = 'Type additional information to describe the product line item of the invoice.';
            ExternalName = 'description';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(21; IsPriceOverridden; Boolean)
        {
            Caption = 'Pricing';
            Description = 'Select whether the price per unit is fixed at the value in the specified price list or can be overridden by users who have edit rights to the invoice product.';
            ExternalName = 'ispriceoverridden';
            ExternalType = 'Boolean';
        }
        field(22; ShipTo_Name; Text[200])
        {
            Caption = 'Ship To Name';
            Description = 'Type a name for the customer''s shipping address, such as "Headquarters" or "Field office", to identify the address.';
            ExternalName = 'shipto_name';
            ExternalType = 'String';
        }
        field(23; PricingErrorCode; Option)
        {
            Caption = 'Pricing Error ';
            Description = 'Pricing error for the invoice product line item.';
            ExternalName = 'pricingerrorcode';
            ExternalType = 'Picklist';
            InitValue = "None";
            OptionCaption = 'None,Detail Error,Missing Price Level,Inactive Price Level,Missing Quantity,Missing Unit Price,Missing Product,Invalid Product,Missing Pricing Code,Invalid Pricing Code,Missing UOM,Product Not In Price Level,Missing Price Level Amount,Missing Price Level Percentage,Missing Price,Missing Current Cost,Missing Standard Cost,Invalid Price Level Amount,Invalid Price Level Percentage,Invalid Price,Invalid Current Cost,Invalid Standard Cost,Invalid Rounding Policy,Invalid Rounding Option,Invalid Rounding Amount,Price Calculation Error,Invalid Discount Type,Discount Type Invalid State,Invalid Discount,Invalid Quantity,Invalid Pricing Precision,Missing Product Default UOM,Missing Product UOM Schedule ,Inactive Discount Type,Invalid Price Level Currency,Price Attribute Out Of Range,Base Currency Attribute Overflow,Base Currency Attribute Underflow';
            OptionOrdinalValues = 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37;
            OptionMembers = "None",DetailError,MissingPriceLevel,InactivePriceLevel,MissingQuantity,MissingUnitPrice,MissingProduct,InvalidProduct,MissingPricingCode,InvalidPricingCode,MissingUOM,ProductNotInPriceLevel,MissingPriceLevelAmount,MissingPriceLevelPercentage,MissingPrice,MissingCurrentCost,MissingStandardCost,InvalidPriceLevelAmount,InvalidPriceLevelPercentage,InvalidPrice,InvalidCurrentCost,InvalidStandardCost,InvalidRoundingPolicy,InvalidRoundingOption,InvalidRoundingAmount,PriceCalculationError,InvalidDiscountType,DiscountTypeInvalidState,InvalidDiscount,InvalidQuantity,InvalidPricingPrecision,MissingProductDefaultUOM,MissingProductUOMSchedule,InactiveDiscountType,InvalidPriceLevelCurrency,PriceAttributeOutOfRange,BaseCurrencyAttributeOverflow,BaseCurrencyAttributeUnderflow;
        }
        field(24; Tax; Decimal)
        {
            Caption = 'Tax';
            Description = 'Type the tax amount for the invoice product.';
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
            Description = 'Select whether the invoice product should be shipped to the specified address or held until the customer calls with further pick up or delivery instructions.';
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
        field(40; QuantityShipped; Decimal)
        {
            Caption = 'Quantity Shipped';
            Description = 'Type the amount or quantity of the product that was shipped.';
            ExternalName = 'quantityshipped';
            ExternalType = 'Decimal';
        }
        field(41; ProductIdName; Text[100])
        {
            CalcFormula = lookup("CRM Product".Name where(ProductId = field(ProductId)));
            Caption = 'ProductIdName';
            ExternalAccess = Read;
            ExternalName = 'productidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(42; UoMIdName; Text[100])
        {
            CalcFormula = lookup("CRM Uom".Name where(UoMId = field(UoMId)));
            Caption = 'UoMIdName';
            ExternalAccess = Read;
            ExternalName = 'uomidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(43; SalesRepIdName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(SalesRepId)));
            Caption = 'SalesRepIdName';
            ExternalAccess = Read;
            ExternalName = 'salesrepidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(44; InvoiceStateCode; Option)
        {
            Caption = 'Invoice Status';
            Description = 'Status of the invoice product.';
            ExternalAccess = Read;
            ExternalName = 'invoicestatecode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ';
            OptionOrdinalValues = -1;
            OptionMembers = " ";
        }
        field(45; CreatedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedBy)));
            Caption = 'CreatedByName';
            ExternalAccess = Read;
            ExternalName = 'createdbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(46; ModifiedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedBy)));
            Caption = 'ModifiedByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(47; VersionNumber; BigInteger)
        {
            Caption = 'Version Number';
            Description = 'Version number of the invoice product line item.';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(48; OwningUser; Guid)
        {
            Caption = 'Owning User';
            Description = 'Unique identifier of the user who owns the invoice product line item.';
            ExternalAccess = Read;
            ExternalName = 'owninguser';
            ExternalType = 'Uniqueidentifier';
        }
        field(49; InvoiceIsPriceLocked; Boolean)
        {
            Caption = 'Invoice Is Price Locked';
            Description = 'Information about whether invoice product pricing is locked.';
            ExternalAccess = Read;
            ExternalName = 'invoiceispricelocked';
            ExternalType = 'Boolean';
        }
        field(50; OwningBusinessUnit; Guid)
        {
            Caption = 'Owning Business Unit';
            Description = 'Unique identifier of the business unit that owns the invoice product line item.';
            ExternalAccess = Read;
            ExternalName = 'owningbusinessunit';
            ExternalType = 'Uniqueidentifier';
        }
        field(51; ExchangeRate; Decimal)
        {
            Caption = 'Exchange Rate';
            Description = 'Shows the conversion rate of the record''s currency. The exchange rate is used to convert all money fields in the record from the local currency to the system''s default currency.';
            ExternalAccess = Read;
            ExternalName = 'exchangerate';
            ExternalType = 'Decimal';
        }
        field(52; TransactionCurrencyId; Guid)
        {
            Caption = 'Currency';
            Description = 'Choose the local currency for the record to make sure budgets are reported in the correct currency.';
            ExternalAccess = Read;
            ExternalName = 'transactioncurrencyid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Transactioncurrency".TransactionCurrencyId;
        }
        field(53; UTCConversionTimeZoneCode; Integer)
        {
            Caption = 'UTC Conversion Time Zone Code';
            Description = 'Time zone code that was in use when the record was created.';
            ExternalName = 'utcconversiontimezonecode';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(54; TimeZoneRuleVersionNumber; Integer)
        {
            Caption = 'Time Zone Rule Version Number';
            Description = 'For internal use only.';
            ExternalName = 'timezoneruleversionnumber';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(55; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            Description = 'Unique identifier of the data import or data migration that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
        }
        field(56; OverriddenCreatedOn; Date)
        {
            Caption = 'Record Created On';
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
        }
        field(57; VolumeDiscountAmount_Base; Decimal)
        {
            Caption = 'Volume Discount (Base)';
            Description = 'Shows the Volume Discount field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'volumediscountamount_base';
            ExternalType = 'Money';
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
        field(61; Tax_Base; Decimal)
        {
            Caption = 'Tax (Base)';
            Description = 'Shows the Tax field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'tax_base';
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
        field(63; ManualDiscountAmount_Base; Decimal)
        {
            Caption = 'Manual Discount (Base)';
            Description = 'Shows the Manual Discount field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'manualdiscountamount_base';
            ExternalType = 'Money';
        }
        field(64; OwnerId; Guid)
        {
            Caption = 'Owner';
            Description = 'Unique identifier of the user or team who owns the invoice detail.';
            ExternalAccess = Read;
            ExternalName = 'ownerid';
            ExternalType = 'Owner';
            TableRelation = if (OwnerIdType = const(systemuser)) "CRM Systemuser".SystemUserId
            else
            if (OwnerIdType = const(team)) "CRM Team".TeamId;
        }
        field(65; OwnerIdType; Option)
        {
            Caption = 'Owner';
            Description = 'Unique identifier of the user or team who owns the invoice detail.';
            ExternalAccess = Read;
            ExternalName = 'owneridtype';
            ExternalType = 'EntityName';
            OptionCaption = ' ,systemuser,team';
            OptionMembers = " ",systemuser,team;
        }
        field(66; CreatedOnBehalfBy; Guid)
        {
            Caption = 'Created By (Delegate)';
            Description = 'Shows who created the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(67; CreatedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            Caption = 'CreatedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(68; ModifiedOnBehalfBy; Guid)
        {
            Caption = 'Modified By (Delegate)';
            Description = 'Shows who last updated the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(69; ModifiedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedOnBehalfBy)));
            Caption = 'ModifiedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(70; SequenceNumber; Integer)
        {
            Caption = 'Sequence Number';
            Description = 'Shows the ID of the data that maintains the sequence.';
            ExternalName = 'sequencenumber';
            ExternalType = 'Integer';
        }
        field(71; ParentBundleId; Guid)
        {
            Caption = 'Parent Bundle';
            Description = 'Choose the parent bundle associated with this product';
            ExternalAccess = Insert;
            ExternalName = 'parentbundleid';
            ExternalType = 'Uniqueidentifier';
        }
        field(72; ProductTypeCode; Option)
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
        field(73; PropertyConfigurationStatus; Option)
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
        field(74; ProductAssociationId; Guid)
        {
            Caption = 'Bundle Item Association';
            Description = 'Unique identifier of the product line item association with bundle in the invoice';
            ExternalAccess = Insert;
            ExternalName = 'productassociationid';
            ExternalType = 'Uniqueidentifier';
        }
    }

    keys
    {
        key(Key1; InvoiceDetailId)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

