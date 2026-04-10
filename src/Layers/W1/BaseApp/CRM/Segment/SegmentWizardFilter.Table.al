// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Segment;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Profiling;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Team;
using Microsoft.Foundation.Address;
using Microsoft.Inventory.Intrastat;

table 5096 "Segment Wizard Filter"
{
    Caption = 'Segment Wizard Filter';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Segment No."; Code[20])
        {
            Caption = 'Segment No.';
            TableRelation = "Segment Header";
        }
        field(2; Functionality; Option)
        {
            Caption = 'Functionality';
            OptionCaption = 'Add Contacts,Remove Contacts,Reduce Contacts,Refine Contacts';
            OptionMembers = "Add Contacts","Remove Contacts","Reduce Contacts","Refine Contacts";
        }
        field(3; "Mailing Group Code Filter"; Code[10])
        {
            Caption = 'Mailing Group Code Filter';
            FieldClass = FlowFilter;
            TableRelation = "Mailing Group";
        }
        field(4; "Industry Group Code Filter"; Code[10])
        {
            Caption = 'Industry Group Code Filter';
            FieldClass = FlowFilter;
            TableRelation = "Industry Group";
        }
        field(5; "Salesperson Code Filter"; Code[20])
        {
            Caption = 'Salesperson Code Filter';
            FieldClass = FlowFilter;
            TableRelation = "Salesperson/Purchaser";
        }
        field(6; "Country/Region Code Filter"; Code[10])
        {
            Caption = 'Country/Region Code Filter';
            FieldClass = FlowFilter;
            TableRelation = "Country/Region";
        }
        field(7; "Territory Code Filter"; Code[10])
        {
            Caption = 'Territory Code Filter';
            FieldClass = FlowFilter;
            TableRelation = Territory;
        }
        field(8; "Post Code Filter"; Code[20])
        {
            Caption = 'Post Code Filter';
            FieldClass = FlowFilter;
            TableRelation = "Post Code";
        }
        field(9; "Business Relation Code Filter"; Code[10])
        {
            Caption = 'Business Relation Code Filter';
            FieldClass = FlowFilter;
            TableRelation = "Business Relation";
        }
        field(10; "Profile Questn. Code Filter"; Code[20])
        {
            Caption = 'Profile Questn. Code Filter';
            FieldClass = FlowFilter;
            TableRelation = "Profile Questionnaire Header";
        }
        field(11; "Profile Questn. Line Filter"; Integer)
        {
            Caption = 'Profile Questn. Line Filter';
            FieldClass = FlowFilter;
            TableRelation = "Profile Questionnaire Line"."Line No." where("Profile Questionnaire Code" = field("Profile Questn. Code Filter"),
                                                                           Type = const(Answer));
        }
        field(12; "Job Responsibility Code Filter"; Code[10])
        {
            Caption = 'Job Responsibility Code Filter';
            FieldClass = FlowFilter;
            TableRelation = "Job Responsibility";
        }
        field(13; "Profile Questionnaire Code"; Code[20])
        {
            Caption = 'Profile Questionnaire Code';
            TableRelation = "Profile Questionnaire Header".Code;
        }
        field(15; "Add Additional Criteria"; Boolean)
        {
            Caption = 'Add Additional Criteria';
        }
        field(9501; "Wizard Step"; Option)
        {
            Caption = 'Wizard Step';
            Editable = false;
            OptionCaption = ' ,1,2,3,4,5,6';
            OptionMembers = " ","1","2","3","4","5","6";
        }
    }

    keys
    {
        key(Key1; "Segment No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        TempProfileQuestionnaireLine: Record "Profile Questionnaire Line" temporary;

    procedure SetParametersProfileQnLine(var FromProfileQuestionnaireLine: Record "Profile Questionnaire Line")
    begin
        TempProfileQuestionnaireLine.CopyFilters(FromProfileQuestionnaireLine);
    end;

    procedure SetProfileQnLine(var GetProfileQuestionnaireLine: Record "Profile Questionnaire Line")
    begin
        TempProfileQuestionnaireLine.DeleteAll();
        if GetProfileQuestionnaireLine.Find('-') then
            repeat
                TempProfileQuestionnaireLine := GetProfileQuestionnaireLine;
                TempProfileQuestionnaireLine.Insert();
            until GetProfileQuestionnaireLine.Next() = 0;
    end;
}

