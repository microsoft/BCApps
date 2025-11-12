// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5343 "CRM Opportunity"
{
    // Dynamics CRM Version: 7.1.0.2040

    Caption = 'CRM Opportunity';
    Description = 'Potential revenue-generating event, or sale to an account, which needs to be tracked through a sales process to completion.';
    ExternalName = 'opportunity';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; OpportunityId; Guid)
        {
            Caption = 'Opportunity';
            Description = 'Unique identifier of the opportunity.';
            ExternalAccess = Insert;
            ExternalName = 'opportunityid';
            ExternalType = 'Uniqueidentifier';
        }
        field(2; PriceLevelId; Guid)
        {
            Caption = 'Price List';
            Description = 'Choose the price list associated with this record to make sure the products associated with the campaign are offered at the correct prices.';
            ExternalName = 'pricelevelid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Pricelevel".PriceLevelId;
        }
        field(3; OpportunityRatingCode; Option)
        {
            Caption = 'Rating';
            Description = 'Select the expected value or priority of the opportunity based on revenue, customer status, or closing probability.';
            ExternalName = 'opportunityratingcode';
            ExternalType = 'Picklist';
            InitValue = Warm;
            OptionCaption = 'Hot,Warm,Cold';
            OptionOrdinalValues = 1, 2, 3;
            OptionMembers = Hot,Warm,Cold;
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
        field(5; ContactId; Guid)
        {
            Caption = 'ContactId';
            Description = 'Unique identifier of the contact associated with the opportunity.';
            ExternalAccess = Read;
            ExternalName = 'contactid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Contact".ContactId;
        }
        field(6; AccountId; Guid)
        {
            Caption = 'AccountId';
            Description = 'Unique identifier of the account with which the opportunity is associated.';
            ExternalAccess = Read;
            ExternalName = 'accountid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Account".AccountId;
        }
        field(7; Name; Text[2048])
        {
            Caption = 'Topic';
            Description = 'Type a subject or descriptive name, such as the expected order or company name, for the opportunity.';
            ExternalName = 'name';
            ExternalType = 'String';
        }
        field(8; StepId; Guid)
        {
            Caption = 'Step';
            Description = 'Shows the ID of the workflow step.';
            ExternalName = 'stepid';
            ExternalType = 'Uniqueidentifier';
        }
        field(9; Description; BLOB)
        {
            Caption = 'Description';
            Description = 'Type additional information to describe the opportunity, such as possible products to sell or past purchases from the customer.';
            ExternalName = 'description';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(10; EstimatedValue; Decimal)
        {
            Caption = 'Est. Revenue';
            Description = 'Type the estimated revenue amount to indicate the potential sale or value of the opportunity for revenue forecasting. This field can be either system-populated or editable based on the selection in the Revenue field.';
            ExternalName = 'estimatedvalue';
            ExternalType = 'Money';
        }
        field(11; StepName; Text[200])
        {
            Caption = 'Pipeline Phase';
            Description = 'Shows the current phase in the sales pipeline for the opportunity. This is updated by a workflow.';
            ExternalName = 'stepname';
            ExternalType = 'String';
        }
        field(12; SalesStageCode; Option)
        {
            Caption = 'Process Code';
            Description = 'Select the sales process stage for the opportunity to indicate the probability of closing the opportunity.';
            ExternalName = 'salesstagecode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(13; ParticipatesInWorkflow; Boolean)
        {
            Caption = 'Participates in Workflow';
            Description = 'Information about whether the opportunity participates in workflow rules.';
            ExternalName = 'participatesinworkflow';
            ExternalType = 'Boolean';
        }
        field(14; PricingErrorCode; Option)
        {
            Caption = 'Pricing Error ';
            Description = 'Pricing error for the opportunity.';
            ExternalName = 'pricingerrorcode';
            ExternalType = 'Picklist';
            InitValue = "None";
            OptionCaption = 'None,Detail Error,Missing Price Level,Inactive Price Level,Missing Quantity,Missing Unit Price,Missing Product,Invalid Product,Missing Pricing Code,Invalid Pricing Code,Missing UOM,Product Not In Price Level,Missing Price Level Amount,Missing Price Level Percentage,Missing Price,Missing Current Cost,Missing Standard Cost,Invalid Price Level Amount,Invalid Price Level Percentage,Invalid Price,Invalid Current Cost,Invalid Standard Cost,Invalid Rounding Policy,Invalid Rounding Option,Invalid Rounding Amount,Price Calculation Error,Invalid Discount Type,Discount Type Invalid State,Invalid Discount,Invalid Quantity,Invalid Pricing Precision,Missing Product Default UOM,Missing Product UOM Schedule ,Inactive Discount Type,Invalid Price Level Currency,Price Attribute Out Of Range,Base Currency Attribute Overflow,Base Currency Attribute Underflow';
            OptionOrdinalValues = 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37;
            OptionMembers = "None",DetailError,MissingPriceLevel,InactivePriceLevel,MissingQuantity,MissingUnitPrice,MissingProduct,InvalidProduct,MissingPricingCode,InvalidPricingCode,MissingUOM,ProductNotInPriceLevel,MissingPriceLevelAmount,MissingPriceLevelPercentage,MissingPrice,MissingCurrentCost,MissingStandardCost,InvalidPriceLevelAmount,InvalidPriceLevelPercentage,InvalidPrice,InvalidCurrentCost,InvalidStandardCost,InvalidRoundingPolicy,InvalidRoundingOption,InvalidRoundingAmount,PriceCalculationError,InvalidDiscountType,DiscountTypeInvalidState,InvalidDiscount,InvalidQuantity,InvalidPricingPrecision,MissingProductDefaultUOM,MissingProductUOMSchedule,InactiveDiscountType,InvalidPriceLevelCurrency,PriceAttributeOutOfRange,BaseCurrencyAttributeOverflow,BaseCurrencyAttributeUnderflow;
        }
        field(15; EstimatedCloseDate; Date)
        {
            Caption = 'Est. Close Date';
            Description = 'Enter the expected closing date of the opportunity to help make accurate revenue forecasts.';
            ExternalName = 'estimatedclosedate';
            ExternalType = 'DateTime';
        }
        field(16; CloseProbability; Integer)
        {
            Caption = 'Probability';
            Description = 'Type a number from 0 to 100 that represents the likelihood of closing the opportunity. This can aid the sales team in their efforts to convert the opportunity in a sale.';
            ExternalName = 'closeprobability';
            ExternalType = 'Integer';
            MaxValue = 100;
            MinValue = 0;
        }
        field(17; ActualValue; Decimal)
        {
            Caption = 'Actual Revenue';
            Description = 'Type the actual revenue amount for the opportunity for reporting and analysis of estimated versus actual sales. Field defaults to the Est. Revenue value when an opportunity is won.';
            ExternalName = 'actualvalue';
            ExternalType = 'Money';
        }
        field(18; ActualCloseDate; Date)
        {
            Caption = 'Actual Close Date';
            Description = 'Shows the date and time when the opportunity was closed or canceled.';
            ExternalName = 'actualclosedate';
            ExternalType = 'DateTime';
        }
        field(19; OwningUser; Guid)
        {
            Caption = 'Owning User';
            Description = 'Unique identifier of the user who owns the opportunity.';
            ExternalAccess = Read;
            ExternalName = 'owninguser';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(20; OwningBusinessUnit; Guid)
        {
            Caption = 'Owning Business Unit';
            Description = 'Unique identifier of the business unit that owns the opportunity.';
            ExternalAccess = Read;
            ExternalName = 'owningbusinessunit';
            ExternalType = 'Lookup';
            TableRelation = "CRM Businessunit".BusinessUnitId;
        }
        field(21; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            Description = 'Shows the date and time when the record was created. The date and time are displayed in the time zone selected in Microsoft Dynamics CRM options.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(22; CreatedBy; Guid)
        {
            Caption = 'Created By';
            Description = 'Shows who created the record.';
            ExternalAccess = Read;
            ExternalName = 'createdby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(23; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            Description = 'Shows the date and time when the record was last updated. The date and time are displayed in the time zone selected in Microsoft Dynamics CRM options.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
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
        field(25; VersionNumber; BigInteger)
        {
            Caption = 'Version Number';
            Description = 'Version number of the opportunity.';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(26; StateCode; Option)
        {
            Caption = 'Status';
            Description = 'Shows whether the opportunity is open, won, or lost. Won and lost opportunities are read-only and can''t be edited until they are reactivated.';
            ExternalAccess = Modify;
            ExternalName = 'statecode';
            ExternalType = 'State';
            InitValue = Open;
            OptionCaption = 'Open,Won,Lost';
            OptionOrdinalValues = 0, 1, 2;
            OptionMembers = Open,Won,Lost;
        }
        field(27; StatusCode; Option)
        {
            Caption = 'Status Reason';
            Description = 'Select the opportunity''s status.';
            ExternalName = 'statuscode';
            ExternalType = 'Status';
            InitValue = " ";
            OptionCaption = ' ,In Progress,On Hold,Won,Canceled,Out-Sold';
            OptionOrdinalValues = -1, 1, 2, 3, 4, 5;
            OptionMembers = " ",InProgress,OnHold,Won,Canceled,"Out-Sold";
        }
        field(28; IsRevenueSystemCalculated; Boolean)
        {
            Caption = 'Revenue';
            Description = 'Select whether the estimated revenue for the opportunity is calculated automatically based on the products entered or entered manually by a user.';
            ExternalName = 'isrevenuesystemcalculated';
            ExternalType = 'Boolean';
        }
        field(29; ContactIdName; Text[160])
        {
            CalcFormula = lookup("CRM Contact".FullName where(ContactId = field(ContactId)));
            Caption = 'ContactIdName';
            ExternalAccess = Read;
            ExternalName = 'contactidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(30; AccountIdName; Text[160])
        {
            CalcFormula = lookup("CRM Account".Name where(AccountId = field(AccountId)));
            Caption = 'AccountIdName';
            ExternalAccess = Read;
            ExternalName = 'accountidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(31; PriceLevelIdName; Text[100])
        {
            CalcFormula = lookup("CRM Pricelevel".Name where(PriceLevelId = field(PriceLevelId)));
            Caption = 'PriceLevelIdName';
            ExternalAccess = Read;
            ExternalName = 'pricelevelidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(32; CreatedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedBy)));
            Caption = 'CreatedByName';
            ExternalAccess = Read;
            ExternalName = 'createdbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(33; ModifiedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedBy)));
            Caption = 'ModifiedByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(34; CustomerId; Guid)
        {
            Caption = 'Potential Customer';
            Description = 'Select the customer account or contact to provide a quick link to additional customer details, such as address, phone number, activities, and orders.';
            ExternalName = 'customerid';
            ExternalType = 'Customer';
            TableRelation = if (CustomerIdType = const(account)) "CRM Account".AccountId
            else
            if (CustomerIdType = const(contact)) "CRM Contact".ContactId;
        }
        field(35; CustomerIdType; Option)
        {
            Caption = 'Potential Customer Type';
            ExternalName = 'customeridtype';
            ExternalType = 'EntityName';
            OptionCaption = ' ,account,contact';
            OptionMembers = " ",account,contact;
        }
        field(36; OwnerId; Guid)
        {
            Caption = 'Owner';
            Description = 'Enter the user or team who is assigned to manage the record. This field is updated every time the record is assigned to a different user.';
            ExternalName = 'ownerid';
            ExternalType = 'Owner';
            TableRelation = if (OwnerIdType = const(systemuser)) "CRM Systemuser".SystemUserId
            else
            if (OwnerIdType = const(team)) "CRM Team".TeamId;
        }
        field(37; OwnerIdType; Option)
        {
            Caption = 'OwnerIdType';
            ExternalName = 'owneridtype';
            ExternalType = 'EntityName';
            OptionCaption = ' ,systemuser,team';
            OptionMembers = " ",systemuser,team;
        }
        field(38; TransactionCurrencyId; Guid)
        {
            Caption = 'Currency';
            Description = 'Choose the local currency for the record to make sure budgets are reported in the correct currency.';
            ExternalName = 'transactioncurrencyid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Transactioncurrency".TransactionCurrencyId;
        }
        field(39; ExchangeRate; Decimal)
        {
            Caption = 'Exchange Rate';
            Description = 'Shows the conversion rate of the record''s currency. The exchange rate is used to convert all money fields in the record from the local currency to the system''s default currency.';
            ExternalAccess = Read;
            ExternalName = 'exchangerate';
            ExternalType = 'Decimal';
        }
        field(40; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            Description = 'Unique identifier of the data import or data migration that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
        }
        field(41; UTCConversionTimeZoneCode; Integer)
        {
            Caption = 'UTC Conversion Time Zone Code';
            Description = 'Time zone code that was in use when the record was created.';
            ExternalName = 'utcconversiontimezonecode';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(42; TimeZoneRuleVersionNumber; Integer)
        {
            Caption = 'Time Zone Rule Version Number';
            Description = 'For internal use only.';
            ExternalName = 'timezoneruleversionnumber';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(43; OverriddenCreatedOn; Date)
        {
            Caption = 'Record Created On';
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
        }
        field(44; TransactionCurrencyIdName; Text[100])
        {
            CalcFormula = lookup("CRM Transactioncurrency".CurrencyName where(TransactionCurrencyId = field(TransactionCurrencyId)));
            Caption = 'TransactionCurrencyIdName';
            ExternalAccess = Read;
            ExternalName = 'transactioncurrencyidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(45; ActualValue_Base; Decimal)
        {
            Caption = 'Actual Revenue (Base)';
            Description = 'Shows the Actual Revenue field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'actualvalue_base';
            ExternalType = 'Money';
        }
        field(46; EstimatedValue_Base; Decimal)
        {
            Caption = 'Est. Revenue (Base)';
            Description = 'Shows the Actual Revenue field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'estimatedvalue_base';
            ExternalType = 'Money';
        }
        field(47; TotalTax; Decimal)
        {
            Caption = 'Total Tax';
            Description = 'Shows the total of the Tax amounts specified on all products included in the opportunity, included in the Total Amount field calculation for the opportunity.';
            ExternalAccess = Modify;
            ExternalName = 'totaltax';
            ExternalType = 'Money';
        }
        field(48; DiscountPercentage; Decimal)
        {
            Caption = 'Opportunity Discount (%)';
            Description = 'Type the discount rate that should be applied to the Product Totals field to include additional savings for the customer in the opportunity.';
            ExternalName = 'discountpercentage';
            ExternalType = 'Decimal';
        }
        field(49; TotalAmount; Decimal)
        {
            Caption = 'Total Amount';
            Description = 'Shows the total amount due, calculated as the sum of the products, discounts, freight, and taxes for the opportunity.';
            ExternalAccess = Modify;
            ExternalName = 'totalamount';
            ExternalType = 'Money';
        }
        field(50; DiscountAmount; Decimal)
        {
            Caption = 'Opportunity Discount Amount';
            Description = 'Type the discount amount for the opportunity if the customer is eligible for special savings.';
            ExternalName = 'discountamount';
            ExternalType = 'Money';
        }
        field(51; TotalAmountLessFreight; Decimal)
        {
            Caption = 'Total Pre-Freight Amount';
            Description = 'Shows the total product amount for the opportunity, minus any discounts. This value is added to freight and tax amounts in the calculation for the total amount of the opportunity.';
            ExternalAccess = Modify;
            ExternalName = 'totalamountlessfreight';
            ExternalType = 'Money';
        }
        field(52; FreightAmount; Decimal)
        {
            Caption = 'Freight Amount';
            Description = 'Type the cost of freight or shipping for the products included in the opportunity for use in calculating the Total Amount field.';
            ExternalName = 'freightamount';
            ExternalType = 'Money';
        }
        field(53; TotalLineItemDiscountAmount; Decimal)
        {
            Caption = 'Total Line Item Discount Amount';
            Description = 'Shows the total of the Manual Discount amounts specified on all products included in the opportunity. This value is reflected in the Total Detail Amount field on the opportunity and is added to any discount amount or rate specified on the opportunity.';
            ExternalAccess = Modify;
            ExternalName = 'totallineitemdiscountamount';
            ExternalType = 'Money';
        }
        field(54; TotalLineItemAmount; Decimal)
        {
            Caption = 'Total Detail Amount';
            Description = 'Shows the sum of all existing and write-in products included on the opportunity, based on the specified price list and quantities.';
            ExternalAccess = Modify;
            ExternalName = 'totallineitemamount';
            ExternalType = 'Money';
        }
        field(55; TotalDiscountAmount; Decimal)
        {
            Caption = 'Total Discount Amount';
            Description = 'Shows the total discount amount, based on the discount price and rate entered on the opportunity.';
            ExternalAccess = Modify;
            ExternalName = 'totaldiscountamount';
            ExternalType = 'Money';
        }
        field(56; TotalLineItemAmount_Base; Decimal)
        {
            Caption = 'Total Detail Amount (Base)';
            Description = 'Shows the Total Detail Amount field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'totallineitemamount_base';
            ExternalType = 'Money';
        }
        field(57; TotalDiscountAmount_Base; Decimal)
        {
            Caption = 'Total Discount Amount (Base)';
            Description = 'Shows the Total Discount Amount field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'totaldiscountamount_base';
            ExternalType = 'Money';
        }
        field(58; TotalTax_Base; Decimal)
        {
            Caption = 'Total Tax (Base)';
            Description = 'Shows the Total Tax field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'totaltax_base';
            ExternalType = 'Money';
        }
        field(59; DiscountAmount_Base; Decimal)
        {
            Caption = 'Opportunity Discount Amount (Base)';
            Description = 'Shows the Opportunity Discount Amount field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'discountamount_base';
            ExternalType = 'Money';
        }
        field(60; TotalLineItemDiscountAmount_Ba; Decimal)
        {
            Caption = 'Total Line Item Discount Amount (Base)';
            Description = 'Shows the Total Line Item Discount Amount field to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'totallineitemdiscountamount_base';
            ExternalType = 'Money';
        }
        field(61; TotalAmount_Base; Decimal)
        {
            Caption = 'Total Amount (Base)';
            Description = 'Shows the Total Amount field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'totalamount_base';
            ExternalType = 'Money';
        }
        field(62; TotalAmountLessFreight_Base; Decimal)
        {
            Caption = 'Total Pre-Freight Amount (Base)';
            Description = 'Shows the Total Pre-Freight Amount field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'totalamountlessfreight_base';
            ExternalType = 'Money';
        }
        field(63; FreightAmount_Base; Decimal)
        {
            Caption = 'Freight Amount (Base)';
            Description = 'Shows the Freight Amount field converted to the system''s default base currency for reporting purposes. The calculation uses the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'freightamount_base';
            ExternalType = 'Money';
        }
        field(64; CreatedOnBehalfBy; Guid)
        {
            Caption = 'Created By (Delegate)';
            Description = 'Shows who created the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(65; CreatedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            Caption = 'CreatedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(66; ModifiedOnBehalfBy; Guid)
        {
            Caption = 'Modified By (Delegate)';
            Description = 'Shows who last updated the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(67; ModifiedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedOnBehalfBy)));
            Caption = 'ModifiedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(68; OwningTeam; Guid)
        {
            Caption = 'Owning Team';
            Description = 'Unique identifier of the team who owns the opportunity.';
            ExternalAccess = Read;
            ExternalName = 'owningteam';
            ExternalType = 'Lookup';
            TableRelation = "CRM Team".TeamId;
        }
        field(69; BudgetStatus; Option)
        {
            Caption = 'Budget';
            Description = 'Select the likely budget status for the lead''s company. This may help determine the lead rating or your sales approach.';
            ExternalName = 'budgetstatus';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,No Committed Budget,May Buy,Can Buy,Will Buy';
            OptionOrdinalValues = -1, 0, 1, 2, 3;
            OptionMembers = " ",NoCommittedBudget,MayBuy,CanBuy,WillBuy;
        }
        field(70; DecisionMaker; Boolean)
        {
            Caption = 'Decision Maker?';
            Description = 'Select whether your notes include information about who makes the purchase decisions at the lead''s company.';
            ExternalName = 'decisionmaker';
            ExternalType = 'Boolean';
        }
        field(71; Need; Option)
        {
            Caption = 'Need';
            Description = 'Choose how high the level of need is for the lead''s company.';
            ExternalName = 'need';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Must have,Should have,Good to have,No need';
            OptionOrdinalValues = -1, 0, 1, 2, 3;
            OptionMembers = " ",Musthave,Shouldhave,Goodtohave,Noneed;
        }
        field(72; TimeLine; Option)
        {
            Caption = 'Timeline';
            Description = 'Select when the opportunity is likely to be closed.';
            ExternalName = 'timeline';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Immediate,This Quarter,Next Quarter,This Year,Not known';
            OptionOrdinalValues = -1, 0, 1, 2, 3, 4;
            OptionMembers = " ",Immediate,ThisQuarter,NextQuarter,ThisYear,Notknown;
        }
        field(73; BudgetAmount; Decimal)
        {
            Caption = 'Budget Amount';
            Description = 'Type a value between 0 and 1,000,000,000,000 to indicate the lead''s potential available budget.';
            ExternalName = 'budgetamount';
            ExternalType = 'Money';
        }
        field(74; BudgetAmount_Base; Decimal)
        {
            Caption = 'Budget Amount (Base)';
            Description = 'Shows the budget amount converted to the system''s base currency.';
            ExternalAccess = Read;
            ExternalName = 'budgetamount_base';
            ExternalType = 'Money';
        }
        field(75; ParentAccountId; Guid)
        {
            Caption = 'Account';
            Description = 'Choose an account to connect this opportunity to, so that the relationship is visible in reports and analytics, and to provide a quick link to additional details, such as financial information and activities.';
            ExternalName = 'parentaccountid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Account".AccountId;
        }
        field(76; ParentAccountIdName; Text[160])
        {
            CalcFormula = lookup("CRM Account".Name where(AccountId = field(ParentAccountId)));
            Caption = 'ParentAccountIdName';
            ExternalAccess = Read;
            ExternalName = 'parentaccountidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(77; ParentContactId; Guid)
        {
            Caption = 'Contact';
            Description = 'Choose a contact to connect this opportunity to, so that the relationship is visible in reports and analytics.';
            ExternalName = 'parentcontactid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Contact".ContactId;
        }
        field(78; ParentContactIdName; Text[160])
        {
            CalcFormula = lookup("CRM Contact".FullName where(ContactId = field(ParentContactId)));
            Caption = 'ParentContactIdName';
            ExternalAccess = Read;
            ExternalName = 'parentcontactidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(79; EvaluateFit; Boolean)
        {
            Caption = 'Evaluate Fit';
            Description = 'Select whether the fit between the lead''s requirements and your offerings was evaluated.';
            ExternalName = 'evaluatefit';
            ExternalType = 'Boolean';
        }
        field(80; InitialCommunication; Option)
        {
            Caption = 'Initial Communication';
            Description = 'Choose whether someone from the sales team contacted this lead earlier.';
            ExternalName = 'initialcommunication';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Contacted,Not Contacted';
            OptionOrdinalValues = -1, 0, 1;
            OptionMembers = " ",Contacted,NotContacted;
        }
        field(81; ConfirmInterest; Boolean)
        {
            Caption = 'Confirm Interest';
            Description = 'Select whether the lead confirmed interest in your offerings. This helps in determining the lead quality and the probability of it turning into an opportunity.';
            ExternalName = 'confirminterest';
            ExternalType = 'Boolean';
        }
        field(82; ScheduleFollowup_Prospect; Date)
        {
            Caption = 'Scheduled Follow up (Prospect)';
            Description = 'Enter the date and time of the prospecting follow-up meeting with the lead.';
            ExternalName = 'schedulefollowup_prospect';
            ExternalType = 'DateTime';
        }
        field(83; ScheduleFollowup_Qualify; Date)
        {
            Caption = 'Scheduled Follow up (Qualify)';
            Description = 'Enter the date and time of the qualifying follow-up meeting with the lead.';
            ExternalName = 'schedulefollowup_qualify';
            ExternalType = 'DateTime';
        }
        field(84; ScheduleProposalMeeting; Date)
        {
            Caption = 'Schedule Proposal Meeting';
            Description = 'Enter the date and time of the proposal meeting for the opportunity.';
            ExternalName = 'scheduleproposalmeeting';
            ExternalType = 'DateTime';
        }
        field(85; FinalDecisionDate; Date)
        {
            Caption = 'Final Decision Date';
            Description = 'Enter the date and time when the final decision of the opportunity was made.';
            ExternalName = 'finaldecisiondate';
            ExternalType = 'DateTime';
        }
        field(86; DevelopProposal; Boolean)
        {
            Caption = 'Develop Proposal';
            Description = 'Select whether a proposal has been developed for the opportunity.';
            ExternalName = 'developproposal';
            ExternalType = 'Boolean';
        }
        field(87; CompleteInternalReview; Boolean)
        {
            Caption = 'Complete Internal Review';
            Description = 'Select whether an internal review has been completed for this opportunity.';
            ExternalName = 'completeinternalreview';
            ExternalType = 'Boolean';
        }
        field(88; CaptureProposalFeedback; Boolean)
        {
            Caption = 'Proposal Feedback Captured';
            Description = 'Choose whether the proposal feedback has been captured for the opportunity.';
            ExternalName = 'captureproposalfeedback';
            ExternalType = 'Boolean';
        }
        field(89; ResolveFeedback; Boolean)
        {
            Caption = 'Feedback Resolved';
            Description = 'Choose whether the proposal feedback has been captured and resolved for the opportunity.';
            ExternalName = 'resolvefeedback';
            ExternalType = 'Boolean';
        }
        field(90; PresentProposal; Boolean)
        {
            Caption = 'Presented Proposal';
            Description = 'Select whether a proposal for the opportunity has been presented to the account.';
            ExternalName = 'presentproposal';
            ExternalType = 'Boolean';
        }
        field(91; SendThankYouNote; Boolean)
        {
            Caption = 'Send Thank You Note';
            Description = 'Select whether a thank you note has been sent to the account for considering the proposal.';
            ExternalName = 'sendthankyounote';
            ExternalType = 'Boolean';
        }
        field(92; SalesStage; Option)
        {
            Caption = 'Sales Stage';
            Description = 'Select the sales stage of this opportunity to aid the sales team in their efforts to win this opportunity.';
            ExternalName = 'salesstage';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Qualify,Develop,Propose,Close';
            OptionOrdinalValues = -1, 0, 1, 2, 3;
            OptionMembers = " ",Qualify,Develop,Propose,Close;
        }
        field(93; TraversedPath; Text[250])
        {
            Caption = 'Traversed Path';
            Description = 'For internal use only.';
            ExternalName = 'traversedpath';
            ExternalType = 'String';
        }
        field(94; CompleteFinalProposal; Boolean)
        {
            Caption = 'Final Proposal Ready';
            Description = 'Select whether a final proposal has been completed for the opportunity.';
            ExternalName = 'completefinalproposal';
            ExternalType = 'Boolean';
        }
        field(95; FileDebrief; Boolean)
        {
            Caption = 'File Debrief';
            Description = 'Choose whether the sales team has recorded detailed notes on the proposals and the account''s responses.';
            ExternalName = 'filedebrief';
            ExternalType = 'Boolean';
        }
        field(96; PursuitDecision; Boolean)
        {
            Caption = 'Decide Go/No-Go';
            Description = 'Select whether the decision about pursuing the opportunity has been made.';
            ExternalName = 'pursuitdecision';
            ExternalType = 'Boolean';
        }
        field(97; CustomerPainPoints; BLOB)
        {
            Caption = 'Customer Pain Points';
            Description = 'Type notes about the customer''s pain points to help the sales team identify products and services that could address these pain points.';
            ExternalName = 'customerpainpoints';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(98; CustomerNeed; BLOB)
        {
            Caption = 'Customer Need';
            Description = 'Type some notes about the customer''s requirements, to help the sales team identify products and services that could meet their requirements.';
            ExternalName = 'customerneed';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(99; ProposedSolution; BLOB)
        {
            Caption = 'Proposed Solution';
            Description = 'Type notes about the proposed solution for the opportunity.';
            ExternalName = 'proposedsolution';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(100; QualificationComments; BLOB)
        {
            Caption = 'Qualification Comments';
            Description = 'Type comments about the qualification or scoring of the lead.';
            ExternalName = 'qualificationcomments';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(101; QuoteComments; BLOB)
        {
            Caption = 'Quote Comments';
            Description = 'Type comments about the quotes associated with the opportunity.';
            ExternalName = 'quotecomments';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(102; PurchaseProcess; Option)
        {
            Caption = 'Purchase Process';
            Description = 'Choose whether an individual or a committee will be involved in the purchase process for the lead.';
            ExternalName = 'purchaseprocess';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Individual,Committee,Unknown';
            OptionOrdinalValues = -1, 0, 1, 2;
            OptionMembers = " ",Individual,Committee,Unknown;
        }
        field(103; PurchaseTimeframe; Option)
        {
            Caption = 'Purchase Timeframe';
            Description = 'Choose how long the lead will likely take to make the purchase.';
            ExternalName = 'purchasetimeframe';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Immediate,This Quarter,Next Quarter,This Year,Unknown';
            OptionOrdinalValues = -1, 0, 1, 2, 3, 4;
            OptionMembers = " ",Immediate,ThisQuarter,NextQuarter,ThisYear,Unknown;
        }
        field(104; IdentifyCustomerContacts; Boolean)
        {
            Caption = 'Identify Customer Contacts';
            Description = 'Select whether the customer contacts for this opportunity have been identified.';
            ExternalName = 'identifycustomercontacts';
            ExternalType = 'Boolean';
        }
        field(105; IdentifyCompetitors; Boolean)
        {
            Caption = 'Identify Competitors';
            Description = 'Select whether information about competitors is included.';
            ExternalName = 'identifycompetitors';
            ExternalType = 'Boolean';
        }
        field(106; IdentifyPursuitTeam; Boolean)
        {
            Caption = 'Identify Sales Team';
            Description = 'Choose whether you have recorded who will pursue the opportunity.';
            ExternalName = 'identifypursuitteam';
            ExternalType = 'Boolean';
        }
        field(107; CurrentSituation; BLOB)
        {
            Caption = 'Current Situation';
            Description = 'Type notes about the company or organization associated with the opportunity.';
            ExternalName = 'currentsituation';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(108; PresentFinalProposal; Boolean)
        {
            Caption = 'Present Final Proposal';
            Description = 'Select whether the final proposal has been presented to the account.';
            ExternalName = 'presentfinalproposal';
            ExternalType = 'Boolean';
        }
        field(109; StageId; Guid)
        {
            Caption = 'Process Stage';
            Description = 'Shows the ID of the stage.';
            ExternalName = 'stageid';
            ExternalType = 'Uniqueidentifier';
        }
        field(110; ProcessId; Guid)
        {
            Caption = 'Process';
            Description = 'Shows the ID of the process.';
            ExternalName = 'processid';
            ExternalType = 'Uniqueidentifier';
        }
        field(111; CompanyId; Guid)
        {
            Caption = 'Company Id';
            Description = 'Unique identifier of the company that owns the opportunity.';
            ExternalName = 'bcbi_companyid';
            ExternalType = 'Lookup';
            TableRelation = "CDS Company".CompanyId;
        }
    }

    keys
    {
        key(Key1; OpportunityId)
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
