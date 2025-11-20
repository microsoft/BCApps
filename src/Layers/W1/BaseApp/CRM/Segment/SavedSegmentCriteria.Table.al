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
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(5; "No. of Actions"; Integer)
        {
            CalcFormula = count("Saved Segment Criteria Line" where("Segment Criteria Code" = field(Code),
                                                                     Type = const(Action)));
            Caption = 'No. of Actions';
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

