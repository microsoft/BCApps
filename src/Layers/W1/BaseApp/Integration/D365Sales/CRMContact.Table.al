// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Integration.Dataverse;

table 5342 "CRM Contact"
{
    // Dynamics CRM Version: 7.1.0.2040

    Caption = 'Dataverse Contact';
    Description = 'Person with whom a business unit has a relationship, such as customer, supplier, and colleague.';
    ExternalName = 'contact';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ContactId; Guid)
        {
            Caption = 'Contact';
            Description = 'Unique identifier of the contact.';
            ExternalAccess = Insert;
            ExternalName = 'contactid';
            ExternalType = 'Uniqueidentifier';
        }
        field(2; DefaultPriceLevelId; Guid)
        {
            Caption = 'Price List';
            Description = 'Choose the default price list associated with the contact to make sure the correct product prices for this customer are applied in sales opportunities, quotes, and orders.';
            ExternalName = 'defaultpricelevelid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Pricelevel".PriceLevelId;
        }
        field(3; CustomerSizeCode; Option)
        {
            Caption = 'Customer Size';
            Description = 'Select the size of the contact''s company for segmentation and reporting purposes.';
            ExternalName = 'customersizecode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(4; CustomerTypeCode; Option)
        {
            Caption = 'Relationship Type';
            Description = 'Select the category that best describes the relationship between the contact and your organization.';
            ExternalName = 'customertypecode';
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
        field(6; LeadSourceCode; Option)
        {
            Caption = 'Lead Source';
            Description = 'Select the primary marketing source that directed the contact to your organization.';
            ExternalName = 'leadsourcecode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(7; OwningBusinessUnit; Guid)
        {
            Caption = 'Owning Business Unit';
            Description = 'Unique identifier of the business unit that owns the contact.';
            ExternalAccess = Read;
            ExternalName = 'owningbusinessunit';
            ExternalType = 'Lookup';
            TableRelation = "CRM Businessunit".BusinessUnitId;
        }
        field(8; OwningUser; Guid)
        {
            Caption = 'Owning User';
            Description = 'Unique identifier of the user who owns the contact.';
            ExternalAccess = Read;
            ExternalName = 'owninguser';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(10; ShippingMethodCode; Option)
        {
            Caption = 'Shipping Method';
            Description = 'Select a shipping method for deliveries sent to this address.';
            ExternalName = 'shippingmethodcode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(11; AccountId; Guid)
        {
            Caption = 'Account';
            Description = 'Unique identifier of the account with which the contact is associated.';
            ExternalAccess = Read;
            ExternalName = 'accountid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Account".AccountId;
        }
        field(12; ParticipatesInWorkflow; Boolean)
        {
            Caption = 'Participates in Workflow';
            Description = 'Shows whether the contact participates in workflow rules.';
            ExternalName = 'participatesinworkflow';
            ExternalType = 'Boolean';
        }
        field(13; IsBackofficeCustomer; Boolean)
        {
            Caption = 'Back Office Customer';
            Description = 'Select whether the contact exists in a separate accounting or other system, such as Microsoft Dynamics GP or another ERP database, for use in integration processes.';
            ExternalName = 'isbackofficecustomer';
            ExternalType = 'Boolean';
        }
        field(14; Salutation; Text[100])
        {
            Caption = 'Salutation';
            Description = 'Type the salutation of the contact to make sure the contact is addressed correctly in sales calls, email messages, and marketing campaigns.';
            ExternalName = 'salutation';
            ExternalType = 'String';
        }
        field(15; JobTitle; Text[100])
        {
            Caption = 'Job Title';
            Description = 'Type the job title of the contact to make sure the contact is addressed correctly in sales calls, email, and marketing campaigns.';
            ExternalName = 'jobtitle';
            ExternalType = 'String';
        }
        field(16; FirstName; Text[50])
        {
            Caption = 'First Name';
            Description = 'Type the contact''s first name to make sure the contact is addressed correctly in sales calls, email, and marketing campaigns.';
            ExternalName = 'firstname';
            ExternalType = 'String';
        }
        field(17; Department; Text[100])
        {
            Caption = 'Department';
            Description = 'Type the department or business unit where the contact works in the parent company or business.';
            ExternalName = 'department';
            ExternalType = 'String';
        }
        field(18; NickName; Text[50])
        {
            Caption = 'Nickname';
            Description = 'Type the contact''s nickname.';
            ExternalName = 'nickname';
            ExternalType = 'String';
        }
        field(19; MiddleName; Text[50])
        {
            Caption = 'Middle Name';
            Description = 'Type the contact''s middle name or initial to make sure the contact is addressed correctly.';
            ExternalName = 'middlename';
            ExternalType = 'String';
        }
        field(20; LastName; Text[50])
        {
            Caption = 'Last Name';
            Description = 'Type the contact''s last name to make sure the contact is addressed correctly in sales calls, email, and marketing campaigns.';
            ExternalName = 'lastname';
            ExternalType = 'String';
        }
        field(21; Suffix; Text[10])
        {
            Caption = 'Suffix';
            Description = 'Type the suffix used in the contact''s name, such as Jr. or Sr. to make sure the contact is addressed correctly in sales calls, email, and marketing campaigns.';
            ExternalName = 'suffix';
            ExternalType = 'String';
        }
        field(22; YomiFirstName; Text[150])
        {
            Caption = 'Yomi First Name';
            Description = 'Type the phonetic spelling of the contact''s first name, if the name is specified in Japanese, to make sure the name is pronounced correctly in phone calls with the contact.';
            ExternalName = 'yomifirstname';
            ExternalType = 'String';
        }
        field(23; FullName; Text[160])
        {
            Caption = 'Full Name';
            Description = 'Combines and shows the contact''s first and last names so that the full name can be displayed in views and reports.';
            ExternalAccess = Read;
            ExternalName = 'fullname';
            ExternalType = 'String';
        }
        field(24; YomiMiddleName; Text[150])
        {
            Caption = 'Yomi Middle Name';
            Description = 'Type the phonetic spelling of the contact''s middle name, if the name is specified in Japanese, to make sure the name is pronounced correctly in phone calls with the contact.';
            ExternalName = 'yomimiddlename';
            ExternalType = 'String';
        }
        field(25; YomiLastName; Text[150])
        {
            Caption = 'Yomi Last Name';
            Description = 'Type the phonetic spelling of the contact''s last name, if the name is specified in Japanese, to make sure the name is pronounced correctly in phone calls with the contact.';
            ExternalName = 'yomilastname';
            ExternalType = 'String';
        }
        field(26; Anniversary; Date)
        {
            Caption = 'Anniversary';
            Description = 'Enter the date of the contact''s wedding or service anniversary for use in customer gift programs or other communications.';
            ExternalName = 'anniversary';
            ExternalType = 'DateTime';
        }
        field(27; BirthDate; Date)
        {
            Caption = 'Birthday';
            Description = 'Enter the contact''s birthday for use in customer gift programs or other communications.';
            ExternalName = 'birthdate';
            ExternalType = 'DateTime';
        }
        field(28; GovernmentId; Text[50])
        {
            Caption = 'Government';
            Description = 'Type the passport number or other government ID for the contact for use in documents or reports.';
            ExternalName = 'governmentid';
            ExternalType = 'String';
        }
        field(29; YomiFullName; Text[250])
        {
            Caption = 'Yomi Full Name';
            Description = 'Shows the combined Yomi first and last names of the contact so that the full phonetic name can be displayed in views and reports.';
            ExternalAccess = Read;
            ExternalName = 'yomifullname';
            ExternalType = 'String';
        }
        field(30; Description; BLOB)
        {
            Caption = 'Description';
            Description = 'Type additional information to describe the contact, such as an excerpt from the company''s website.';
            ExternalName = 'description';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(31; EmployeeId; Text[50])
        {
            Caption = 'Employee';
            Description = 'Type the employee ID or number for the contact for reference in orders, service cases, or other communications with the contact''s organization.';
            ExternalName = 'employeeid';
            ExternalType = 'String';
        }
        field(32; GenderCode; Option)
        {
            Caption = 'Gender';
            Description = 'Select the contact''s gender to make sure the contact is addressed correctly in sales calls, email, and marketing campaigns.';
            ExternalName = 'gendercode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Male,Female';
            OptionOrdinalValues = -1, 1, 2;
            OptionMembers = " ",Male,Female;
        }
        field(33; AnnualIncome; Decimal)
        {
            Caption = 'Annual Income';
            Description = 'Type the contact''s annual income for use in profiling and financial analysis.';
            ExternalName = 'annualincome';
            ExternalType = 'Money';
        }
        field(34; HasChildrenCode; Option)
        {
            Caption = 'Has Children';
            Description = 'Select whether the contact has any children for reference in follow-up phone calls and other communications.';
            ExternalName = 'haschildrencode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(35; EducationCode; Option)
        {
            Caption = 'Education';
            Description = 'Select the contact''s highest level of education for use in segmentation and analysis.';
            ExternalName = 'educationcode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(36; WebSiteUrl; Text[200])
        {
            Caption = 'Website';
            Description = 'Type the contact''s professional or personal website or blog URL.';
            ExtendedDatatype = URL;
            ExternalName = 'websiteurl';
            ExternalType = 'String';
        }
        field(37; FamilyStatusCode; Option)
        {
            Caption = 'Marital Status';
            Description = 'Select the marital status of the contact for reference in follow-up phone calls and other communications.';
            ExternalName = 'familystatuscode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Single,Married,Divorced,Widowed';
            OptionOrdinalValues = -1, 1, 2, 3, 4;
            OptionMembers = " ",Single,Married,Divorced,Widowed;
        }
        field(38; FtpSiteUrl; Text[200])
        {
            Caption = 'FTP Site';
            Description = 'Type the URL for the contact''s FTP site to enable users to access data and share documents.';
            ExtendedDatatype = URL;
            ExternalName = 'ftpsiteurl';
            ExternalType = 'String';
        }
        field(39; EMailAddress1; Text[100])
        {
            Caption = 'Email';
            Description = 'Type the primary email address for the contact.';
            ExtendedDatatype = EMail;
            ExternalName = 'emailaddress1';
            ExternalType = 'String';
        }
        field(40; SpousesName; Text[100])
        {
            Caption = 'Spouse/Partner Name';
            Description = 'Type the name of the contact''s spouse or partner for reference during calls, events, or other communications with the contact.';
            ExternalName = 'spousesname';
            ExternalType = 'String';
        }
        field(41; AssistantName; Text[100])
        {
            Caption = 'Assistant';
            Description = 'Type the name of the contact''s assistant.';
            ExternalName = 'assistantname';
            ExternalType = 'String';
        }
        field(42; EMailAddress2; Text[100])
        {
            Caption = 'Email Address 2';
            Description = 'Type the secondary email address for the contact.';
            ExtendedDatatype = EMail;
            ExternalName = 'emailaddress2';
            ExternalType = 'String';
        }
        field(43; AssistantPhone; Text[50])
        {
            Caption = 'Assistant Phone';
            Description = 'Type the phone number for the contact''s assistant.';
            ExternalName = 'assistantphone';
            ExternalType = 'String';
        }
        field(44; EMailAddress3; Text[100])
        {
            Caption = 'Email Address 3';
            Description = 'Type an alternate email address for the contact.';
            ExtendedDatatype = EMail;
            ExternalName = 'emailaddress3';
            ExternalType = 'String';
        }
        field(45; DoNotPhone; Boolean)
        {
            Caption = 'Do not allow Phone Calls';
            Description = 'Select whether the contact accepts phone calls. If Do Not Allow is selected, the contact will be excluded from any phone call activities distributed in marketing campaigns.';
            ExternalName = 'donotphone';
            ExternalType = 'Boolean';
        }
        field(46; ManagerName; Text[100])
        {
            Caption = 'Manager';
            Description = 'Type the name of the contact''s manager for use in escalating issues or other follow-up communications with the contact.';
            ExternalName = 'managername';
            ExternalType = 'String';
        }
        field(47; ManagerPhone; Text[50])
        {
            Caption = 'Manager Phone';
            Description = 'Type the phone number for the contact''s manager.';
            ExternalName = 'managerphone';
            ExternalType = 'String';
        }
        field(48; DoNotFax; Boolean)
        {
            Caption = 'Do not allow Faxes';
            Description = 'Select whether the contact allows faxes. If Do Not Allow is selected, the contact will be excluded from any fax activities distributed in marketing campaigns.';
            ExternalName = 'donotfax';
            ExternalType = 'Boolean';
        }
        field(49; DoNotEMail; Boolean)
        {
            Caption = 'Do not allow Emails';
            Description = 'Select whether the contact allows direct email sent from Microsoft Dynamics CRM. If Do Not Allow is selected, Microsoft Dynamics CRM will not send the email.';
            ExternalName = 'donotemail';
            ExternalType = 'Boolean';
        }
        field(50; DoNotPostalMail; Boolean)
        {
            Caption = 'Do not allow Mails';
            Description = 'Select whether the contact allows direct mail. If Do Not Allow is selected, the contact will be excluded from letter activities distributed in marketing campaigns.';
            ExternalName = 'donotpostalmail';
            ExternalType = 'Boolean';
        }
        field(51; DoNotBulkEMail; Boolean)
        {
            Caption = 'Do not allow Bulk Emails';
            Description = 'Select whether the contact accepts bulk email sent through marketing campaigns or quick campaigns. If Do Not Allow is selected, the contact can be added to marketing lists, but will be excluded from the email.';
            ExternalName = 'donotbulkemail';
            ExternalType = 'Boolean';
        }
        field(52; DoNotBulkPostalMail; Boolean)
        {
            Caption = 'Do not allow Bulk Mails';
            Description = 'Select whether the contact accepts bulk postal mail sent through marketing campaigns or quick campaigns. If Do Not Allow is selected, the contact can be added to marketing lists, but will be excluded from the letters.';
            ExternalName = 'donotbulkpostalmail';
            ExternalType = 'Boolean';
        }
        field(53; AccountRoleCode; Option)
        {
            Caption = 'Role';
            Description = 'Select the contact''s role within the company or sales process, such as decision maker, employee, or influencer.';
            ExternalName = 'accountrolecode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Decision Maker,Employee,Influencer';
            OptionOrdinalValues = -1, 1, 2, 3;
            OptionMembers = " ",DecisionMaker,Employee,Influencer;
        }
        field(54; TerritoryCode; Option)
        {
            Caption = 'Territory';
            Description = 'Select a region or territory for the contact for use in segmentation and analysis.';
            ExternalName = 'territorycode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(55; CreditLimit; Decimal)
        {
            Caption = 'Credit Limit';
            Description = 'Type the credit limit of the contact for reference when you address invoice and accounting issues with the customer.';
            ExternalName = 'creditlimit';
            ExternalType = 'Money';
        }
        field(56; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            Description = 'Shows the date and time when the record was created. The date and time are displayed in the time zone selected in Microsoft Dynamics CRM options.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(57; CreditOnHold; Boolean)
        {
            Caption = 'Credit Hold';
            Description = 'Select whether the contact is on a credit hold, for reference when addressing invoice and accounting issues.';
            ExternalName = 'creditonhold';
            ExternalType = 'Boolean';
        }
        field(58; CreatedBy; Guid)
        {
            Caption = 'Created By';
            Description = 'Shows who created the record.';
            ExternalAccess = Read;
            ExternalName = 'createdby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(59; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            Description = 'Shows the date and time when the record was last updated. The date and time are displayed in the time zone selected in Microsoft Dynamics CRM options.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
        }
        field(60; ModifiedBy; Guid)
        {
            Caption = 'Modified By';
            Description = 'Shows who last updated the record.';
            ExternalAccess = Read;
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(61; NumberOfChildren; Integer)
        {
            Caption = 'No. of Children';
            Description = 'Type the number of children the contact has for reference in follow-up phone calls and other communications.';
            ExternalName = 'numberofchildren';
            ExternalType = 'Integer';
            MaxValue = 1000000000;
            MinValue = 0;
        }
        field(62; ChildrensNames; Text[250])
        {
            Caption = 'Children''s Names';
            Description = 'Type the names of the contact''s children for reference in communications and client programs.';
            ExternalName = 'childrensnames';
            ExternalType = 'String';
        }
        field(63; VersionNumber; BigInteger)
        {
            Caption = 'Version Number';
            Description = 'Version number of the contact.';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(64; MobilePhone; Text[50])
        {
            Caption = 'Mobile Phone';
            Description = 'Type the mobile phone number for the contact.';
            ExternalName = 'mobilephone';
            ExternalType = 'String';
        }
        field(65; Pager; Text[50])
        {
            Caption = 'Pager';
            Description = 'Type the pager number for the contact.';
            ExternalName = 'pager';
            ExternalType = 'String';
        }
        field(66; Telephone1; Text[50])
        {
            Caption = 'Business Phone';
            Description = 'Type the main phone number for this contact.';
            ExternalName = 'telephone1';
            ExternalType = 'String';
        }
        field(67; Telephone2; Text[50])
        {
            Caption = 'Home Phone';
            Description = 'Type a second phone number for this contact.';
            ExternalName = 'telephone2';
            ExternalType = 'String';
        }
        field(68; Telephone3; Text[50])
        {
            Caption = 'Telephone 3';
            Description = 'Type a third phone number for this contact.';
            ExternalName = 'telephone3';
            ExternalType = 'String';
        }
        field(69; Fax; Text[50])
        {
            Caption = 'Fax';
            Description = 'Type the fax number for the contact.';
            ExternalName = 'fax';
            ExternalType = 'String';
        }
        field(70; Aging30; Decimal)
        {
            Caption = 'Aging 30';
            Description = 'For system use only.';
            ExternalAccess = Read;
            ExternalName = 'aging30';
            ExternalType = 'Money';
        }
        field(71; StateCode; Option)
        {
            Caption = 'Status';
            Description = 'Shows whether the contact is active or inactive. Inactive contacts are read-only and can''t be edited unless they are reactivated.';
            ExternalAccess = Modify;
            ExternalName = 'statecode';
            ExternalType = 'State';
            InitValue = Active;
            OptionCaption = 'Active,Inactive';
            OptionOrdinalValues = 0, 1;
            OptionMembers = Active,Inactive;
        }
        field(72; Aging60; Decimal)
        {
            Caption = 'Aging 60';
            Description = 'For system use only.';
            ExternalAccess = Read;
            ExternalName = 'aging60';
            ExternalType = 'Money';
        }
        field(73; StatusCode; Option)
        {
            Caption = 'Status Reason';
            Description = 'Select the contact''s status.';
            ExternalName = 'statuscode';
            ExternalType = 'Status';
            InitValue = " ";
            OptionCaption = ' ,Active,Inactive';
            OptionOrdinalValues = -1, 1, 2;
            OptionMembers = " ",Active,Inactive;
        }
        field(74; Aging90; Decimal)
        {
            Caption = 'Aging 90';
            Description = 'For system use only.';
            ExternalAccess = Read;
            ExternalName = 'aging90';
            ExternalType = 'Money';
        }
        field(75; ParentContactId; Guid)
        {
            Caption = 'Parent Contact';
            Description = 'Unique identifier of the parent contact.';
            ExternalAccess = Read;
            ExternalName = 'parentcontactid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Contact".ContactId;
        }
        field(76; ParentContactIdName; Text[160])
        {
            CalcFormula = lookup("CRM Contact".FullName where(ContactId = field(ParentContactId)));
            Caption = 'ParentContactIdName';
            ExternalAccess = Read;
            ExternalName = 'parentcontactidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(77; AccountIdName; Text[160])
        {
            CalcFormula = lookup("CRM Account".Name where(AccountId = field(AccountId)));
            Caption = 'AccountIdName';
            ExternalAccess = Read;
            ExternalName = 'accountidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(78; DefaultPriceLevelIdName; Text[100])
        {
            CalcFormula = lookup("CRM Pricelevel".Name where(PriceLevelId = field(DefaultPriceLevelId)));
            Caption = 'DefaultPriceLevelIdName';
            ExternalAccess = Read;
            ExternalName = 'defaultpricelevelidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(79; Address1_AddressId; Guid)
        {
            Caption = 'Address 1: ID';
            Description = 'Unique identifier for address 1.';
            ExternalName = 'address1_addressid';
            ExternalType = 'Uniqueidentifier';
        }
        field(80; Address1_AddressTypeCode; Option)
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
        field(81; Address1_Name; Text[200])
        {
            Caption = 'Address 1: Name';
            Description = 'Type a descriptive name for the primary address, such as Corporate Headquarters.';
            ExternalName = 'address1_name';
            ExternalType = 'String';
        }
        field(82; Address1_PrimaryContactName; Text[100])
        {
            Caption = 'Address 1: Primary Contact Name';
            Description = 'Type the name of the main contact at the account''s primary address.';
            ExternalName = 'address1_primarycontactname';
            ExternalType = 'String';
        }
        field(83; Address1_Line1; Text[250])
        {
            Caption = 'Address 1: Street 1';
            Description = 'Type the first line of the primary address.';
            ExternalName = 'address1_line1';
            ExternalType = 'String';
        }
        field(84; Address1_Line2; Text[250])
        {
            Caption = 'Address 1: Street 2';
            Description = 'Type the second line of the primary address.';
            ExternalName = 'address1_line2';
            ExternalType = 'String';
        }
        field(85; Address1_Line3; Text[250])
        {
            Caption = 'Address 1: Street 3';
            Description = 'Type the third line of the primary address.';
            ExternalName = 'address1_line3';
            ExternalType = 'String';
        }
        field(86; Address1_City; Text[80])
        {
            Caption = 'Address 1: City';
            Description = 'Type the city for the primary address.';
            ExternalName = 'address1_city';
            ExternalType = 'String';
        }
        field(87; Address1_StateOrProvince; Text[50])
        {
            Caption = 'Address 1: State/Province';
            Description = 'Type the state or province of the primary address.';
            ExternalName = 'address1_stateorprovince';
            ExternalType = 'String';
        }
        field(88; Address1_County; Text[50])
        {
            Caption = 'Address 1: County';
            Description = 'Type the county for the primary address.';
            ExternalName = 'address1_county';
            ExternalType = 'String';
        }
        field(89; Address1_Country; Text[80])
        {
            Caption = 'Address 1: Country/Region';
            Description = 'Type the country or region for the primary address.';
            ExternalName = 'address1_country';
            ExternalType = 'String';
        }
        field(90; Address1_PostOfficeBox; Text[20])
        {
            Caption = 'Address 1: Post Office Box';
            Description = 'Type the post office box number of the primary address.';
            ExternalName = 'address1_postofficebox';
            ExternalType = 'String';
        }
        field(91; Address1_PostalCode; Text[20])
        {
            Caption = 'Address 1: ZIP/Postal Code';
            Description = 'Type the ZIP Code or postal code for the primary address.';
            ExternalName = 'address1_postalcode';
            ExternalType = 'String';
        }
        field(92; Address1_UTCOffset; Integer)
        {
            Caption = 'Address 1: UTC Offset';
            Description = 'Select the time zone, or UTC offset, for this address so that other people can reference it when they contact someone at this address.';
            ExternalName = 'address1_utcoffset';
            ExternalType = 'Integer';
            MaxValue = 1500;
            MinValue = -1500;
        }
        field(94; Address1_UPSZone; Text[4])
        {
            Caption = 'Address 1: UPS Zone';
            Description = 'Type the UPS zone of the primary address to make sure shipping charges are calculated correctly and deliveries are made promptly, if shipped by UPS.';
            ExternalName = 'address1_upszone';
            ExternalType = 'String';
        }
        field(95; Address1_Latitude; Decimal)
        {
            Caption = 'Address 1: Latitude';
            Description = 'Type the latitude value for the primary address for use in mapping and other applications.';
            ExternalName = 'address1_latitude';
            ExternalType = 'Double';
        }
        field(96; Address1_Telephone1; Text[50])
        {
            Caption = 'Address 1: Phone';
            Description = 'Type the main phone number associated with the primary address.';
            ExternalName = 'address1_telephone1';
            ExternalType = 'String';
        }
        field(97; Address1_Longitude; Decimal)
        {
            Caption = 'Address 1: Longitude';
            Description = 'Type the longitude value for the primary address for use in mapping and other applications.';
            ExternalName = 'address1_longitude';
            ExternalType = 'Double';
        }
        field(99; Address1_Telephone2; Text[50])
        {
            Caption = 'Address 1: Telephone 2';
            Description = 'Type a second phone number associated with the primary address.';
            ExternalName = 'address1_telephone2';
            ExternalType = 'String';
        }
        field(100; Address1_Telephone3; Text[50])
        {
            Caption = 'Address 1: Telephone 3';
            Description = 'Type a third phone number associated with the primary address.';
            ExternalName = 'address1_telephone3';
            ExternalType = 'String';
        }
        field(101; Address1_Fax; Text[50])
        {
            Caption = 'Address 1: Fax';
            Description = 'Type the fax number associated with the primary address.';
            ExternalName = 'address1_fax';
            ExternalType = 'String';
        }
        field(102; Address2_AddressId; Guid)
        {
            Caption = 'Address 2: ID';
            Description = 'Unique identifier for address 2.';
            ExternalName = 'address2_addressid';
            ExternalType = 'Uniqueidentifier';
        }
        field(103; Address2_AddressTypeCode; Option)
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
        field(104; Address2_Name; Text[100])
        {
            Caption = 'Address 2: Name';
            Description = 'Type a descriptive name for the secondary address, such as Corporate Headquarters.';
            ExternalName = 'address2_name';
            ExternalType = 'String';
        }
        field(105; Address2_PrimaryContactName; Text[100])
        {
            Caption = 'Address 2: Primary Contact Name';
            Description = 'Type the name of the main contact at the account''s secondary address.';
            ExternalName = 'address2_primarycontactname';
            ExternalType = 'String';
        }
        field(106; Address2_Line1; Text[250])
        {
            Caption = 'Address 2: Street 1';
            Description = 'Type the first line of the secondary address.';
            ExternalName = 'address2_line1';
            ExternalType = 'String';
        }
        field(107; Address2_Line2; Text[250])
        {
            Caption = 'Address 2: Street 2';
            Description = 'Type the second line of the secondary address.';
            ExternalName = 'address2_line2';
            ExternalType = 'String';
        }
        field(108; Address2_Line3; Text[250])
        {
            Caption = 'Address 2: Street 3';
            Description = 'Type the third line of the secondary address.';
            ExternalName = 'address2_line3';
            ExternalType = 'String';
        }
        field(109; Address2_City; Text[80])
        {
            Caption = 'Address 2: City';
            Description = 'Type the city for the secondary address.';
            ExternalName = 'address2_city';
            ExternalType = 'String';
        }
        field(110; Address2_StateOrProvince; Text[50])
        {
            Caption = 'Address 2: State/Province';
            Description = 'Type the state or province of the secondary address.';
            ExternalName = 'address2_stateorprovince';
            ExternalType = 'String';
        }
        field(111; Address2_County; Text[50])
        {
            Caption = 'Address 2: County';
            Description = 'Type the county for the secondary address.';
            ExternalName = 'address2_county';
            ExternalType = 'String';
        }
        field(112; Address2_Country; Text[80])
        {
            Caption = 'Address 2: Country/Region';
            Description = 'Type the country or region for the secondary address.';
            ExternalName = 'address2_country';
            ExternalType = 'String';
        }
        field(113; Address2_PostOfficeBox; Text[20])
        {
            Caption = 'Address 2: Post Office Box';
            Description = 'Type the post office box number of the secondary address.';
            ExternalName = 'address2_postofficebox';
            ExternalType = 'String';
        }
        field(114; Address2_PostalCode; Text[20])
        {
            Caption = 'Address 2: ZIP/Postal Code';
            Description = 'Type the ZIP Code or postal code for the secondary address.';
            ExternalName = 'address2_postalcode';
            ExternalType = 'String';
        }
        field(115; Address2_UTCOffset; Integer)
        {
            Caption = 'Address 2: UTC Offset';
            Description = 'Select the time zone, or UTC offset, for this address so that other people can reference it when they contact someone at this address.';
            ExternalName = 'address2_utcoffset';
            ExternalType = 'Integer';
            MaxValue = 1500;
            MinValue = -1500;
        }
        field(116; Address2_FreightTermsCode; Option)
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
        field(117; Address2_UPSZone; Text[4])
        {
            Caption = 'Address 2: UPS Zone';
            Description = 'Type the UPS zone of the secondary address to make sure shipping charges are calculated correctly and deliveries are made promptly, if shipped by UPS.';
            ExternalName = 'address2_upszone';
            ExternalType = 'String';
        }
        field(118; Address2_Latitude; Decimal)
        {
            Caption = 'Address 2: Latitude';
            Description = 'Type the latitude value for the secondary address for use in mapping and other applications.';
            ExternalName = 'address2_latitude';
            ExternalType = 'Double';
        }
        field(119; Address2_Telephone1; Text[50])
        {
            Caption = 'Address 2: Telephone 1';
            Description = 'Type the main phone number associated with the secondary address.';
            ExternalName = 'address2_telephone1';
            ExternalType = 'String';
        }
        field(120; Address2_Longitude; Decimal)
        {
            Caption = 'Address 2: Longitude';
            Description = 'Type the longitude value for the secondary address for use in mapping and other applications.';
            ExternalName = 'address2_longitude';
            ExternalType = 'Double';
        }
        field(121; Address2_ShippingMethodCode; Option)
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
        field(122; Address2_Telephone2; Text[50])
        {
            Caption = 'Address 2: Telephone 2';
            Description = 'Type a second phone number associated with the secondary address.';
            ExternalName = 'address2_telephone2';
            ExternalType = 'String';
        }
        field(123; Address2_Telephone3; Text[50])
        {
            Caption = 'Address 2: Telephone 3';
            Description = 'Type a third phone number associated with the secondary address.';
            ExternalName = 'address2_telephone3';
            ExternalType = 'String';
        }
        field(124; Address2_Fax; Text[50])
        {
            Caption = 'Address 2: Fax';
            Description = 'Type the fax number associated with the secondary address.';
            ExternalName = 'address2_fax';
            ExternalType = 'String';
        }
        field(125; CreatedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedBy)));
            Caption = 'CreatedByName';
            ExternalAccess = Read;
            ExternalName = 'createdbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(126; ModifiedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedBy)));
            Caption = 'ModifiedByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(127; OwnerId; Guid)
        {
            Caption = 'Owner';
            Description = 'Enter the user or team who is assigned to manage the record. This field is updated every time the record is assigned to a different user.';
            ExternalName = 'ownerid';
            ExternalType = 'Owner';
            TableRelation = if (OwnerIdType = const(systemuser)) "CRM Systemuser".SystemUserId
            else
            if (OwnerIdType = const(team)) "CRM Team".TeamId;
        }
        field(128; OwnerIdType; Option)
        {
            Caption = 'OwnerIdType';
            ExternalName = 'owneridtype';
            ExternalType = 'EntityName';
            OptionCaption = ' ,systemuser,team';
            OptionMembers = " ",systemuser,team;
        }
        field(129; PreferredSystemUserId; Guid)
        {
            Caption = 'Preferred User';
            Description = 'Choose the regular or preferred customer service representative for reference when scheduling service activities for the contact.';
            ExternalName = 'preferredsystemuserid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(130; MasterId; Guid)
        {
            Caption = 'Master ID';
            Description = 'Unique identifier of the master contact for merge.';
            ExternalAccess = Read;
            ExternalName = 'masterid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Contact".ContactId;
        }
        field(131; PreferredAppointmentDayCode; Option)
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
        field(132; PreferredAppointmentTimeCode; Option)
        {
            Caption = 'Preferred Time';
            Description = 'Select the preferred time of day for service appointments.';
            ExternalName = 'preferredappointmenttimecode';
            ExternalType = 'Picklist';
            InitValue = Morning;
            OptionCaption = 'Morning,Afternoon,Evening';
            OptionOrdinalValues = 1, 2, 3;
            OptionMembers = Morning,Afternoon,Evening;
        }
        field(133; DoNotSendMM; Boolean)
        {
            Caption = 'Send Marketing Materials';
            Description = 'Select whether the contact accepts marketing materials, such as brochures or catalogs. Contacts that opt out can be excluded from marketing initiatives.';
            ExternalName = 'donotsendmm';
            ExternalType = 'Boolean';
        }
        field(134; ParentCustomerId; Guid)
        {
            Caption = 'Company Name';
            Description = 'Select the parent account or parent contact for the contact to provide a quick link to additional details, such as financial information, activities, and opportunities.';
            ExternalName = 'parentcustomerid';
            ExternalType = 'Customer';
            TableRelation = if (ParentCustomerIdType = const(account)) "CRM Account".AccountId
            else
            if (ParentCustomerIdType = const(contact)) "CRM Contact".ContactId;
        }
        field(135; Merged; Boolean)
        {
            Caption = 'Merged';
            Description = 'Shows whether the account has been merged with a master contact.';
            ExternalAccess = Read;
            ExternalName = 'merged';
            ExternalType = 'Boolean';
        }
        field(136; ExternalUserIdentifier; Text[50])
        {
            Caption = 'External User Identifier';
            Description = 'Identifier for an external user.';
            ExternalName = 'externaluseridentifier';
            ExternalType = 'String';
        }
        field(137; LastUsedInCampaign; Date)
        {
            Caption = 'Last Date Included in Campaign';
            Description = 'Shows the date when the contact was last included in a marketing campaign or quick campaign.';
            ExternalAccess = Modify;
            ExternalName = 'lastusedincampaign';
            ExternalType = 'DateTime';
        }
        field(138; MasterContactIdName; Text[160])
        {
            CalcFormula = lookup("CRM Contact".FullName where(ContactId = field(MasterId)));
            Caption = 'MasterContactIdName';
            ExternalAccess = Read;
            ExternalName = 'mastercontactidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(139; PreferredSystemUserIdName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(PreferredSystemUserId)));
            Caption = 'PreferredSystemUserIdName';
            ExternalAccess = Read;
            ExternalName = 'preferredsystemuseridname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(140; ParentCustomerIdType; Option)
        {
            Caption = 'Parent Customer Type';
            ExternalName = 'parentcustomeridtype';
            ExternalType = 'EntityName';
            OptionCaption = ' ,account,contact';
            OptionMembers = " ",account,contact;
        }
        field(141; TransactionCurrencyId; Guid)
        {
            Caption = 'Currency';
            Description = 'Choose the local currency for the record to make sure budgets are reported in the correct currency.';
            ExternalName = 'transactioncurrencyid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Transactioncurrency".TransactionCurrencyId;
        }
        field(142; OverriddenCreatedOn; Date)
        {
            Caption = 'Record Created On';
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
        }
        field(143; ExchangeRate; Decimal)
        {
            Caption = 'Exchange Rate';
            Description = 'Shows the conversion rate of the record''s currency. The exchange rate is used to convert all money fields in the record from the local currency to the system''s default currency.';
            ExternalAccess = Read;
            ExternalName = 'exchangerate';
            ExternalType = 'Decimal';
        }
        field(144; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            Description = 'Unique identifier of the data import or data migration that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
        }
        field(145; TimeZoneRuleVersionNumber; Integer)
        {
            Caption = 'Time Zone Rule Version Number';
            Description = 'For internal use only.';
            ExternalName = 'timezoneruleversionnumber';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(146; UTCConversionTimeZoneCode; Integer)
        {
            Caption = 'UTC Conversion Time Zone Code';
            Description = 'Time zone code that was in use when the record was created.';
            ExternalName = 'utcconversiontimezonecode';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(147; AnnualIncome_Base; Decimal)
        {
            Caption = 'Annual Income (Base)';
            Description = 'Shows the Annual Income field converted to the system''s default base currency. The calculations use the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'annualincome_base';
            ExternalType = 'Money';
        }
        field(148; CreditLimit_Base; Decimal)
        {
            Caption = 'Credit Limit (Base)';
            Description = 'Shows the Credit Limit field converted to the system''s default base currency for reporting purposes. The calculations use the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'creditlimit_base';
            ExternalType = 'Money';
        }
        field(149; Aging60_Base; Decimal)
        {
            Caption = 'Aging 60 (Base)';
            Description = 'Shows the Aging 60 field converted to the system''s default base currency. The calculations use the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'aging60_base';
            ExternalType = 'Money';
        }
        field(150; Aging90_Base; Decimal)
        {
            Caption = 'Aging 90 (Base)';
            Description = 'Shows the Aging 90 field converted to the system''s default base currency. The calculations use the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'aging90_base';
            ExternalType = 'Money';
        }
        field(151; Aging30_Base; Decimal)
        {
            Caption = 'Aging 30 (Base)';
            Description = 'Shows the Aging 30 field converted to the system''s default base currency. The calculations use the exchange rate specified in the Currencies area.';
            ExternalAccess = Read;
            ExternalName = 'aging30_base';
            ExternalType = 'Money';
        }
        field(152; TransactionCurrencyIdName; Text[100])
        {
            CalcFormula = lookup("CRM Transactioncurrency".CurrencyName where(TransactionCurrencyId = field(TransactionCurrencyId)));
            Caption = 'TransactionCurrencyIdName';
            ExternalAccess = Read;
            ExternalName = 'transactioncurrencyidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(153; CreatedOnBehalfBy; Guid)
        {
            Caption = 'Created By (Delegate)';
            Description = 'Shows who created the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(154; CreatedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            Caption = 'CreatedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(155; ModifiedOnBehalfBy; Guid)
        {
            Caption = 'Modified By (Delegate)';
            Description = 'Shows who last updated the record on behalf of another user.';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(156; ModifiedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedOnBehalfBy)));
            Caption = 'ModifiedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(157; OwningTeam; Guid)
        {
            Caption = 'Owning Team';
            Description = 'Unique identifier of the team who owns the contact.';
            ExternalAccess = Read;
            ExternalName = 'owningteam';
            ExternalType = 'Lookup';
            TableRelation = "CRM Team".TeamId;
        }
        field(158; StageId; Guid)
        {
            Caption = 'Process Stage';
            Description = 'Shows the ID of the stage.';
            ExternalName = 'stageid';
            ExternalType = 'Uniqueidentifier';
        }
        field(159; ProcessId; Guid)
        {
            Caption = 'Process';
            Description = 'Shows the ID of the process.';
            ExternalName = 'processid';
            ExternalType = 'Uniqueidentifier';
        }
        field(160; Address2_Composite; BLOB)
        {
            Caption = 'Address 2';
            Description = 'Shows the complete secondary address.';
            ExternalAccess = Read;
            ExternalName = 'address2_composite';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(161; Address1_Composite; BLOB)
        {
            Caption = 'Address 1';
            Description = 'Shows the complete primary address.';
            ExternalAccess = Read;
            ExternalName = 'address1_composite';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(162; EntityImageId; Guid)
        {
            Caption = 'Entity Image Id';
            Description = 'For internal use only.';
            ExternalAccess = Read;
            ExternalName = 'entityimageid';
            ExternalType = 'Uniqueidentifier';
        }
        field(163; TraversedPath; Text[250])
        {
            Caption = 'Traversed Path';
            Description = 'For internal use only.';
            ExternalName = 'traversedpath';
            ExternalType = 'String';
        }
        field(164; Address3_Country; Text[80])
        {
            Caption = 'Address3: Country/Region';
            Description = 'the country or region for the 3rd address.';
            ExternalName = 'address3_country';
            ExternalType = 'String';
        }
        field(165; Address3_Line1; Text[250])
        {
            Caption = 'Address3: Street 1';
            Description = 'the first line of the 3rd address.';
            ExternalName = 'address3_line1';
            ExternalType = 'String';
        }
        field(166; Address3_Line2; Text[250])
        {
            Caption = 'Address3: Street 2';
            Description = 'the second line of the 3rd address.';
            ExternalName = 'address3_line2';
            ExternalType = 'String';
        }
        field(167; Address3_Line3; Text[250])
        {
            Caption = 'Address3: Street 3';
            Description = 'the third line of the 3rd address.';
            ExternalName = 'address3_line3';
            ExternalType = 'String';
        }
        field(168; Address3_PostalCode; Text[20])
        {
            Caption = 'Address3: ZIP/Postal Code';
            Description = 'the ZIP Code or postal code for the 3rd address.';
            ExternalName = 'address3_postalcode';
            ExternalType = 'String';
        }
        field(169; Address3_PostOfficeBox; Text[20])
        {
            Caption = 'Address 3: Post Office Box';
            Description = 'the post office box number of the 3rd address.';
            ExternalName = 'address3_postofficebox';
            ExternalType = 'String';
        }
        field(170; Address3_StateOrProvince; Text[50])
        {
            Caption = 'Address3: State/Province';
            Description = 'the state or province of the third address.';
            ExternalName = 'address3_stateorprovince';
            ExternalType = 'String';
        }
        field(171; Address3_City; Text[80])
        {
            Caption = 'Address 3: City';
            Description = 'Type the city for the 3rd address.';
            ExternalName = 'address3_city';
            ExternalType = 'String';
        }
        field(172; Business2; Text[50])
        {
            Caption = 'Business Phone 2';
            Description = 'Type a second business phone number for this contact.';
            ExternalName = 'business2';
            ExternalType = 'String';
        }
        field(173; Callback; Text[50])
        {
            Caption = 'Callback Number';
            Description = 'Type a callback phone number for this contact.';
            ExternalName = 'callback';
            ExternalType = 'String';
        }
        field(174; Company; Text[50])
        {
            Caption = 'Company Phone';
            Description = 'Type the company phone of the contact.';
            ExternalName = 'company';
            ExternalType = 'String';
        }
        field(175; Home2; Text[50])
        {
            Caption = 'Home Phone 2';
            Description = 'Type a second home phone number for this contact.';
            ExternalName = 'home2';
            ExternalType = 'String';
        }
        field(176; Address3_AddressId; Guid)
        {
            Caption = 'Address 3: ID';
            Description = 'Unique identifier for address 3.';
            ExternalName = 'address3_addressid';
            ExternalType = 'Uniqueidentifier';
        }
        field(177; Address3_Composite; BLOB)
        {
            Caption = 'Address 3';
            Description = 'Shows the complete third address.';
            ExternalAccess = Read;
            ExternalName = 'address3_composite';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(178; Address3_Fax; Text[50])
        {
            Caption = 'Address 3: Fax';
            Description = 'Type the fax number associated with the third address.';
            ExternalName = 'address3_fax';
            ExternalType = 'String';
        }
        field(179; Address3_FreightTermsCode; Option)
        {
            Caption = 'Address 3: Freight Terms';
            Description = 'Select the freight terms for the third address to make sure shipping orders are processed correctly.';
            ExternalName = 'address3_freighttermscode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Default Value';
            OptionOrdinalValues = -1, 1;
            OptionMembers = " ",DefaultValue;
        }
        field(180; Address3_Latitude; Decimal)
        {
            Caption = 'Address 3: Latitude';
            Description = 'Type the latitude value for the third address for use in mapping and other applications.';
            ExternalName = 'address3_latitude';
            ExternalType = 'Double';
        }
        field(181; Address3_Longitude; Decimal)
        {
            Caption = 'Address 3: Longitude';
            Description = 'Type the longitude value for the third address for use in mapping and other applications.';
            ExternalName = 'address3_longitude';
            ExternalType = 'Double';
        }
        field(182; Address3_Name; Text[200])
        {
            Caption = 'Address 3: Name';
            Description = 'Type a descriptive name for the third address, such as Corporate Headquarters.';
            ExternalName = 'address3_name';
            ExternalType = 'String';
        }
        field(183; Address3_PrimaryContactName; Text[100])
        {
            Caption = 'Address 3: Primary Contact Name';
            Description = 'Type the name of the main contact at the account''s third address.';
            ExternalName = 'address3_primarycontactname';
            ExternalType = 'String';
        }
        field(184; Address3_ShippingMethodCode; Option)
        {
            Caption = 'Address 3: Shipping Method';
            Description = 'Select a shipping method for deliveries sent to this address.';
            ExternalName = 'address3_shippingmethodcode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Default Value';
            OptionOrdinalValues = -1, 1;
            OptionMembers = " ",DefaultValue;
        }
        field(185; Address3_Telephone1; Text[50])
        {
            Caption = 'Address 3: Telephone1';
            Description = 'Type the main phone number associated with the third address.';
            ExternalName = 'address3_telephone1';
            ExternalType = 'String';
        }
        field(186; Address3_Telephone2; Text[50])
        {
            Caption = 'Address 3: Telephone2';
            Description = 'Type a second phone number associated with the third address.';
            ExternalName = 'address3_telephone2';
            ExternalType = 'String';
        }
        field(187; Address3_Telephone3; Text[50])
        {
            Caption = 'Address 3: Telephone3';
            Description = 'Type a third phone number associated with the primary address.';
            ExternalName = 'address3_telephone3';
            ExternalType = 'String';
        }
        field(188; Address3_UPSZone; Text[4])
        {
            Caption = 'Address 3: UPS Zone';
            Description = 'Type the UPS zone of the third address to make sure shipping charges are calculated correctly and deliveries are made promptly, if shipped by UPS.';
            ExternalName = 'address3_upszone';
            ExternalType = 'String';
        }
        field(189; Address3_UTCOffset; Integer)
        {
            Caption = 'Address 3: UTC Offset';
            Description = 'Select the time zone, or UTC offset, for this address so that other people can reference it when they contact someone at this address.';
            ExternalName = 'address3_utcoffset';
            ExternalType = 'Integer';
            MaxValue = 1500;
            MinValue = -1500;
        }
        field(190; Address3_County; Text[50])
        {
            Caption = 'Address 3: County';
            Description = 'Type the county for the third address.';
            ExternalName = 'address3_county';
            ExternalType = 'String';
        }
        field(191; Address3_AddressTypeCode; Option)
        {
            Caption = 'Address 3: Address Type';
            Description = 'Select the third address type.';
            ExternalName = 'address3_addresstypecode';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Default Value';
            OptionOrdinalValues = -1, 1;
            OptionMembers = " ",DefaultValue;
        }
        field(192; CompanyId; Guid)
        {
            Caption = 'Company Id';
            Description = 'Unique identifier of the company that owns the contact.';
            ExternalName = 'bcbi_companyid';
            ExternalType = 'Lookup';
            TableRelation = "CDS Company".CompanyId;
        }
        field(193; PaymentTermsCodeEnum; Enum "CDS Payment Terms Code")
        {
            Caption = 'Payment Terms';
            Description = 'Select the payment terms to indicate when the customer needs to pay the total amount.';
            ExternalName = 'paymenttermscode';
            ExternalType = 'Picklist';
            InitValue = " ";
        }
        field(194; Address1_FreightTermsCodeEnum; Enum "CDS Shipment Method Code")
        {
            Caption = 'Address 1: Freight Terms';
            Description = 'Select the freight terms for the primary address to make sure shipping orders are processed correctly.';
            ExternalName = 'address1_freighttermscode';
            ExternalType = 'Picklist';
            InitValue = " ";
        }
        field(195; Address1_ShippingMethodCodeEnum; Enum "CDS Shipping Agent Code")
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
        key(Key1; ContactId)
        {
            Clustered = true;
        }
        key(Key2; FullName)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; FullName)
        {
        }
    }
}
