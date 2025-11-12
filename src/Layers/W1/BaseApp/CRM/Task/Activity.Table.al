// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Task;

table 5081 Activity
{
    Caption = 'Activity';
    DataCaptionFields = "Code", Description;
    DataClassification = CustomerContent;
    LookupPageID = "Activity List";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ActivityStep: Record "Activity Step";
    begin
        ActivityStep.SetRange("Activity Code", Code);
        ActivityStep.DeleteAll();
    end;

    procedure IncludesMeeting(ActivityCode: Code[10]): Boolean
    var
        ActivityStep: Record "Activity Step";
    begin
        ActivityStep.SetCurrentKey("Activity Code", ActivityStep.Type);
        ActivityStep.SetRange("Activity Code", ActivityCode);
        ActivityStep.SetRange(Type, ActivityStep.Type::Meeting);
        exit(not ActivityStep.IsEmpty());
    end;
}

