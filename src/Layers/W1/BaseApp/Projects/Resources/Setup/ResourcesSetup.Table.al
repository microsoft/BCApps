// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Setup;

using Microsoft.Foundation.NoSeries;
using Microsoft.Projects.TimeSheet;

table 314 "Resources Setup"
{
    Caption = 'Resources Setup';
    DataClassification = CustomerContent;
    DrillDownPageID = "Resources Setup";
    LookupPageID = "Resources Setup";

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Resource Nos."; Code[20])
        {
            Caption = 'Resource Nos.';
            ToolTip = 'Specifies the number series code you can use to assign numbers to resources.';
            TableRelation = "No. Series";
        }
        field(950; "Time Sheet Nos."; Code[20])
        {
            Caption = 'Time Sheet Nos.';
            ToolTip = 'Specifies the number series code you can use to assign document numbers to time sheets.';
            TableRelation = "No. Series";
        }
        field(951; "Time Sheet First Weekday"; Option)
        {
            Caption = 'Time Sheet First Weekday';
            ToolTip = 'Specifies the first weekday to use on a time sheet. The default is Monday.';
            OptionCaption = 'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday';
            OptionMembers = Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday;

            trigger OnValidate()
            begin
                if "Time Sheet First Weekday" <> xRec."Time Sheet First Weekday" then begin
                    TimeSheetHeader.Reset();
                    if not TimeSheetHeader.IsEmpty() then
                        Error(Text002, FieldCaption("Time Sheet First Weekday"));
                end;
            end;
        }
        field(952; "Time Sheet by Job Approval"; Option)
        {
            Caption = 'Time Sheet by Project Approval';
            ToolTip = 'Specifies whether time sheets must be approved on a per job basis by the user specified for the job.';
            OptionCaption = 'Never,Machine Only,Always';
            OptionMembers = Never,"Machine Only",Always;

            trigger OnValidate()
            begin
                if "Time Sheet by Job Approval" <> xRec."Time Sheet by Job Approval" then begin
                    TimeSheetLine.Reset();
                    TimeSheetLine.SetRange(Type, TimeSheetLine.Type::Job);
                    TimeSheetLine.SetRange(Status, TimeSheetLine.Status::Submitted);
                    if not TimeSheetLine.IsEmpty() then
                        Error(Text001, FieldCaption("Time Sheet by Job Approval"));
                end;
            end;
        }
#if not CLEANSCHEMA25
        field(953; "Use New Time Sheet Experience"; Boolean)
        {
            Caption = 'Use New Time Sheet Experience';
            DataClassification = SystemMetadata;
            InitValue = true;
            ObsoleteReason = 'Replacement of NewTimeSheetExperience feature key until removal of old one.';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
        field(954; "Time Sheet Submission Policy"; Option)
        {
            Caption = 'Time Sheet Submission Policy';
            ToolTip = 'Specifies the policy for submitting time sheets.';
            OptionCaption = 'Empty Lines Not Submitted,Stop and Show Empty Line Error';
            OptionMembers = "Empty Lines Not Submitted","Stop and Show Empty Line Error";
        }
        field(955; "Incl. Time Sheet Date in Jnl."; Boolean)
        {
            Caption = 'Include Time Sheet Date in Project Journal Line';
            ToolTip = 'Specifies whether the date of the time sheets entry is included in the description in project journal line.';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 cannot be changed, because there is at least one submitted time sheet line with Type=Project.';
        Text002: Label '%1 cannot be changed, because there is at least one time sheet.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure UseLegacyPosting(): Boolean
    var
        FeatureKeyManagement: Codeunit System.Environment.Configuration."Feature Key Management";
    begin
        exit(not FeatureKeyManagement.IsConcurrentResourcePostingEnabled());
    end;
}

