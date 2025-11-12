// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Task;

table 5082 "Activity Step"
{
    Caption = 'Activity Step';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Activity Code"; Code[10])
        {
            Caption = 'Activity Code';
            NotBlank = true;
            TableRelation = Activity;
        }
        field(2; "Step No."; Integer)
        {
            Caption = 'Step No.';
        }
        field(3; Type; Enum "Task Type")
        {
            Caption = 'Type';
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(5; Priority; Option)
        {
            Caption = 'Priority';
            OptionCaption = 'Low,Normal,High';
            OptionMembers = Low,Normal,High;
        }
        field(6; "Date Formula"; DateFormula)
        {
            Caption = 'Date Formula';
        }
    }

    keys
    {
        key(Key1; "Activity Code", "Step No.")
        {
            Clustered = true;
        }
        key(Key2; "Activity Code", Type)
        {
        }
    }

    fieldgroups
    {
    }
}

