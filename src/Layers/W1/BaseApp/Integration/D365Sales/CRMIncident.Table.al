// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5349 "CRM Incident"
{
    // Dynamics CRM Version: 7.1.0.2040

    Caption = 'CRM Incident';
    Description = 'Service request case associated with a contract.';
    ExternalName = 'incident';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; IncidentId; Guid)
        {
            Caption = 'Case';
            Description = 'Unique identifier of the case.';
            ExternalAccess = Insert;
            ExternalName = 'incidentid';
            ExternalType = 'Uniqueidentifier';
        }
        field(2; OwningBusinessUnit; Guid)
        {
            Caption = 'Owning Business Unit';
            Description = 'Unique identifier of the business unit that owns the case.';
            ExternalAccess = Read;
            ExternalName = 'owningbusinessunit';
            ExternalType = 'Lookup';
            TableRelation = "CRM Businessunit".BusinessUnitId;
        }
        field(3; ContractId; Guid)
        {
            Caption = 'Contract';
            Description = 'Choose the service contract that the case should be logged under to make sure the customer is eligible for support services.';
            ExternalName = 'contractid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Contract".ContractId;
        }
        field(4; OwningUser; Guid)
        {
            Caption = 'Owning User';
            Description = 'Unique identifier of the user who owns the case.';
            ExternalAccess = Read;
            ExternalName = 'owninguser';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(5; ActualServiceUnits; Integer)
        {
            Caption = 'Actual Service Units';
            Description = 'Type the number of service units that were actually required to resolve the case.';
            ExternalName = 'actualserviceunits';
            ExternalType = 'Integer';
            MaxValue = 1000000000;
            MinValue = 0;
        }
        field(6; CaseOriginCode; Option)
        {
            Caption = 'Origin';
            Description = 'Select how contact about the case was originated, such as email, phone, or web, for use in reporting and analysis.';
            ExternalName = 'caseorigincode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Phone,Email,Web,Facebook,Twitter';
            OptionOrdinalValues = -1, 1, 2, 3, 2483, 3986;
            OptionMembers = " ",Phone,Email,Web,Facebook,Twitter;
        }
        field(7; BilledServiceUnits; Integer)
        {
            Caption = 'Billed Service Units';
            Description = 'Type the number of service units that were billed to the customer for the case.';
            ExternalName = 'billedserviceunits';
            ExternalType = 'Integer';
            MaxValue = 1000000000;
            MinValue = 0;
        }
        field(8; CaseTypeCode; Option)
        {
            Caption = 'Case Type';
            Description = 'Select the type of case to identify the incident for use in case routing and analysis.';
            ExternalName = 'casetypecode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Question,Problem,Request';
            OptionOrdinalValues = -1, 1, 2, 3;
            OptionMembers = " ",Question,Problem,Request;
        }
        field(9; ProductSerialNumber; Text[100])
        {
            Caption = 'Serial Number';
            Description = 'Type the serial number of the product that is associated with this case, so that the number of cases per product can be reported.';
            ExternalName = 'productserialnumber';
            ExternalType = 'String';
        }
        field(10; Title; Text[200])
        {
            Caption = 'Case Title';
            Description = 'Type a subject or descriptive name, such as the request, issue, or company name, to identify the case in Microsoft Dynamics CRM views.';
            ExternalName = 'title';
            ExternalType = 'String';
        }
        field(11; ProductId; Guid)
        {
            Caption = 'Product';
            Description = 'Choose the product associated with the case to identify warranty, service, or other product issues and be able to report the number of incidents for each product.';
            ExternalName = 'productid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Product".ProductId;
        }
        field(12; ContractServiceLevelCode; Option)
        {
            Caption = 'Service Level';
            Description = 'Select the service level for the case to make sure the case is handled correctly.';
            ExternalName = 'contractservicelevelcode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Gold,Silver,Bronze';
            OptionOrdinalValues = -1, 1, 2, 3;
            OptionMembers = " ",Gold,Silver,Bronze;
        }
        field(13; AccountId; Guid)
        {
            Caption = 'Account';
            Description = 'Unique identifier of the account with which the case is associated.';
            ExternalAccess = Read;
            ExternalName = 'accountid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Account".AccountId;
        }
        field(14; Description; BLOB)
        {
            Caption = 'Description';
            Description = 'Type additional information to describe the case to assist the service team in reaching a resolution.';
            ExternalName = 'description';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(15; ContactId; Guid)
        {
            Caption = 'Contact';
            Description = 'Unique identifier of the contact associated with the case.';
            ExternalAccess = Read;
            ExternalName = 'contactid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Contact".ContactId;
        }
        field(16; IsDecrementing; Boolean)
        {
            Caption = 'Decrementing';
            Description = 'For system use only.';
            ExternalName = 'isdecrementing';
            ExternalType = 'Boolean';
        }
        field(17; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            Description = 'Shows the date and time when the record was created. The date and time are displayed in the time zone selected in Microsoft Dynamics CRM options.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(18; TicketNumber; Text[100])
        {
            Caption = 'Case Number';
            Description = 'Shows the case number for customer reference and searching capabilities. This cannot be modified.';
            ExternalAccess = Insert;
            ExternalName = 'ticketnumber';
            ExternalType = 'String';
        }
        field(19; PriorityCode; Option)
        {
            Caption = 'Priority';
            Description = 'Select the priority so that preferred customers or critical issues are handled quickly.';
            ExternalName = 'prioritycode';
            ExternalType = 'Picklist';
            InitValue = Normal;
            OptionCaption = 'High,Normal,Low';
            OptionOrdinalValues = 1, 2, 3;
            OptionMembers = High,Normal,Low;
        }
        field(20; CustomerSatisfactionCode; Option)
        {
            Caption = 'Satisfaction';
            Description = 'Select the customer''s level of satisfaction with the handling and resolution of the case.';
            ExternalName = 'customersatisfactioncode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Very Satisfied,Satisfied,Neutral,Dissatisfied,Very Dissatisfied';
            OptionOrdinalValues = -1, 5, 4, 3, 2, 1;
            OptionMembers = " ",VerySatisfied,Satisfied,Neutral,Dissatisfied,VeryDissatisfied;
        }
        field(21; IncidentStageCode; Option)
        {
            Caption = 'Case Stage';
            Description = 'Select the current stage of the service process for the case to assist service team members when they review or transfer a case.';
            ExternalName = 'incidentstagecode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(22; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            Description = 'Shows the date and time when the record was last updated. The date and time are displayed in the time zone selected in Microsoft Dynamics CRM options.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
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
        field(24; FollowupBy; Date)
        {
            Caption = 'Follow Up By';
            Description = 'Enter the date by which a customer service representative has to follow up with the customer on this case.';
            ExternalName = 'followupby';
            ExternalType = 'DateTime';
        }
        field(25; ModifiedBy; Guid)
        {
            Caption = 'Modified By';
            Description = 'Shows who last updated the record.';
            ExternalAccess = Read;
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(26; VersionNumber; BigInteger)
        {
            Caption = 'Version Number';
            Description = 'Version number of the case.';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(27; StateCode; Option)
        {
            Caption = 'Status';
            Description = 'Shows whether the case is active, resolved, or canceled. Resolved and canceled cases are read-only and can''t be edited unless they are reactivated.';
            ExternalAccess = Modify;
            ExternalName = 'statecode';
            ExternalType = 'State';
            InitValue = Active;
            OptionCaption = 'Active,Resolved,Canceled';
            OptionOrdinalValues = 0, 1, 2;
            OptionMembers = Active,Resolved,Canceled;
        }
        field(28; SeverityCode; Option)
        {
            Caption = 'Severity';
            Description = 'Select the severity of this case to indicate the incident''s impact on the customer''s business.';
            ExternalName = 'severitycode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(29; StatusCode; Option)
        {
            Caption = 'Status Reason';
            Description = 'Select the case''s status.';
            ExternalName = 'statuscode';
            ExternalType = 'Status';
            InitValue = " ";
            OptionCaption = ' ,Problem Solved,Information Provided,Canceled,Merged,In Progress,On Hold,Waiting for Details,Researching';
            OptionOrdinalValues = -1, 5, 1000, 6, 2000, 1, 2, 3, 4;
            OptionMembers = " ",ProblemSolved,InformationProvided,Canceled,Merged,InProgress,OnHold,WaitingforDetails,Researching;
        }
        field(30; ResponsibleContactId; Guid)
        {
            Caption = 'Responsible Contact';
            Description = 'Choose an additional customer contact who can also help resolve the case.';
            ExternalName = 'responsiblecontactid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Contact".ContactId;
        }
        field(31; AccountIdName; Text[160])
        {
            CalcFormula = lookup("CRM Account".Name where(AccountId = field(AccountId)));
            Caption = 'AccountIdName';
            ExternalAccess = Read;
            ExternalName = 'accountidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(32; ContactIdName; Text[160])
        {
            CalcFormula = lookup("CRM Contact".FullName where(ContactId = field(ContactId)));
            Caption = 'ContactIdName';
            ExternalAccess = Read;
            ExternalName = 'contactidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(33; ResponsibleContactIdName; Text[160])
        {
            CalcFormula = lookup("CRM Contact".FullName where(ContactId = field(ResponsibleContactId)));
            Caption = 'ResponsibleContactIdName';
            ExternalAccess = Read;
            ExternalName = 'responsiblecontactidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(34; ContractIdName; Text[100])
        {
            CalcFormula = lookup("CRM Contract".Title where(ContractId = field(ContractId)));
            Caption = 'ContractIdName';
            ExternalAccess = Read;
            ExternalName = 'contractidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(35; ProductIdName; Text[100])
        {
            CalcFormula = lookup("CRM Product".Name where(ProductId = field(ProductId)));
            Caption = 'ProductIdName';
            ExternalAccess = Read;
            ExternalName = 'productidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(36; CreatedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedBy)));
            Caption = 'CreatedByName';
            ExternalAccess = Read;
            ExternalName = 'createdbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(37; ModifiedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedBy)));
            Caption = 'ModifiedByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(38; CustomerId; Guid)
        {
            Caption = 'Customer';
            Description = 'Select the customer account or contact to provide a quick link to additional customer details, such as account information, activities, and opportunities.';
            ExternalName = 'customerid';
            ExternalType = 'Customer';
            TableRelation = if (CustomerIdType = const(account)) "CRM Account".AccountId
            else
            if (CustomerIdType = const(contact)) "CRM Contact".ContactId;
        }
        field(39; CustomerIdType; Option)
        {
            Caption = 'Customer Type';
            ExternalName = 'customeridtype';
            ExternalType = 'EntityName';
            OptionCaption = ' ,account,contact';
            OptionMembers = " ",account,contact;
        }
        field(40; OwnerId; Guid)
        {
            Caption = 'Owner';
            Description = 'Enter the user or team who is assigned to manage the record. This field is updated every time the record is assigned to a different user.';
            ExternalName = 'ownerid';
            ExternalType = 'Owner';
            TableRelation = if (OwnerIdType = const(systemuser)) "CRM Systemuser".SystemUserId
            else
            if (OwnerIdType = const(team)) "CRM Team".TeamId;
        }
        field(41; OwnerIdType; Option)
        {
            Caption = 'OwnerIdType';
            ExternalName = 'owneridtype';
            ExternalType = 'EntityName';
            OptionCaption = ' ,systemuser,team';
            OptionMembers = " ",systemuser,team;
        }
        field(42; TimeZoneRuleVersionNumber; Integer)
        {
            Caption = 'Time Zone Rule Version Number';
            Description = 'For internal use only.';
            ExternalName = 'timezoneruleversionnumber';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(43; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            Description = 'Unique identifier of the data import or data migration that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
        }
        field(44; UTCConversionTimeZoneCode; Integer)
        {
            Caption = 'UTC Conversion Time Zone Code';
            Description = 'Time zone code that was in use when the record was created.';
            ExternalName = 'utcconversiontimezonecode';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(45; OverriddenCreatedOn; Date)
        {
            Caption = 'Record Created On';
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
        }
        field(46; CreatedOnBehalfBy; Guid)
        {
            Caption = 'Created By (Delegate)';
            Description = 'Shows who created the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(47; CreatedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            Caption = 'CreatedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(48; ModifiedOnBehalfBy; Guid)
        {
            Caption = 'Modified By (Delegate)';
            Description = 'Shows who last updated the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(49; ModifiedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedOnBehalfBy)));
            Caption = 'ModifiedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(50; OwningTeam; Guid)
        {
            Caption = 'Owning Team';
            Description = 'Unique identifier of the team who owns the case.';
            ExternalAccess = Read;
            ExternalName = 'owningteam';
            ExternalType = 'Lookup';
            TableRelation = "CRM Team".TeamId;
        }
        field(51; TransactionCurrencyId; Guid)
        {
            Caption = 'Currency';
            Description = 'Choose the local currency for the record to make sure budgets are reported in the correct currency.';
            ExternalName = 'transactioncurrencyid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Transactioncurrency".TransactionCurrencyId;
        }
        field(52; TransactionCurrencyIdName; Text[100])
        {
            CalcFormula = lookup("CRM Transactioncurrency".CurrencyName where(TransactionCurrencyId = field(TransactionCurrencyId)));
            Caption = 'TransactionCurrencyIdName';
            ExternalAccess = Read;
            ExternalName = 'transactioncurrencyidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(53; ExchangeRate; Decimal)
        {
            Caption = 'Exchange Rate';
            Description = 'Shows the conversion rate of the record''s currency. The exchange rate is used to convert all money fields in the record from the local currency to the system''s default currency.';
            ExternalAccess = Read;
            ExternalName = 'exchangerate';
            ExternalType = 'Decimal';
        }
        field(54; ServiceStage; Option)
        {
            Caption = 'Service Stage';
            Description = 'Select the stage, in the case resolution process, that the case is in.';
            ExternalName = 'servicestage';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Identify,Research,Resolve';
            OptionOrdinalValues = -1, 0, 1, 2;
            OptionMembers = " ",Identify,Research,Resolve;
        }
        field(55; ExistingCase; Guid)
        {
            Caption = 'Existing Case';
            Description = 'Select an existing case for the customer that has been populated. For internal use only.';
            ExternalName = 'existingcase';
            ExternalType = 'Lookup';
            TableRelation = "CRM Incident".IncidentId;
        }
        field(56; StageId; Guid)
        {
            Caption = 'Process Stage';
            Description = 'Shows the ID of the stage.';
            ExternalName = 'stageid';
            ExternalType = 'Uniqueidentifier';
        }
        field(57; ProcessId; Guid)
        {
            Caption = 'Process';
            Description = 'Shows the ID of the process.';
            ExternalName = 'processid';
            ExternalType = 'Uniqueidentifier';
        }
        field(58; EntityImageId; Guid)
        {
            Caption = 'Entity Image Id';
            Description = 'For internal use only.';
            ExternalAccess = Read;
            ExternalName = 'entityimageid';
            ExternalType = 'Uniqueidentifier';
        }
        field(59; CheckEmail; Boolean)
        {
            Caption = 'Check Email';
            Description = 'This attribute is used for Sample Service Business Processes.';
            ExternalName = 'checkemail';
            ExternalType = 'Boolean';
        }
        field(60; ActivitiesComplete; Boolean)
        {
            Caption = 'Activities Complete';
            Description = 'This attribute is used for Sample Service Business Processes.';
            ExternalName = 'activitiescomplete';
            ExternalType = 'Boolean';
        }
        field(61; FollowUpTaskCreated; Boolean)
        {
            Caption = 'Follow up Task Created';
            Description = 'This attribute is used for Sample Service Business Processes.';
            ExternalName = 'followuptaskcreated';
            ExternalType = 'Boolean';
        }
        field(62; NumberOfChildIncidents; Integer)
        {
            Caption = 'Child Cases';
            Description = 'Number of child incidents associated with the incident.';
            ExternalAccess = Read;
            ExternalName = 'numberofchildincidents';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(63; MessageTypeCode; Option)
        {
            Caption = 'Received As';
            Description = 'Shows whether the post originated as a public or private message.';
            ExternalAccess = Insert;
            ExternalName = 'messagetypecode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Public Message,Private Message';
            OptionOrdinalValues = -1, 0, 1;
            OptionMembers = " ",PublicMessage,PrivateMessage;
        }
        field(64; BlockedProfile; Boolean)
        {
            Caption = 'Blocked Profile';
            Description = 'Details whether the profile is blocked or not.';
            ExternalAccess = Insert;
            ExternalName = 'blockedprofile';
            ExternalType = 'Boolean';
        }
        field(65; MasterId; Guid)
        {
            Caption = 'Master Case';
            Description = 'Choose the primary case the current case was merged into.';
            ExternalName = 'masterid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Incident".IncidentId;
        }
        field(66; MasterIdName; Text[200])
        {
            CalcFormula = lookup("CRM Incident".Title where(IncidentId = field(MasterId)));
            Caption = 'MasterIdName';
            ExternalAccess = Read;
            ExternalName = 'masteridname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(67; TraversedPath; Text[250])
        {
            Caption = 'Traversed Path';
            Description = 'For internal use only.';
            ExternalName = 'traversedpath';
            ExternalType = 'String';
        }
        field(68; ParentCaseId; Guid)
        {
            Caption = 'Parent Case';
            Description = 'Choose the parent case for a case.';
            ExternalName = 'parentcaseid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Incident".IncidentId;
        }
        field(69; DecrementEntitlementTerm; Boolean)
        {
            Caption = 'Decrement Entitlement Terms';
            Description = 'Shows whether terms of the associated entitlement should be decremented or not.';
            ExternalName = 'decremententitlementterm';
            ExternalType = 'Boolean';
        }
        field(70; ParentCaseIdName; Text[200])
        {
            CalcFormula = lookup("CRM Incident".Title where(IncidentId = field(ParentCaseId)));
            Caption = 'ParentCaseIdName';
            ExternalAccess = Read;
            ExternalName = 'parentcaseidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(71; SentimentValue; Decimal)
        {
            Caption = 'Sentiment Value';
            Description = 'Value derived after assessing words commonly associated with a negative, neutral, or positive sentiment that occurs in a social post. Sentiment information can also be reported as numeric values.';
            ExternalAccess = Insert;
            ExternalName = 'sentimentvalue';
            ExternalType = 'Double';
        }
        field(72; InfluenceScore; Decimal)
        {
            Caption = 'Influence Score';
            Description = 'Will contain the Influencer score coming from NetBreeze.';
            ExternalAccess = Insert;
            ExternalName = 'influencescore';
            ExternalType = 'Double';
        }
        field(73; Merged; Boolean)
        {
            Caption = 'Internal Use Only';
            Description = 'Tells whether the incident has been merged with another incident.';
            ExternalAccess = Read;
            ExternalName = 'merged';
            ExternalType = 'Boolean';
        }
        field(74; RouteCase; Boolean)
        {
            Caption = 'Route Case';
            Description = 'Tells whether the incident has been routed to queue or not.';
            ExternalAccess = Insert;
            ExternalName = 'routecase';
            ExternalType = 'Boolean';
        }
        field(75; ResolveBy; DateTime)
        {
            Caption = 'Resolve By';
            Description = 'Enter the date by when the case must be resolved.';
            ExternalName = 'resolveby';
            ExternalType = 'DateTime';
        }
        field(76; ResponseBy; DateTime)
        {
            Caption = 'First Response By';
            Description = 'For internal use only.';
            ExternalName = 'responseby';
            ExternalType = 'DateTime';
        }
        field(77; CustomerContacted; Boolean)
        {
            Caption = 'Customer Contacted';
            Description = 'Tells whether customer service representative has contacted the customer or not.';
            ExternalAccess = Insert;
            ExternalName = 'customercontacted';
            ExternalType = 'Boolean';
        }
        field(78; IsEscalated; Boolean)
        {
            Caption = 'IsEscalated';
            Description = 'Indicates if the case has been escalated.';
            ExternalName = 'isescalated';
            ExternalType = 'Boolean';
        }
        field(79; EscalatedOn; DateTime)
        {
            Caption = 'Escalated On';
            Description = 'Indicates the date and time when the case was escalated.';
            ExternalAccess = Read;
            ExternalName = 'escalatedon';
            ExternalType = 'DateTime';
        }
        field(80; PrimaryContactId; Guid)
        {
            Caption = 'Contact';
            Description = 'Select a primary contact for this case.';
            ExternalName = 'primarycontactid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Contact".ContactId;
        }
        field(81; PrimaryContactIdName; Text[160])
        {
            CalcFormula = lookup("CRM Contact".FullName where(ContactId = field(PrimaryContactId)));
            Caption = 'PrimaryContactIdName';
            ExternalAccess = Read;
            ExternalName = 'primarycontactidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(82; FirstResponseSent; Boolean)
        {
            Caption = 'First Response Sent';
            Description = 'Indicates if the first response has been sent.';
            ExternalName = 'firstresponsesent';
            ExternalType = 'Boolean';
        }
        field(83; FirstResponseSLAStatus; Option)
        {
            Caption = 'First Response SLA Status';
            Description = 'Shows the status of the initial response time for the case according to the terms of the SLA.';
            ExternalName = 'firstresponseslastatus';
            ExternalType = 'Picklist';
            InitValue = InProgress;
            OptionCaption = 'In Progress,Nearing Noncompliance,Succeeded,Noncompliant';
            OptionOrdinalValues = 1, 2, 3, 4;
            OptionMembers = InProgress,NearingNoncompliance,Succeeded,Noncompliant;
        }
        field(84; ResolveBySLAStatus; Option)
        {
            Caption = 'Resolve By SLA Status';
            Description = 'Shows the status of the resolution time for the case according to the terms of the SLA.';
            ExternalName = 'resolvebyslastatus';
            ExternalType = 'Picklist';
            InitValue = InProgress;
            OptionCaption = 'In Progress,Nearing Noncompliance,Succeeded,Noncompliant';
            OptionOrdinalValues = 1, 2, 3, 4;
            OptionMembers = InProgress,NearingNoncompliance,Succeeded,Noncompliant;
        }
        field(85; OnHoldTime; Integer)
        {
            Caption = 'On Hold Time (Minutes)';
            Description = 'Shows the duration in minutes for which the case was on hold.';
            ExternalAccess = Read;
            ExternalName = 'onholdtime';
            ExternalType = 'Integer';
        }
        field(86; LastOnHoldTime; DateTime)
        {
            Caption = 'Last On Hold Time';
            Description = 'Contains the date time stamp of the last on hold time.';
            ExternalName = 'lastonholdtime';
            ExternalType = 'DateTime';
        }
    }

    keys
    {
        key(Key1; IncidentId)
        {
            Clustered = true;
        }
        key(Key2; Title)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Title)
        {
        }
    }
}

