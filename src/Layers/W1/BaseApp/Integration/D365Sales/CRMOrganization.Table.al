// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5363 "CRM Organization"
{
    // Dynamics CRM Version: 7.1.0.2040

    Caption = 'CRM Organization';
    Description = 'Top level of the Microsoft Dynamics CRM business hierarchy. The organization can be a specific business, holding company, or corporation.';
    ExternalName = 'organization';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; OrganizationId; Guid)
        {
            Caption = 'Organization';
            Description = 'Unique identifier of the organization.';
            ExternalAccess = Read;
            ExternalName = 'organizationid';
            ExternalType = 'Uniqueidentifier';
        }
        field(2; Name; Text[160])
        {
            Caption = 'Organization Name';
            Description = 'Name of the organization. The name is set when Microsoft CRM is installed and should not be changed.';
            ExternalAccess = Insert;
            ExternalName = 'name';
            ExternalType = 'String';
        }
        field(3; UserGroupId; Guid)
        {
            Caption = 'User Group';
            Description = 'Unique identifier of the default group of users in the organization.';
            ExternalName = 'usergroupid';
            ExternalType = 'Uniqueidentifier';
        }
        field(4; PrivilegeUserGroupId; Guid)
        {
            Caption = 'Privilege User Group';
            Description = 'Unique identifier of the default privilege for users in the organization.';
            ExternalName = 'privilegeusergroupid';
            ExternalType = 'Uniqueidentifier';
        }
        field(5; RecurrenceExpansionJobBatchSiz; Integer)
        {
            Caption = 'Recurrence Expansion On Demand Job Batch Size';
            Description = 'Specifies the value for number of instances created in on demand job in one shot.';
            ExternalName = 'recurrenceexpansionjobbatchsize';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(6; RecurrenceExpansionJobBatchInt; Integer)
        {
            Caption = 'Recurrence Expansion Job Batch Interval';
            Description = 'Specifies the interval (in seconds) for pausing expansion job.';
            ExternalName = 'recurrenceexpansionjobbatchinterval';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(7; FiscalPeriodType; Integer)
        {
            Caption = 'Fiscal Period Type';
            Description = 'Type of fiscal period used throughout Microsoft CRM.';
            ExternalName = 'fiscalperiodtype';
            ExternalType = 'Integer';
        }
        field(8; FiscalCalendarStart; Date)
        {
            Caption = 'Fiscal Calendar Start';
            Description = 'Start date for the fiscal period that is to be used throughout Microsoft CRM.';
            ExternalName = 'fiscalcalendarstart';
            ExternalType = 'DateTime';
        }
        field(9; DateFormatCode; Option)
        {
            Caption = 'Date Format Code';
            Description = 'Information about how the date is displayed throughout Microsoft CRM.';
            ExternalName = 'dateformatcode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ';
            OptionOrdinalValues = -1;
            OptionMembers = " ";
        }
        field(10; TimeFormatCode; Option)
        {
            Caption = 'Time Format Code';
            Description = 'Information that specifies how the time is displayed throughout Microsoft CRM.';
            ExternalName = 'timeformatcode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ';
            OptionOrdinalValues = -1;
            OptionMembers = " ";
        }
        field(11; CurrencySymbol; Text[13])
        {
            Caption = 'Currency Symbol';
            Description = 'Symbol used for currency throughout Microsoft Dynamics CRM.';
            ExternalName = 'currencysymbol';
            ExternalType = 'String';
        }
        field(12; WeekStartDayCode; Option)
        {
            Caption = 'Week Start Day Code';
            Description = 'Designated first day of the week throughout Microsoft Dynamics CRM.';
            ExternalName = 'weekstartdaycode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ';
            OptionOrdinalValues = -1;
            OptionMembers = " ";
        }
        field(13; DateSeparator; Text[5])
        {
            Caption = 'Date Separator';
            Description = 'Character used to separate the month, the day, and the year in dates throughout Microsoft Dynamics CRM.';
            ExternalName = 'dateseparator';
            ExternalType = 'String';
        }
        field(14; FullNameConventionCode; Option)
        {
            Caption = 'Full Name Display Order';
            Description = 'Order in which names are to be displayed throughout Microsoft CRM.';
            ExternalName = 'fullnameconventioncode';
            ExternalType = 'Picklist';
            InitValue = LastNameFirstName;
            OptionCaption = 'Last Name; First Name,First Name,Last Name; First Name; Middle Initial,First Name; Middle Initial; Last Name,Last Name; First Name; Middle Name,First Name; Middle Name; Last Name,Last Name; space; First Name,Last Name; no space; First Name';
            OptionOrdinalValues = 0, 1, 2, 3, 4, 5, 6, 7;
            OptionMembers = LastNameFirstName,FirstName,LastNameFirstNameMiddleInitial,FirstNameMiddleInitialLastName,LastNameFirstNameMiddleName,FirstNameMiddleNameLastName,LastNamespaceFirstName,LastNamenospaceFirstName;
        }
        field(15; NegativeFormatCode; Option)
        {
            Caption = 'Negative Format';
            Description = 'Information that specifies how negative numbers are displayed throughout Microsoft CRM.';
            ExternalName = 'negativeformatcode';
            ExternalType = 'Picklist';
            InitValue = Brackets;
            OptionCaption = 'Brackets,Dash,Dash plus Space,Trailing Dash,Space plus Trailing Dash';
            OptionOrdinalValues = 0, 1, 2, 3, 4;
            OptionMembers = Brackets,Dash,DashplusSpace,TrailingDash,SpaceplusTrailingDash;
        }
        field(16; NumberFormat; Text[2])
        {
            Caption = 'Number Format';
            Description = 'Specification of how numbers are displayed throughout Microsoft CRM.';
            ExternalName = 'numberformat';
            ExternalType = 'String';
        }
        field(17; IsDisabled; Boolean)
        {
            Caption = 'Is Organization Disabled';
            Description = 'Information that specifies whether the organization is disabled.';
            ExternalAccess = Read;
            ExternalName = 'isdisabled';
            ExternalType = 'Boolean';
        }
        field(18; DisabledReason; Text[250])
        {
            Caption = 'Disabled Reason';
            Description = 'Reason for disabling the organization.';
            ExternalAccess = Read;
            ExternalName = 'disabledreason';
            ExternalType = 'String';
        }
        field(19; KbPrefix; Text[20])
        {
            Caption = 'Article Prefix';
            Description = 'Prefix to use for all articles in Microsoft Dynamics CRM.';
            ExternalName = 'kbprefix';
            ExternalType = 'String';
        }
        field(20; CurrentKbNumber; Integer)
        {
            Caption = 'Current Article Number';
            Description = 'First article number to use.';
            ExternalName = 'currentkbnumber';
            ExternalType = 'Integer';
        }
        field(21; CasePrefix; Text[20])
        {
            Caption = 'Case Prefix';
            Description = 'Prefix to use for all cases throughout Microsoft Dynamics CRM.';
            ExternalName = 'caseprefix';
            ExternalType = 'String';
        }
        field(22; CurrentCaseNumber; Integer)
        {
            Caption = 'Current Case Number';
            Description = 'First case number to use.';
            ExternalName = 'currentcasenumber';
            ExternalType = 'Integer';
        }
        field(23; ContractPrefix; Text[20])
        {
            Caption = 'Contract Prefix';
            Description = 'Prefix to use for all contracts throughout Microsoft Dynamics CRM.';
            ExternalName = 'contractprefix';
            ExternalType = 'String';
        }
        field(24; CurrentContractNumber; Integer)
        {
            Caption = 'Current Contract Number';
            Description = 'First contract number to use.';
            ExternalName = 'currentcontractnumber';
            ExternalType = 'Integer';
        }
        field(25; QuotePrefix; Text[20])
        {
            Caption = 'Quote Prefix';
            Description = 'Prefix to use for all quotes throughout Microsoft Dynamics CRM.';
            ExternalName = 'quoteprefix';
            ExternalType = 'String';
        }
        field(26; CurrentQuoteNumber; Integer)
        {
            Caption = 'Current Quote Number';
            Description = 'First quote number to use.';
            ExternalName = 'currentquotenumber';
            ExternalType = 'Integer';
        }
        field(27; OrderPrefix; Text[20])
        {
            Caption = 'Order Prefix';
            Description = 'Prefix to use for all orders throughout Microsoft Dynamics CRM.';
            ExternalName = 'orderprefix';
            ExternalType = 'String';
        }
        field(28; CurrentOrderNumber; Integer)
        {
            Caption = 'Current Order Number';
            Description = 'First order number to use.';
            ExternalName = 'currentordernumber';
            ExternalType = 'Integer';
        }
        field(29; InvoicePrefix; Text[20])
        {
            Caption = 'Invoice Prefix';
            Description = 'Prefix to use for all invoice numbers throughout Microsoft Dynamics CRM.';
            ExternalName = 'invoiceprefix';
            ExternalType = 'String';
        }
        field(30; CurrentInvoiceNumber; Integer)
        {
            Caption = 'Current Invoice Number';
            Description = 'First invoice number to use.';
            ExternalName = 'currentinvoicenumber';
            ExternalType = 'Integer';
        }
        field(31; UniqueSpecifierLength; Integer)
        {
            Caption = 'Unique String Length';
            Description = 'Number of characters appended to invoice, quote, and order numbers.';
            ExternalName = 'uniquespecifierlength';
            ExternalType = 'Integer';
            MaxValue = 6;
            MinValue = 4;
        }
        field(32; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            Description = 'Date and time when the organization was created.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(33; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            Description = 'Date and time when the organization was last modified.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
        }
        field(34; FiscalYearFormat; Text[25])
        {
            Caption = 'Fiscal Year Format';
            Description = 'Information that specifies how the name of the fiscal year is displayed throughout Microsoft CRM.';
            ExternalName = 'fiscalyearformat';
            ExternalType = 'String';
        }
        field(35; FiscalPeriodFormat; Text[25])
        {
            Caption = 'Fiscal Period Format';
            Description = 'Information that specifies how the name of the fiscal period is displayed throughout Microsoft CRM.';
            ExternalName = 'fiscalperiodformat';
            ExternalType = 'String';
        }
        field(36; FiscalYearPeriodConnect; Text[5])
        {
            Caption = 'Fiscal Year Period Connector';
            Description = 'Information that specifies how the names of the fiscal year and the fiscal period should be connected when displayed together.';
            ExternalName = 'fiscalyearperiodconnect';
            ExternalType = 'String';
        }
        field(37; LanguageCode; Integer)
        {
            Caption = 'Language';
            Description = 'Preferred language for the organization.';
            ExternalAccess = Insert;
            ExternalName = 'languagecode';
            ExternalType = 'Integer';
        }
        field(38; SortId; Integer)
        {
            Caption = 'Sort';
            Description = 'For internal use only.';
            ExternalName = 'sortid';
            ExternalType = 'Integer';
        }
        field(39; DateFormatString; Text[250])
        {
            Caption = 'Date Format String';
            Description = 'String showing how the date is displayed throughout Microsoft CRM.';
            ExternalName = 'dateformatstring';
            ExternalType = 'String';
        }
        field(40; TimeFormatString; Text[250])
        {
            Caption = 'Time Format String';
            Description = 'Text for how time is displayed in Microsoft Dynamics CRM.';
            ExternalName = 'timeformatstring';
            ExternalType = 'String';
        }
        field(41; PricingDecimalPrecision; Integer)
        {
            Caption = 'Pricing Decimal Precision';
            Description = 'Number of decimal places that can be used for prices.';
            ExternalName = 'pricingdecimalprecision';
            ExternalType = 'Integer';
            MaxValue = 4;
            MinValue = 0;
        }
        field(42; ShowWeekNumber; Boolean)
        {
            Caption = 'Show Week Number';
            Description = 'Information that specifies whether to display the week number in calendar displays throughout Microsoft CRM.';
            ExternalName = 'showweeknumber';
            ExternalType = 'Boolean';
        }
        field(43; NextTrackingNumber; Integer)
        {
            Caption = 'Next Tracking Number';
            Description = 'Next token to be placed on the subject line of an email message.';
            ExternalName = 'nexttrackingnumber';
            ExternalType = 'Integer';
        }
        field(44; TagMaxAggressiveCycles; Integer)
        {
            Caption = 'Auto-Tag Max Cycles';
            Description = 'Maximum number of aggressive polling cycles executed for email auto-tagging when a new email is received.';
            ExternalName = 'tagmaxaggressivecycles';
            ExternalType = 'Integer';
        }
        field(45; SystemUserId; Guid)
        {
            Caption = 'System User';
            Description = 'Unique identifier of the system user for the organization.';
            ExternalName = 'systemuserid';
            ExternalType = 'Uniqueidentifier';
        }
        field(46; CreatedBy; Guid)
        {
            Caption = 'Created By';
            Description = 'Unique identifier of the user who created the organization.';
            ExternalAccess = Read;
            ExternalName = 'createdby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(47; GrantAccessToNetworkService; Boolean)
        {
            Caption = 'Grant Access To Network Service';
            Description = 'For internal use only.';
            ExternalAccess = Insert;
            ExternalName = 'grantaccesstonetworkservice';
            ExternalType = 'Boolean';
        }
        field(48; AllowOutlookScheduledSyncs; Boolean)
        {
            Caption = 'Allow Scheduled Synchronization';
            Description = 'Indicates whether scheduled synchronizations to Outlook are allowed.';
            ExternalName = 'allowoutlookscheduledsyncs';
            ExternalType = 'Boolean';
        }
        field(49; AllowMarketingEmailExecution; Boolean)
        {
            Caption = 'Allow Marketing Email Execution';
            Description = 'Indicates whether marketing emails execution is allowed.';
            ExternalName = 'allowmarketingemailexecution';
            ExternalType = 'Boolean';
        }
        field(50; SqlAccessGroupId; Guid)
        {
            Caption = 'SQL Access Group';
            Description = 'For internal use only.';
            ExternalName = 'sqlaccessgroupid';
            ExternalType = 'Uniqueidentifier';
        }
        field(51; CurrencyFormatCode; Option)
        {
            Caption = 'Currency Format Code';
            Description = 'Information about how currency symbols are placed throughout Microsoft Dynamics CRM.';
            ExternalName = 'currencyformatcode';
            ExternalType = 'Picklist';
            InitValue = "$123";
            OptionCaption = '$123,123$,$ 123,123 $';
            OptionOrdinalValues = 0, 1, 2, 3;
            OptionMembers = "$123","123$","$1231","123$1";
        }
        field(52; FiscalSettingsUpdated; Boolean)
        {
            Caption = 'Is Fiscal Settings Updated';
            Description = 'Information that specifies whether the fiscal settings have been updated.';
            ExternalAccess = Read;
            ExternalName = 'fiscalsettingsupdated';
            ExternalType = 'Boolean';
        }
        field(53; ReportingGroupId; Guid)
        {
            Caption = 'Reporting Group';
            Description = 'For internal use only.';
            ExternalName = 'reportinggroupid';
            ExternalType = 'Uniqueidentifier';
        }
        field(54; TokenExpiry; Integer)
        {
            Caption = 'Token Expiration Duration';
            Description = 'Duration used for token expiration.';
            ExternalAccess = Modify;
            ExternalName = 'tokenexpiry';
            ExternalType = 'Integer';
        }
        field(55; ShareToPreviousOwnerOnAssign; Boolean)
        {
            Caption = 'Share To Previous Owner On Assign';
            Description = 'Information that specifies whether to share to previous owner on assign.';
            ExternalAccess = Modify;
            ExternalName = 'sharetopreviousowneronassign';
            ExternalType = 'Boolean';
        }
        field(56; ModifiedBy; Guid)
        {
            Caption = 'Modified By';
            Description = 'Unique identifier of the user who last modified the organization.';
            ExternalAccess = Read;
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(57; IntegrationUserId; Guid)
        {
            Caption = 'Integration User';
            Description = 'Unique identifier of the integration user for the organization.';
            ExternalName = 'integrationuserid';
            ExternalType = 'Uniqueidentifier';
        }
        field(58; TrackingTokenIdBase; Integer)
        {
            Caption = 'Tracking Token Base';
            Description = 'Base number used to provide separate tracking token identifiers to users belonging to different deployments.';
            ExternalName = 'trackingtokenidbase';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(59; BusinessClosureCalendarId; Guid)
        {
            Caption = 'Business Closure Calendar';
            Description = 'Unique identifier of the business closure calendar of organization.';
            ExternalAccess = Insert;
            ExternalName = 'businessclosurecalendarid';
            ExternalType = 'Uniqueidentifier';
        }
        field(60; AllowAutoUnsubscribeAcknowledg; Boolean)
        {
            Caption = 'Allow Automatic Unsubscribe Acknowledgement';
            Description = 'Indicates whether automatic unsubscribe acknowledgement email is allowed to send.';
            ExternalName = 'allowautounsubscribeacknowledgement';
            ExternalType = 'Boolean';
        }
        field(61; AllowAutoUnsubscribe; Boolean)
        {
            Caption = 'Allow Automatic Unsubscribe';
            Description = 'Indicates whether automatic unsubscribe is allowed.';
            ExternalName = 'allowautounsubscribe';
            ExternalType = 'Boolean';
        }
        field(62; VersionNumber; BigInteger)
        {
            Caption = 'Version Number';
            Description = 'Version number of the organization.';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(63; TrackingPrefix; Text[250])
        {
            Caption = 'Tracking Prefix';
            Description = 'History list of tracking token prefixes.';
            ExternalName = 'trackingprefix';
            ExternalType = 'String';
        }
        field(64; MinOutlookSyncInterval; Integer)
        {
            Caption = 'Min Synchronization Frequency';
            Description = 'Minimum allowed time between scheduled Outlook synchronizations.';
            ExternalName = 'minoutlooksyncinterval';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(65; BulkOperationPrefix; Text[20])
        {
            Caption = 'Bulk Operation Prefix';
            Description = 'Prefix used for bulk operation numbering.';
            ExternalName = 'bulkoperationprefix';
            ExternalType = 'String';
        }
        field(66; AllowAutoResponseCreation; Boolean)
        {
            Caption = 'Allow Automatic Response Creation';
            Description = 'Indicates whether automatic response creation is allowed.';
            ExternalName = 'allowautoresponsecreation';
            ExternalType = 'Boolean';
        }
        field(67; MaximumTrackingNumber; Integer)
        {
            Caption = 'Max Tracking Number';
            Description = 'Maximum tracking number before recycling takes place.';
            ExternalName = 'maximumtrackingnumber';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(68; CampaignPrefix; Text[20])
        {
            Caption = 'Campaign Prefix';
            Description = 'Prefix used for campaign numbering.';
            ExternalName = 'campaignprefix';
            ExternalType = 'String';
        }
        field(69; SqlAccessGroupName; Text[250])
        {
            Caption = 'SQL Access Group Name';
            Description = 'For internal use only.';
            ExternalName = 'sqlaccessgroupname';
            ExternalType = 'String';
        }
        field(70; CurrentCampaignNumber; Integer)
        {
            Caption = 'Current Campaign Number';
            Description = 'Current campaign number.';
            ExternalName = 'currentcampaignnumber';
            ExternalType = 'Integer';
        }
        field(71; FiscalYearDisplayCode; Integer)
        {
            Caption = 'Fiscal Year Display';
            Description = 'Information that specifies whether the fiscal year should be displayed based on the start date or the end date of the fiscal year.';
            ExternalName = 'fiscalyeardisplaycode';
            ExternalType = 'Integer';
        }
        field(72; SiteMapXml; BLOB)
        {
            Caption = 'SiteMap XML';
            Description = 'XML string that defines the navigation structure for the application.';
            ExternalName = 'sitemapxml';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(73; ReportingGroupName; Text[250])
        {
            Caption = 'Reporting Group Name';
            Description = 'For internal use only.';
            ExternalName = 'reportinggroupname';
            ExternalType = 'String';
        }
        field(74; CurrentBulkOperationNumber; Integer)
        {
            Caption = 'Current Bulk Operation Number';
            Description = 'Current bulk operation number.';
            ExternalName = 'currentbulkoperationnumber';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(75; SchemaNamePrefix; Text[8])
        {
            Caption = 'Customization Name Prefix';
            Description = 'Prefix used for custom entities and attributes.';
            ExternalName = 'schemanameprefix';
            ExternalType = 'String';
        }
        field(76; IgnoreInternalEmail; Boolean)
        {
            Caption = 'Ignore Internal Email';
            Description = 'Indicates whether incoming email sent by internal Microsoft Dynamics CRM users or queues should be tracked.';
            ExternalName = 'ignoreinternalemail';
            ExternalType = 'Boolean';
        }
        field(77; TagPollingPeriod; Integer)
        {
            Caption = 'Auto-Tag Interval';
            Description = 'Normal polling frequency used for email receive auto-tagging in outlook.';
            ExternalName = 'tagpollingperiod';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(78; TrackingTokenIdDigits; Integer)
        {
            Caption = 'Tracking Token Digits';
            Description = 'Number of digits used to represent a tracking token identifier.';
            ExternalName = 'trackingtokeniddigits';
            ExternalType = 'Integer';
        }
        field(79; ModifiedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedBy)));
            Caption = 'ModifiedByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(80; CreatedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedBy)));
            Caption = 'CreatedByName';
            ExternalAccess = Read;
            ExternalName = 'createdbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(81; NumberGroupFormat; Text[50])
        {
            Caption = 'Number Grouping Format';
            Description = 'Specifies how numbers are grouped in Microsoft Dynamics CRM.';
            ExternalName = 'numbergroupformat';
            ExternalType = 'String';
        }
        field(82; LongDateFormatCode; Integer)
        {
            Caption = 'Long Date Format';
            Description = 'Information that specifies how the Long Date format is displayed in Microsoft Dynamics CRM.';
            ExternalName = 'longdateformatcode';
            ExternalType = 'Integer';
        }
        field(83; UTCConversionTimeZoneCode; Integer)
        {
            Caption = 'UTC Conversion Time Zone Code';
            Description = 'Time zone code that was in use when the record was created.';
            ExternalName = 'utcconversiontimezonecode';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(84; TimeZoneRuleVersionNumber; Integer)
        {
            Caption = 'Time Zone Rule Version Number';
            Description = 'For internal use only.';
            ExternalName = 'timezoneruleversionnumber';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(85; CurrentImportSequenceNumber; Integer)
        {
            Caption = 'Current Import Sequence Number';
            Description = 'Import sequence to use.';
            ExternalAccess = Read;
            ExternalName = 'currentimportsequencenumber';
            ExternalType = 'Integer';
        }
        field(86; ParsedTablePrefix; Text[20])
        {
            Caption = 'Parsed Table Prefix';
            Description = 'Prefix used for parsed tables.';
            ExternalAccess = Read;
            ExternalName = 'parsedtableprefix';
            ExternalType = 'String';
        }
        field(87; V3CalloutConfigHash; Text[250])
        {
            Caption = 'V3 Callout Hash';
            Description = 'Hash of the V3 callout configuration file.';
            ExternalAccess = Read;
            ExternalName = 'v3calloutconfighash';
            ExternalType = 'String';
        }
        field(88; IsFiscalPeriodMonthBased; Boolean)
        {
            Caption = 'Is Fiscal Period Monthly';
            Description = 'Indicates whether the fiscal period is displayed as the month number.';
            ExternalName = 'isfiscalperiodmonthbased';
            ExternalType = 'Boolean';
        }
        field(89; LocaleId; Integer)
        {
            Caption = 'Locale';
            Description = 'Unique identifier of the locale of the organization.';
            ExternalName = 'localeid';
            ExternalType = 'Integer';
        }
        field(90; ParsedTableColumnPrefix; Text[20])
        {
            Caption = 'Parsed Table Column Prefix';
            Description = 'Prefix used for parsed table columns.';
            ExternalAccess = Read;
            ExternalName = 'parsedtablecolumnprefix';
            ExternalType = 'String';
        }
        field(91; SupportUserId; Guid)
        {
            Caption = 'Support User';
            Description = 'Unique identifier of the support user for the organization.';
            ExternalAccess = Insert;
            ExternalName = 'supportuserid';
            ExternalType = 'Uniqueidentifier';
        }
        field(92; AMDesignator; Text[25])
        {
            Caption = 'AM Designator';
            Description = 'AM designator to use throughout Microsoft Dynamics CRM.';
            ExternalName = 'amdesignator';
            ExternalType = 'String';
        }
        field(93; CurrencyDisplayOption; Option)
        {
            Caption = 'Display Currencies Using';
            Description = 'Indicates whether to display money fields with currency code or currency symbol.';
            ExternalName = 'currencydisplayoption';
            ExternalType = 'Picklist';
            InitValue = Currencysymbol;
            OptionCaption = 'Currency symbol,Currency code';
            OptionOrdinalValues = 0, 1;
            OptionMembers = Currencysymbol,Currencycode;
        }
        field(94; MinAddressBookSyncInterval; Integer)
        {
            Caption = 'Min Address Synchronization Frequency';
            Description = 'Normal polling frequency used for address book synchronization in Microsoft Office Outlook.';
            ExternalName = 'minaddressbooksyncinterval';
            ExternalType = 'Integer';
        }
        field(95; IsDuplicateDetectionEnabledFor; Boolean)
        {
            Caption = 'Is Duplicate Detection Enabled for Online Create/Update';
            Description = 'Indicates whether duplicate detection during online create or update is enabled.';
            ExternalName = 'isduplicatedetectionenabledforonlinecreateupdate';
            ExternalType = 'Boolean';
        }
        field(96; FeatureSet; Text[250])
        {
            Caption = 'Feature Set';
            Description = 'Features to be enabled as an XML BLOB.';
            ExternalName = 'featureset';
            ExternalType = 'String';
        }
        field(97; BlockedAttachments; Text[250])
        {
            Caption = 'Block Attachments';
            Description = 'Prevent upload or download of certain attachment types that are considered dangerous.';
            ExternalName = 'blockedattachments';
            ExternalType = 'String';
        }
        field(98; IsDuplicateDetectionEnabledFo1; Boolean)
        {
            Caption = 'Is Duplicate Detection Enabled For Offline Synchronization';
            Description = 'Indicates whether duplicate detection of records during offline synchronization is enabled.';
            ExternalName = 'isduplicatedetectionenabledforofflinesync';
            ExternalType = 'Boolean';
        }
        field(99; AllowOfflineScheduledSyncs; Boolean)
        {
            Caption = 'Allow Offline Scheduled Synchronization';
            Description = 'Indicates whether background offline synchronization in Microsoft Office Outlook is allowed.';
            ExternalName = 'allowofflinescheduledsyncs';
            ExternalType = 'Boolean';
        }
        field(100; AllowUnresolvedPartiesOnEmailS; Boolean)
        {
            Caption = 'Allow Unresolved Address Email Send';
            Description = 'Indicates whether users are allowed to send email to unresolved parties (parties must still have an email address).';
            ExternalName = 'allowunresolvedpartiesonemailsend';
            ExternalType = 'Boolean';
        }
        field(101; TimeSeparator; Text[5])
        {
            Caption = 'Time Separator';
            Description = 'Text for how the time separator is displayed throughout Microsoft Dynamics CRM.';
            ExternalName = 'timeseparator';
            ExternalType = 'String';
        }
        field(102; CurrentParsedTableNumber; Integer)
        {
            Caption = 'Current Parsed Table Number';
            Description = 'First parsed table number to use.';
            ExternalAccess = Read;
            ExternalName = 'currentparsedtablenumber';
            ExternalType = 'Integer';
        }
        field(103; MinOfflineSyncInterval; Integer)
        {
            Caption = 'Min Offline Synchronization Frequency';
            Description = 'Normal polling frequency used for background offline synchronization in Microsoft Office Outlook.';
            ExternalName = 'minofflinesyncinterval';
            ExternalType = 'Integer';
        }
        field(104; AllowWebExcelExport; Boolean)
        {
            Caption = 'Allow Export to Excel';
            Description = 'Indicates whether Web-based export of grids to Microsoft Office Excel is allowed.';
            ExternalName = 'allowwebexcelexport';
            ExternalType = 'Boolean';
        }
        field(105; ReferenceSiteMapXml; Text[250])
        {
            Caption = 'Reference SiteMap XML';
            Description = 'XML string that defines the navigation structure for the application. This is the site map from the previously upgraded build and is used in a 3-way merge during upgrade.';
            ExternalName = 'referencesitemapxml';
            ExternalType = 'String';
        }
        field(106; IsDuplicateDetectionEnabledFo2; Boolean)
        {
            Caption = 'Is Duplicate Detection Enabled For Import';
            Description = 'Indicates whether duplicate detection of records during import is enabled.';
            ExternalName = 'isduplicatedetectionenabledforimport';
            ExternalType = 'Boolean';
        }
        field(107; CalendarType; Integer)
        {
            Caption = 'Calendar Type';
            Description = 'Calendar type for the system. Set to Gregorian US by default.';
            ExternalName = 'calendartype';
            ExternalType = 'Integer';
        }
        field(108; SQMEnabled; Boolean)
        {
            Caption = 'Is SQM Enabled';
            Description = 'Setting for SQM data collection, 0 no, 1 yes enabled';
            ExternalName = 'sqmenabled';
            ExternalType = 'Boolean';
        }
        field(109; NegativeCurrencyFormatCode; Integer)
        {
            Caption = 'Negative Currency Format';
            Description = 'Information that specifies how negative currency numbers are displayed throughout Microsoft Dynamics CRM.';
            ExternalName = 'negativecurrencyformatcode';
            ExternalType = 'Integer';
        }
        field(110; AllowAddressBookSyncs; Boolean)
        {
            Caption = 'Allow Address Book Synchronization';
            Description = 'Indicates whether background address book synchronization in Microsoft Office Outlook is allowed.';
            ExternalName = 'allowaddressbooksyncs';
            ExternalType = 'Boolean';
        }
        field(111; ISVIntegrationCode; Option)
        {
            Caption = 'ISV Integration Mode';
            Description = 'Indicates whether loading of Microsoft Dynamics CRM in a browser window that does not have address, tool, and menu bars is enabled.';
            ExternalName = 'isvintegrationcode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,None,Web,Outlook Workstation Client,Web; Outlook Workstation Client,Outlook Laptop Client,Web; Outlook Laptop Client,Outlook,All';
            OptionOrdinalValues = -1, 0, 1, 2, 3, 4, 5, 6, 7;
            OptionMembers = " ","None",Web,OutlookWorkstationClient,"Web;OutlookWorkstationClient",OutlookLaptopClient,"Web;OutlookLaptopClient",Outlook,All;
        }
        field(112; DecimalSymbol; Text[5])
        {
            Caption = 'Decimal Symbol';
            Description = 'Symbol used for decimal in Microsoft Dynamics CRM.';
            ExternalName = 'decimalsymbol';
            ExternalType = 'String';
        }
        field(113; MaxUploadFileSize; Integer)
        {
            Caption = 'Max Upload File Size';
            Description = 'Maximum allowed size of an attachment.';
            ExternalName = 'maxuploadfilesize';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(114; IsAppMode; Boolean)
        {
            Caption = 'Is Application Mode Enabled';
            Description = 'Indicates whether loading of Microsoft Dynamics CRM in a browser window that does not have address, tool, and menu bars is enabled.';
            ExternalName = 'isappmode';
            ExternalType = 'Boolean';
        }
        field(115; EnablePricingOnCreate; Boolean)
        {
            Caption = 'Enable Pricing On Create';
            Description = 'Enable pricing calculations on a Create call.';
            ExternalName = 'enablepricingoncreate';
            ExternalType = 'Boolean';
        }
        field(116; IsSOPIntegrationEnabled; Boolean)
        {
            Caption = 'Is Sales Order Integration Enabled';
            Description = 'Enable sales order processing integration.';
            ExternalName = 'issopintegrationenabled';
            ExternalType = 'Boolean';
        }
        field(117; PMDesignator; Text[25])
        {
            Caption = 'PM Designator';
            Description = 'PM designator to use throughout Microsoft Dynamics CRM.';
            ExternalName = 'pmdesignator';
            ExternalType = 'String';
        }
        field(118; CurrencyDecimalPrecision; Integer)
        {
            Caption = 'Currency Decimal Precision';
            Description = 'Number of decimal places that can be used for currency.';
            ExternalName = 'currencydecimalprecision';
            ExternalType = 'Integer';
        }
        field(119; MaxAppointmentDurationDays; Integer)
        {
            Caption = 'Max Appointment Duration';
            Description = 'Maximum number of days an appointment can last.';
            ExternalName = 'maxappointmentdurationdays';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(120; EmailSendPollingPeriod; Integer)
        {
            Caption = 'Email Send Polling Frequency';
            Description = 'Normal polling frequency used for sending email in Microsoft Office Outlook.';
            ExternalName = 'emailsendpollingperiod';
            ExternalType = 'Integer';
        }
        field(121; RenderSecureIFrameForEmail; Boolean)
        {
            Caption = 'Render Secure Frame For Email';
            Description = 'Flag to render the body of email in the Web form in an IFRAME with the security=''restricted'' attribute set. This is additional security but can cause a credentials prompt.';
            ExternalName = 'rendersecureiframeforemail';
            ExternalType = 'Boolean';
        }
        field(122; NumberSeparator; Text[5])
        {
            Caption = 'Number Separator';
            Description = 'Symbol used for number separation in Microsoft Dynamics CRM.';
            ExternalName = 'numberseparator';
            ExternalType = 'String';
        }
        field(123; PrivReportingGroupId; Guid)
        {
            Caption = 'Privilege Reporting Group';
            Description = 'For internal use only.';
            ExternalName = 'privreportinggroupid';
            ExternalType = 'Uniqueidentifier';
        }
        field(124; BaseCurrencyId; Guid)
        {
            Caption = 'Currency';
            Description = 'Unique identifier of the base currency of the organization.';
            ExternalAccess = Insert;
            ExternalName = 'basecurrencyid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Transactioncurrency".TransactionCurrencyId;
        }
        field(125; MaxRecordsForExportToExcel; Integer)
        {
            Caption = 'Max Records For Excel Export';
            Description = 'Maximum number of records that will be exported to a static Microsoft Office Excel worksheet when exporting from the grid.';
            ExternalName = 'maxrecordsforexporttoexcel';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(126; PrivReportingGroupName; Text[250])
        {
            Caption = 'Privilege Reporting Group Name';
            Description = 'For internal use only.';
            ExternalName = 'privreportinggroupname';
            ExternalType = 'String';
        }
        field(127; YearStartWeekCode; Integer)
        {
            Caption = 'Year Start Week Code';
            Description = 'Information that specifies how the first week of the year is specified in Microsoft Dynamics CRM.';
            ExternalName = 'yearstartweekcode';
            ExternalType = 'Integer';
        }
        field(128; IsPresenceEnabled; Boolean)
        {
            Caption = 'Presence Enabled';
            Description = 'Information on whether IM presence is enabled.';
            ExternalName = 'ispresenceenabled';
            ExternalType = 'Boolean';
        }
        field(129; IsDuplicateDetectionEnabled; Boolean)
        {
            Caption = 'Is Duplicate Detection Enabled';
            Description = 'Indicates whether duplicate detection of records is enabled.';
            ExternalName = 'isduplicatedetectionenabled';
            ExternalType = 'Boolean';
        }
        field(130; BaseCurrencyIdName; Text[100])
        {
            CalcFormula = lookup("CRM Transactioncurrency".CurrencyName where(TransactionCurrencyId = field(BaseCurrencyId)));
            Caption = 'BaseCurrencyIdName';
            ExternalAccess = Read;
            ExternalName = 'basecurrencyidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(131; ExpireSubscriptionsInDays; Integer)
        {
            Caption = 'Days to Expire Subscriptions';
            Description = 'Maximum number of days before deleting inactive subscriptions.';
            ExternalName = 'expiresubscriptionsindays';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(132; IsAuditEnabled; Boolean)
        {
            Caption = 'Is Auditing Enabled';
            Description = 'Enable or disable auditing of changes.';
            ExternalName = 'isauditenabled';
            ExternalType = 'Boolean';
        }
        field(133; BaseCurrencyPrecision; Integer)
        {
            Caption = 'Base Currency Precision';
            Description = 'Number of decimal places that can be used for the base currency.';
            ExternalAccess = Read;
            ExternalName = 'basecurrencyprecision';
            ExternalType = 'Integer';
            MaxValue = 4;
            MinValue = 0;
        }
        field(134; BaseCurrencySymbol; Text[5])
        {
            Caption = 'Base Currency Symbol';
            Description = 'Symbol used for the base currency.';
            ExternalAccess = Read;
            ExternalName = 'basecurrencysymbol';
            ExternalType = 'String';
        }
        field(135; MaxRecordsForLookupFilters; Integer)
        {
            Caption = 'Max Records Filter Selection';
            Description = 'Maximum number of lookup and picklist records that can be selected by user for filtering.';
            ExternalName = 'maxrecordsforlookupfilters';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(136; AllowEntityOnlyAudit; Boolean)
        {
            Caption = 'Allow Entity Level Auditing';
            Description = 'Indicates whether auditing of changes to entity is allowed when no attributes have changed.';
            ExternalAccess = Insert;
            ExternalName = 'allowentityonlyaudit';
            ExternalType = 'Boolean';
        }
        field(137; DefaultRecurrenceEndRangeType; Option)
        {
            Caption = 'Default Recurrence End Range Type';
            Description = 'Type of default recurrence end range date.';
            ExternalName = 'defaultrecurrenceendrangetype';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,No End Date,Number of Occurrences,End By Date';
            OptionOrdinalValues = -1, 1, 2, 3;
            OptionMembers = " ",NoEndDate,NumberofOccurrences,EndByDate;
        }
        field(138; FutureExpansionWindow; Integer)
        {
            Caption = 'Future Expansion Window';
            Description = 'Specifies the maximum number of months in future for which the recurring activities can be created.';
            ExternalName = 'futureexpansionwindow';
            ExternalType = 'Integer';
            MaxValue = 140;
            MinValue = 1;
        }
        field(139; PastExpansionWindow; Integer)
        {
            Caption = 'Past Expansion Window';
            Description = 'Specifies the maximum number of months in past for which the recurring activities can be created.';
            ExternalName = 'pastexpansionwindow';
            ExternalType = 'Integer';
            MaxValue = 120;
            MinValue = 1;
        }
        field(140; RecurrenceExpansionSynchCreate; Integer)
        {
            Caption = 'Recurrence Expansion Synchronization Create Maximum';
            Description = 'Specifies the maximum number of instances to be created synchronously after creating a recurring appointment.';
            ExternalName = 'recurrenceexpansionsynchcreatemax';
            ExternalType = 'Integer';
            MaxValue = 1000;
            MinValue = 1;
        }
        field(141; RecurrenceDefaultNumberOfOccur; Integer)
        {
            Caption = 'Recurrence Default Number of Occurrences';
            Description = 'Specifies the default value for number of occurrences field in the recurrence dialog.';
            ExternalName = 'recurrencedefaultnumberofoccurrences';
            ExternalType = 'Integer';
            MaxValue = 999;
            MinValue = 1;
        }
        field(142; CreatedOnBehalfBy; Guid)
        {
            Caption = 'Created By (Delegate)';
            Description = 'Unique identifier of the delegate user who created the organization.';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(143; CreatedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            Caption = 'CreatedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(144; ModifiedOnBehalfBy; Guid)
        {
            Caption = 'Modified By (Delegate)';
            Description = 'Unique identifier of the delegate user who last modified the organization.';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(145; ModifiedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedOnBehalfBy)));
            Caption = 'ModifiedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(146; GetStartedPaneContentEnabled; Boolean)
        {
            Caption = 'Is Get Started Pane Content Enabled';
            Description = 'Indicates whether Get Started content is enabled for this organization.';
            ExternalName = 'getstartedpanecontentenabled';
            ExternalType = 'Boolean';
        }
        field(147; UseReadForm; Boolean)
        {
            Caption = 'Use Read-Optimized Form';
            Description = 'Indicates whether the read-optimized form should be enabled for this organization.';
            ExternalName = 'usereadform';
            ExternalType = 'Boolean';
        }
        field(148; InitialVersion; Text[20])
        {
            Caption = 'Initial Version';
            Description = 'Initial version of the organization.';
            ExternalAccess = Insert;
            ExternalName = 'initialversion';
            ExternalType = 'String';
        }
        field(149; SampleDataImportId; Guid)
        {
            Caption = 'Sample Data Import';
            Description = 'Unique identifier of the sample data import job.';
            ExternalName = 'sampledataimportid';
            ExternalType = 'Uniqueidentifier';
        }
        field(150; ReportScriptErrors; Option)
        {
            Caption = 'Report Script Errors';
            Description = 'Picklist for selecting the organization preference for reporting scripting errors.';
            ExternalName = 'reportscripterrors';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,No preference for sending an error report to Microsoft about Microsoft Dynamics CRM,Ask me for permission to send an error report to Microsoft,Automatically send an error report to Microsoft without asking me for permission,Never send an error report to Microsoft about Microsoft Dynamics CRM';
            OptionOrdinalValues = -1, 0, 1, 2, 3;
            OptionMembers = " ",NopreferenceforsendinganerrorreporttoMicrosoftaboutMicrosoftDynamicsCRM,AskmeforpermissiontosendanerrorreporttoMicrosoft,AutomaticallysendanerrorreporttoMicrosoftwithoutaskingmeforpermission,NeversendanerrorreporttoMicrosoftaboutMicrosoftDynamicsCRM;
        }
        field(151; RequireApprovalForUserEmail; Boolean)
        {
            Caption = 'Is Approval For User Email Required';
            Description = 'Indicates whether Send As Other User privilege is enabled.';
            ExternalName = 'requireapprovalforuseremail';
            ExternalType = 'Boolean';
        }
        field(152; RequireApprovalForQueueEmail; Boolean)
        {
            Caption = 'Is Approval For Queue Email Required';
            Description = 'Indicates whether Send As Other User privilege is enabled.';
            ExternalName = 'requireapprovalforqueueemail';
            ExternalType = 'Boolean';
        }
        field(153; GoalRollupExpiryTime; Integer)
        {
            Caption = 'Rollup Expiration Time for Goal';
            Description = 'Number of days after the goal''s end date after which the rollup of the goal stops automatically.';
            ExternalName = 'goalrollupexpirytime';
            ExternalType = 'Integer';
            MaxValue = 400;
            MinValue = 0;
        }
        field(154; GoalRollupFrequency; Integer)
        {
            Caption = 'Automatic Rollup Frequency for Goal';
            Description = 'Number of hours between automatic rollup jobs .';
            ExternalName = 'goalrollupfrequency';
            ExternalType = 'Integer';
            MinValue = 1;
        }
        field(155; AutoApplyDefaultonCaseCreate; Boolean)
        {
            Caption = 'Auto Apply Default Entitlement on Case Create';
            Description = 'Select whether to auto apply the default customer entitlement on case creation.';
            ExternalName = 'autoapplydefaultoncasecreate';
            ExternalType = 'Boolean';
        }
        field(156; AutoApplyDefaultonCaseUpdate; Boolean)
        {
            Caption = 'Auto Apply Default Entitlement on Case Update';
            Description = 'Select whether to auto apply the default customer entitlement on case update.';
            ExternalName = 'autoapplydefaultoncaseupdate';
            ExternalType = 'Boolean';
        }
        field(157; FiscalYearFormatPrefix; Option)
        {
            Caption = 'Prefix for Fiscal Year';
            Description = 'Prefix for the display of the fiscal year.';
            ExternalName = 'fiscalyearformatprefix';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,FY';
            OptionOrdinalValues = -1, 1;
            OptionMembers = " ",FY;
        }
        field(158; FiscalYearFormatSuffix; Option)
        {
            Caption = 'Suffix for Fiscal Year';
            Description = 'Suffix for the display of the fiscal year.';
            ExternalName = 'fiscalyearformatsuffix';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,FY, Fiscal Year';
            OptionOrdinalValues = -1, 1, 2;
            OptionMembers = " ",FY,FiscalYear;
        }
        field(159; FiscalYearFormatYear; Option)
        {
            Caption = 'Fiscal Year Format Year';
            Description = 'Format for the year.';
            ExternalName = 'fiscalyearformatyear';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,YYYY,YY,GGYY';
            OptionOrdinalValues = -1, 1, 2, 3;
            OptionMembers = " ",YYYY,YY,GGYY;
        }
        field(160; DiscountCalculationMethod; Option)
        {
            Caption = 'Discount calculation method';
            Description = 'Discount calculation method for the QOOI product.';
            ExternalName = 'discountcalculationmethod';
            ExternalType = 'Picklist';
            InitValue = Lineitem;
            OptionCaption = 'Line item,Per unit';
            OptionOrdinalValues = 0, 1;
            OptionMembers = Lineitem,Perunit;
        }
        field(161; FiscalPeriodFormatPeriod; Option)
        {
            Caption = 'Format for Fiscal Period';
            Description = 'Format in which the fiscal period will be displayed.';
            ExternalName = 'fiscalperiodformatperiod';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Quarter {0},Q{0},P{0},Month {0},M{0},Semester {0},Month Name';
            OptionOrdinalValues = -1, 1, 2, 3, 4, 5, 6, 7;
            OptionMembers = " ","Quarter{0}","Q{0}","P{0}","Month{0}","M{0}","Semester{0}",MonthName;
        }
        field(162; AllowClientMessageBarAd; Boolean)
        {
            Caption = 'Allow Outlook Client Message Bar Advertisement';
            Description = 'Indicates whether Outlook Client message bar advertisement is allowed.';
            ExternalName = 'allowclientmessagebarad';
            ExternalType = 'Boolean';
        }
        field(163; AllowUserFormModePreference; Boolean)
        {
            Caption = 'Allow User Form Mode Preference';
            Description = 'Indicates whether individuals can select their form mode preference in their personal options.';
            ExternalName = 'allowuserformmodepreference';
            ExternalType = 'Boolean';
        }
        field(164; HashFilterKeywords; Text[250])
        {
            Caption = 'Hash Filter Keywords';
            Description = 'Filter Subject Keywords';
            ExternalName = 'hashfilterkeywords';
            ExternalType = 'String';
        }
        field(165; HashMaxCount; Integer)
        {
            Caption = 'Hash Max Count';
            Description = 'Maximum number of subject keywords or recipients used for correlation';
            ExternalName = 'hashmaxcount';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(166; HashDeltaSubjectCount; Integer)
        {
            Caption = 'Hash Delta Subject Count';
            Description = 'Maximum difference allowed between subject keywords count of the email messaged to be correlated';
            ExternalName = 'hashdeltasubjectcount';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(167; HashMinAddressCount; Integer)
        {
            Caption = 'Hash Min Address Count';
            Description = 'Minimum number of recipients required to match for email messaged to be correlated';
            ExternalName = 'hashminaddresscount';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(168; EnableSmartMatching; Boolean)
        {
            Caption = 'Enable Smart Matching';
            Description = 'Use Smart Matching.';
            ExternalName = 'enablesmartmatching';
            ExternalType = 'Boolean';
        }
        field(169; PinpointLanguageCode; Integer)
        {
            Caption = 'PinpointLanguageCode';
            ExternalAccess = Modify;
            ExternalName = 'pinpointlanguagecode';
            ExternalType = 'Integer';
        }
        field(170; OrgDbOrgSettings; Text[250])
        {
            Caption = 'Organization Database Organization Settings';
            Description = 'Organization settings stored in Organization Database.';
            ExternalName = 'orgdborgsettings';
            ExternalType = 'String';
        }
        field(171; IsUserAccessAuditEnabled; Boolean)
        {
            Caption = 'Is User Access Auditing Enabled';
            Description = 'Enable or disable auditing of user access.';
            ExternalName = 'isuseraccessauditenabled';
            ExternalType = 'Boolean';
        }
        field(172; UserAccessAuditingInterval; Integer)
        {
            Caption = 'User Authentication Auditing Interval';
            Description = 'The interval at which user access is checked for auditing.';
            ExternalName = 'useraccessauditinginterval';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(173; QuickFindRecordLimitEnabled; Boolean)
        {
            Caption = 'Quick Find Record Limit Enabled';
            Description = 'Indicates whether a quick find record limit should be enabled for this organization (allows for faster Quick Find queries but prevents overly broad searches).';
            ExternalName = 'quickfindrecordlimitenabled';
            ExternalType = 'Boolean';
        }
        field(174; EnableBingMapsIntegration; Boolean)
        {
            Caption = 'Enable Integration with Bing Maps';
            Description = 'Enable Integration with Bing Maps';
            ExternalName = 'enablebingmapsintegration';
            ExternalType = 'Boolean';
        }
        field(175; IsDefaultCountryCodeCheckEnabl; Boolean)
        {
            Caption = 'Enable or disable country code selection';
            Description = 'Enable or disable country code selection.';
            ExternalName = 'isdefaultcountrycodecheckenabled';
            ExternalType = 'Boolean';
        }
        field(176; DefaultCountryCode; Text[30])
        {
            Caption = 'Default Country Code';
            Description = 'Text area to enter default country code.';
            ExternalName = 'defaultcountrycode';
            ExternalType = 'String';
        }
        field(177; UseSkypeProtocol; Boolean)
        {
            Caption = 'User Skype Protocol';
            Description = 'Indicates default protocol selected for organization.';
            ExternalName = 'useskypeprotocol';
            ExternalType = 'Boolean';
        }
        field(178; IncomingEmailExchangeEmailRetr; Integer)
        {
            Caption = 'Exchange Email Retrieval Batch Size';
            Description = 'Setting for the Async Service Mailbox Queue. Defines the retrieval batch size of exchange server.';
            ExternalName = 'incomingemailexchangeemailretrievalbatchsize';
            ExternalType = 'Integer';
            MinValue = 1;
        }
        field(179; EmailCorrelationEnabled; Boolean)
        {
            Caption = 'Use Email Correlation';
            Description = 'Flag to turn email correlation on or off.';
            ExternalName = 'emailcorrelationenabled';
            ExternalType = 'Boolean';
        }
        field(180; YammerOAuthAccessTokenExpired; Boolean)
        {
            Caption = 'Yammer OAuth Access Token Expired';
            Description = 'Denotes whether the OAuth access token for Yammer network has expired';
            ExternalAccess = Modify;
            ExternalName = 'yammeroauthaccesstokenexpired';
            ExternalType = 'Boolean';
        }
        field(181; DefaultEmailSettings; Text[250])
        {
            Caption = 'Default Email Settings';
            Description = 'XML string containing the default email settings that are applied when a user or queue is created.';
            ExternalName = 'defaultemailsettings';
            ExternalType = 'String';
        }
        field(182; YammerGroupId; Integer)
        {
            Caption = 'Yammer Group Id';
            Description = 'Denotes the Yammer group ID';
            ExternalAccess = Modify;
            ExternalName = 'yammergroupid';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(183; YammerNetworkPermalink; Text[100])
        {
            Caption = 'Yammer Network Permalink';
            Description = 'Denotes the Yammer network permalink';
            ExternalAccess = Modify;
            ExternalName = 'yammernetworkpermalink';
            ExternalType = 'String';
        }
        field(184; YammerPostMethod; Option)
        {
            Caption = 'Internal Use Only';
            Description = 'Internal Use Only';
            ExternalAccess = Modify;
            ExternalName = 'yammerpostmethod';
            ExternalType = 'Picklist';
            InitValue = Public;
            OptionCaption = 'Public,Private';
            OptionOrdinalValues = 0, 1;
            OptionMembers = Public,Private;
        }
        field(185; EmailConnectionChannel; Option)
        {
            Caption = 'Email Connection Channel';
            Description = 'Select if you want to use the Email Router or server-side synchronization for email processing.';
            ExternalName = 'emailconnectionchannel';
            ExternalType = 'Picklist';
            InitValue = "Server-SideSynchronization";
            OptionCaption = 'Server-Side Synchronization,Microsoft Dynamics CRM 2015 Email Router';
            OptionOrdinalValues = 0, 1;
            OptionMembers = "Server-SideSynchronization",MicrosoftDynamicsCRM2015EmailRouter;
        }
        field(186; IsAutoSaveEnabled; Boolean)
        {
            Caption = 'Auto Save Enabled';
            Description = 'Information on whether auto save is enabled.';
            ExternalName = 'isautosaveenabled';
            ExternalType = 'Boolean';
        }
        field(187; BingMapsApiKey; Text[250])
        {
            Caption = 'Bing Maps API Key';
            Description = 'Api Key to be used in requests to Bing Maps services.';
            ExternalName = 'bingmapsapikey';
            ExternalType = 'String';
        }
        field(188; GenerateAlertsForErrors; Boolean)
        {
            Caption = 'Generate Alerts For Errors';
            Description = 'Indicates whether alerts will be generated for errors.';
            ExternalName = 'generatealertsforerrors';
            ExternalType = 'Boolean';
        }
        field(189; GenerateAlertsForInformation; Boolean)
        {
            Caption = 'Generate Alerts For Information';
            Description = 'Indicates whether alerts will be generated for information.';
            ExternalName = 'generatealertsforinformation';
            ExternalType = 'Boolean';
        }
        field(190; GenerateAlertsForWarnings; Boolean)
        {
            Caption = 'Generate Alerts For Warnings';
            Description = 'Indicates whether alerts will be generated for warnings.';
            ExternalName = 'generatealertsforwarnings';
            ExternalType = 'Boolean';
        }
        field(191; NotifyMailboxOwnerOfEmailServe; Boolean)
        {
            Caption = 'Notify Mailbox Owner Of Email Server Level Alerts';
            Description = 'Indicates whether mailbox owners will be notified of email server profile level alerts.';
            ExternalName = 'notifymailboxownerofemailserverlevelalerts';
            ExternalType = 'Boolean';
        }
        field(192; MaximumActiveBusinessProcessFl; Integer)
        {
            Caption = 'Maximum active business process flows per entity';
            Description = 'Maximum number of active business process flows allowed per entity';
            ExternalName = 'maximumactivebusinessprocessflowsallowedperentity';
            ExternalType = 'Integer';
            MinValue = 1;
        }
        field(193; EntityImageId; Guid)
        {
            Caption = 'Entity Image Id';
            Description = 'For internal use only.';
            ExternalAccess = Read;
            ExternalName = 'entityimageid';
            ExternalType = 'Uniqueidentifier';
        }
        field(194; AllowUsersSeeAppdownloadMessag; Boolean)
        {
            Caption = 'Allow the showing tablet application notification bars in a browser.';
            Description = 'Indicates whether the showing tablet application notification bars in a browser is allowed.';
            ExternalName = 'allowusersseeappdownloadmessage';
            ExternalType = 'Boolean';
        }
        field(195; SignupOutlookDownloadFWLink; Text[200])
        {
            Caption = 'CRMForOutlookDownloadURL';
            Description = 'CRM for Outlook Download URL';
            ExternalName = 'signupoutlookdownloadfwlink';
            ExternalType = 'String';
        }
        field(196; CascadeStatusUpdate; Boolean)
        {
            Caption = 'Cascade Status Update';
            Description = 'Flag to cascade Update on incident.';
            ExternalName = 'cascadestatusupdate';
            ExternalType = 'Boolean';
        }
        field(197; RestrictStatusUpdate; Boolean)
        {
            Caption = 'Restrict Status Update';
            Description = 'Flag to restrict Update on incident.';
            ExternalName = 'restrictstatusupdate';
            ExternalType = 'Boolean';
        }
        field(198; SuppressSLA; Boolean)
        {
            Caption = 'Is SLA suppressed';
            Description = 'Indicates whether SLA is suppressed.';
            ExternalName = 'suppresssla';
            ExternalType = 'Boolean';
        }
        field(199; SocialInsightsTermsAccepted; Boolean)
        {
            Caption = 'Social Insights Terms of Use';
            Description = 'Flag for whether the organization has accepted the Social Insights terms of use.';
            ExternalAccess = Modify;
            ExternalName = 'socialinsightstermsaccepted';
            ExternalType = 'Boolean';
        }
        field(200; SocialInsightsInstance; Text[250])
        {
            Caption = 'Social Insights instance identifier';
            Description = 'Identifier for the Social Insights instance for the organization.';
            ExternalName = 'socialinsightsinstance';
            ExternalType = 'String';
        }
        field(201; DisableSocialCare; Boolean)
        {
            Caption = 'Is Social Care disabled';
            Description = 'Indicates whether Social Care is disabled.';
            ExternalName = 'disablesocialcare';
            ExternalType = 'Boolean';
        }
        field(202; MaxProductsInBundle; Integer)
        {
            Caption = 'Bundle Item Limit';
            Description = 'Restrict the maximum no of items in a bundle';
            ExternalName = 'maxproductsinbundle';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(203; UseInbuiltRuleForDefaultPricel; Boolean)
        {
            Caption = 'Use Inbuilt Rule For Default Pricelist Selection';
            Description = 'Flag indicates whether to Use Inbuilt Rule For DefaultPricelist.';
            ExternalName = 'useinbuiltrulefordefaultpricelistselection';
            ExternalType = 'Boolean';
        }
        field(204; OOBPriceCalculationEnabled; Boolean)
        {
            Caption = 'Enable OOB Price calculation';
            Description = 'Enable OOB pricing calculation logic for Opportunity, Quote, Order and Invoice entities.';
            ExternalName = 'oobpricecalculationenabled';
            ExternalType = 'Boolean';
        }
        field(205; IsHierarchicalSecurityModelEna; Boolean)
        {
            Caption = 'Enable Hierarchical Security Model';
            Description = 'Enable Hierarchical Security Model';
            ExternalName = 'ishierarchicalsecuritymodelenabled';
            ExternalType = 'Boolean';
        }
        field(206; MaximumDynamicPropertiesAllowe; Integer)
        {
            Caption = 'Product Properties Item Limit';
            Description = 'Restrict the maximum number of product properties for a product family/bundle';
            ExternalName = 'maximumdynamicpropertiesallowed';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(207; UsePositionHierarchy; Boolean)
        {
            Caption = 'Use position hierarchy';
            Description = 'Use position hierarchy';
            ExternalName = 'usepositionhierarchy';
            ExternalType = 'Boolean';
        }
        field(208; MaxDepthForHierarchicalSecurit; Integer)
        {
            Caption = 'Maximum depth for hierarchy security propagation.';
            Description = 'Maximum depth for hierarchy security propagation.';
            ExternalName = 'maxdepthforhierarchicalsecuritymodel';
            ExternalType = 'Integer';
        }
        field(209; SlaPauseStates; Text[250])
        {
            Caption = 'SLA pause states';
            Description = 'Contains the on hold case status values.';
            ExternalName = 'slapausestates';
            ExternalType = 'String';
        }
        field(210; SocialInsightsEnabled; Boolean)
        {
            Caption = 'Social Insights Enabled';
            Description = 'Flag for whether the organization is using Social Insights.';
            ExternalAccess = Modify;
            ExternalName = 'socialinsightsenabled';
            ExternalType = 'Boolean';
        }
        field(211; IsAppointmentAttachmentSyncEna; Boolean)
        {
            Caption = 'Is Attachment Sync Enabled';
            Description = 'Enable or disable attachments sync for outlook and exchange.';
            ExternalName = 'isappointmentattachmentsyncenabled';
            ExternalType = 'Boolean';
        }
        field(212; IsAssignedTasksSyncEnabled; Boolean)
        {
            Caption = 'Is Assigned Tasks Sync Enabled';
            Description = 'Enable or disable assigned tasks sync for outlook and exchange.';
            ExternalName = 'isassignedtaskssyncenabled';
            ExternalType = 'Boolean';
        }
        field(213; IsContactMailingAddressSyncEna; Boolean)
        {
            Caption = 'Is Mailing Address Sync Enabled';
            Description = 'Enable or disable mailing address sync for outlook and exchange.';
            ExternalName = 'iscontactmailingaddresssyncenabled';
            ExternalType = 'Boolean';
        }
        field(214; MaxSupportedInternetExplorerVe; Integer)
        {
            Caption = 'Max supported IE version';
            Description = 'The maximum version of IE to run browser emulation for in Outlook client';
            ExternalAccess = Read;
            ExternalName = 'maxsupportedinternetexplorerversion';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(215; GlobalHelpUrl; Text[250])
        {
            Caption = 'Global Help URL.';
            Description = 'URL for the web page global help.';
            ExternalName = 'globalhelpurl';
            ExternalType = 'String';
        }
        field(216; GlobalHelpUrlEnabled; Boolean)
        {
            Caption = 'Is Customizable Global Help enabled';
            Description = 'Indicates whether the customizable global help is enabled.';
            ExternalName = 'globalhelpurlenabled';
            ExternalType = 'Boolean';
        }
        field(217; GlobalAppendUrlParametersEnabl; Boolean)
        {
            Caption = 'Is AppendUrl Parameters enabled';
            Description = 'Indicates whether the append URL parameters is enabled.';
            ExternalName = 'globalappendurlparametersenabled';
            ExternalType = 'Boolean';
        }
        field(218; KMSettings; Text[250])
        {
            Caption = 'Knowledge Management Settings';
            Description = 'XML string containing the Knowledge Management settings that are applied in Knowledge Management Wizard.';
            ExternalName = 'kmsettings';
            ExternalType = 'String';
        }
        field(219; MobileClientMashupEnabled; Boolean)
        {
            Caption = 'Is Mobile Client Mashup enabled';
            Description = 'Indicates whether the mobile client mashup is enabled.';
            ExternalName = 'mobileclientmashupenabled';
            ExternalType = 'Boolean';
        }
        field(220; CreateProductsWithoutParentInA; Boolean)
        {
            Caption = 'Enable Active Initial Product State';
            Description = 'Enable Initial state of newly created products to be Active instead of Draft';
            ExternalName = 'createproductswithoutparentinactivestate';
            ExternalType = 'Boolean';
        }
        field(221; IsMailboxInactiveBackoffEnable; Boolean)
        {
            Caption = 'Is Mailbox Keep Alive Enabled';
            Description = 'Enable or disable mailbox keep alive for Server Side Sync.';
            ExternalName = 'ismailboxinactivebackoffenabled';
            ExternalType = 'Boolean';
        }
        field(222; IsFullTextSearchEnabled; Boolean)
        {
            Caption = 'Enable Full-text search for Quick Find';
            Description = 'Indicates whether full-text search for Quick Find entities should be enabled for the organization.';
            ExternalName = 'isfulltextsearchenabled';
            ExternalType = 'Boolean';
        }
        field(223; EnforceReadOnlyPlugins; Boolean)
        {
            Caption = 'Organization setting to enforce read only plugins.';
            Description = 'Organization setting to enforce read only plugins.';
            ExternalName = 'enforcereadonlyplugins';
            ExternalType = 'Boolean';
        }
        field(224; SharePointDeploymentType; Option)
        {
            Caption = 'Choose SharePoint Deployment Type';
            Description = 'Indicates which SharePoint deployment type is configured for Server to Server. (Online or On-Premises)';
            ExternalName = 'sharepointdeploymenttype';
            ExternalType = 'Picklist';
            InitValue = Online;
            OptionCaption = 'Online,On-Premises';
            OptionOrdinalValues = 0, 1;
            OptionMembers = Online,"On-Premises";
        }
        field(225; DefaultThemeData; BLOB)
        {
            Caption = 'Default Theme Data';
            Description = 'Default theme data for the organization.';
            ExternalName = 'defaultthemedata';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(226; IsFolderBasedTrackingEnabled; Boolean)
        {
            Caption = 'Is Folder Based Tracking Enabled';
            Description = 'Enable or disable folder based tracking for Server Side Sync.';
            ExternalName = 'isfolderbasedtrackingenabled';
            ExternalType = 'Boolean';
        }
        field(227; WebResourceHash; Text[100])
        {
            Caption = 'Web resource hash';
            Description = 'Hash value of web resources.';
            ExternalName = 'webresourcehash';
            ExternalType = 'String';
        }
        field(228; ExpireChangeTrackingInDays; Integer)
        {
            Caption = 'Days to Expire Change Tracking Deleted Records';
            Description = 'Maximum number of days to keep change tracking deleted records';
            ExternalName = 'expirechangetrackingindays';
            ExternalType = 'Integer';
            MaxValue = 365;
            MinValue = 0;
        }
        field(229; MaxFolderBasedTrackingMappings; Integer)
        {
            Caption = 'Max Folder Based Tracking Mappings';
            Description = 'Maximum number of Folder Based Tracking mappings user can add';
            ExternalName = 'maxfolderbasedtrackingmappings';
            ExternalType = 'Integer';
            MaxValue = 25;
            MinValue = 1;
        }
        field(230; PrivacyStatementUrl; Text[250])
        {
            Caption = 'Privacy Statement URL';
            Description = 'Privacy Statement URL';
            ExternalName = 'privacystatementurl';
            ExternalType = 'String';
        }
        field(231; PluginTraceLogSetting; Option)
        {
            Caption = 'Plug-in Trace Log Setting';
            Description = 'Plug-in Trace Log Setting for the Organization.';
            ExternalName = 'plugintracelogsetting';
            ExternalType = 'Picklist';
            InitValue = Off;
            OptionCaption = 'Off,Exception,All';
            OptionOrdinalValues = 0, 1, 2;
            OptionMembers = Off,Exception,All;
        }
        field(232; IsMailboxForcedUnlockingEnable; Boolean)
        {
            Caption = 'Is Mailbox Forced Unlocking Enabled';
            Description = 'Enable or disable forced unlocking for Server Side Sync mailboxes.';
            ExternalName = 'ismailboxforcedunlockingenabled';
            ExternalType = 'Boolean';
        }
        field(233; MailboxIntermittentIssueMinRan; Integer)
        {
            Caption = 'Lower Threshold For Mailbox Intermittent Issue';
            Description = 'Lower Threshold For Mailbox Intermittent Issue.';
            ExternalName = 'mailboxintermittentissueminrange';
            ExternalType = 'Integer';
        }
        field(234; MailboxPermanentIssueMinRange; Integer)
        {
            Caption = 'Lower Threshold For Mailbox Permanent Issue.';
            Description = 'Lower Threshold For Mailbox Permanent Issue.';
            ExternalName = 'mailboxpermanentissueminrange';
            ExternalType = 'Integer';
        }
        field(235; HighContrastThemeData; BLOB)
        {
            Caption = 'High contrast Theme Data';
            Description = 'High contrast theme data for the organization.';
            ExternalName = 'highcontrastthemedata';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(236; DelegatedAdminUserId; Guid)
        {
            Caption = 'Delegated Admin';
            Description = 'Unique identifier of the delegated admin user for the organization.';
            ExternalAccess = Insert;
            ExternalName = 'delegatedadminuserid';
            ExternalType = 'Uniqueidentifier';
        }
        field(237; IsEmailServerProfileContentFil; Boolean)
        {
            Caption = 'Is Email Server Profile Content Filtering Enabled';
            Description = 'Enable Email Server Profile content filtering';
            ExternalName = 'isemailserverprofilecontentfilteringenabled';
            ExternalType = 'Boolean';
        }
        field(238; IsDelegateAccessEnabled; Boolean)
        {
            Caption = 'Is Delegation Access Enabled';
            Description = 'Enable Delegation Access content';
            ExternalName = 'isdelegateaccessenabled';
            ExternalType = 'Boolean';
        }
        field(239; DisplayNavigationTour; Boolean)
        {
            Caption = 'Display Navigation Tour';
            Description = 'Indicates whether or not navigation tour is displayed.';
            ExternalName = 'displaynavigationtour';
            ExternalType = 'Boolean';
        }
        field(240; UseLegacyRendering; Boolean)
        {
            Caption = 'Legacy Form Rendering';
            Description = 'Select whether to use legacy form rendering.';
            ExternalName = 'uselegacyrendering';
            ExternalType = 'Boolean';
        }
    }

    keys
    {
        key(Key1; OrganizationId)
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

