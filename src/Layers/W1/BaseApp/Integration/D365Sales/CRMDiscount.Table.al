// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5365 "CRM Discount"
{
    // Dynamics CRM Version: 7.1.0.2040

    Caption = 'CRM Discount';
    Description = 'Price reduction made from the list price of a product or service based on the quantity purchased.';
    ExternalName = 'discount';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; DiscountId; Guid)
        {
            Caption = 'Discount';
            Description = 'Unique identifier of the discount.';
            ExternalAccess = Insert;
            ExternalName = 'discountid';
            ExternalType = 'Uniqueidentifier';
        }
        field(2; DiscountTypeId; Guid)
        {
            Caption = 'Discount Type';
            Description = 'Unique identifier of the discount list associated with the discount.';
            ExternalAccess = Insert;
            ExternalName = 'discounttypeid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Discounttype".DiscountTypeId;
        }
        field(3; LowQuantity; Decimal)
        {
            Caption = 'Begin Quantity';
            Description = 'Lower boundary for the quantity range to which a particular discount is applied.';
            ExternalName = 'lowquantity';
            ExternalType = 'Decimal';
        }
        field(4; HighQuantity; Decimal)
        {
            Caption = 'End Quantity';
            Description = 'Upper boundary for the quantity range to which a particular discount can be applied.';
            ExternalName = 'highquantity';
            ExternalType = 'Decimal';
        }
        field(5; Percentage; Decimal)
        {
            Caption = 'Percentage';
            Description = 'Percentage discount value.';
            ExternalName = 'percentage';
            ExternalType = 'Decimal';
        }
        field(6; Amount; Decimal)
        {
            Caption = 'Amount';
            Description = 'Amount of the discount, specified either as a percentage or as a monetary amount.';
            ExternalName = 'amount';
            ExternalType = 'Money';
        }
        field(7; StatusCode; Option)
        {
            Caption = 'Status Reason';
            Description = 'Select the discount''s status.';
            ExternalName = 'statuscode';
            ExternalType = 'Status';
            InitValue = " ";
            OptionCaption = ' ';
            OptionOrdinalValues = -1;
            OptionMembers = " ";
        }
        field(8; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            Description = 'Date and time when the discount was created.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(9; CreatedBy; Guid)
        {
            Caption = 'Created By';
            Description = 'Unique identifier of the user who created the discount.';
            ExternalAccess = Read;
            ExternalName = 'createdby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(10; ModifiedBy; Guid)
        {
            Caption = 'Modified By';
            Description = 'Unique identifier of the user who last modified the discount.';
            ExternalAccess = Read;
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(11; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            Description = 'Date and time when the discount was last modified.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
        }
        field(12; DiscountTypeIdName; Text[100])
        {
            CalcFormula = lookup("CRM Discounttype".Name where(DiscountTypeId = field(DiscountTypeId)));
            Caption = 'DiscountTypeIdName';
            ExternalAccess = Read;
            ExternalName = 'discounttypeidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(13; IsAmountType; Boolean)
        {
            Caption = 'Amount Type';
            Description = 'Specifies whether the discount is specified as a monetary amount or a percentage.';
            ExternalAccess = Read;
            ExternalName = 'isamounttype';
            ExternalType = 'Boolean';
        }
        field(14; CreatedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedBy)));
            Caption = 'CreatedByName';
            ExternalAccess = Read;
            ExternalName = 'createdbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(15; ModifiedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedBy)));
            Caption = 'ModifiedByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(16; VersionNumber; BigInteger)
        {
            Caption = 'Version Number';
            Description = 'Version number of the discount.';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(17; OrganizationId; Guid)
        {
            Caption = 'Organization ';
            Description = 'Unique identifier of the organization associated with the discount.';
            ExternalAccess = Read;
            ExternalName = 'organizationid';
            ExternalType = 'Uniqueidentifier';
        }
        field(18; OverriddenCreatedOn; Date)
        {
            Caption = 'Record Created On';
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
        }
        field(19; TransactionCurrencyId; Guid)
        {
            Caption = 'Currency';
            Description = 'Choose the local currency for the record to make sure budgets are reported in the correct currency.';
            ExternalAccess = Read;
            ExternalName = 'transactioncurrencyid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Transactioncurrency".TransactionCurrencyId;
        }
        field(20; ExchangeRate; Decimal)
        {
            Caption = 'Exchange Rate';
            Description = 'Shows the conversion rate of the record''s currency. The exchange rate is used to convert all money fields in the record from the local currency to the system''s default currency.';
            ExternalAccess = Read;
            ExternalName = 'exchangerate';
            ExternalType = 'Decimal';
        }
        field(21; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            Description = 'Unique identifier of the data import or data migration that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
        }
        field(22; Amount_Base; Decimal)
        {
            Caption = 'Amount (Base)';
            Description = 'Shows the Amount field converted to the system''s default base currency, if specified as a fixed amount. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'amount_base';
            ExternalType = 'Money';
        }
        field(23; TransactionCurrencyIdName; Text[100])
        {
            CalcFormula = lookup("CRM Transactioncurrency".CurrencyName where(TransactionCurrencyId = field(TransactionCurrencyId)));
            Caption = 'TransactionCurrencyIdName';
            ExternalAccess = Read;
            ExternalName = 'transactioncurrencyidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(24; CreatedOnBehalfBy; Guid)
        {
            Caption = 'Created By (Delegate)';
            Description = 'Unique identifier of the delegate user who created the discount.';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(25; CreatedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            Caption = 'CreatedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(26; ModifiedOnBehalfBy; Guid)
        {
            Caption = 'Modified By (Delegate)';
            Description = 'Unique identifier of the delegate user who last modified the discount.';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(27; ModifiedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedOnBehalfBy)));
            Caption = 'ModifiedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; DiscountId)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

