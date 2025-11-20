// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5367 "CRM Account Statistics"
{
    Caption = 'CRM Account Statistics';
    Description = 'An entity to store aggregate statistics from Dynamics NAV about an account.';
    ExternalName = 'nav_accountstatistics';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; AccountStatisticsId; Guid)
        {
            Caption = 'Account Statistics';
            Description = 'Unique identifier for entity instances';
            ExternalAccess = Insert;
            ExternalName = 'nav_accountstatisticsid';
            ExternalType = 'Uniqueidentifier';
        }
        field(2; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            Description = 'Date and time when the record was created.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(3; CreatedBy; Guid)
        {
            Caption = 'Created By';
            Description = 'Unique identifier of the user who created the record.';
            ExternalAccess = Read;
            ExternalName = 'createdby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(4; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            Description = 'Date and time when the record was modified.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
        }
        field(5; ModifiedBy; Guid)
        {
            Caption = 'Modified By';
            Description = 'Unique identifier of the user who modified the record.';
            ExternalAccess = Read;
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(6; CreatedOnBehalfBy; Guid)
        {
            Caption = 'Created By (Delegate)';
            Description = 'Unique identifier of the delegate user who created the record.';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(7; ModifiedOnBehalfBy; Guid)
        {
            Caption = 'Modified By (Delegate)';
            Description = 'Unique identifier of the delegate user who modified the record.';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(8; CreatedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedBy)));
            Caption = 'CreatedByName';
            ExternalAccess = Read;
            ExternalName = 'createdbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(9; CreatedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            Caption = 'CreatedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(10; ModifiedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedBy)));
            Caption = 'ModifiedByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(11; ModifiedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedOnBehalfBy)));
            Caption = 'ModifiedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(12; OrganizationId; Guid)
        {
            Caption = 'Organization Id';
            Description = 'Unique identifier for the organization';
            ExternalAccess = Read;
            ExternalName = 'organizationid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Organization".OrganizationId;
        }
        field(13; OrganizationIdName; Text[160])
        {
            CalcFormula = lookup("CRM Organization".Name where(OrganizationId = field(OrganizationId)));
            Caption = 'OrganizationIdName';
            ExternalAccess = Read;
            ExternalName = 'organizationidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(14; statecode; Option)
        {
            Caption = 'Status';
            Description = 'Status of the Account Statistics';
            ExternalAccess = Modify;
            ExternalName = 'statecode';
            ExternalType = 'State';
            InitValue = " ";
            OptionCaption = ' ,Active,Inactive';
            OptionOrdinalValues = -1, 0, 1;
            OptionMembers = " ",Active,Inactive;
        }
        field(15; statuscode; Option)
        {
            Caption = 'Status Reason';
            Description = 'Reason for the status of the Account Statistics';
            ExternalName = 'statuscode';
            ExternalType = 'Status';
            InitValue = " ";
            OptionCaption = ' ,Active,Inactive';
            OptionOrdinalValues = -1, 1, 2;
            OptionMembers = " ",Active,Inactive;
        }
        field(16; VersionNumber; BigInteger)
        {
            Caption = 'VersionNumber';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(17; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            Description = 'Sequence number of the import that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
        }
        field(18; OverriddenCreatedOn; Date)
        {
            Caption = 'Record Created On';
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
        }
        field(19; TimeZoneRuleVersionNumber; Integer)
        {
            Caption = 'Time Zone Rule Version Number';
            Description = 'For internal use only.';
            ExternalName = 'timezoneruleversionnumber';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(20; UTCConversionTimeZoneCode; Integer)
        {
            Caption = 'UTC Conversion Time Zone Code';
            Description = 'Time zone code that was in use when the record was created.';
            ExternalName = 'utcconversiontimezonecode';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(21; Name; Text[160])
        {
            Caption = 'Account Name';
            ExternalName = 'nav_name';
            ExternalType = 'String';
        }
        field(22; "Customer No"; Text[20])
        {
            Caption = 'Customer No.';
            Description = 'Dynamics NAV Customer Number';
            ExternalName = 'nav_customerno';
            ExternalType = 'String';
        }
        field(23; "Balance (LCY)"; Decimal)
        {
            Caption = 'Balance (LCY)';
            Description = 'Account Balance at the last known date';
            ExternalName = 'nav_balancelcy';
            ExternalType = 'Money';
        }
        field(24; TransactionCurrencyId; Guid)
        {
            Caption = 'Currency';
            Description = 'Unique identifier of the currency associated with the entity.';
            ExternalName = 'transactioncurrencyid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Transactioncurrency".TransactionCurrencyId;
        }
        field(25; TransactionCurrencyIdName; Text[100])
        {
            CalcFormula = lookup("CRM Transactioncurrency".CurrencyName where(TransactionCurrencyId = field(TransactionCurrencyId)));
            Caption = 'TransactionCurrencyIdName';
            ExternalAccess = Read;
            ExternalName = 'transactioncurrencyidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(26; ExchangeRate; Decimal)
        {
            Caption = 'Exchange Rate';
            Description = 'Exchange rate for the currency associated with the entity with respect to the base currency.';
            ExternalAccess = Read;
            ExternalName = 'exchangerate';
            ExternalType = 'Decimal';
        }
        field(27; "Balance (Base)"; Decimal)
        {
            Caption = 'Balance (LCY) (Base)';
            Description = 'Value of the Balance (LCY) in base currency.';
            ExternalAccess = Read;
            ExternalName = 'nav_balancelcy_base';
            ExternalType = 'Money';
        }
        field(28; "Outstanding Orders (LCY)"; Decimal)
        {
            Caption = 'Outstanding Orders (LCY)';
            Description = '';
            ExternalName = 'nav_outstandingorderslcy';
            ExternalType = 'Money';
        }
        field(29; "Outstanding Orders (Base)"; Decimal)
        {
            Caption = 'Outstanding Orders (LCY) (Base)';
            Description = 'Value of the Outstanding Orders (LCY) in base currency.';
            ExternalAccess = Read;
            ExternalName = 'nav_outstandingorderslcy_base';
            ExternalType = 'Money';
        }
        field(30; "Shipped Not Invoiced (LCY)"; Decimal)
        {
            Caption = 'Shipped Not Invd. (LCY)';
            Description = '';
            ExternalName = 'nav_shippednotinvoicedlcy';
            ExternalType = 'Money';
        }
        field(31; "Shipped Not Invoiced (Base)"; Decimal)
        {
            Caption = 'Shipped Not Invd. (LCY) (Base)';
            Description = 'Value of the Shipped Not Invd. (LCY) in base currency.';
            ExternalAccess = Read;
            ExternalName = 'nav_shippednotinvoicedlcy_base';
            ExternalType = 'Money';
        }
        field(32; "Outstanding Invoices (LCY)"; Decimal)
        {
            Caption = 'Outstanding Invoices (LCY)';
            Description = '';
            ExternalName = 'nav_outstandinginvoiceslcy';
            ExternalType = 'Money';
        }
        field(33; "Outstanding Invoices (Base)"; Decimal)
        {
            Caption = 'Outstanding Invoices (LCY) (Base)';
            Description = 'Value of the Outstanding Invoices (LCY) in base currency.';
            ExternalAccess = Read;
            ExternalName = 'nav_outstandinginvoiceslcy_base';
            ExternalType = 'Money';
        }
        field(34; "Outstanding Serv Orders (LCY)"; Decimal)
        {
            Caption = 'Outstanding Serv. Orders (LCY)';
            Description = '';
            ExternalName = 'nav_outstandingserviceorderslcy';
            ExternalType = 'Money';
        }
        field(35; "Outstanding Serv Orders (Base)"; Decimal)
        {
            Caption = 'Outstanding Serv. Orders (LCY) (Base)';
            Description = 'Value of the Outstanding Serv. Orders (LCY) in base currency.';
            ExternalAccess = Read;
            ExternalName = 'nav_outstandingserviceorderslcy_base';
            ExternalType = 'Money';
        }
        field(36; "Serv Shipped Not Invd (LCY)"; Decimal)
        {
            Caption = 'Serv. Shipped Not Invd. (LCY)';
            Description = '';
            ExternalName = 'nav_servshippednotinvoicedlcy';
            ExternalType = 'Money';
        }
        field(37; "Serv Shipped Not Invd (Base)"; Decimal)
        {
            Caption = 'Serv. Shipped Not Invd. (LCY) (Base)';
            Description = 'Value of the Serv. Shipped Not Invd. (LCY) in base currency.';
            ExternalAccess = Read;
            ExternalName = 'nav_servshippednotinvoicedlcy_base';
            ExternalType = 'Money';
        }
        field(38; "Outstd Serv Invoices (LCY)"; Decimal)
        {
            Caption = 'Outstanding Serv. Invoices (LCY)';
            Description = '';
            ExternalName = 'nav_outstandingservinvoiceslcy';
            ExternalType = 'Money';
        }
        field(39; "Outstd Serv Invoices (Base)"; Decimal)
        {
            Caption = 'Outstanding Serv. Invoices (LCY) (Base)';
            Description = 'Value of the Outstanding Serv. Invoices (LCY) in base currency.';
            ExternalAccess = Read;
            ExternalName = 'nav_outstandingservinvoiceslcy_base';
            ExternalType = 'Money';
        }
        field(40; "Total (LCY)"; Decimal)
        {
            Caption = 'Total (LCY)';
            Description = '';
            ExternalName = 'nav_totallcy';
            ExternalType = 'Money';
        }
        field(41; "Total (Base)"; Decimal)
        {
            Caption = 'Total (LCY) (Base)';
            Description = 'Value of the Total (LCY) in base currency.';
            ExternalAccess = Read;
            ExternalName = 'nav_totallcy_base';
            ExternalType = 'Money';
        }
        field(42; "Credit Limit (LCY)"; Decimal)
        {
            Caption = 'Credit Limit (LCY)';
            Description = '';
            ExternalName = 'nav_creditlimitlcy';
            ExternalType = 'Money';
        }
        field(43; "Credit Limit (Base)"; Decimal)
        {
            Caption = 'Credit Limit (LCY) (Base)';
            Description = 'Value of the Credit Limit (LCY) in base currency.';
            ExternalAccess = Read;
            ExternalName = 'nav_creditlimitlcy_base';
            ExternalType = 'Money';
        }
        field(44; "Overdue Amounts (LCY)"; Decimal)
        {
            Caption = 'Overdue Amounts (LCY)';
            Description = '';
            ExternalName = 'nav_overdueamountslcy';
            ExternalType = 'Money';
        }
        field(45; "Overdue Amounts (Base)"; Decimal)
        {
            Caption = 'Overdue Amounts (LCY) (Base)';
            Description = 'Value of the Overdue Amounts (LCY) in base currency.';
            ExternalAccess = Read;
            ExternalName = 'nav_overdueamountslcy_base';
            ExternalType = 'Money';
        }
        field(46; "Overdue Amounts As Of Date"; Date)
        {
            Caption = 'Overdue Amounts as of';
            Description = 'The date as of which the Overdue Amounts (LCY) are measured.';
            ExternalName = 'nav_overdueamountsasof';
            ExternalType = 'DateTime';
        }
        field(47; "Total Sales (LCY)"; Decimal)
        {
            Caption = 'Total Sales (LCY)';
            Description = '';
            ExternalName = 'nav_totalsaleslcy';
            ExternalType = 'Money';
        }
        field(48; "Total Sales (Base)"; Decimal)
        {
            Caption = 'Total Sales (LCY) (Base)';
            Description = 'Value of the Total Sales (LCY) in base currency.';
            ExternalAccess = Read;
            ExternalName = 'nav_totalsaleslcy_base';
            ExternalType = 'Money';
        }
        field(49; "Invd Prepayment Amount (LCY)"; Decimal)
        {
            Caption = 'Invoiced Prepayment Amount (LCY)';
            Description = '';
            ExternalName = 'nav_invoicedprepaymentamountlcy';
            ExternalType = 'Money';
        }
        field(50; "Invd Prepayment Amount (Base)"; Decimal)
        {
            Caption = 'Invoiced Prepayment Amount (LCY) (Base)';
            Description = 'Value of the Invoiced Prepayment Amount (LCY) in base currency.';
            ExternalAccess = Read;
            ExternalName = 'nav_invoicedprepaymentamountlcy_base';
            ExternalType = 'Money';
        }
    }

    keys
    {
        key(Key1; AccountStatisticsId)
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

