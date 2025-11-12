// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5340 "CRM Systemuser"
{
    // Dynamics CRM Version: 7.1.0.2040

    Caption = 'Dataverse Systemuser';
    Description = 'Person with access to the Microsoft Dataverse system and who owns objects in the Microsoft Dataverse database.';
    ExternalName = 'systemuser';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; SystemUserId; Guid)
        {
            Caption = 'User';
            Description = 'Unique identifier for the user.';
            ExternalAccess = Insert;
            ExternalName = 'systemuserid';
            ExternalType = 'Uniqueidentifier';
        }
        field(2; OrganizationId; Guid)
        {
            Caption = 'Organization ';
            Description = 'Unique identifier of the organization associated with the user.';
            ExternalAccess = Read;
            ExternalName = 'organizationid';
            ExternalType = 'Uniqueidentifier';
        }
        field(3; BusinessUnitId; Guid)
        {
            Caption = 'Business Unit';
            Description = 'Unique identifier of the business unit with which the user is associated.';
            ExternalName = 'businessunitid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Businessunit".BusinessUnitId;
        }
        field(4; ParentSystemUserId; Guid)
        {
            Caption = 'Manager';
            Description = 'Unique identifier of the manager of the user.';
            ExternalName = 'parentsystemuserid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(5; FirstName; Text[64])
        {
            Caption = 'First Name';
            Description = 'First name of the user.';
            ExternalName = 'firstname';
            ExternalType = 'String';
        }
        field(6; Salutation; Text[20])
        {
            Caption = 'Salutation';
            Description = 'Salutation for correspondence with the user.';
            ExternalName = 'salutation';
            ExternalType = 'String';
        }
        field(7; MiddleName; Text[50])
        {
            Caption = 'Middle Name';
            Description = 'Middle name of the user.';
            ExternalName = 'middlename';
            ExternalType = 'String';
        }
        field(8; LastName; Text[64])
        {
            Caption = 'Last Name';
            Description = 'Last name of the user.';
            ExternalName = 'lastname';
            ExternalType = 'String';
        }
        field(9; PersonalEMailAddress; Text[100])
        {
            Caption = 'Email 2';
            Description = 'Personal email address of the user.';
            ExtendedDatatype = EMail;
            ExternalName = 'personalemailaddress';
            ExternalType = 'String';
        }
        field(10; FullName; Text[200])
        {
            Caption = 'Full Name';
            Description = 'Full name of the user.';
            ExternalAccess = Read;
            ExternalName = 'fullname';
            ExternalType = 'String';
        }
        field(11; NickName; Text[50])
        {
            Caption = 'Nickname';
            Description = 'Nickname of the user.';
            ExternalName = 'nickname';
            ExternalType = 'String';
        }
        field(12; Title; Text[128])
        {
            Caption = 'Title';
            Description = 'Title of the user.';
            ExternalName = 'title';
            ExternalType = 'String';
        }
        field(13; InternalEMailAddress; Text[100])
        {
            Caption = 'Primary Email';
            Description = 'Internal email address for the user.';
            ExtendedDatatype = EMail;
            ExternalName = 'internalemailaddress';
            ExternalType = 'String';
        }
        field(14; JobTitle; Text[100])
        {
            Caption = 'Job Title';
            Description = 'Job title of the user.';
            ExternalName = 'jobtitle';
            ExternalType = 'String';
        }
        field(15; MobileAlertEMail; Text[100])
        {
            Caption = 'Mobile Alert Email';
            Description = 'Mobile alert email address for the user.';
            ExtendedDatatype = EMail;
            ExternalName = 'mobilealertemail';
            ExternalType = 'String';
        }
        field(16; PreferredEmailCode; Option)
        {
            Caption = 'Preferred Email';
            Description = 'Preferred email address for the user.';
            ExternalName = 'preferredemailcode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(17; HomePhone; Text[50])
        {
            Caption = 'Home Phone';
            Description = 'Home phone number for the user.';
            ExternalName = 'homephone';
            ExternalType = 'String';
        }
        field(18; MobilePhone; Text[64])
        {
            Caption = 'Mobile Phone';
            Description = 'Mobile phone number for the user.';
            ExternalName = 'mobilephone';
            ExternalType = 'String';
        }
        field(19; PreferredPhoneCode; Option)
        {
            Caption = 'Preferred Phone';
            Description = 'Preferred phone number for the user.';
            ExternalName = 'preferredphonecode';
            ExternalType = 'Picklist';
            InitValue = MainPhone;
            OptionCaption = 'Main Phone,Other Phone,Home Phone,Mobile Phone';
            OptionOrdinalValues = 1, 2, 3, 4;
            OptionMembers = MainPhone,OtherPhone,HomePhone,MobilePhone;
        }
        field(20; PreferredAddressCode; Option)
        {
            Caption = 'Preferred Address';
            Description = 'Preferred address for the user.';
            ExternalName = 'preferredaddresscode';
            ExternalType = 'Picklist';
            InitValue = MailingAddress;
            OptionCaption = 'Mailing Address,Other Address';
            OptionOrdinalValues = 1, 2;
            OptionMembers = MailingAddress,OtherAddress;
        }
        field(21; PhotoUrl; Text[200])
        {
            Caption = 'Photo URL';
            Description = 'URL for the Website on which a photo of the user is located.';
            ExtendedDatatype = URL;
            ExternalName = 'photourl';
            ExternalType = 'String';
        }
        field(22; DomainName; Text[250])
        {
            Caption = 'User Name';
            Description = 'Active Directory domain of which the user is a member.';
            ExternalName = 'domainname';
            ExternalType = 'String';
        }
        field(23; PassportLo; Integer)
        {
            Caption = 'Passport Lo';
            Description = 'For internal use only.';
            ExternalName = 'passportlo';
            ExternalType = 'Integer';
            MaxValue = 1000000000;
            MinValue = 0;
        }
        field(24; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            Description = 'Date and time when the user was created.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(25; PassportHi; Integer)
        {
            Caption = 'Passport Hi';
            Description = 'For internal use only.';
            ExternalName = 'passporthi';
            ExternalType = 'Integer';
            MaxValue = 1000000000;
            MinValue = 0;
        }
        field(26; DisabledReason; Text[250])
        {
            Caption = 'Disabled Reason';
            Description = 'Reason for disabling the user.';
            ExternalAccess = Read;
            ExternalName = 'disabledreason';
            ExternalType = 'String';
        }
        field(27; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            Description = 'Date and time when the user was last modified.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
        }
        field(28; CreatedBy; Guid)
        {
            Caption = 'Created By';
            Description = 'Unique identifier of the user who created the user.';
            ExternalAccess = Read;
            ExternalName = 'createdby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(29; EmployeeId; Text[100])
        {
            Caption = 'Employee';
            Description = 'Employee identifier for the user.';
            ExternalName = 'employeeid';
            ExternalType = 'String';
        }
        field(30; ModifiedBy; Guid)
        {
            Caption = 'Modified By';
            Description = 'Unique identifier of the user who last modified the user.';
            ExternalAccess = Read;
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(31; IsDisabled; Boolean)
        {
            Caption = 'Status';
            Description = 'Information about whether the user is enabled.';
            ExternalAccess = Read;
            ExternalName = 'isdisabled';
            ExternalType = 'Boolean';
        }
        field(32; GovernmentId; Text[100])
        {
            Caption = 'Government';
            Description = 'Government identifier for the user.';
            ExternalName = 'governmentid';
            ExternalType = 'String';
        }
        field(33; VersionNumber; BigInteger)
        {
            Caption = 'Version number';
            Description = 'Version number of the user.';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(34; ParentSystemUserIdName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ParentSystemUserId)));
            Caption = 'ParentSystemUserIdName';
            ExternalAccess = Read;
            ExternalName = 'parentsystemuseridname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(35; Address1_AddressId; Guid)
        {
            Caption = 'Address 1: ID';
            Description = 'Unique identifier for address 1.';
            ExternalName = 'address1_addressid';
            ExternalType = 'Uniqueidentifier';
        }
        field(36; Address1_AddressTypeCode; Option)
        {
            Caption = 'Address 1: Address Type';
            Description = 'Type of address for address 1, such as billing, shipping, or primary address.';
            ExternalName = 'address1_addresstypecode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(37; Address1_Name; Text[100])
        {
            Caption = 'Address 1: Name';
            Description = 'Name to enter for address 1.';
            ExternalName = 'address1_name';
            ExternalType = 'String';
        }
        field(38; Address1_Line1; Text[250])
        {
            Caption = 'Street 1';
            Description = 'First line for entering address 1 information.';
            ExternalName = 'address1_line1';
            ExternalType = 'String';
        }
        field(39; Address1_Line2; Text[250])
        {
            Caption = 'Street 2';
            Description = 'Second line for entering address 1 information.';
            ExternalName = 'address1_line2';
            ExternalType = 'String';
        }
        field(40; Address1_Line3; Text[250])
        {
            Caption = 'Street 3';
            Description = 'Third line for entering address 1 information.';
            ExternalName = 'address1_line3';
            ExternalType = 'String';
        }
        field(41; Address1_City; Text[128])
        {
            Caption = 'City';
            Description = 'City name for address 1.';
            ExternalName = 'address1_city';
            ExternalType = 'String';
        }
        field(42; Address1_StateOrProvince; Text[128])
        {
            Caption = 'State/Province';
            Description = 'State or province for address 1.';
            ExternalName = 'address1_stateorprovince';
            ExternalType = 'String';
        }
        field(43; Address1_County; Text[128])
        {
            Caption = 'Address 1: County';
            Description = 'County name for address 1.';
            ExternalName = 'address1_county';
            ExternalType = 'String';
        }
        field(44; Address1_Country; Text[128])
        {
            Caption = 'Country/Region';
            Description = 'Country/region name in address 1.';
            ExternalName = 'address1_country';
            ExternalType = 'String';
        }
        field(45; Address1_PostOfficeBox; Text[40])
        {
            Caption = 'Address 1: Post Office Box';
            Description = 'Post office box number for address 1.';
            ExternalName = 'address1_postofficebox';
            ExternalType = 'String';
        }
        field(46; Address1_PostalCode; Text[40])
        {
            Caption = 'ZIP/Postal Code';
            Description = 'ZIP Code or postal code for address 1.';
            ExternalName = 'address1_postalcode';
            ExternalType = 'String';
        }
        field(47; Address1_UTCOffset; Integer)
        {
            Caption = 'Address 1: UTC Offset';
            Description = 'UTC offset for address 1. This is the difference between local time and standard Coordinated Universal Time.';
            ExternalName = 'address1_utcoffset';
            ExternalType = 'Integer';
            MaxValue = 1500;
            MinValue = -1500;
        }
        field(48; Address1_UPSZone; Text[4])
        {
            Caption = 'Address 1: UPS Zone';
            Description = 'United Parcel Service (UPS) zone for address 1.';
            ExternalName = 'address1_upszone';
            ExternalType = 'String';
        }
        field(49; Address1_Latitude; Decimal)
        {
            Caption = 'Address 1: Latitude';
            Description = 'Latitude for address 1.';
            ExternalName = 'address1_latitude';
            ExternalType = 'Double';
        }
        field(50; Address1_Telephone1; Text[64])
        {
            Caption = 'Main Phone';
            Description = 'First telephone number associated with address 1.';
            ExternalName = 'address1_telephone1';
            ExternalType = 'String';
        }
        field(51; Address1_Longitude; Decimal)
        {
            Caption = 'Address 1: Longitude';
            Description = 'Longitude for address 1.';
            ExternalName = 'address1_longitude';
            ExternalType = 'Double';
        }
        field(52; Address1_ShippingMethodCode; Option)
        {
            Caption = 'Address 1: Shipping Method';
            Description = 'Method of shipment for address 1.';
            ExternalName = 'address1_shippingmethodcode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(53; Address1_Telephone2; Text[50])
        {
            Caption = 'Other Phone';
            Description = 'Second telephone number associated with address 1.';
            ExternalName = 'address1_telephone2';
            ExternalType = 'String';
        }
        field(54; Address1_Telephone3; Text[50])
        {
            Caption = 'Pager';
            Description = 'Third telephone number associated with address 1.';
            ExternalName = 'address1_telephone3';
            ExternalType = 'String';
        }
        field(55; Address1_Fax; Text[64])
        {
            Caption = 'Address 1: Fax';
            Description = 'Fax number for address 1.';
            ExternalName = 'address1_fax';
            ExternalType = 'String';
        }
        field(56; Address2_AddressId; Guid)
        {
            Caption = 'Address 2: ID';
            Description = 'Unique identifier for address 2.';
            ExternalName = 'address2_addressid';
            ExternalType = 'Uniqueidentifier';
        }
        field(57; Address2_AddressTypeCode; Option)
        {
            Caption = 'Address 2: Address Type';
            Description = 'Type of address for address 2, such as billing, shipping, or primary address.';
            ExternalName = 'address2_addresstypecode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(58; Address2_Name; Text[100])
        {
            Caption = 'Address 2: Name';
            Description = 'Name to enter for address 2.';
            ExternalName = 'address2_name';
            ExternalType = 'String';
        }
        field(59; Address2_Line1; Text[250])
        {
            Caption = 'Other Street 1';
            Description = 'First line for entering address 2 information.';
            ExternalName = 'address2_line1';
            ExternalType = 'String';
        }
        field(60; Address2_Line2; Text[250])
        {
            Caption = 'Other Street 2';
            Description = 'Second line for entering address 2 information.';
            ExternalName = 'address2_line2';
            ExternalType = 'String';
        }
        field(61; Address2_Line3; Text[250])
        {
            Caption = 'Other Street 3';
            Description = 'Third line for entering address 2 information.';
            ExternalName = 'address2_line3';
            ExternalType = 'String';
        }
        field(62; Address2_City; Text[128])
        {
            Caption = 'Other City';
            Description = 'City name for address 2.';
            ExternalName = 'address2_city';
            ExternalType = 'String';
        }
        field(63; Address2_StateOrProvince; Text[128])
        {
            Caption = 'Other State/Province';
            Description = 'State or province for address 2.';
            ExternalName = 'address2_stateorprovince';
            ExternalType = 'String';
        }
        field(64; Address2_County; Text[128])
        {
            Caption = 'Address 2: County';
            Description = 'County name for address 2.';
            ExternalName = 'address2_county';
            ExternalType = 'String';
        }
        field(65; Address2_Country; Text[128])
        {
            Caption = 'Other Country/Region';
            Description = 'Country/region name in address 2.';
            ExternalName = 'address2_country';
            ExternalType = 'String';
        }
        field(66; Address2_PostOfficeBox; Text[40])
        {
            Caption = 'Address 2: Post Office Box';
            Description = 'Post office box number for address 2.';
            ExternalName = 'address2_postofficebox';
            ExternalType = 'String';
        }
        field(67; Address2_PostalCode; Text[40])
        {
            Caption = 'Other ZIP/Postal Code';
            Description = 'ZIP Code or postal code for address 2.';
            ExternalName = 'address2_postalcode';
            ExternalType = 'String';
        }
        field(68; Address2_UTCOffset; Integer)
        {
            Caption = 'Address 2: UTC Offset';
            Description = 'UTC offset for address 2. This is the difference between local time and standard Coordinated Universal Time.';
            ExternalName = 'address2_utcoffset';
            ExternalType = 'Integer';
            MaxValue = 1500;
            MinValue = -1500;
        }
        field(69; Address2_UPSZone; Text[4])
        {
            Caption = 'Address 2: UPS Zone';
            Description = 'United Parcel Service (UPS) zone for address 2.';
            ExternalName = 'address2_upszone';
            ExternalType = 'String';
        }
        field(70; Address2_Latitude; Decimal)
        {
            Caption = 'Address 2: Latitude';
            Description = 'Latitude for address 2.';
            ExternalName = 'address2_latitude';
            ExternalType = 'Double';
        }
        field(71; Address2_Telephone1; Text[50])
        {
            Caption = 'Address 2: Telephone 1';
            Description = 'First telephone number associated with address 2.';
            ExternalName = 'address2_telephone1';
            ExternalType = 'String';
        }
        field(72; Address2_Longitude; Decimal)
        {
            Caption = 'Address 2: Longitude';
            Description = 'Longitude for address 2.';
            ExternalName = 'address2_longitude';
            ExternalType = 'Double';
        }
        field(73; Address2_ShippingMethodCode; Option)
        {
            Caption = 'Address 2: Shipping Method';
            Description = 'Method of shipment for address 2.';
            ExternalName = 'address2_shippingmethodcode';
            ExternalType = 'Picklist';
            InitValue = DefaultValue;
            OptionCaption = 'Default Value';
            OptionOrdinalValues = 1;
            OptionMembers = DefaultValue;
        }
        field(74; Address2_Telephone2; Text[50])
        {
            Caption = 'Address 2: Telephone 2';
            Description = 'Second telephone number associated with address 2.';
            ExternalName = 'address2_telephone2';
            ExternalType = 'String';
        }
        field(75; Address2_Telephone3; Text[50])
        {
            Caption = 'Address 2: Telephone 3';
            Description = 'Third telephone number associated with address 2.';
            ExternalName = 'address2_telephone3';
            ExternalType = 'String';
        }
        field(76; Address2_Fax; Text[50])
        {
            Caption = 'Address 2: Fax';
            Description = 'Fax number for address 2.';
            ExternalName = 'address2_fax';
            ExternalType = 'String';
        }
        field(77; CreatedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedBy)));
            Caption = 'CreatedByName';
            ExternalAccess = Read;
            ExternalName = 'createdbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(78; ModifiedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedBy)));
            Caption = 'ModifiedByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(79; BusinessUnitIdName; Text[160])
        {
            CalcFormula = lookup("CRM Businessunit".Name where(BusinessUnitId = field(BusinessUnitId)));
            Caption = 'BusinessUnitIdName';
            ExternalAccess = Read;
            ExternalName = 'businessunitidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(80; Skills; Text[100])
        {
            Caption = 'Skills';
            Description = 'Skill set of the user.';
            ExternalName = 'skills';
            ExternalType = 'String';
        }
        field(81; DisplayInServiceViews; Boolean)
        {
            Caption = 'Display in Service Views';
            Description = 'Whether to display the user in service views.';
            ExternalName = 'displayinserviceviews';
            ExternalType = 'Boolean';
        }
        field(82; SetupUser; Boolean)
        {
            Caption = 'Restricted Access Mode';
            Description = 'Check if user is a setup user.';
            ExternalName = 'setupuser';
            ExternalType = 'Boolean';
        }
        field(83; WindowsLiveID; Text[250])
        {
            Caption = 'Windows Live ID';
            Description = 'Windows Live ID';
            ExtendedDatatype = EMail;
            ExternalName = 'windowsliveid';
            ExternalType = 'String';
        }
        field(84; IncomingEmailDeliveryMethod; Option)
        {
            Caption = 'Incoming Email Delivery Method';
            Description = 'Incoming email delivery method for the user.';
            ExternalName = 'incomingemaildeliverymethod';
            ExternalType = 'Picklist';
            InitValue = MicrosoftDynamicsCRMforOutlook;
            OptionCaption = 'None,Microsoft Dynamics CRM for Outlook,Server-Side Synchronization or Email Router,Forward Mailbox';
            OptionOrdinalValues = 0, 1, 2, 3;
            OptionMembers = "None",MicrosoftDynamicsCRMforOutlook,"Server-SideSynchronizationorEmailRouter",ForwardMailbox;
        }
        field(85; OutgoingEmailDeliveryMethod; Option)
        {
            Caption = 'Outgoing Email Delivery Method';
            Description = 'Outgoing email delivery method for the user.';
            ExternalName = 'outgoingemaildeliverymethod';
            ExternalType = 'Picklist';
            InitValue = MicrosoftDynamicsCRMforOutlook;
            OptionCaption = 'None,Microsoft Dynamics CRM for Outlook,Server-Side Synchronization or Email Router';
            OptionOrdinalValues = 0, 1, 2;
            OptionMembers = "None",MicrosoftDynamicsCRMforOutlook,"Server-SideSynchronizationorEmailRouter";
        }
        field(86; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            Description = 'Unique identifier of the data import or data migration that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
        }
        field(87; AccessMode; Option)
        {
            Caption = 'Access Mode';
            Description = 'Type of user.';
            ExternalName = 'accessmode';
            ExternalType = 'Picklist';
            InitValue = "Read-Write";
            OptionCaption = 'Read-Write,Administrative,Read,Support User,Non-interactive';
            OptionOrdinalValues = 0, 1, 2, 3, 4;
            OptionMembers = "Read-Write",Administrative,Read,SupportUser,"Non-interactive";
        }
        field(88; InviteStatusCode; Option)
        {
            Caption = 'Invitation Status';
            Description = 'User invitation status.';
            ExternalName = 'invitestatuscode';
            ExternalType = 'Picklist';
            InitValue = InvitationNotSent;
            OptionCaption = 'Invitation Not Sent,Invited,Invitation Near Expired,Invitation Expired,Invitation Accepted,Invitation Rejected,Invitation Revoked';
            OptionOrdinalValues = 0, 1, 2, 3, 4, 5, 6;
            OptionMembers = InvitationNotSent,Invited,InvitationNearExpired,InvitationExpired,InvitationAccepted,InvitationRejected,InvitationRevoked;
        }
        field(89; OverriddenCreatedOn; Date)
        {
            Caption = 'Record Created On';
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
        }
        field(90; UTCConversionTimeZoneCode; Integer)
        {
            Caption = 'UTC Conversion Time Zone Code';
            Description = 'Time zone code that was in use when the record was created.';
            ExternalName = 'utcconversiontimezonecode';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(91; TimeZoneRuleVersionNumber; Integer)
        {
            Caption = 'Time Zone Rule Version Number';
            Description = 'For internal use only.';
            ExternalName = 'timezoneruleversionnumber';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(92; YomiFullName; Text[200])
        {
            Caption = 'Yomi Full Name';
            Description = 'Pronunciation of the full name of the user, written in phonetic hiragana or katakana characters.';
            ExternalAccess = Read;
            ExternalName = 'yomifullname';
            ExternalType = 'String';
        }
        field(93; YomiLastName; Text[64])
        {
            Caption = 'Yomi Last Name';
            Description = 'Pronunciation of the last name of the user, written in phonetic hiragana or katakana characters.';
            ExternalName = 'yomilastname';
            ExternalType = 'String';
        }
        field(94; YomiMiddleName; Text[50])
        {
            Caption = 'Yomi Middle Name';
            Description = 'Pronunciation of the middle name of the user, written in phonetic hiragana or katakana characters.';
            ExternalName = 'yomimiddlename';
            ExternalType = 'String';
        }
        field(95; YomiFirstName; Text[64])
        {
            Caption = 'Yomi First Name';
            Description = 'Pronunciation of the first name of the user, written in phonetic hiragana or katakana characters.';
            ExternalName = 'yomifirstname';
            ExternalType = 'String';
        }
        field(96; IsIntegrationUser; Boolean)
        {
            Caption = 'Integration user mode';
            Description = 'Check if user is an integration user.';
            ExternalName = 'isintegrationuser';
            ExternalType = 'Boolean';
        }
        field(97; DefaultFiltersPopulated; Boolean)
        {
            Caption = 'Default Filters Populated';
            Description = 'Indicates if default outlook filters have been populated.';
            ExternalAccess = Read;
            ExternalName = 'defaultfilterspopulated';
            ExternalType = 'Boolean';
        }
        field(98; CreatedOnBehalfBy; Guid)
        {
            Caption = 'Created By (Delegate)';
            Description = 'Unique identifier of the delegate user who created the systemuser.';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(99; ModifiedOnBehalfBy; Guid)
        {
            Caption = 'Modified By (Delegate)';
            Description = 'Unique identifier of the delegate user who last modified the systemuser.';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(100; ModifiedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedOnBehalfBy)));
            Caption = 'ModifiedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(101; CreatedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            Caption = 'CreatedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(102; EmailRouterAccessApproval; Option)
        {
            Caption = 'Primary Email Status';
            Description = 'Shows the status of the primary email address.';
            ExternalAccess = Modify;
            ExternalName = 'emailrouteraccessapproval';
            ExternalType = 'Picklist';
            InitValue = Empty;
            OptionCaption = 'Empty,Approved,Pending Approval,Rejected';
            OptionOrdinalValues = 0, 1, 2, 3;
            OptionMembers = Empty,Approved,PendingApproval,Rejected;
        }
        field(103; TransactionCurrencyId; Guid)
        {
            Caption = 'Currency';
            Description = 'Unique identifier of the currency associated with the systemuser.';
            ExternalName = 'transactioncurrencyid';
            ExternalType = 'Lookup';
            TableRelation = "CRM Transactioncurrency".TransactionCurrencyId;
        }
        field(104; TransactionCurrencyIdName; Text[100])
        {
            CalcFormula = lookup("CRM Transactioncurrency".CurrencyName where(TransactionCurrencyId = field(TransactionCurrencyId)));
            Caption = 'TransactionCurrencyIdName';
            ExternalAccess = Read;
            ExternalName = 'transactioncurrencyidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(105; ExchangeRate; Decimal)
        {
            Caption = 'Exchange Rate';
            Description = 'Exchange rate for the currency associated with the systemuser with respect to the base currency.';
            ExternalAccess = Read;
            ExternalName = 'exchangerate';
            ExternalType = 'Decimal';
        }
        field(106; CALType; Option)
        {
            Caption = 'License Type';
            Description = 'License type of user.';
            ExternalName = 'caltype';
            ExternalType = 'Picklist';
            InitValue = Professional;
            OptionCaption = 'Professional,Administrative,Basic,Device Professional,Device Basic,Essential,Device Essential,Enterprise,Device Enterprise';
            OptionOrdinalValues = 0, 1, 2, 3, 4, 5, 6, 7, 8;
            OptionMembers = Professional,Administrative,Basic,DeviceProfessional,DeviceBasic,Essential,DeviceEssential,Enterprise,DeviceEnterprise;
        }
        field(107; IsLicensed; Boolean)
        {
            Caption = 'User Licensed';
            Description = 'Information about whether the user is licensed.';
            ExternalName = 'islicensed';
            ExternalType = 'Boolean';
        }
        field(108; IsSyncWithDirectory; Boolean)
        {
            Caption = 'User Synced';
            Description = 'Information about whether the user is synced with the directory.';
            ExternalName = 'issyncwithdirectory';
            ExternalType = 'Boolean';
        }
        field(109; YammerEmailAddress; Text[200])
        {
            Caption = 'Yammer Email';
            Description = 'User''s Yammer login email address';
            ExtendedDatatype = EMail;
            ExternalName = 'yammeremailaddress';
            ExternalType = 'String';
        }
        field(110; YammerUserId; Text[128])
        {
            Caption = 'Yammer User ID';
            Description = 'User''s Yammer ID';
            ExternalName = 'yammeruserid';
            ExternalType = 'String';
        }
        field(111; UserLicenseType; Integer)
        {
            Caption = 'User License Type';
            Description = 'Shows the type of user license.';
            ExternalName = 'userlicensetype';
            ExternalType = 'Integer';
        }
        field(112; EntityImageId; Guid)
        {
            Caption = 'Entity Image Id';
            Description = 'For internal use only.';
            ExternalAccess = Read;
            ExternalName = 'entityimageid';
            ExternalType = 'Uniqueidentifier';
        }
        field(113; Address2_Composite; BLOB)
        {
            Caption = 'Other Address';
            Description = 'Shows the complete secondary address.';
            ExternalAccess = Read;
            ExternalName = 'address2_composite';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(114; Address1_Composite; BLOB)
        {
            Caption = 'Address';
            Description = 'Shows the complete primary address.';
            ExternalAccess = Read;
            ExternalName = 'address1_composite';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(115; ProcessId; Guid)
        {
            Caption = 'Process';
            Description = 'Shows the ID of the process.';
            ExternalName = 'processid';
            ExternalType = 'Uniqueidentifier';
        }
        field(116; StageId; Guid)
        {
            Caption = 'Process Stage';
            Description = 'Shows the ID of the stage.';
            ExternalName = 'stageid';
            ExternalType = 'Uniqueidentifier';
        }
        field(117; IsEmailAddressApprovedByO365Ad; Boolean)
        {
            Caption = 'Email Address O365 Admin Approval Status';
            Description = 'Shows the status of approval of the email address by O365 Admin.';
            ExternalAccess = Read;
            ExternalName = 'isemailaddressapprovedbyo365admin';
            ExternalType = 'Boolean';
        }
        field(118; TraversedPath; Text[250])
        {
            Caption = 'Traversed Path';
            Description = 'For internal use only.';
            ExternalName = 'traversedpath';
            ExternalType = 'String';
        }
        field(119; SharePointEmailAddress; Text[250])
        {
            Caption = 'SharePoint Email Address';
            Description = 'SharePoint Work Email Address';
            ExternalName = 'sharepointemailaddress';
            ExternalType = 'String';
        }
        field(120; ApplicationId; Guid)
        {
            Caption = 'Application ID';
            Description = 'The identifier for the application. This is used to access data in another application.';
            ExternalName = 'applicationid';
            ExternalType = 'Uniqueidentifier';
        }
    }

    keys
    {
        key(Key1; SystemUserId)
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

