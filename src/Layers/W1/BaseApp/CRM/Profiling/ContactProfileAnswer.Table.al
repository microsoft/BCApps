// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Profiling;

using Microsoft.CRM.Contact;

table 5089 "Contact Profile Answer"
{
    Caption = 'Contact Profile Answer';
    DataClassification = CustomerContent;
    DrillDownPageID = "Profile Contacts";

    fields
    {
        field(1; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            NotBlank = true;
            TableRelation = Contact;

            trigger OnValidate()
            var
                Cont: Record Contact;
            begin
                if Cont.Get("Contact No.") then
                    "Contact Company No." := Cont."Company No."
                else
                    "Contact Company No." := '';
            end;
        }
        field(2; "Contact Company No."; Code[20])
        {
            Caption = 'Contact Company No.';
            NotBlank = true;
            TableRelation = Contact where(Type = const(Company));
        }
        field(3; "Profile Questionnaire Code"; Code[20])
        {
            Caption = 'Profile Questionnaire Code';
            NotBlank = true;
            TableRelation = "Profile Questionnaire Header";

            trigger OnValidate()
            var
                ProfileQuestnHeader: Record "Profile Questionnaire Header";
            begin
                ProfileQuestnHeader.Get("Profile Questionnaire Code");
                "Profile Questionnaire Priority" := ProfileQuestnHeader.Priority;
            end;
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            TableRelation = "Profile Questionnaire Line"."Line No." where("Profile Questionnaire Code" = field("Profile Questionnaire Code"),
                                                                           Type = const(Answer));

            trigger OnValidate()
            var
                ProfileQuestnLine: Record "Profile Questionnaire Line";
            begin
                ProfileQuestnLine.Get("Profile Questionnaire Code", "Line No.");
                "Answer Priority" := ProfileQuestnLine.Priority;
            end;
        }
        field(5; Answer; Text[250])
        {
            CalcFormula = lookup("Profile Questionnaire Line".Description where("Profile Questionnaire Code" = field("Profile Questionnaire Code"),
                                                                                 "Line No." = field("Line No.")));
            Caption = 'Answer';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Contact Company Name"; Text[100])
        {
            CalcFormula = lookup(Contact."Company Name" where("No." = field("Contact No.")));
            Caption = 'Contact Company Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Contact Name"; Text[100])
        {
            CalcFormula = lookup(Contact.Name where("No." = field("Contact No.")));
            Caption = 'Contact Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Profile Questionnaire Priority"; Enum "Profile Questionnaire Priority")
        {
            Caption = 'Profile Questionnaire Priority';
            Editable = false;
        }
        field(9; "Answer Priority"; Enum "Profile Answer Priority")
        {
            Caption = 'Answer Priority';
        }
        field(10; "Last Date Updated"; Date)
        {
            Caption = 'Last Date Updated';
        }
        field(11; "Questions Answered (%)"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Questions Answered (%)';
            DecimalPlaces = 0 : 0;
        }
        field(5088; "Profile Questionnaire Value"; Text[250])
        {
            Caption = 'Profile Questionnaire Value';
        }
    }

    keys
    {
        key(Key1; "Contact No.", "Profile Questionnaire Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Contact No.", "Answer Priority", "Profile Questionnaire Priority")
        {
        }
        key(Key3; "Profile Questionnaire Code", "Line No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        Contact: Record Contact;
        ProfileQuestnLine: Record "Profile Questionnaire Line";
    begin
        ProfileQuestnLine.Get("Profile Questionnaire Code", QuestionLineNo());
        ProfileQuestnLine.TestField("Auto Contact Classification", false);

        if PartOfRating() then begin
            Delete();
            UpdateContactClassification.UpdateRating("Contact No.");
            Insert();
        end;

        Contact.TouchContact("Contact No.");
    end;

    trigger OnInsert()
    var
        Contact: Record Contact;
        ContProfileAnswer: Record "Contact Profile Answer";
        ProfileQuestnLine: Record "Profile Questionnaire Line";
        ProfileQuestnLine2: Record "Profile Questionnaire Line";
        ProfileQuestnLine3: Record "Profile Questionnaire Line";
        PerformCheck: Boolean;
    begin
        ProfileQuestnLine.Get("Profile Questionnaire Code", "Line No.");
        ProfileQuestnLine.TestField(Type, ProfileQuestnLine.Type::Answer);

        ProfileQuestnLine2.Get("Profile Questionnaire Code", QuestionLineNo());
        ProfileQuestnLine2.TestField("Auto Contact Classification", false);

        PerformCheck := not ProfileQuestnLine2."Multiple Answers";
        OnInsertOnBeforeMutipleAnswerCheck(Rec, ProfileQuestnLine, ProfileQuestnLine2, PerformCheck);
        if PerformCheck then begin
            ContProfileAnswer.Reset();
            ProfileQuestnLine3.Reset();
            ProfileQuestnLine3.SetRange("Profile Questionnaire Code", "Profile Questionnaire Code");
            ProfileQuestnLine3.SetRange(Type, ProfileQuestnLine3.Type::Question);
            ProfileQuestnLine3.SetFilter("Line No.", '>%1', ProfileQuestnLine2."Line No.");
            if ProfileQuestnLine3.FindFirst() then
                ContProfileAnswer.SetRange(
                  "Line No.", ProfileQuestnLine2."Line No.", ProfileQuestnLine3."Line No.")
            else
                ContProfileAnswer.SetFilter("Line No.", '>%1', ProfileQuestnLine2."Line No.");
            ContProfileAnswer.SetRange("Contact No.", "Contact No.");
            ContProfileAnswer.SetRange("Profile Questionnaire Code", "Profile Questionnaire Code");
            if not ContProfileAnswer.IsEmpty() then
                Error(Text000, ProfileQuestnLine2.FieldCaption("Multiple Answers"));
        end;

        if PartOfRating() then begin
            Insert();
            UpdateContactClassification.UpdateRating("Contact No.");
            Delete();
        end;

        Contact.TouchContact("Contact No.");
    end;

    trigger OnModify()
    var
        Contact: Record Contact;
    begin
        Contact.TouchContact("Contact No.");
    end;

    trigger OnRename()
    var
        Contact: Record Contact;
    begin
        if xRec."Contact No." = "Contact No." then
            Contact.TouchContact("Contact No.")
        else begin
            Contact.TouchContact("Contact No.");
            Contact.TouchContact(xRec."Contact No.");
        end;
    end;

    var
        UpdateContactClassification: Report "Update Contact Classification";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'This Question does not allow %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure Question(): Text[250]
    var
        ProfileQuestnLine: Record "Profile Questionnaire Line";
    begin
        if ProfileQuestnLine.Get("Profile Questionnaire Code", QuestionLineNo()) then
            exit(ProfileQuestnLine.Description)
    end;

    local procedure QuestionLineNo(): Integer
    var
        ProfileQuestnLine: Record "Profile Questionnaire Line";
    begin
        ProfileQuestnLine.Reset();
        ProfileQuestnLine.SetRange("Profile Questionnaire Code", Rec."Profile Questionnaire Code");
        ProfileQuestnLine.SetFilter("Line No.", '<%1', Rec."Line No.");
        ProfileQuestnLine.SetRange(Type, ProfileQuestnLine.Type::Question);
        if ProfileQuestnLine.FindLast() then
            exit(ProfileQuestnLine."Line No.")
    end;

    local procedure PartOfRating(): Boolean
    var
        Rating: Record Rating;
        ProfileQuestnLine: Record "Profile Questionnaire Line";
        ProfileQuestnLine2: Record "Profile Questionnaire Line";
    begin
        Rating.SetCurrentKey("Rating Profile Quest. Code", "Rating Profile Quest. Line No.");
        Rating.SetRange("Rating Profile Quest. Code", "Profile Questionnaire Code");

        ProfileQuestnLine.Get("Profile Questionnaire Code", "Line No.");
        ProfileQuestnLine.Get("Profile Questionnaire Code", ProfileQuestnLine.FindQuestionLine());

        ProfileQuestnLine2 := ProfileQuestnLine;
        ProfileQuestnLine2.SetRange(Type, ProfileQuestnLine2.Type::Question);
        ProfileQuestnLine2.SetRange("Profile Questionnaire Code", ProfileQuestnLine2."Profile Questionnaire Code");
        if ProfileQuestnLine2.Next() <> 0 then
            Rating.SetRange("Rating Profile Quest. Line No.", ProfileQuestnLine."Line No.", ProfileQuestnLine2."Line No.")
        else
            Rating.SetFilter("Rating Profile Quest. Line No.", '%1..', ProfileQuestnLine."Line No.");

        exit(not Rating.IsEmpty());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOnBeforeMutipleAnswerCheck(var ContactProfileAnswer: Record "Contact Profile Answer"; var ProfileQuestionnaireLine: Record "Profile Questionnaire Line"; var ProfileQuestionnaireLine2: Record "Profile Questionnaire Line"; var PerformCheck: Boolean);
    begin
    end;
}
