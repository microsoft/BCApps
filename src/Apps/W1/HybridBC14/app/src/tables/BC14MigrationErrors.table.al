// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

table 50157 "BC14 Migration Errors"
{
    DataClassification = CustomerContent;
    Description = 'BC14 Migration Errors';

    fields
    {
        field(1; Id; Integer)
        {
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(2; "Migration Type"; Text[250])
        {
            DataClassification = SystemMetadata;
        }
        field(3; "Destination Table ID"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(4; "Company Name"; Text[30])
        {
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(5; "Error Message"; Text[250])
        {
            DataClassification = CustomerContent;
        }
        field(6; "Error Code"; Code[20])
        {
            DataClassification = SystemMetadata;
        }
        field(7; "Scheduled For Retry"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(8; "Exception Message"; Text[250])
        {
            DataClassification = CustomerContent;
        }
        field(9; "Exception Call Stack"; Blob)
        {
            DataClassification = SystemMetadata;
        }
        field(10; "Record Id"; RecordId)
        {
            DataClassification = SystemMetadata;
        }
        field(11; "Created On"; DateTime)
        {
            DataClassification = SystemMetadata;
        }
        field(12; "Source Table ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Source Table ID';
        }
        field(13; "Source Table Name"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'Source Table Name';
        }
        field(14; "Source Record Key"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Source Record Key';
        }
        field(15; "Retry Count"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Retry Count';
            InitValue = 0;
        }
        field(16; "Last Retry On"; DateTime)
        {
            DataClassification = SystemMetadata;
            Caption = 'Last Retry On';
        }
        field(17; "Resolved"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Resolved';
            InitValue = false;
        }
        field(18; "Resolved On"; DateTime)
        {
            DataClassification = SystemMetadata;
            Caption = 'Resolved On';
        }
        field(19; "Resolved By"; Code[50])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Resolved By';
        }
        field(20; "Resolution Notes"; Text[500])
        {
            DataClassification = CustomerContent;
            Caption = 'Resolution Notes';
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
        key(Key2; "Destination Table ID", "Company Name")
        {
        }
        key(Key3; "Source Table ID", "Company Name", "Resolved")
        {
        }
        key(Key4; "Scheduled For Retry", "Resolved")
        {
        }
    }

    procedure MarkAsResolved(ResolutionNote: Text[500])
    begin
        Rec."Resolved" := true;
        Rec."Resolved On" := CurrentDateTime();
        Rec."Resolved By" := CopyStr(UserId(), 1, MaxStrLen(Rec."Resolved By"));
        Rec."Resolution Notes" := ResolutionNote;
        Rec.Modify(true);
    end;

    procedure ScheduleForRetry()
    begin
        Rec."Scheduled For Retry" := true;
        Rec."Retry Count" += 1;
        Rec."Last Retry On" := CurrentDateTime();
        Rec.Modify(true);
    end;

    procedure GetUnresolvedErrorCount(TableId: Integer; CompanyNameFilter: Text[30]): Integer
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
    begin
        BC14MigrationErrors.SetRange("Destination Table ID", TableId);
        BC14MigrationErrors.SetRange("Company Name", CompanyNameFilter);
        BC14MigrationErrors.SetRange("Resolved", false);
        exit(BC14MigrationErrors.Count());
    end;
}
