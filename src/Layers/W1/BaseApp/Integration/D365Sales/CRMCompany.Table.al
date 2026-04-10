// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 7206 "CRM Company"
{
    ExternalName = 'cdm_company';
    TableType = CRM;
    Description = 'A legal entity formed to carry on a business.';
    DataClassification = CustomerContent;

    fields
    {
        field(1; cdm_companyId; GUID)
        {
            ExternalName = 'cdm_companyid';
            ExternalType = 'Uniqueidentifier';
            ExternalAccess = Insert;
            Description = 'Unique identifier for company or legal entity instances';
            Caption = 'Company';
        }
        field(2; CreatedOn; Datetime)
        {
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
            ExternalAccess = Read;
            Description = 'Date and time when the record was created.';
            Caption = 'Created On';
        }
        field(3; CreatedBy; GUID)
        {
            ExternalName = 'createdby';
            ExternalType = 'Lookup';
            ExternalAccess = Read;
            Description = 'Unique identifier of the user who created the record.';
            Caption = 'Created By';
            TableRelation = "CRM SystemUser".SystemUserId;
        }
        field(4; ModifiedOn; Datetime)
        {
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
            ExternalAccess = Read;
            Description = 'Date and time when the record was modified.';
            Caption = 'Modified On';
        }
        field(5; ModifiedBy; GUID)
        {
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            ExternalAccess = Read;
            Description = 'Unique identifier of the user who modified the record.';
            Caption = 'Modified By';
            TableRelation = "CRM SystemUser".SystemUserId;
        }
        field(6; CreatedOnBehalfBy; GUID)
        {
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            ExternalAccess = Read;
            Description = 'Unique identifier of the delegate user who created the record.';
            Caption = 'Created By (Delegate)';
            TableRelation = "CRM SystemUser".SystemUserId;
        }
        field(7; ModifiedOnBehalfBy; GUID)
        {
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            ExternalAccess = Read;
            Description = 'Unique identifier of the delegate user who modified the record.';
            Caption = 'Modified By (Delegate)';
            TableRelation = "CRM SystemUser".SystemUserId;
        }
        field(8; CreatedByName; Text[200])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("CRM SystemUser".FullName where(SystemUserId = field(CreatedBy)));
            ExternalName = 'createdbyname';
            ExternalType = 'String';
            ExternalAccess = Read;
            Caption = 'Created By Name';
        }
        field(10; CreatedOnBehalfByName; Text[200])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("CRM SystemUser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            ExternalAccess = Read;
            Caption = 'Created On Behalf By Name';
        }
        field(12; ModifiedByName; Text[200])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("CRM SystemUser".FullName where(SystemUserId = field(ModifiedBy)));
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            ExternalAccess = Read;
            Caption = 'Modified By Name';
        }
        field(14; ModifiedOnBehalfByName; Text[200])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("CRM SystemUser".FullName where(SystemUserId = field(ModifiedOnBehalfBy)));
            ExternalName = 'modifiedonbehalfbyname';
            ExternalType = 'String';
            ExternalAccess = Read;
            Caption = 'Modified On Behalf By Name';
        }
        field(16; OwnerId; GUID)
        {
            ExternalName = 'ownerid';
            ExternalType = 'Owner';
            Description = 'Owner Id';
            Caption = 'Owner';
        }
        field(21; OwningBusinessUnit; GUID)
        {
            ExternalName = 'owningbusinessunit';
            ExternalType = 'Lookup';
            ExternalAccess = Read;
            Description = 'Unique identifier for the business unit that owns the record';
            Caption = 'Owning Business Unit';
            TableRelation = "CRM BusinessUnit".BusinessUnitId;
        }
        field(22; OwningUser; GUID)
        {
            ExternalName = 'owninguser';
            ExternalType = 'Lookup';
            ExternalAccess = Read;
            Description = 'Unique identifier for the user that owns the record.';
            Caption = 'Owning User';
            TableRelation = "CRM SystemUser".SystemUserId;
        }
        field(23; OwningTeam; GUID)
        {
            ExternalName = 'owningteam';
            ExternalType = 'Lookup';
            ExternalAccess = Read;
            Description = 'Unique identifier for the team that owns the record.';
            Caption = 'Owning Team';
            TableRelation = "CRM Team".TeamId;
        }
        field(24; OwningBusinessUnitName; Text[160])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("CRM BusinessUnit".Name where(BusinessUnitId = field(OwningBusinessUnit)));
            ExternalName = 'owningbusinessunitname';
            ExternalType = 'String';
            ExternalAccess = Read;
        }
        field(25; statecode; Option)
        {
            ExternalName = 'statecode';
            ExternalType = 'State';
            ExternalAccess = Modify;
            Description = 'Status of the Company';
            Caption = 'Status';
            InitValue = " ";
            OptionMembers = " ",Active,Inactive;
            OptionOrdinalValues = -1, 0, 1;
        }
        field(27; statuscode; Option)
        {
            ExternalName = 'statuscode';
            ExternalType = 'Status';
            Description = 'Reason for the status of the Company';
            Caption = 'Status Reason';
            InitValue = " ";
            OptionMembers = " ",Active,Inactive;
            OptionOrdinalValues = -1, 1, 2;
        }
        field(29; VersionNumber; BigInteger)
        {
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
            ExternalAccess = Read;
            Description = 'Version Number';
            Caption = 'Version Number';
        }
        field(30; ImportSequenceNumber; Integer)
        {
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
            ExternalAccess = Insert;
            Description = 'Sequence number of the import that created this record.';
            Caption = 'Import Sequence Number';
        }
        field(31; OverriddenCreatedOn; Date)
        {
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
            ExternalAccess = Insert;
            Description = 'Date and time that the record was migrated.';
            Caption = 'Record Created On';
        }
        field(32; TimeZoneRuleVersionNumber; Integer)
        {
            ExternalName = 'timezoneruleversionnumber';
            ExternalType = 'Integer';
            Description = 'For internal use only.';
            Caption = 'Time Zone Rule Version Number';
        }
        field(33; UTCConversionTimeZoneCode; Integer)
        {
            ExternalName = 'utcconversiontimezonecode';
            ExternalType = 'Integer';
            Description = 'Time zone code that was in use when the record was created.';
            Caption = 'UTC Conversion Time Zone Code';
        }
        field(34; cdm_CompanyCode; Text[30])
        {
            ExternalName = 'cdm_companycode';
            ExternalType = 'String';
            Description = 'The code of the company or legal table';
            Caption = 'Company Code';
        }
        field(35; cdm_defaultowningteam; GUID)
        {
            ExternalName = 'cdm_defaultowningteam';
            ExternalType = 'Lookup';
            Description = 'Specifies which team should own new records created which are related to this company by default.';
            Caption = 'Default owning team';
            TableRelation = "CRM Team".TeamId;
        }
        field(36; cdm_IsEnabledforDualWrite; Boolean)
        {
            ExternalName = 'cdm_isenabledfordualwrite';
            ExternalType = 'Boolean';
            Description = '';
            Caption = 'Is Enabled for Dual Write';
        }
        field(38; cdm_Name; Text[100])
        {
            ExternalName = 'cdm_name';
            ExternalType = 'String';
            Description = 'The name of the company or legal entity';
            Caption = 'Name';
        }
        field(39; cdm_defaultowningteamName; Text[160])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("CRM Team".Name where(TeamId = field(cdm_defaultowningteam)));
            ExternalName = 'cdm_defaultowningteamname';
            ExternalType = 'String';
            ExternalAccess = Read;
            Caption = 'Default Owning Team Name';
        }
    }
    keys
    {
        key(PK; cdm_companyId)
        {
            Clustered = true;
        }
        key(Name; cdm_CompanyCode)
        {
        }
    }
    fieldgroups
    {
        fieldgroup(DropDown; cdm_CompanyCode)
        {
        }
    }
}