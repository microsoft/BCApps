// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Task;

table 1175 "User Task Group"
{
    Caption = 'User Task Group';
    DataCaptionFields = "Code", Description;
    DrillDownPageId = "User Task Groups";
    LookupPageId = "User Task Groups";
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
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
        UserTaskGroupMember: Record "User Task Group Member";
    begin
        Message(GroupDeleteActionMsg, Code);
        UserTaskGroupMember.SetRange("User Task Group Code", Code);
        if not UserTaskGroupMember.IsEmpty() then
            UserTaskGroupMember.DeleteAll(true);
    end;

    var
        GroupDeleteActionMsg: Label 'If you delete the user task group with the code %1, any user tasks that are assigned to this group are not deleted.', Comment = '%1 = group code';
}

