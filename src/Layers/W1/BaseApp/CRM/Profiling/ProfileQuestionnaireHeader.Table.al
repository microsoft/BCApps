// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Profiling;

using Microsoft.CRM.BusinessRelation;

table 5087 "Profile Questionnaire Header"
{
    Caption = 'Profile Questionnaire Header';
    DataCaptionFields = "Code", Description;
    DataClassification = CustomerContent;
    DrillDownPageID = "Profile Questionnaire List";
    LookupPageID = "Profile Questionnaires";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(3; "Contact Type"; Enum "Profile Questionnaire Contact Type")
        {
            Caption = 'Contact Type';
        }
        field(4; "Business Relation Code"; Code[10])
        {
            Caption = 'Business Relation Code';
            TableRelation = "Business Relation";
        }
        field(5; Priority; Enum "Profile Questionnaire Priority")
        {
            Caption = 'Priority';
            InitValue = Normal;

            trigger OnValidate()
            var
                ContProfileAnswer: Record "Contact Profile Answer";
            begin
                ContProfileAnswer.SetCurrentKey("Profile Questionnaire Code");
                ContProfileAnswer.SetRange("Profile Questionnaire Code", Code);
                ContProfileAnswer.ModifyAll("Profile Questionnaire Priority", Priority);
                Modify();
            end;
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
    begin
        ProfileQuestnLine.Reset();
        ProfileQuestnLine.SetRange("Profile Questionnaire Code", Code);
        ProfileQuestnLine.DeleteAll(true);
    end;

    var
        ProfileQuestnLine: Record "Profile Questionnaire Line";
}

