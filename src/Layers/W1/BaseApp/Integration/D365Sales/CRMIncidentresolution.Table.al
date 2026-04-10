// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5350 "CRM Incidentresolution"
{
    // Dynamics CRM Version: 7.1.0.2040

    Caption = 'CRM Incidentresolution';
    Description = 'Special type of activity that includes description of the resolution, billing status, and the duration of the case.';
    ExternalName = 'incidentresolution';
    TableType = CRM;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ModifiedOn; DateTime)
        {
            Caption = 'Modified On';
            Description = 'Date and time when the case resolution activity was last modified.';
            ExternalAccess = Read;
            ExternalName = 'modifiedon';
            ExternalType = 'DateTime';
        }
        field(2; ActualStart; Date)
        {
            Caption = 'Actual Start';
            Description = 'Actual start time of the case resolution activity.';
            ExternalName = 'actualstart';
            ExternalType = 'DateTime';
        }
        field(3; CreatedBy; Guid)
        {
            Caption = 'Created By';
            Description = 'Unique identifier of the user who created the case resolution activity.';
            ExternalAccess = Read;
            ExternalName = 'createdby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(4; ActualDurationMinutes; Integer)
        {
            Caption = 'Actual Duration';
            Description = 'Actual duration of the case resolution activity in minutes.';
            ExternalName = 'actualdurationminutes';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(5; IsWorkflowCreated; Boolean)
        {
            Caption = 'Is Workflow Created';
            Description = 'Information that specifies if the case resolution activity was created from a workflow rule.';
            ExternalName = 'isworkflowcreated';
            ExternalType = 'Boolean';
        }
        field(6; ScheduledEnd; Date)
        {
            Caption = 'Scheduled End';
            Description = 'Scheduled end time of the case resolution activity.';
            ExternalName = 'scheduledend';
            ExternalType = 'DateTime';
        }
        field(7; Category; Text[250])
        {
            Caption = 'Category';
            Description = 'Category for the case resolution activity.';
            ExternalName = 'category';
            ExternalType = 'String';
        }
        field(8; IsBilled; Boolean)
        {
            Caption = 'Is Billed';
            Description = 'Information about whether the case resolution activity was billed as part of resolving a case.';
            ExternalName = 'isbilled';
            ExternalType = 'Boolean';
        }
        field(9; ActivityId; Guid)
        {
            Caption = 'Case Resolution';
            Description = 'Unique identifier of the case resolution activity.';
            ExternalAccess = Insert;
            ExternalName = 'activityid';
            ExternalType = 'Uniqueidentifier';
        }
        field(10; StateCode; Option)
        {
            Caption = 'Status';
            Description = 'Shows whether the case resolution is open, completed, or canceled. By default, all case resolutions are completed and the status value can''t be changed.';
            ExternalAccess = Modify;
            ExternalName = 'statecode';
            ExternalType = 'State';
            InitValue = Open;
            OptionCaption = 'Open,Completed,Canceled';
            OptionOrdinalValues = 0, 1, 2;
            OptionMembers = Open,Completed,Canceled;
        }
        field(11; Description; BLOB)
        {
            Caption = 'Description';
            Description = 'Type additional information that describes the case resolution.';
            ExternalName = 'description';
            ExternalType = 'Memo';
            SubType = Memo;
        }
        field(12; StatusCode; Option)
        {
            Caption = 'Status Reason';
            Description = 'Reason for the status of the case resolution activity.';
            ExternalName = 'statuscode';
            ExternalType = 'Status';
            InitValue = " ";
            OptionCaption = ' ,Open,Closed,Canceled';
            OptionOrdinalValues = -1, 1, 2, 3;
            OptionMembers = " ",Open,Closed,Canceled;
        }
        field(13; OwnerId; Guid)
        {
            Caption = 'Owner';
            Description = 'Unique identifier of the user or team who owns the case resolution activity.';
            ExternalName = 'ownerid';
            ExternalType = 'Owner';
            TableRelation = if (OwnerIdType = const(systemuser)) "CRM Systemuser".SystemUserId
            else
            if (OwnerIdType = const(team)) "CRM Team".TeamId;
        }
        field(14; TimeSpent; Integer)
        {
            Caption = 'Time Spent';
            Description = 'Time spent on the case resolution activity.';
            ExternalName = 'timespent';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(15; Subject; Text[200])
        {
            Caption = 'Subject';
            Description = 'Subject associated with the case resolution activity.';
            ExternalName = 'subject';
            ExternalType = 'String';
        }
        field(16; CreatedOn; DateTime)
        {
            Caption = 'Created On';
            Description = 'Date and time when the case resolution activity was created.';
            ExternalAccess = Read;
            ExternalName = 'createdon';
            ExternalType = 'DateTime';
        }
        field(17; ModifiedBy; Guid)
        {
            Caption = 'Modified By';
            Description = 'Unique identifier of the user who last modified the case resolution activity.';
            ExternalAccess = Read;
            ExternalName = 'modifiedby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(18; ScheduledStart; Date)
        {
            Caption = 'Scheduled Start';
            Description = 'Scheduled start time of the case resolution activity.';
            ExternalName = 'scheduledstart';
            ExternalType = 'DateTime';
        }
        field(19; ScheduledDurationMinutes; Integer)
        {
            Caption = 'Scheduled Duration';
            Description = 'Scheduled duration of the case resolution activity, specified in minutes.';
            ExternalAccess = Read;
            ExternalName = 'scheduleddurationminutes';
            ExternalType = 'Integer';
            MinValue = 0;
        }
        field(20; VersionNumber; BigInteger)
        {
            Caption = 'Version Number';
            Description = 'Version number of the case.';
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
        field(21; ActualEnd; Date)
        {
            Caption = 'Actual End';
            Description = 'Actual end time of the case resolution activity.';
            ExternalName = 'actualend';
            ExternalType = 'DateTime';
        }
        field(22; OwningBusinessUnit; Guid)
        {
            Caption = 'Owning Business Unit';
            Description = 'Unique identifier of the business unit that owns the case resolution activity.';
            ExternalAccess = Read;
            ExternalName = 'owningbusinessunit';
            ExternalType = 'Lookup';
            TableRelation = "CRM Businessunit".BusinessUnitId;
        }
        field(23; IncidentId; Guid)
        {
            Caption = 'Case';
            Description = 'Unique identifier of the case.';
            ExternalName = 'incidentid';
            ExternalType = 'Lookup';
            TableRelation = if (IncidentIdType = const(incident)) "CRM Incident".IncidentId;
        }
        field(24; Subcategory; Text[250])
        {
            Caption = 'Sub-Category';
            Description = 'Subcategory of the case resolution activity.';
            ExternalName = 'subcategory';
            ExternalType = 'String';
        }
        field(25; OwningUser; Guid)
        {
            Caption = 'Owning User';
            Description = 'Unique identifier of the user who owns the case resolution.';
            ExternalAccess = Read;
            ExternalName = 'owninguser';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(26; CreatedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedBy)));
            Caption = 'CreatedByName';
            ExternalAccess = Read;
            ExternalName = 'createdbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(27; IncidentIdName; Text[200])
        {
            CalcFormula = lookup("CRM Incident".Title where(IncidentId = field(IncidentId)));
            Caption = 'IncidentIdName';
            ExternalAccess = Read;
            ExternalName = 'incidentidname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(28; ModifiedByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedBy)));
            Caption = 'ModifiedByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(29; OwnerIdType; Option)
        {
            Caption = 'OwnerIdType';
            ExternalName = 'owneridtype';
            ExternalType = 'EntityName';
            OptionCaption = ' ,systemuser,team';
            OptionMembers = " ",systemuser,team;
        }
        field(30; ImportSequenceNumber; Integer)
        {
            Caption = 'Import Sequence Number';
            Description = 'Unique identifier of the data import or data migration that created this record.';
            ExternalAccess = Insert;
            ExternalName = 'importsequencenumber';
            ExternalType = 'Integer';
        }
        field(31; TimeZoneRuleVersionNumber; Integer)
        {
            Caption = 'Time Zone Rule Version Number';
            Description = 'For internal use only.';
            ExternalName = 'timezoneruleversionnumber';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(32; UTCConversionTimeZoneCode; Integer)
        {
            Caption = 'UTC Conversion Time Zone Code';
            Description = 'Time zone code that was in use when the record was created.';
            ExternalName = 'utcconversiontimezonecode';
            ExternalType = 'Integer';
            MinValue = -1;
        }
        field(33; OverriddenCreatedOn; Date)
        {
            Caption = 'Record Created On';
            Description = 'Date and time that the record was migrated.';
            ExternalAccess = Insert;
            ExternalName = 'overriddencreatedon';
            ExternalType = 'DateTime';
        }
        field(34; IncidentIdType; Option)
        {
            Caption = 'IncidentIdType';
            ExternalAccess = Read;
            ExternalName = 'incidentidtype';
            ExternalType = 'EntityName';
            OptionCaption = ' ,incident';
            OptionMembers = " ",incident;
        }
        field(35; CreatedOnBehalfBy; Guid)
        {
            Caption = 'Created By (Delegate)';
            Description = 'Unique identifier of the delegate user who created the incidentresolution.';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(36; CreatedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(CreatedOnBehalfBy)));
            Caption = 'CreatedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'createdonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(37; ModifiedOnBehalfBy; Guid)
        {
            Caption = 'Modified By (Delegate)';
            Description = 'Unique identifier of the delegate user who last modified the incidentresolution.';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfby';
            ExternalType = 'Lookup';
            TableRelation = "CRM Systemuser".SystemUserId;
        }
        field(38; ModifiedOnBehalfByName; Text[200])
        {
            CalcFormula = lookup("CRM Systemuser".FullName where(SystemUserId = field(ModifiedOnBehalfBy)));
            Caption = 'ModifiedOnBehalfByName';
            ExternalAccess = Read;
            ExternalName = 'modifiedonbehalfbyname';
            ExternalType = 'String';
            FieldClass = FlowField;
        }
        field(39; IsRegularActivity; Boolean)
        {
            Caption = 'Is Regular Activity';
            Description = 'Information regarding whether the activity is a regular activity type or event type.';
            ExternalAccess = Read;
            ExternalName = 'isregularactivity';
            ExternalType = 'Boolean';
        }
        field(40; OwningTeam; Guid)
        {
            Caption = 'Owning Team';
            Description = 'Unique identifier of the team who owns the case resolution.';
            ExternalAccess = Read;
            ExternalName = 'owningteam';
            ExternalType = 'Lookup';
            TableRelation = "CRM Team".TeamId;
        }
    }

    keys
    {
        key(Key1; ActivityId)
        {
            Clustered = true;
        }
        key(Key2; Subject)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Subject)
        {
        }
    }
}

