// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Profiling;

table 5088 "Profile Questionnaire Line"
{
    Caption = 'Profile Questionnaire Line';
    DataCaptionFields = "Profile Questionnaire Code", Description;
    DataClassification = CustomerContent;
    LookupPageID = "Profile Questn. Line List";

    fields
    {
        field(1; "Profile Questionnaire Code"; Code[20])
        {
            Caption = 'Profile Questionnaire Code';
            TableRelation = "Profile Questionnaire Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Type; Enum "Profile Questionnaire Line Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            begin
                case Type of
                    Type::Question:
                        begin
                            CalcFields("No. of Contacts");
                            TestField("No. of Contacts", 0);
                            TestField("From Value", 0);
                            TestField("To Value", 0);
                        end;
                    Type::Answer:
                        begin
                            TestField("Multiple Answers", false);
                            TestField("Auto Contact Classification", false);
                            TestField("Customer Class. Field", 0);
                            TestField("Vendor Class. Field", 0);
                            TestField("Contact Class. Field", 0);
                            TestField("Starting Date Formula", ZeroDateFormula);
                            TestField("Ending Date Formula", ZeroDateFormula);
                            TestField("Classification Method", 0);
                            TestField("Sorting Method", 0);
                            TestField("No. of Decimals", 0);
                        end;
                end;
            end;
        }
        field(4; Description; Text[250])
        {
            Caption = 'Description';
            NotBlank = true;
        }
        field(5; "Multiple Answers"; Boolean)
        {
            Caption = 'Multiple Answers';

            trigger OnValidate()
            begin
                if "Multiple Answers" then
                    TestField(Type, Type::Question);
            end;
        }
        field(6; "Auto Contact Classification"; Boolean)
        {
            Caption = 'Auto Contact Classification';

            trigger OnValidate()
            begin
                if "Auto Contact Classification" then
                    TestField(Type, Type::Question)
                else begin
                    TestField("Customer Class. Field", "Customer Class. Field"::" ");
                    TestField("Vendor Class. Field", "Vendor Class. Field"::" ");
                    TestField("Contact Class. Field", "Contact Class. Field"::" ");
                    TestField("Starting Date Formula", ZeroDateFormula);
                    TestField("Ending Date Formula", ZeroDateFormula);
                    TestField("Classification Method", "Classification Method"::" ");
                    TestField("Sorting Method", "Sorting Method"::" ");
                end;
            end;
        }
        field(7; "Customer Class. Field"; Enum "Profile Quest. Cust. Class. Field")
        {
            Caption = 'Customer Class. Field';

            trigger OnValidate()
            begin
                if "Customer Class. Field" <> "Customer Class. Field"::" " then begin
                    TestField(Type, Type::Question);
                    Clear("Vendor Class. Field");
                    Clear("Contact Class. Field");
                    if "Classification Method" = "Classification Method"::" " then
                        "Classification Method" := "Classification Method"::"Defined Value";
                end else
                    ResetFields();
            end;
        }
        field(8; "Vendor Class. Field"; Enum "Profile Quest. Vend. Class. Field")
        {
            Caption = 'Vendor Class. Field';

            trigger OnValidate()
            begin
                if "Vendor Class. Field" <> "Vendor Class. Field"::" " then begin
                    TestField(Type, Type::Question);
                    Clear("Customer Class. Field");
                    Clear("Contact Class. Field");
                    if "Classification Method" = "Classification Method"::" " then
                        "Classification Method" := "Classification Method"::"Defined Value";
                end else
                    ResetFields();
            end;
        }
        field(9; "Contact Class. Field"; Enum "Profile Quest. Cont. Class. Field")
        {
            Caption = 'Contact Class. Field';

            trigger OnValidate()
            var
                Rating: Record Rating;
            begin
                if xRec."Contact Class. Field" = "Contact Class. Field"::Rating then begin
                    Rating.SetRange("Profile Questionnaire Code", "Profile Questionnaire Code");
                    Rating.SetRange("Profile Questionnaire Line No.", "Line No.");
                    if Rating.FindFirst() then
                        if Confirm(Text000, false) then
                            Rating.DeleteAll()
                        else
                            Error(Text001, FieldCaption("Contact Class. Field"));
                end;

                if "Contact Class. Field" <> "Contact Class. Field"::" " then begin
                    TestField(Type, Type::Question);
                    Clear("Customer Class. Field");
                    Clear("Vendor Class. Field");
                    if ("Classification Method" = "Classification Method"::" ") or
                       ("Contact Class. Field" = "Contact Class. Field"::Rating)
                    then begin
                        "Classification Method" := "Classification Method"::"Defined Value";
                        "Sorting Method" := "Sorting Method"::" ";
                    end;
                    if "Contact Class. Field" = "Contact Class. Field"::Rating then begin
                        Clear("Starting Date Formula");
                        Clear("Ending Date Formula");
                    end;
                end else
                    ResetFields();
            end;
        }
        field(10; "Starting Date Formula"; DateFormula)
        {
            Caption = 'Starting Date Formula';

            trigger OnValidate()
            begin
                if Format("Starting Date Formula") <> '' then
                    TestField(Type, Type::Question);
            end;
        }
        field(11; "Ending Date Formula"; DateFormula)
        {
            Caption = 'Ending Date Formula';

            trigger OnValidate()
            begin
                if Format("Ending Date Formula") <> '' then
                    TestField(Type, Type::Question);
            end;
        }
        field(12; "Classification Method"; Option)
        {
            Caption = 'Classification Method';
            OptionCaption = ' ,Defined Value,Percentage of Value,Percentage of Contacts';
            OptionMembers = " ","Defined Value","Percentage of Value","Percentage of Contacts";

            trigger OnValidate()
            begin
                if "Classification Method" <> "Classification Method"::" " then begin
                    TestField(Type, Type::Question);
                    if "Classification Method" <> "Classification Method"::"Defined Value" then
                        "Sorting Method" := ProfileQuestnLine."Sorting Method"::Descending
                    else
                        "Sorting Method" := ProfileQuestnLine."Sorting Method"::" ";
                end else
                    "Sorting Method" := ProfileQuestnLine."Sorting Method"::" ";
            end;
        }
        field(13; "Sorting Method"; Option)
        {
            Caption = 'Sorting Method';
            OptionCaption = ' ,Descending,Ascending';
            OptionMembers = " ","Descending","Ascending";

            trigger OnValidate()
            begin
                if "Sorting Method" <> "Sorting Method"::" " then
                    TestField(Type, Type::Question);
            end;
        }
        field(14; "From Value"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'From Value';
            DecimalPlaces = 0 : 25;

            trigger OnValidate()
            begin
                if "From Value" <> 0 then
                    TestField(Type, Type::Answer);
            end;
        }
        field(15; "To Value"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'To Value';
            DecimalPlaces = 0 : 25;

            trigger OnValidate()
            begin
                if "To Value" <> 0 then
                    TestField(Type, Type::Answer);
            end;
        }
        field(16; "No. of Contacts"; Integer)
        {
            BlankZero = true;
            CalcFormula = count("Contact Profile Answer" where("Profile Questionnaire Code" = field("Profile Questionnaire Code"),
                                                                "Line No." = field("Line No.")));
            Caption = 'No. of Contacts';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; Priority; Enum "Profile Answer Priority")
        {
            Caption = 'Priority';
            InitValue = Normal;

            trigger OnValidate()
            var
                ContProfileAnswer: Record "Contact Profile Answer";
            begin
                TestField(Type, Type::Answer);
                ContProfileAnswer.SetCurrentKey("Profile Questionnaire Code", "Line No.");
                ContProfileAnswer.SetRange("Profile Questionnaire Code", "Profile Questionnaire Code");
                ContProfileAnswer.SetRange("Line No.", "Line No.");
                ContProfileAnswer.ModifyAll("Answer Priority", Priority);
                Modify();
            end;
        }
        field(18; "No. of Decimals"; Integer)
        {
            Caption = 'No. of Decimals';
            MaxValue = 25;
            MinValue = -25;

            trigger OnValidate()
            begin
                if "No. of Decimals" <> 0 then
                    TestField(Type, Type::Question);
            end;
        }
        field(19; "Min. % Questions Answered"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Min. % Questions Answered';
            DecimalPlaces = 0 : 0;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Min. % Questions Answered" <> 0 then begin
                    TestField(Type, Type::Question);
                    TestField("Contact Class. Field", "Contact Class. Field"::Rating);
                end;
            end;
        }
        field(9501; "Wizard Step"; Option)
        {
            Caption = 'Wizard Step';
            Editable = false;
            OptionCaption = ' ,1,2,3,4,5,6';
            OptionMembers = " ","1","2","3","4","5","6";
        }
        field(9502; "Interval Option"; Option)
        {
            Caption = 'Interval Option';
            OptionCaption = 'Minimum,Maximum,Interval';
            OptionMembers = Minimum,Maximum,Interval;
        }
        field(9503; "Answer Option"; Option)
        {
            Caption = 'Answer Option';
            OptionCaption = 'HighLow,ABC,Custom';
            OptionMembers = HighLow,ABC,Custom;
        }
        field(9504; "Answer Description"; Text[250])
        {
            Caption = 'Answer Description';
        }
        field(9505; "Wizard From Value"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Wizard From Value';
            DecimalPlaces = 0 : 25;

            trigger OnValidate()
            begin
                if "From Value" <> 0 then
                    TestField(Type, Type::Answer);
            end;
        }
        field(9506; "Wizard To Value"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Wizard To Value';
            DecimalPlaces = 0 : 25;

            trigger OnValidate()
            begin
                if "To Value" <> 0 then
                    TestField(Type, Type::Answer);
            end;
        }
        field(9707; "Wizard From Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Wizard From Line No.';

            trigger OnValidate()
            begin
                if "To Value" <> 0 then
                    TestField(Type, Type::Answer);
            end;
        }
    }

    keys
    {
        key(Key1; "Profile Questionnaire Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; Type, Description)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; Type, Description, Priority, "Multiple Answers", "Auto Contact Classification", "No. of Contacts")
        {
        }
    }

    trigger OnDelete()
    var
        Rating: Record Rating;
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
    begin
        CalcFields("No. of Contacts");
        TestField("No. of Contacts", 0);

        Rating.SetRange("Rating Profile Quest. Code", "Profile Questionnaire Code");
        Rating.SetRange("Rating Profile Quest. Line No.", "Line No.");
        if not Rating.IsEmpty() then
            Error(Text002);

        Rating.Reset();
        Rating.SetRange("Profile Questionnaire Code", "Profile Questionnaire Code");
        Rating.SetRange("Profile Questionnaire Line No.", "Line No.");
        if not Rating.IsEmpty() then
            Error(Text003);

        if Type = Type::Question then begin
            ProfileQuestionnaireLine.Get("Profile Questionnaire Code", "Line No.");
            if (ProfileQuestionnaireLine.Next() <> 0) and
               (ProfileQuestionnaireLine.Type = ProfileQuestnLine.Type::Answer)
            then
                Error(Text004);
        end;
    end;

    var
        ProfileQuestnLine: Record "Profile Questionnaire Line";
        TempProfileQuestionnaireLine: Record "Profile Questionnaire Line" temporary;
        ZeroDateFormula: DateFormula;
#pragma warning disable AA0074
        Text000: Label 'Do you want to delete the rating values?';
#pragma warning disable AA0470
        Text001: Label '%1 cannot be changed until the rating value is deleted.';
#pragma warning restore AA0470
        Text002: Label 'You cannot delete this line because one or more questions are depending on it.';
        Text003: Label 'You cannot delete this line because one or more rating values exists.';
        Text004: Label 'You cannot delete this question while answers exists.';
        Text005: Label 'Please select for which questionnaire this rating should be created.';
        Text006: Label 'Please describe the rating.';
        Text007: Label 'Please create one or more different answers.';
        Text008: Label 'Please enter which range of points this answer should require.';
        Text009: Label 'High';
        Text010: Label 'Low';
        Text011: Label 'A', Comment = 'Selecting answer A';
        Text012: Label 'B', Comment = 'Selecting answer B';
        Text013: Label 'C', Comment = 'Selecting answer C';
#pragma warning restore AA0074

    procedure MoveUp()
    var
        UpperProfileQuestnLine: Record "Profile Questionnaire Line";
        LineNo: Integer;
        UpperRecLineNo: Integer;
    begin
        TestField(Type, Type::Answer);
        UpperProfileQuestnLine.SetRange("Profile Questionnaire Code", "Profile Questionnaire Code");
        LineNo := "Line No.";
        UpperProfileQuestnLine.Get("Profile Questionnaire Code", "Line No.");

        if UpperProfileQuestnLine.Find('<') and
           (UpperProfileQuestnLine.Type = UpperProfileQuestnLine.Type::Answer)
        then begin
            UpperRecLineNo := UpperProfileQuestnLine."Line No.";
            Rename("Profile Questionnaire Code", -1);
            UpperProfileQuestnLine.Rename("Profile Questionnaire Code", LineNo);
            Rename("Profile Questionnaire Code", UpperRecLineNo);
        end;
    end;

    procedure MoveDown()
    var
        LowerProfileQuestnLine: Record "Profile Questionnaire Line";
        LineNo: Integer;
        LowerRecLineNo: Integer;
    begin
        TestField(Type, Type::Answer);
        LowerProfileQuestnLine.SetRange("Profile Questionnaire Code", "Profile Questionnaire Code");
        LineNo := "Line No.";
        LowerProfileQuestnLine.Get("Profile Questionnaire Code", "Line No.");

        if LowerProfileQuestnLine.Find('>') and
           (LowerProfileQuestnLine.Type = LowerProfileQuestnLine.Type::Answer)
        then begin
            LowerRecLineNo := LowerProfileQuestnLine."Line No.";
            Rename("Profile Questionnaire Code", -1);
            LowerProfileQuestnLine.Rename("Profile Questionnaire Code", LineNo);
            Rename("Profile Questionnaire Code", LowerRecLineNo);
        end;
    end;

    procedure Question(): Text[250]
    begin
        ProfileQuestnLine.Reset();
        ProfileQuestnLine.SetRange("Profile Questionnaire Code", "Profile Questionnaire Code");
        ProfileQuestnLine.SetFilter("Line No.", '<%1', "Line No.");
        ProfileQuestnLine.SetRange(Type, Type::Question);
        if ProfileQuestnLine.FindLast() then
            exit(ProfileQuestnLine.Description);
    end;

    procedure FindQuestionLine(): Integer
    begin
        ProfileQuestnLine.Reset();
        ProfileQuestnLine.SetRange("Profile Questionnaire Code", "Profile Questionnaire Code");
        ProfileQuestnLine.SetFilter("Line No.", '<%1', "Line No.");
        ProfileQuestnLine.SetRange(Type, Type::Question);
        if ProfileQuestnLine.FindLast() then
            exit(ProfileQuestnLine."Line No.");
    end;

    local procedure ResetFields()
    begin
        Clear("Starting Date Formula");
        Clear("Ending Date Formula");
        "Classification Method" := "Classification Method"::" ";
        "Sorting Method" := "Sorting Method"::" ";
        "No. of Decimals" := 0;
        "Min. % Questions Answered" := 0;
    end;

    procedure CreateRatingFromProfQuestnLine(var ProfileQuestnLine: Record "Profile Questionnaire Line")
    begin
        Init();
        "Profile Questionnaire Code" := ProfileQuestnLine."Profile Questionnaire Code";
        StartWizard();
    end;

    local procedure StartWizard()
    begin
        "Wizard Step" := "Wizard Step"::"1";
        Validate("Auto Contact Classification", true);
        Validate("Contact Class. Field", "Contact Class. Field"::Rating);
        Insert();

        ValidateAnswerOption();
        ValidateIntervalOption();

        PAGE.RunModal(PAGE::"Create Rating", Rec);
    end;

    procedure CheckStatus()
    begin
        case "Wizard Step" of
            "Wizard Step"::"1":
                begin
                    if "Profile Questionnaire Code" = '' then
                        Error(Text005);
                    if Description = '' then
                        Error(Text006);
                end;
            "Wizard Step"::"2":
                if TempProfileQuestionnaireLine.Count = 0 then
                    Error(Text007);
            "Wizard Step"::"3":
                if ("Wizard From Value" = 0) and ("Wizard To Value" = 0) then
                    Error(Text008);
        end;
    end;

    procedure PerformNextWizardStatus()
    begin
        case "Wizard Step" of
            "Wizard Step"::"1":
                "Wizard Step" := "Wizard Step" + 1;
            "Wizard Step"::"2":
                begin
                    "Wizard From Line No." := 0;
                    "Wizard Step" := "Wizard Step" + 1;
                    TempProfileQuestionnaireLine.SetRange("Line No.");
                    TempProfileQuestionnaireLine.Find('-');
                    SetIntervalOption();
                end;
            "Wizard Step"::"3":
                begin
                    TempProfileQuestionnaireLine.SetFilter("Line No.", '%1..', "Wizard From Line No.");
                    TempProfileQuestionnaireLine.Find('-');
                    TempProfileQuestionnaireLine."From Value" := "Wizard From Value";
                    TempProfileQuestionnaireLine."To Value" := "Wizard To Value";
                    TempProfileQuestionnaireLine.Modify();
                    if TempProfileQuestionnaireLine.Next() <> 0 then begin
                        TempProfileQuestionnaireLine.SetRange("Line No.", TempProfileQuestionnaireLine."Line No.");
                        "Wizard From Line No." := TempProfileQuestionnaireLine."Line No.";
                        "Wizard From Value" := TempProfileQuestionnaireLine."From Value";
                        "Wizard To Value" := TempProfileQuestionnaireLine."To Value";
                        SetIntervalOption();
                    end else begin
                        TempProfileQuestionnaireLine.SetRange("Line No.");
                        TempProfileQuestionnaireLine.Find('-');
                        "Wizard Step" := "Wizard Step" + 1;
                    end;
                end;
        end;
    end;

    procedure PerformPrevWizardStatus()
    begin
        case "Wizard Step" of
            "Wizard Step"::"3":
                begin
                    TempProfileQuestionnaireLine.SetFilter("Line No.", '..%1', "Wizard From Line No.");
                    if TempProfileQuestionnaireLine.Find('+') then begin
                        TempProfileQuestionnaireLine."From Value" := "Wizard From Value";
                        TempProfileQuestionnaireLine."To Value" := "Wizard To Value";
                        TempProfileQuestionnaireLine.Modify();
                    end;
                    if TempProfileQuestionnaireLine.Next(-1) <> 0 then begin
                        "Wizard From Line No." := TempProfileQuestionnaireLine."Line No.";
                        "Wizard From Value" := TempProfileQuestionnaireLine."From Value";
                        "Wizard To Value" := TempProfileQuestionnaireLine."To Value";
                        SetIntervalOption();
                    end else begin
                        TempProfileQuestionnaireLine.SetRange("Line No.");
                        TempProfileQuestionnaireLine.Find('-');
                        "Wizard Step" := "Wizard Step" - 1;
                    end;
                end;
            else
                "Wizard Step" := "Wizard Step" - 1;
        end;
    end;

    procedure FinishWizard()
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
        ProfileMgt: Codeunit ProfileManagement;
        NextLineNo: Integer;
        QuestionLineNo: Integer;
    begin
        ProfileQuestionnaireLine.SetRange("Profile Questionnaire Code", "Profile Questionnaire Code");
        if ProfileQuestionnaireLine.FindLast() then
            QuestionLineNo := ProfileQuestionnaireLine."Line No." + 10000
        else
            QuestionLineNo := 10000;

        ProfileQuestionnaireLine := Rec;
        ProfileQuestionnaireLine."Line No." := QuestionLineNo;
        ProfileQuestionnaireLine.Insert(true);

        NextLineNo := QuestionLineNo;
        TempProfileQuestionnaireLine.Reset();
        if TempProfileQuestionnaireLine.FindSet() then
            repeat
                NextLineNo := NextLineNo + 10000;
                ProfileQuestionnaireLine := TempProfileQuestionnaireLine;
                ProfileQuestionnaireLine."Profile Questionnaire Code" := "Profile Questionnaire Code";
                ProfileQuestionnaireLine."Line No." := NextLineNo;
                ProfileQuestionnaireLine.Insert(true);
            until TempProfileQuestionnaireLine.Next() = 0;

        Commit();

        ProfileQuestionnaireLine.Get("Profile Questionnaire Code", QuestionLineNo);
        ProfileMgt.ShowAnswerPoints(ProfileQuestionnaireLine);
    end;

    procedure SetIntervalOption()
    begin
        case true of
            (TempProfileQuestionnaireLine."From Value" = 0) and (TempProfileQuestionnaireLine."To Value" <> 0):
                "Interval Option" := "Interval Option"::Maximum;
            (TempProfileQuestionnaireLine."From Value" <> 0) and (TempProfileQuestionnaireLine."To Value" = 0):
                "Interval Option" := "Interval Option"::Minimum
            else
                "Interval Option" := "Interval Option"::Interval
        end;

        ValidateIntervalOption();
    end;

    procedure ValidateIntervalOption()
    begin
        TempProfileQuestionnaireLine.SetFilter("Line No.", '%1..', "Wizard From Line No.");
        TempProfileQuestionnaireLine.Find('-');
        if "Interval Option" = "Interval Option"::Minimum then
            TempProfileQuestionnaireLine."To Value" := 0;
        if "Interval Option" = "Interval Option"::Maximum then
            TempProfileQuestionnaireLine."From Value" := 0;
        TempProfileQuestionnaireLine.Modify();
    end;

    procedure ValidateAnswerOption()
    begin
        if "Answer Option" = "Answer Option"::Custom then
            exit;

        TempProfileQuestionnaireLine.DeleteAll();

        case "Answer Option" of
            "Answer Option"::HighLow:
                begin
                    CreateAnswer(Text009);
                    CreateAnswer(Text010);
                end;
            "Answer Option"::ABC:
                begin
                    CreateAnswer(Text011);
                    CreateAnswer(Text012);
                    CreateAnswer(Text013);
                end;
        end;
    end;

    local procedure CreateAnswer(AnswerDescription: Text[250])
    begin
        TempProfileQuestionnaireLine.Init();
        TempProfileQuestionnaireLine."Line No." := (TempProfileQuestionnaireLine.Count + 1) * 10000;
        TempProfileQuestionnaireLine.Type := TempProfileQuestionnaireLine.Type::Answer;
        TempProfileQuestionnaireLine.Description := AnswerDescription;
        TempProfileQuestionnaireLine.Insert();
    end;

    procedure NoOfProfileAnswers(): Decimal
    begin
        exit(TempProfileQuestionnaireLine.Count);
    end;

    procedure ShowAnswers()
    var
        TempProfileQuestionnaireLine2: Record "Profile Questionnaire Line" temporary;
    begin
        if "Answer Option" <> "Answer Option"::Custom then
            if TempProfileQuestionnaireLine.Find('-') then
                repeat
                    TempProfileQuestionnaireLine2 := TempProfileQuestionnaireLine;
                    TempProfileQuestionnaireLine2.Insert();
                until TempProfileQuestionnaireLine.Next() = 0;

        PAGE.RunModal(PAGE::"Rating Answers", TempProfileQuestionnaireLine);

        if "Answer Option" <> "Answer Option"::Custom then
            if TempProfileQuestionnaireLine.Count <> TempProfileQuestionnaireLine2.Count then
                "Answer Option" := "Answer Option"::Custom
            else
                if TempProfileQuestionnaireLine.Find('-') then
                    repeat
                        if not TempProfileQuestionnaireLine2.Get(
                             TempProfileQuestionnaireLine."Profile Questionnaire Code", TempProfileQuestionnaireLine."Line No.")
                        then
                            "Answer Option" := "Answer Option"::Custom
                        else
                            if TempProfileQuestionnaireLine.Description <> TempProfileQuestionnaireLine2.Description then
                                "Answer Option" := "Answer Option"::Custom
                    until (TempProfileQuestionnaireLine.Next() = 0) or ("Answer Option" = "Answer Option"::Custom);
    end;

    procedure GetProfileLineAnswerDesc(): Text[250]
    begin
        TempProfileQuestionnaireLine.SetFilter("Line No.", '%1..', "Wizard From Line No.");
        TempProfileQuestionnaireLine.Find('-');
        exit(TempProfileQuestionnaireLine.Description);
    end;

    procedure GetAnswers(var ProfileQuestionnaireLine: Record "Profile Questionnaire Line")
    begin
        TempProfileQuestionnaireLine.Reset();
        ProfileQuestionnaireLine.Reset();
        ProfileQuestionnaireLine.DeleteAll();
        if TempProfileQuestionnaireLine.Find('-') then
            repeat
                ProfileQuestionnaireLine.Init();
                ProfileQuestionnaireLine := TempProfileQuestionnaireLine;
                ProfileQuestionnaireLine.Insert();
            until TempProfileQuestionnaireLine.Next() = 0;
    end;
}
