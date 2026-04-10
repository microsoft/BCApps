// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5368 "CRM NAV Connection"
{
    Caption = 'CRM NAV Connection';
    Description = 'An entity for storing the link to connect to Microsoft Dynamics NAV.';
    ExternalName = 'nav_connection';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; NAVConnectionId; Guid)
        {
            Caption = 'Business Central Connection';
            Description = 'Unique identifier for entity instances';
            ExternalAccess = Insert;
            ExternalName = 'nav_connectionid';
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
            Description = 'Status of the Dynamics NAV Connection';
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
            Description = 'Reason for the status of the Dynamics NAV Connection';
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
        field(21; Name; Text[100])
        {
            Caption = 'Name';
            ExternalName = 'nav_name';
            ExternalType = 'String';
        }
        field(22; "Dynamics NAV URL"; Text[250])
        {
            Caption = 'Business Central URL';
            Description = 'The CRM API URL to a Dynamics NAV instance.';
            ExternalName = 'nav_dynamicsnavurl';
            ExternalType = 'String';
        }
        field(23; "Dynamics NAV OData URL"; Text[250])
        {
            Caption = 'Business Central OData URL';
            Description = 'The CRM API URL to a Dynamics NAV instance OData web services.';
            ExternalName = 'nav_dynamicsnavodataurl';
            ExternalType = 'String';
        }
        field(24; "Dynamics NAV OData Username"; Text[250])
        {
            Caption = 'Dynamics NAV OData Username';
            Description = 'The username to access Dynamics NAV instance OData web services.';
            ExternalName = 'nav_dynamicsnavodatausername';
            ExternalType = 'String';
        }
        field(25; "Dynamics NAV OData Accesskey"; Text[250])
        {
            Caption = 'Dynamics NAV OData Accesskey';
            Description = 'The accesskey for Dynamics NAV instance OData web services.';
            ExternalName = 'nav_dynamicsnavodataaccesskey';
            ExternalType = 'String';
        }
    }

    keys
    {
        key(Key1; NAVConnectionId)
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

