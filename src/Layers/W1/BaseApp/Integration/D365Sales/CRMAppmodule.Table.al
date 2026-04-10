// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5369 "CRM Appmodule"
{
    // Dynamics CRM Version: 9.1.0.853

    Caption = 'Model-driven App';
    Description = 'A role-based, modular business app that provides task-based functionality for a particular area of work.';
    ExternalName = 'appmodule';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; AppModuleId; Guid)
        {
            Caption = 'AppModuleId';
            DataClassification = SystemMetadata;
            Description = 'Unique identifier for entity instances';
            ExternalName = 'appmoduleid';
            ExternalType = 'Uniqueidentifier';
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
            DataClassification = SystemMetadata;
            Description = 'Name of App Module';
            ExternalName = 'name';
            ExternalType = 'String';
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
            Description = 'Description for entity';
            ExternalName = 'description';
            ExternalType = 'String';
        }
        field(4; VersionNumber; BigInteger)
        {
            Caption = 'VersionNumber';
            DataClassification = SystemMetadata;
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(5; FormFactor; Integer)
        {
            Caption = 'Form Factor';
            DataClassification = SystemMetadata;
            Description = 'Form Factor';
            ExternalName = 'formfactor';
            ExternalType = 'Integer';
            MaxValue = 8;
            MinValue = 1;
        }
        field(6; ComponentState; Option)
        {
            Caption = 'Component State';
            DataClassification = SystemMetadata;
            Description = 'For internal use only';
            ExternalAccess = Read;
            ExternalName = 'componentstate';
            ExternalType = 'Picklist';
            InitValue = " ";
            OptionCaption = ' ,Published,Unpublished,Deleted,Deleted Unpublished';
            OptionOrdinalValues = -1, 0, 1, 2, 3;
            OptionMembers = " ",Published,Unpublished,Deleted,DeletedUnpublished;
        }
        field(7; IntroducedVersion; Text[100])
        {
            Caption = 'Introduced Version';
            DataClassification = SystemMetadata;
            Description = 'Version in which the similarity rule is introduced.';
            ExternalAccess = Insert;
            ExternalName = 'introducedversion';
            ExternalType = 'String';
        }
        field(8; SolutionId; Guid)
        {
            Caption = 'Solution';
            DataClassification = SystemMetadata;
            Description = 'Unique identifier of the associated solution.';
            ExternalAccess = Read;
            ExternalName = 'solutionid';
            ExternalType = 'Uniqueidentifier';
        }
        field(9; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            DataClassification = SystemMetadata;
            Description = 'Date and time when the record was created.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(10; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            DataClassification = SystemMetadata;
            Description = 'Date and time when the record was modified.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
        }
        field(11; OverwriteTime; DateTime)
        {
            Caption = 'Overwrite Time';
            DataClassification = SystemMetadata;
            Description = 'Internal use only';
            ExternalAccess = Read;
            ExternalName = 'overwritetime';
            ExternalType = 'DateTime';
        }
        field(12; IsManaged; Boolean)
        {
            Caption = 'IsManaged';
            DataClassification = SystemMetadata;
            Description = 'Is Managed';
            ExternalAccess = Read;
            ExternalName = 'ismanaged';
            ExternalType = 'Boolean';
        }
        field(13; AppModuleVersion; Text[48])
        {
            Caption = 'App Module Version';
            DataClassification = SystemMetadata;
            Description = 'App Module Version';
            ExternalName = 'appmoduleversion';
            ExternalType = 'String';
        }
        field(14; IsFeatured; Boolean)
        {
            Caption = 'IsFeatured';
            DataClassification = SystemMetadata;
            Description = 'Is Featured';
            ExternalName = 'isfeatured';
            ExternalType = 'Boolean';
        }
        field(15; IsDefault; Boolean)
        {
            Caption = 'Is Default';
            DataClassification = SystemMetadata;
            Description = 'Is Default';
            ExternalName = 'isdefault';
            ExternalType = 'Boolean';
        }
        field(16; AppModuleXmlManaged; BLOB)
        {
            Caption = 'AppModuleXmlManaged';
            DataClassification = SystemMetadata;
            Description = 'App Module Xml Managed';
            ExternalName = 'appmodulexmlmanaged';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(17; PublishedOn; DateTime)
        {
            Caption = 'Published On';
            DataClassification = SystemMetadata;
            Description = 'Date and time when the record was published.';
            ExternalName = 'publishedon';
            ExternalType = 'DateTime';
        }
        field(18; URL; Text[200])
        {
            Caption = 'URL';
            DataClassification = SystemMetadata;
            Description = 'Contains URL';
            ExternalName = 'url';
            ExternalType = 'String';
        }
        field(19; AppModuleIdUnique; Guid)
        {
            Caption = 'App Module Unique Id';
            DataClassification = SystemMetadata;
            Description = 'Unique identifier of the App Module used when synchronizing customizations for the Microsoft Dynamics 365 client for Outlook';
            ExternalAccess = Insert;
            ExternalName = 'appmoduleidunique';
            ExternalType = 'Uniqueidentifier';
        }
        field(20; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            DataClassification = SystemMetadata;
            Description = 'Unique identifier of the data import or data migration that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
        }
        field(21; OverriddenCreatedOn; DateTime)
        {
            Caption = 'Record Created On';
            DataClassification = SystemMetadata;
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
        }
        field(22; WebResourceId; Guid)
        {
            Caption = 'Web Resource Id';
            DataClassification = SystemMetadata;
            Description = 'Unique identifier of the Web Resource';
            ExternalName = 'webresourceid';
            ExternalType = 'Uniqueidentifier';
        }
        field(23; ConfigXML; BLOB)
        {
            Caption = 'ConfigXML';
            DataClassification = SystemMetadata;
            Description = 'Contains configuration XML';
            ExternalName = 'configxml';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(24; ClientType; Integer)
        {
            Caption = 'Client Type';
            DataClassification = SystemMetadata;
            Description = 'Client Type such as Web or UCI';
            ExternalName = 'clienttype';
            ExternalType = 'Integer';
            MaxValue = 31;
            MinValue = 1;
        }
        field(25; UniqueName; Text[100])
        {
            Caption = 'Unique Name';
            DataClassification = SystemMetadata;
            Description = 'Unique Name of App Module';
            ExternalName = 'uniquename';
            ExternalType = 'String';
        }
        field(26; WelcomePageId; Guid)
        {
            Caption = 'Welcome Page Id';
            DataClassification = SystemMetadata;
            Description = 'Unique identifier of the Web Resource as Welcome Page Id';
            ExternalName = 'welcomepageid';
            ExternalType = 'Uniqueidentifier';
        }
        field(27; Descriptor; Text[250])
        {
            Caption = 'Descriptor';
            DataClassification = SystemMetadata;
            Description = 'App Module Descriptor';
            ExternalAccess = Read;
            ExternalName = 'descriptor';
            ExternalType = 'String';
        }
        field(28; EventHandlers; Text[250])
        {
            Caption = 'Event Handlers';
            DataClassification = SystemMetadata;
            Description = 'App Module Event Handlers';
            ExternalName = 'eventhandlers';
            ExternalType = 'String';
        }
    }

    keys
    {
        key(Key1; AppModuleId)
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

