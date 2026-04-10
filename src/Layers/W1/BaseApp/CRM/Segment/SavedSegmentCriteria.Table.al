// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Segment;

using System.Security.AccessControl;

table 5098 "Saved Segment Criteria"
{
    Caption = 'Saved Segment Criteria';
    DataClassification = CustomerContent;
    LookupPageID = "Saved Segment Criteria List";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the code of the saved segment criteria.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the saved segment criteria.';
        }
        field(4; "User ID"; Code[50])
        {
            Caption = 'User ID';
            ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(5; "No. of Actions"; Integer)
        {
            CalcFormula = count("Saved Segment Criteria Line" where("Segment Criteria Code" = field(Code),
                                                                     Type = const(Action)));
            Caption = 'No. of Actions';
            ToolTip = 'Specifies the number of actions that make up the segment criteria.';
            Editable = false;
            FieldClass = FlowField;
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
        SavedSegCriteriaLine: Record "Saved Segment Criteria Line";
    begin
        SavedSegCriteriaLine.SetRange("Segment Criteria Code", Code);
        SavedSegCriteriaLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
    end;
}

