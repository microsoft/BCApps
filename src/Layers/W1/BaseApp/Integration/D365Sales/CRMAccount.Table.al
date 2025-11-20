// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Integration.Dataverse;

table 5341 "CRM Account"
{
    // Dynamics CRM Version: 7.1.0.2040

    Caption = 'Dataverse Account';
    Description = 'Business that represents a customer or potential customer. The company that is billed in business transactions.';
    ExternalName = 'account';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; AccountId; Guid)
        {
            Caption = 'Account';
            Description = 'Unique identifier of the account.';
            ExternalAccess = Insert;
            ExternalName = 'accountid';
            ExternalType = 'Uniqueidentifier';
        }
        field(2; AccountCategoryCode; Option)
        {
            Caption = 'Category';
            Description = 'Select a category to indicate whether the customer account is standard or preferred.';
            ExternalName = 'accountcategorycode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Preferred Customer,Standard';
            OptionOrdinalValues = -1, 1, 2;
            OptionMembers = " ",PreferredCustomer,Standard;
        }
        field(3; DefaultPriceLevelId; Guid)
        {
            Caption = 'Price List';
            Description = 'Choose the default price list associated with the account to make sure the correct product prices for this customer are applied in sales opportunities, quotes, and orders.';
            ExternalName = 'defaultpricelevelid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Pricelevel".PriceLevelId;
        }
        field(4; CustomerSizeCode; Option)
        {
            Caption = 'Customer Size';
            Description = 'Select the size category or range of the account for segmentation and reporting purposes.';
            ExternalName = 'customersizecode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(5; PreferredContactMethodCode; Option)
        {
            Caption = 'Preferred Method of Contact';
            Description = 'Select the preferred method of contact.';
            ExternalName = 'preferredcontactmethodcode';
            ExternalType = 'Picklist';
            InitValue = Any;
            OptionCaption = 'Any,Email,Phone,Fax,Mail';
            OptionOrdinalValues = 1, 2, 3, 4, 5;
            OptionMembers = Any,Email,Phone,Fax,Mail;
        }
        field(6; CustomerTypeCode; Option)
        {
            Caption = 'Relationship Type';
            Description = 'Select the category that best describes the relationship between the account and your organization.';
            ExternalName = 'customertypecode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Competitor,Consultant,Customer,Investor,Partner,Influencer,Press,Prospect,Reseller,Supplier,Vendor,Other';
            OptionOrdinalValues = -1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12;
            OptionMembers = " ",Competitor,Consultant,Customer,Investor,Partner,Influencer,Press,Prospect,Reseller,Supplier,Vendor,Other;
        }
        field(7; AccountRatingCode; Option)
        {
            Caption = 'Account Rating';
            Description = 'Select a rating to indicate the value of the customer account.';
            ExternalName = 'accountratingcode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(8; IndustryCode; Option)
        {
            Caption = 'Industry';
            Description = 'Select the account''s primary industry for use in marketing segmentation and demographic analysis.';
            ExternalName = 'industrycode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Accounting,Agriculture and Non-petrol Natural Resource Extraction,Broadcasting Printing and Publishing,Brokers,Building Supply Retail,Business Services,Consulting,Consumer Services,Design; Direction and Creative Management,Distributors; Dispatchers and Processors,Doctor''s Offices and Clinics,Durable Manufacturing,Eating and Drinking Places,Entertainment Retail,Equipment Rental and Leasing,Financial,Food and Tobacco Processing,Inbound Capital Intensive Processing,Inbound Repair and Services,Insurance,Legal Services,Non-Durable Merchandise Retail,Outbound Consumer Service,Petrochemical Extraction and Distribution,Service Retail,SIG Affiliations,Social Services,Special Outbound Trade Contractors,Specialty Realty,Transportation,Utility Creation and Distribution,Vehicle Retail,Wholesale';
            OptionOrdinalValues = -1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33;
            OptionMembers = " ",Accounting,"AgricultureandNon-petrolNaturalResourceExtraction",BroadcastingPrintingandPublishing,Brokers,BuildingSupplyRetail,BusinessServices,Consulting,ConsumerServices,DesignDirectionandCreativeManagement,DistributorsDispatchersandProcessors,DoctorsOfficesandClinics,DurableManufacturing,EatingandDrinkingPlaces,EntertainmentRetail,EquipmentRentalandLeasing,Financial,FoodandTobaccoProcessing,InboundCapitalIntensiveProcessing,InboundRepairandServices,Insurance,LegalServices,"Non-DurableMerchandiseRetail",OutboundConsumerService,PetrochemicalExtractionandDistribution,ServiceRetail,SIGAffiliations,SocialServices,SpecialOutboundTradeContractors,SpecialtyRealty,Transportation,UtilityCreationandDistribution,VehicleRetail,Wholesale;
        }
        field(9; TerritoryCode; Option)
        {
            Caption = 'Territory Code';
            Description = 'Select a region or territory for the account for use in segmentation and analysis.';
            ExternalName = 'territorycode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(10; AccountClassificationCode; Option)
        {
            Caption = 'Classification';
            Description = 'Select a classification code to indicate the potential value of the customer account based on the projected return on investment, cooperation level, sales cycle length or other criteria.';
            ExternalName = 'accountclassificationcode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(11; BusinessTypeCode; Option)
        {
            Caption = 'Business Type';
            Description = 'Select the legal designation or other business type of the account for contracts or reporting purposes.';
            ExternalName = 'businesstypecode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(12; OwningBusinessUnit; Guid)
        {
            Caption = 'Owning Business Unit';
            Description = 'Shows the business unit that the record owner belongs to.';
            ExternalAccess = Read;
            ExternalName = 'owningbusinessunit';
            ExternalType = 'Lookup';
            TableRelation = "CRM Businessunit".BusinessUnitId;
        }
        field(13; TraversedPath; Text[250])
        {
            Caption = 'Traversed Path';
            Description = 'For internal use only.';
            ExternalName = 'traversedpath';
            ExternalType = 'String';
        }
        field(14; OwningUser; Guid)
        {
            Caption = 'Owning User';
            Description = 'Unique identifier of the user who owns the account.';
            ExternalAccess = Read;
            ExternalName = 'owninguser';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(16; ShippingMethodCode; Option)
        {
            Caption = 'Shipping Method Code';
            Description = 'Select a shipping method for deliveries sent to the account''s address to designate the preferred carrier or other delivery option.';
            ExternalName = 'shippingmethodcode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(17; PrimaryContactId; Guid)
        {
            Caption = 'Primary Contact';
            Description = 'Choose the primary contact for the account to provide quick access to contact details.';
            ExternalName = 'primarycontactid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Contact".ContactId;
        }
        field(18; ParticipatesInWorkflow; Boolean)
        {
            Caption = 'Participates in Workflow';
            Description = 'For system use only. Legacy Microsoft Dynamics CRM 3.0 workflow data.';
            ExternalName = 'participatesinworkflow';
            ExternalType = 'Boolean';
        }
        field(19; Name; Text[160])
        {
            Caption = 'Account Name';
            Description = 'Type the company or business name.';
            ExternalName = 'name';
            ExternalType = 'String';
        }
        field(20; AccountNumber; Text[20])
        {
            Caption = 'Account Number';
            Description = 'Type an ID number or code for the account to quickly search and identify the account in system views.';
            ExternalName = 'accountnumber';
            ExternalType = 'String';
        }
        field(21; Revenue; Decimal)
        {
            Caption = 'Annual Revenue';
            Description = 'Type the annual revenue for the account, used as an indicator in financial performance analysis.';
            ExternalName = 'revenue';
            ExternalType = 'Money';
        }
        field(22; NumberOfEmployees; Integer)
        {
            Caption = 'No. of Employees';
            Description = 'Type the number of employees that work at the account for use in marketing segmentation and demographic analysis.';
            ExternalName = 'numberofemployees';
            ExternalType = 'Integer';
            MaxValue = 1000000000;
            MinValue = 0;
        }
        field(23; Description; BLOB)
        {
            Caption = 'Description';
            Description = 'Type additional information to describe the account, such as an excerpt from the company''s website.';
            ExternalName = 'description';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(24; SIC; Text[20])
        {
            Caption = 'SIC Code';
            Description = 'Type the Standard Industrial Classification (SIC) code that indicates the account''s primary industry of business, for use in marketing segmentation and demographic analysis.';
            ExternalName = 'sic';
            ExternalType = 'String';
        }
        field(25; OwnershipCode; Option)
        {
            Caption = 'Ownership';
            Description = 'Select the account''s ownership structure, such as public or private.';
            ExternalName = 'ownershipcode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Public,Private,Subsidiary,Other';
            OptionOrdinalValues = -1, 1, 2, 3, 4;
            OptionMembers = " ",Public,Private,Subsidiary,Other;
        }
        field(26; MarketCap; Decimal)
        {
            Caption = 'Market Capitalization';
            Description = 'Type the market capitalization of the account to identify the company''s equity, used as an indicator in financial performance analysis.';
            ExternalName = 'marketcap';
            ExternalType = 'Money';
        }
        field(27; SharesOutstanding; Integer)
        {
            Caption = 'Shares Outstanding';
            Description = 'Type the number of shares available to the public for the account. This number is used as an indicator in financial performance analysis.';
            ExternalName = 'sharesoutstanding';
            ExternalType = 'Integer';
            MaxValue = 1000000000;
            MinValue = 0;
        }
        field(28; TickerSymbol; Text[10])
        {
            Caption = 'Ticker Symbol';
            Description = 'Type the stock exchange symbol for the account to track financial performance of the company. You can click the code entered in this field to access the latest trading information from MSN Money.';
            ExternalName = 'tickersymbol';
            ExternalType = 'String';
        }
        field(29; StockExchange; Text[20])
        {
            Caption = 'Stock Exchange';
            Description = 'Type the stock exchange at which the account is listed to track their stock and financial performance of the company.';
            ExternalName = 'stockexchange';
            ExternalType = 'String';
        }
        field(30; WebSiteURL; Text[200])
        {
            Caption = 'Website';
            Description = 'Type the account''s website URL to get quick details about the company profile.';
            ExtendedDatatype = URL;
            ExternalName = 'websiteurl';
            ExternalType = 'String';
        }
        field(31; FtpSiteURL; Text[200])
        {
            Caption = 'FTP Site';
            Description = 'Type the URL for the account''s FTP site to enable users to access data and share documents.';
            ExtendedDatatype = URL;
            ExternalName = 'ftpsiteurl';
            ExternalType = 'String';
        }
        field(32; EMailAddress1; Text[100])
        {
            Caption = 'Email';
            Description = 'Type the primary email address for the account.';
            ExtendedDatatype = EMail;
            ExternalName = 'emailaddress1';
            ExternalType = 'String';
        }
        field(33; EMailAddress2; Text[100])
        {
            Caption = 'Email Address 2';
            Description = 'Type the secondary email address for the account.';
            ExtendedDatatype = EMail;
            ExternalName = 'emailaddress2';
            ExternalType = 'String';
        }
        field(34; EMailAddress3; Text[100])
        {
            Caption = 'Email Address 3';
            Description = 'Type an alternate email address for the account.';
            ExtendedDatatype = EMail;
            ExternalName = 'emailaddress3';
            ExternalType = 'String';
        }
        field(35; DoNotPhone; Boolean)
        {
            Caption = 'Do not allow Phone Calls';
            Description = 'Select whether the account allows phone calls. If Do Not Allow is selected, the account will be excluded from phone call activities distributed in marketing campaigns.';
            ExternalName = 'donotphone';
            ExternalType = 'Boolean';
        }
        field(36; DoNotFax; Boolean)
        {
            Caption = 'Do not allow Faxes';
            Description = 'Select whether the account allows faxes. If Do Not Allow is selected, the account will be excluded from fax activities distributed in marketing campaigns.';
            ExternalName = 'donotfax';
            ExternalType = 'Boolean';
        }
        field(37; Telephone1; Text[50])
        {
            Caption = 'Main Phone';
            Description = 'Type the main phone number for this account.';
            ExternalName = 'telephone1';
            ExternalType = 'String';
        }
        field(38; DoNotEMail; Boolean)
        {
            Caption = 'Do not allow Emails';
            Description = 'Select whether the account allows direct email sent from Microsoft Dynamics CRM.';
            ExternalName = 'donotemail';
            ExternalType = 'Boolean';
        }
        field(39; Telephone2; Text[50])
        {
            Caption = 'Other Phone';
            Description = 'Type a second phone number for this account.';
            ExternalName = 'telephone2';
            ExternalType = 'String';
        }
        field(40; Fax; Text[50])
        {
            Caption = 'Fax';
            Description = 'Type the fax number for the account.';
            ExternalName = 'fax';
            ExternalType = 'String';
        }
        field(41; Telephone3; Text[50])
        {
            Caption = 'Telephone 3';
            Description = 'Type a third phone number for this account.';
            ExternalName = 'telephone3';
            ExternalType = 'String';
        }
        field(42; DoNotPostalMail; Boolean)
        {
            Caption = 'Do not allow Mails';
            Description = 'Select whether the account allows direct mail. If Do Not Allow is selected, the account will be excluded from letter activities distributed in marketing campaigns.';
            ExternalName = 'donotpostalmail';
            ExternalType = 'Boolean';
        }
        field(43; DoNotBulkEMail; Boolean)
        {
            Caption = 'Do not allow Bulk Emails';
            Description = 'Select whether the account allows bulk email sent through campaigns. If Do Not Allow is selected, the account can be added to marketing lists, but is excluded from email.';
            ExternalName = 'donotbulkemail';
            ExternalType = 'Boolean';
        }
        field(44; DoNotBulkPostalMail; Boolean)
        {
            Caption = 'Do not allow Bulk Mails';
            Description = 'Select whether the account allows bulk postal mail sent through marketing campaigns or quick campaigns. If Do Not Allow is selected, the account can be added to marketing lists, but will be excluded from the postal mail.';
            ExternalName = 'donotbulkpostalmail';
            ExternalType = 'Boolean';
        }
        field(45; CreditLimit; Decimal)
        {
            Caption = 'Credit Limit';
            Description = 'Type the credit limit of the account. This is a useful reference when you address invoice and accounting issues with the customer.';
            ExternalName = 'creditlimit';
            ExternalType = 'Money';
        }
        field(46; CreditOnHold; Boolean)
        {
            Caption = 'Credit Hold';
            Description = 'Select whether the credit for the account is on hold. This is a useful reference while addressing the invoice and accounting issues with the customer.';
            ExternalName = 'creditonhold';
            ExternalType = 'Boolean';
        }
        field(47; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            Description = 'Shows the date and time when the record was created. The date and time are displayed in the time zone selected in Microsoft Dynamics CRM options.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(48; CreatedBy; Guid)
        {
            Caption = 'Created By';
            Description = 'Shows who created the record.';
            ExternalAccess = Read;
            ExternalName = 'createdby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(49; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            Description = 'Shows the date and time when the record was last updated. The date and time are displayed in the time zone selected in Microsoft Dynamics CRM options.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
        }
        field(50; ModifiedBy; Guid)
        {
            Caption = 'Modified By';
            Description = 'Shows who last updated the record.';
            ExternalAccess = Read;
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(51; VersionNumber; BigInteger)
        {
            Caption = 'Version Number';
            Description = 'Version number of the account.';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(52; ParentAccountId; Guid)
        {
            Caption = 'Parent Account';
            Description = 'Choose the parent account associated with this account to show parent and child businesses in reporting and analytics.';
            ExternalName = 'parentaccountid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Account".AccountId;
        }
        field(53; Aging30; Decimal)
        {
            Caption = 'Aging 30';
            Description = 'For system use only.';
            ExternalAccess = Read;
            ExternalName = 'aging30';
            ExternalType = 'Money';
        }
        field(54; StateCode; Option)
        {
            Caption = 'Status';
            Description = 'Shows whether the account is active or inactive. Inactive accounts are read-only and can''t be edited unless they are reactivated.';
            ExternalAccess = Modify;
            ExternalName = 'statecode';
            ExternalType = 'State';
            InitValue = Active;
            OptionCaption = 'Active,Inactive';
            OptionOrdinalValues = 0, 1;
            OptionMembers = Active,Inactive;
        }
        field(55; Aging60; Decimal)
        {
            Caption = 'Aging 60';
            Description = 'For system use only.';
            ExternalAccess = Read;
            ExternalName = 'aging60';
            ExternalType = 'Money';
        }
        field(56; StatusCode; Option)
        {
            Caption = 'Status Reason';
            Description = 'Select the account''s status.';
            ExternalName = 'statuscode';
            ExternalType = 'Status';
            InitValue = " ";
            OptionCaption = ' ,Active,Inactive';
            OptionOrdinalValues = -1, 1, 2;
            OptionMembers = " ",Active,Inactive;
        }
        field(57; Aging90; Decimal)
        {
            Caption = 'Aging 90';
            Description = 'For system use only.';
            ExternalAccess = Read;
            ExternalName = 'aging90';
            ExternalType = 'Money';
        }
        field(58; PrimaryContactIdName; Text[160])
        {
            CalcFormula = lookup("CRM Contact".FullName where(ContactId = field(PrimaryContactId)));
            Caption = 'PrimaryContactIdName';
            ExternalAccess = Read;
            ExternalName = 'primarycontactidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(59; ParentAccountIdName; Text[160])
        {
            CalcFormula = lookup("CRM Account".Name where(AccountId = field(ParentAccountId)));
            Caption = 'ParentAccountIdName';
            ExternalAccess = Read;
            ExternalName = 'parentaccountidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(60; DefaultPriceLevelIdName; Text[100])
        {
            CalcFormula = lookup("CRM Pricelevel".Name where(PriceLevelId = field(DefaultPriceLevelId)));
            Caption = 'DefaultPriceLevelIdName';
            ExternalAccess = Read;
            ExternalName = 'defaultpricelevelidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(61; Address1_AddressId; Guid)
        {
            Caption = 'Address 1: ID';
            Description = 'Unique identifier for address 1.';
            ExternalName = 'address1_addressid';
            ExternalType = 'Uniqueidentifier';
        }
        field(62; Address1_AddressTypeCode; Option)
        {
            Caption = 'Address 1: Address Type';
            Description = 'Select the primary address type.';
            ExternalName = 'address1_addresstypecode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Bill To,Ship To,Primary,Other';
            OptionOrdinalValues = -1, 1, 2, 3, 4;
            OptionMembers = " ",BillTo,ShipTo,Primary,Other;
        }
        field(63; Address1_Name; Text[200])
        {
            Caption = 'Address 1: Name';
            Description = 'Type a descriptive name for the primary address, such as Corporate Headquarters.';
            ExternalName = 'address1_name';
            ExternalType = 'String';
        }
        field(64; Address1_PrimaryContactName; Text[100])
        {
            Caption = 'Address 1: Primary Contact Name';
            Description = 'Type the name of the main contact at the account''s primary address.';
            ExternalName = 'address1_primarycontactname';
            ExternalType = 'String';
        }
        field(65; Address1_Line1; Text[250])
        {
            Caption = 'Address 1: Street 1';
            Description = 'Type the first line of the primary address.';
            ExternalName = 'address1_line1';
            ExternalType = 'String';
        }
        field(66; Address1_Line2; Text[250])
        {
            Caption = 'Address 1: Street 2';
            Description = 'Type the second line of the primary address.';
            ExternalName = 'address1_line2';
            ExternalType = 'String';
        }
        field(67; Address1_Line3; Text[250])
        {
            Caption = 'Address 1: Street 3';
            Description = 'Type the third line of the primary address.';
            ExternalName = 'address1_line3';
            ExternalType = 'String';
        }
        field(68; Address1_City; Text[80])
        {
            Caption = 'Address 1: City';
            Description = 'Type the city for the primary address.';
            ExternalName = 'address1_city';
            ExternalType = 'String';
        }
        field(69; Address1_StateOrProvince; Text[50])
        {
            Caption = 'Address 1: State/Province';
            Description = 'Type the state or province of the primary address.';
            ExternalName = 'address1_stateorprovince';
            ExternalType = 'String';
        }
        field(70; Address1_County; Text[50])
        {
            Caption = 'Address 1: County';
            Description = 'Type the county for the primary address.';
            ExternalName = 'address1_county';
            ExternalType = 'String';
        }
        field(71; Address1_Country; Text[80])
        {
            Caption = 'Address 1: Country/Region';
            Description = 'Type the country or region for the primary address.';
            ExternalName = 'address1_country';
            ExternalType = 'String';
        }
        field(72; Address1_PostOfficeBox; Text[20])
        {
            Caption = 'Address 1: Post Office Box';
            Description = 'Type the post office box number of the primary address.';
            ExternalName = 'address1_postofficebox';
            ExternalType = 'String';
        }
        field(73; Address1_PostalCode; Text[20])
        {
            Caption = 'Address 1: ZIP/Postal Code';
            Description = 'Type the ZIP Code or postal code for the primary address.';
            ExternalName = 'address1_postalcode';
            ExternalType = 'String';
        }
        field(74; Address1_UTCOffset; Integer)
        {
            Caption = 'Address 1: UTC Offset';
            Description = 'Select the time zone, or UTC offset, for this address so that other people can reference it when they contact someone at this address.';
            ExternalName = 'address1_utcoffset';
            ExternalType = 'Integer';
            MaxValue = 1500;
            MinValue = -1500;
        }
        field(76; Address1_UPSZone; Text[4])
        {
            Caption = 'Address 1: UPS Zone';
            Description = 'Type the UPS zone of the primary address to make sure shipping charges are calculated correctly and deliveries are made promptly, if shipped by UPS.';
            ExternalName = 'address1_upszone';
            ExternalType = 'String';
        }
        field(77; Address1_Latitude; Decimal)
        {
            Caption = 'Address 1: Latitude';
            Description = 'Type the latitude value for the primary address for use in mapping and other applications.';
            ExternalName = 'address1_latitude';
            ExternalType = 'Double';
        }
        field(78; Address1_Telephone1; Text[50])
        {
            Caption = 'Address Phone';
            Description = 'Type the main phone number associated with the primary address.';
            ExternalName = 'address1_telephone1';
            ExternalType = 'String';
        }
        field(79; Address1_Longitude; Decimal)
        {
            Caption = 'Address 1: Longitude';
            Description = 'Type the longitude value for the primary address for use in mapping and other applications.';
            ExternalName = 'address1_longitude';
            ExternalType = 'Double';
        }
        field(81; Address1_Telephone2; Text[50])
        {
            Caption = 'Address 1: Telephone 2';
            Description = 'Type a second phone number associated with the primary address.';
            ExternalName = 'address1_telephone2';
            ExternalType = 'String';
        }
        field(82; Address1_Telephone3; Text[50])
        {
            Caption = 'Address 1: Telephone 3';
            Description = 'Type a third phone number associated with the primary address.';
            ExternalName = 'address1_telephone3';
            ExternalType = 'String';
        }
        field(83; Address1_Fax; Text[50])
        {
            Caption = 'Address 1: Fax';
            Description = 'Type the fax number associated with the primary address.';
            ExternalName = 'address1_fax';
            ExternalType = 'String';
        }
        field(84; Address2_AddressId; Guid)
        {
            Caption = 'Address 2: ID';
            Description = 'Unique identifier for address 2.';
            ExternalName = 'address2_addressid';
            ExternalType = 'Uniqueidentifier';
        }
        field(85; Address2_AddressTypeCode; Option)
        {
            Caption = 'Address 2: Address Type';
            Description = 'Select the secondary address type.';
            ExternalName = 'address2_addresstypecode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(86; Address2_Name; Text[200])
        {
            Caption = 'Address 2: Name';
            Description = 'Type a descriptive name for the secondary address, such as Corporate Headquarters.';
            ExternalName = 'address2_name';
            ExternalType = 'String';
        }
        field(87; Address2_PrimaryContactName; Text[100])
        {
            Caption = 'Address 2: Primary Contact Name';
            Description = 'Type the name of the main contact at the account''s secondary address.';
            ExternalName = 'address2_primarycontactname';
            ExternalType = 'String';
        }
        field(88; Address2_Line1; Text[250])
        {
            Caption = 'Address 2: Street 1';
            Description = 'Type the first line of the secondary address.';
            ExternalName = 'address2_line1';
            ExternalType = 'String';
        }
        field(89; Address2_Line2; Text[250])
        {
            Caption = 'Address 2: Street 2';
            Description = 'Type the second line of the secondary address.';
            ExternalName = 'address2_line2';
            ExternalType = 'String';
        }
        field(90; Address2_Line3; Text[250])
        {
            Caption = 'Address 2: Street 3';
            Description = 'Type the third line of the secondary address.';
            ExternalName = 'address2_line3';
            ExternalType = 'String';
        }
        field(91; Address2_City; Text[80])
        {
            Caption = 'Address 2: City';
            Description = 'Type the city for the secondary address.';
            ExternalName = 'address2_city';
            ExternalType = 'String';
        }
        field(92; Address2_StateOrProvince; Text[50])
        {
            Caption = 'Address 2: State/Province';
            Description = 'Type the state or province of the secondary address.';
            ExternalName = 'address2_stateorprovince';
            ExternalType = 'String';
        }
        field(93; Address2_County; Text[50])
        {
            Caption = 'Address 2: County';
            Description = 'Type the county for the secondary address.';
            ExternalName = 'address2_county';
            ExternalType = 'String';
        }
        field(94; Address2_Country; Text[80])
        {
            Caption = 'Address 2: Country/Region';
            Description = 'Type the country or region for the secondary address.';
            ExternalName = 'address2_country';
            ExternalType = 'String';
        }
        field(95; Address2_PostOfficeBox; Text[20])
        {
            Caption = 'Address 2: Post Office Box';
            Description = 'Type the post office box number of the secondary address.';
            ExternalName = 'address2_postofficebox';
            ExternalType = 'String';
        }
        field(96; Address2_PostalCode; Text[20])
        {
            Caption = 'Address 2: ZIP/Postal Code';
            Description = 'Type the ZIP Code or postal code for the secondary address.';
            ExternalName = 'address2_postalcode';
            ExternalType = 'String';
        }
        field(97; Address2_UTCOffset; Integer)
        {
            Caption = 'Address 2: UTC Offset';
            Description = 'Select the time zone, or UTC offset, for this address so that other people can reference it when they contact someone at this address.';
            ExternalName = 'address2_utcoffset';
            ExternalType = 'Integer';
            MaxValue = 1500;
            MinValue = -1500;
        }
        field(98; Address2_FreightTermsCode; Option)
        {
            Caption = 'Address 2: Freight Terms';
            Description = 'Select the freight terms for the secondary address to make sure shipping orders are processed correctly.';
            ExternalName = 'address2_freighttermscode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(99; Address2_UPSZone; Text[4])
        {
            Caption = 'Address 2: UPS Zone';
            Description = 'Type the UPS zone of the secondary address to make sure shipping charges are calculated correctly and deliveries are made promptly, if shipped by UPS.';
            ExternalName = 'address2_upszone';
            ExternalType = 'String';
        }
        field(100; Address2_Latitude; Decimal)
        {
            Caption = 'Address 2: Latitude';
            Description = 'Type the latitude value for the secondary address for use in mapping and other applications.';
            ExternalName = 'address2_latitude';
            ExternalType = 'Double';
        }
        field(101; Address2_Telephone1; Text[50])
        {
            Caption = 'Address 2: Telephone 1';
            Description = 'Type the main phone number associated with the secondary address.';
            ExternalName = 'address2_telephone1';
            ExternalType = 'String';
        }
        field(102; Address2_Longitude; Decimal)
        {
            Caption = 'Address 2: Longitude';
            Description = 'Type the longitude value for the secondary address for use in mapping and other applications.';
            ExternalName = 'address2_longitude';
            ExternalType = 'Double';
        }
        field(103; Address2_ShippingMethodCode; Option)
        {
            Caption = 'Address 2: Shipping Method';
            Description = 'Select a shipping method for deliveries sent to this address.';
            ExternalName = 'address2_shippingmethodcode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(104; Address2_Telephone2; Text[50])
        {
            Caption = 'Address 2: Telephone 2';
            Description = 'Type a second phone number associated with the secondary address.';
            ExternalName = 'address2_telephone2';
            ExternalType = 'String';
        }
        field(105; Address2_Telephone3; Text[50])
        {
            Caption = 'Address 2: Telephone 3';
            Description = 'Type a third phone number associated with the secondary address.';
            ExternalName = 'address2_telephone3';
            ExternalType = 'String';
        }
        field(106; Address2_Fax; Text[50])
        {
            Caption = 'Address 2: Fax';
            Description = 'Type the fax number associated with the secondary address.';
            ExternalName = 'address2_fax';
            ExternalType = 'String';
        }
        field(107; CreatedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedBy)));
            Caption = 'CreatedByName';
            ExternalAccess = Read;
            ExternalName = 'createdbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(108; ModifiedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedBy)));
            Caption = 'ModifiedByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(109; OwnerId; Guid)
        {
            Caption = 'Owner';
            Description = 'Enter the user or team who is assigned to manage the record. This field is updated every time the record is assigned to a different user.';
            ExternalName = 'ownerid';
            ExternalType = 'Owner';
            TableRelation = if (OwnerIdType = const(systemuser)) "CRM Systemuser".SystemUserId
            else
            if (OwnerIdType = const(team)) "CRM Team".TeamId;
        }
        field(110; OwnerIdType; Option)
        {
            Caption = 'OwnerIdType';
            ExternalName = 'owneridtype';
            ExternalType = 'EntityName';
            OptionCaption = ' ,systemuser,team';
            OptionMembers = " ",systemuser,team;
        }
        field(111; PreferredAppointmentDayCode; Option)
        {
            Caption = 'Preferred Day';
            Description = 'Select the preferred day of the week for service appointments.';
            ExternalName = 'preferredappointmentdaycode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday';
            OptionOrdinalValues = -1, 0, 1, 2, 3, 4, 5, 6;
            OptionMembers = " ",Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday;
        }
        field(112; PreferredSystemUserId; Guid)
        {
            Caption = 'Preferred User';
            Description = 'Choose the preferred service representative for reference when you schedule service activities for the account.';
            ExternalName = 'preferredsystemuserid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(113; PreferredAppointmentTimeCode; Option)
        {
            Caption = 'Preferred Time';
            Description = 'Select the preferred time of day for service appointments.';
            ExternalName = 'preferredappointmenttimecode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Morning,Afternoon,Evening';
            OptionOrdinalValues = -1, 1, 2, 3;
            OptionMembers = " ",Morning,Afternoon,Evening;
        }
        field(114; Merged; Boolean)
        {
            Caption = 'Merged';
            Description = 'Shows whether the account has been merged with another account.';
            ExternalAccess = Read;
            ExternalName = 'merged';
            ExternalType = 'Boolean';
        }
        field(115; DoNotSendMM; Boolean)
        {
            Caption = 'Send Marketing Materials';
            Description = 'Select whether the account accepts marketing materials, such as brochures or catalogs.';
            ExternalName = 'donotsendmm';
            ExternalType = 'Boolean';
        }
        field(116; MasterId; Guid)
        {
            Caption = 'Master ID';
            Description = 'Shows the master account that the account was merged with.';
            ExternalAccess = Read;
            ExternalName = 'masterid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Account".AccountId;
        }
        field(117; LastUsedInCampaign; Date)
        {
            Caption = 'Last Date Included in Campaign';
            Description = 'Shows the date when the account was last included in a marketing campaign or quick campaign.';
            ExternalAccess = Modify;
            ExternalName = 'lastusedincampaign';
            ExternalType = 'DateTime';
        }
        field(118; PreferredSystemUserIdName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(PreferredSystemUserId)));
            Caption = 'PreferredSystemUserIdName';
            ExternalAccess = Read;
            ExternalName = 'preferredsystemuseridname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(119; MasterAccountIdName; Text[160])
        {
            CalcFormula = lookup("CRM Account".Name where(AccountId = field(MasterId)));
            Caption = 'MasterAccountIdName';
            ExternalAccess = Read;
            ExternalName = 'masteraccountidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(120; ExchangeRate; Decimal)
        {
            Caption = 'Exchange Rate';
            Description = 'Shows the conversion rate of the record''s currency. The exchange rate is used to convert all money fields in the record from the local currency to the system''s default currency.';
            ExternalAccess = Read;
            ExternalName = 'exchangerate';
            ExternalType = 'Decimal';
        }
        field(121; UTCConversionTimeZoneCode; Integer)
        {
            Caption = 'UTC Conversion Time Zone Code';
            Description = 'Time zone code that was in use when the record was created.';
            ExternalName = 'utcconversiontimezonecode';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(122; OverriddenCreatedOn; Date)
        {
            Caption = 'Record Created On';
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
        }
        field(123; TimeZoneRuleVersionNumber; Integer)
        {
            Caption = 'Time Zone Rule Version Number';
            Description = 'For internal use only.';
            ExternalName = 'timezoneruleversionnumber';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(124; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            Description = 'Unique identifier of the data import or data migration that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
        }
        field(125; TransactionCurrencyId; Guid)
        {
            Caption = 'Currency';
            Description = 'Choose the local currency for the record to make sure budgets are reported in the correct currency.';
            ExternalName = 'transactioncurrencyid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Transactioncurrency".TransactionCurrencyId;
        }
        field(126; CreditLimit_Base; Decimal)
        {
            Caption = 'Credit Limit (Base)';
            Description = 'Shows the credit limit converted to the system''s default base currency for reporting purposes.';
            ExternalAccess = Read;
            ExternalName = 'creditlimit_base';
            ExternalType = 'Money';
        }
        field(127; TransactionCurrencyIdName; Text[100])
        {
            CalcFormula = lookup("CRM Transactioncurrency".CurrencyName where(TransactionCurrencyId = field(TransactionCurrencyId)));
            Caption = 'TransactionCurrencyIdName';
            ExternalAccess = Read;
            ExternalName = 'transactioncurrencyidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(128; Aging30_Base; Decimal)
        {
            Caption = 'Aging 30 (Base)';
            Description = 'The base currency equivalent of the aging 30 field.';
            ExternalAccess = Read;
            ExternalName = 'aging30_base';
            ExternalType = 'Money';
        }
        field(129; Revenue_Base; Decimal)
        {
            Caption = 'Annual Revenue (Base)';
            Description = 'Shows the annual revenue converted to the system''s default base currency. The calculations use the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'revenue_base';
            ExternalType = 'Money';
        }
        field(130; Aging90_Base; Decimal)
        {
            Caption = 'Aging 90 (Base)';
            Description = 'The base currency equivalent of the aging 90 field.';
            ExternalAccess = Read;
            ExternalName = 'aging90_base';
            ExternalType = 'Money';
        }
        field(131; MarketCap_Base; Decimal)
        {
            Caption = 'Market Capitalization (Base)';
            Description = 'Shows the market capitalization converted to the system''s default base currency.';
            ExternalAccess = Read;
            ExternalName = 'marketcap_base';
            ExternalType = 'Money';
        }
        field(132; Aging60_Base; Decimal)
        {
            Caption = 'Aging 60 (Base)';
            Description = 'The base currency equivalent of the aging 60 field.';
            ExternalAccess = Read;
            ExternalName = 'aging60_base';
            ExternalType = 'Money';
        }
        field(133; YomiName; Text[160])
        {
            Caption = 'Yomi Account Name';
            Description = 'Type the phonetic spelling of the company name, if specified in Japanese, to make sure the name is pronounced correctly in phone calls and other communications.';
            ExternalName = 'yominame';
            ExternalType = 'String';
        }
        field(134; CreatedOnBehalfBy; Guid)
        {
            Caption = 'Created By (Delegate)';
            Description = 'Shows who created the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(135; CreatedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            Caption = 'CreatedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(136; ModifiedOnBehalfBy; Guid)
        {
            Caption = 'Modified By (Delegate)';
            Description = 'Shows who created the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(137; ModifiedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedOnBehalfBy)));
            Caption = 'ModifiedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(138; OwningTeam; Guid)
        {
            Caption = 'Owning Team';
            Description = 'Unique identifier of the team who owns the account.';
            ExternalAccess = Read;
            ExternalName = 'owningteam';
            ExternalType = 'Lookup';
            TableRelation = "CRM Team".TeamId;
        }
        field(139; StageId; Guid)
        {
            Caption = 'Process Stage';
            Description = 'Shows the ID of the stage.';
            ExternalName = 'stageid';
            ExternalType = 'Uniqueidentifier';
        }
        field(140; ProcessId; Guid)
        {
            Caption = 'Process';
            Description = 'Shows the ID of the process.';
            ExternalName = 'processid';
            ExternalType = 'Uniqueidentifier';
        }
        field(141; Address2_Composite; BLOB)
        {
            Caption = 'Address 2';
            Description = 'Shows the complete secondary address.';
            ExternalAccess = Read;
            ExternalName = 'address2_composite';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(142; Address1_Composite; BLOB)
        {
            Caption = 'Address 1';
            Description = 'Shows the complete primary address.';
            ExternalAccess = Read;
            ExternalName = 'address1_composite';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(143; EntityImageId; Guid)
        {
            Caption = 'Entity Image Id';
            Description = 'For internal use only.';
            ExternalAccess = Read;
            ExternalName = 'entityimageid';
            ExternalType = 'Uniqueidentifier';
        }
        field(144; OpenDeals; Integer)
        {
            Caption = 'Open Deals';
            Description = 'Number of open opportunities against an account and its child accounts.';
            ExternalAccess = Read;
            ExternalName = 'opendeals';
            ExternalType = 'Integer';
        }
        field(145; OpenDeals_Date; DateTime)
        {
            Caption = 'Open Deals(Last Updated Time)';
            Description = 'The date time for Open Deals.';
            ExternalAccess = Read;
            ExternalName = 'opendeals_date';
            ExternalType = 'DateTime';
        }
        field(146; OpenDeals_State; Integer)
        {
            Caption = 'Open Deals(State)';
            Description = 'State of Open Deals.';
            ExternalAccess = Read;
            ExternalName = 'opendeals_state';
            ExternalType = 'Integer';
        }
        field(147; OpenRevenue; Decimal)
        {
            Caption = 'Open Revenue';
            Description = 'Sum of open revenue against an account and its child accounts.';
            ExternalAccess = Read;
            ExternalName = 'openrevenue';
            ExternalType = 'Money';
        }
        field(148; OpenRevenue_Base; Decimal)
        {
            Caption = 'Open Revenue (Base)';
            Description = 'Sum of open revenue against an account and its child accounts.';
            ExternalAccess = Read;
            ExternalName = 'openrevenue_base';
            ExternalType = 'Money';
        }
        field(149; OpenRevenue_Date; DateTime)
        {
            Caption = 'Open Revenue(Last Updated Time)';
            Description = 'The date time for Open Revenue.';
            ExternalAccess = Read;
            ExternalName = 'openrevenue_date';
            ExternalType = 'DateTime';
        }
        field(150; OpenRevenue_State; Integer)
        {
            Caption = 'Open Revenue(State)';
            Description = 'State of Open Revenue.';
            ExternalAccess = Read;
            ExternalName = 'openrevenue_state';
            ExternalType = 'Integer';
        }
        field(200; AccountStatiticsId; Guid)
        {
            Caption = 'Account Statistics';
            Description = 'The account statistics of this account';
            ExternalName = 'nav_accountstatisticsid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Account Statistics".AccountStatisticsId;
        }
        field(202; CompanyId; Guid)
        {
            Caption = 'Company Id';
            Description = 'Unique identifier of the company that owns the account.';
            ExternalName = 'bcbi_companyid';
            ExternalType = 'Lookup';
            TableRelation = "CDS Company".CompanyId;
        }
        field(203; PaymentTermsCodeEnum; Enum "CDS Payment Terms Code")
        {
            Caption = 'Payment Terms';
            Description = 'Select the payment terms to indicate when the customer needs to pay the total amount.';
            ExternalName = 'paymenttermscode';
            ExternalType = 'Picklist';
            InitValue = " ";
        }
        field(204; Address1_FreightTermsCodeEnum; Enum "CDS Shipment Method Code")
        {
            Caption = 'Address 1: Freight Terms';
            Description = 'Select the freight terms for the primary address to make sure shipping orders are processed correctly.';
            ExternalName = 'address1_freighttermscode';
            ExternalType = 'Picklist';
            InitValue = " ";
        }
        field(205; Address1_ShippingMethodCodeEnum; Enum "CDS Shipping Agent Code")
        {
            Caption = 'Address 1: Shipping Method';
            Description = 'Select a shipping method for deliveries sent to this address.';
            ExternalName = 'address1_shippingmethodcode';
            ExternalType = 'Picklist';
            InitValue = " ";
        }
    }

    keys
    {
        key(Key1; AccountId)
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