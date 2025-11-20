// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5347 "CRM Productpricelevel"
{
    // Dynamics CRM Version: 7.1.0.2040

    Caption = 'CRM Productpricelevel';
    Description = 'Information about how to price a product in the specified price level, including pricing method, rounding option, and discount type based on a specified product unit.';
    ExternalName = 'productpricelevel';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; PriceLevelId; Guid)
        {
            Caption = 'Price List';
            Description = 'Unique identifier of the price level associated with this price list.';
            ExternalAccess = Insert;
            ExternalName = 'pricelevelid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Pricelevel".PriceLevelId;
        }
        field(2; ProductPriceLevelId; Guid)
        {
            Caption = 'Product Price List';
            Description = 'Unique identifier of the price list.';
            ExternalAccess = Insert;
            ExternalName = 'productpricelevelid';
            ExternalType = 'Uniqueidentifier';
        }
        field(3; UoMId; Guid)
        {
            Caption = 'Unit';
            Description = 'Unique identifier of the unit for the price list.';
            ExternalName = 'uomid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Uom".UoMId;
        }
        field(4; UoMScheduleId; Guid)
        {
            Caption = 'Unit Schedule ID';
            Description = 'Unique identifier of the unit schedule for the price list.';
            ExternalName = 'uomscheduleid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Uomschedule".UoMScheduleId;
        }
        field(5; DiscountTypeId; Guid)
        {
            Caption = 'Discount List';
            Description = 'Unique identifier of the discount list associated with the price list.';
            ExternalName = 'discounttypeid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Discounttype".DiscountTypeId;
        }
        field(6; ProductId; Guid)
        {
            Caption = 'Product';
            Description = 'Product associated with the price list.';
            ExternalName = 'productid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Product".ProductId;
        }
        field(7; Percentage; Decimal)
        {
            Caption = 'Percentage';
            Description = 'Percentage for the price list.';
            ExternalName = 'percentage';
            ExternalType = 'Decimal';
        }
        field(8; Amount; Decimal)
        {
            Caption = 'Amount';
            Description = 'Monetary amount for the price list.';
            ExternalName = 'amount';
            ExternalType = 'Money';
        }
        field(9; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            Description = 'Date and time when the price list was created.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(10; QuantitySellingCode; Option)
        {
            Caption = 'Quantity Selling Option';
            Description = 'Quantity of the product that must be sold for a given price level.';
            ExternalName = 'quantitysellingcode';
            ExternalType = 'Picklist';
            InitValue = NoControl;
            OptionCaption = 'No Control,Whole,Whole and Fractional';
            OptionOrdinalValues = 1, 2, 3;
            OptionMembers = NoControl,Whole,WholeandFractional;
        }
        field(11; RoundingPolicyCode; Option)
        {
            Caption = 'Rounding Policy';
            Description = 'Policy for rounding the price list.';
            ExternalName = 'roundingpolicycode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,None,Up,Down,To Nearest';
            OptionOrdinalValues = -1, 1, 2, 3, 4;
            OptionMembers = " ","None",Up,Down,ToNearest;
        }
        field(12; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            Description = 'Date and time when the price list was last modified.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
        }
        field(13; PricingMethodCode; Option)
        {
            Caption = 'Pricing Method';
            Description = 'Pricing method applied to the price list.';
            ExternalName = 'pricingmethodcode';
            ExternalType = 'Picklist';
            InitValue = CurrencyAmount;
            OptionCaption = 'Currency Amount,Percent of List,Percent Markup - Current Cost,Percent Margin - Current Cost,Percent Markup - Standard Cost,Percent Margin - Standard Cost';
            OptionOrdinalValues = 1, 2, 3, 4, 5, 6;
            OptionMembers = CurrencyAmount,PercentofList,"PercentMarkup-CurrentCost","PercentMargin-CurrentCost","PercentMarkup-StandardCost","PercentMargin-StandardCost";
        }
        field(14; RoundingOptionCode; Option)
        {
            Caption = 'Rounding Option';
            Description = 'Option for rounding the price list.';
            ExternalName = 'roundingoptioncode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Ends in,Multiple of';
            OptionOrdinalValues = -1, 1, 2;
            OptionMembers = " ",Endsin,Multipleof;
        }
        field(15; RoundingOptionAmount; Decimal)
        {
            Caption = 'Rounding Amount';
            Description = 'Rounding option amount for the price list.';
            ExternalName = 'roundingoptionamount';
            ExternalType = 'Money';
        }
        field(16; VersionNumber; BigInteger)
        {
            Caption = 'Version Number';
            Description = 'Version number of the price list.';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(17; CreatedBy; Guid)
        {
            Caption = 'Created By';
            Description = 'Unique identifier of the user who created the price list.';
            ExternalAccess = Read;
            ExternalName = 'createdby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(18; ModifiedBy; Guid)
        {
            Caption = 'Modified By';
            Description = 'Unique identifier of the user who last modified the price list.';
            ExternalAccess = Read;
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(19; DiscountTypeIdName; Text[100])
        {
            CalcFormula = lookup("CRM Discounttype".Name where(DiscountTypeId = field(DiscountTypeId)));
            Caption = 'DiscountTypeIdName';
            ExternalAccess = Read;
            ExternalName = 'discounttypeidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(20; ProductIdName; Text[100])
        {
            CalcFormula = lookup("CRM Product".Name where(ProductId = field(ProductId)));
            Caption = 'ProductIdName';
            ExternalAccess = Read;
            ExternalName = 'productidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(21; PriceLevelIdName; Text[100])
        {
            CalcFormula = lookup("CRM Pricelevel".Name where(PriceLevelId = field(PriceLevelId)));
            Caption = 'PriceLevelIdName';
            ExternalAccess = Read;
            ExternalName = 'pricelevelidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(22; UoMIdName; Text[100])
        {
            CalcFormula = lookup("CRM Uom".Name where(UoMId = field(UoMId)));
            Caption = 'UoMIdName';
            ExternalAccess = Read;
            ExternalName = 'uomidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(23; UoMScheduleIdName; Text[200])
        {
            CalcFormula = lookup("CRM Uomschedule".Name where(UoMScheduleId = field(UoMScheduleId)));
            Caption = 'UoMScheduleIdName';
            ExternalAccess = Read;
            ExternalName = 'uomscheduleidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(24; CreatedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedBy)));
            Caption = 'CreatedByName';
            ExternalAccess = Read;
            ExternalName = 'createdbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(25; ModifiedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedBy)));
            Caption = 'ModifiedByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(26; OrganizationId; Guid)
        {
            Caption = 'Organization';
            Description = 'Unique identifier of the organization associated with the price list.';
            ExternalAccess = Read;
            ExternalName = 'organizationid';
            ExternalType = 'Uniqueidentifier';
        }
        field(27; ExchangeRate; Decimal)
        {
            Caption = 'Exchange Rate';
            Description = 'Shows the conversion rate of the record''s currency. The exchange rate is used to convert all money fields in the record from the local currency to the system''s default currency.';
            ExternalAccess = Read;
            ExternalName = 'exchangerate';
            ExternalType = 'Decimal';
        }
        field(28; TransactionCurrencyId; Guid)
        {
            Caption = 'Currency';
            Description = 'Choose the local currency for the record to make sure budgets are reported in the correct currency.';
            ExternalAccess = Modify;
            ExternalName = 'transactioncurrencyid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Transactioncurrency".TransactionCurrencyId;
        }
        field(29; OverriddenCreatedOn; Date)
        {
            Caption = 'Record Created On';
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
        }
        field(30; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            Description = 'Unique identifier of the data import or data migration that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
        }
        field(31; Amount_Base; Decimal)
        {
            Caption = 'Amount (Base)';
            Description = 'Shows the Amount field converted to the system''s default base currency, if specified as a fixed amount. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'amount_base';
            ExternalType = 'Money';
        }
        field(32; TransactionCurrencyIdName; Text[100])
        {
            CalcFormula = lookup("CRM Transactioncurrency".CurrencyName where(TransactionCurrencyId = field(TransactionCurrencyId)));
            Caption = 'TransactionCurrencyIdName';
            ExternalAccess = Read;
            ExternalName = 'transactioncurrencyidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(33; RoundingOptionAmount_Base; Decimal)
        {
            Caption = 'Rounding Amount (Base)';
            Description = 'Shows the Rounding Amount field converted to the system''s default base currency for reporting purposes. The calculations use the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'roundingoptionamount_base';
            ExternalType = 'Money';
        }
        field(34; CreatedOnBehalfBy; Guid)
        {
            Caption = 'Created By (Delegate)';
            Description = 'Shows who created the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(35; CreatedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            Caption = 'CreatedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(36; ModifiedOnBehalfBy; Guid)
        {
            Caption = 'Modified By (Delegate)';
            Description = 'Shows who last updated the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(37; ModifiedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedOnBehalfBy)));
            Caption = 'ModifiedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(38; ProcessId; Guid)
        {
            Caption = 'Process';
            Description = 'Unique identifier of the Process.';
            ExternalName = 'processid';
            ExternalType = 'Uniqueidentifier';
        }
        field(39; StageId; Guid)
        {
            Caption = 'Process Stage';
            Description = 'Shows the ID of the stage.';
            ExternalName = 'stageid';
            ExternalType = 'Uniqueidentifier';
        }
        field(40; ProductNumber; Text[100])
        {
            Caption = 'Product ID';
            Description = 'User-defined product number.';
            ExternalAccess = Read;
            ExternalName = 'productnumber';
            ExternalType = 'String';
        }
        field(41; TraversedPath; Text[250])
        {
            Caption = 'Traversed Path';
            Description = 'For internal use only.';
            ExternalName = 'traversedpath';
            ExternalType = 'String';
        }
    }

    keys
    {
        key(Key1; ProductPriceLevelId)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

