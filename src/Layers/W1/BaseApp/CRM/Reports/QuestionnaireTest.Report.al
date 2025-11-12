// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Reports;

using Microsoft.CRM.Profiling;
using System.Utilities;

report 5067 "Questionnaire - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CRM/Reports/QuestionnaireTest.rdlc';
    Caption = 'Questionnaire - Test';

    dataset
    {
        dataitem("Profile Questionnaire Header"; "Profile Questionnaire Header")
        {
            RequestFilterFields = "Code";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(Profile_Questionnaire_Header_Code; Code)
            {
            }
            column(Profile_Questionnaire_LineCaption; Profile_Questionnaire_LineCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Profile_Questionnaire_Line_DescriptionCaption; "Profile Questionnaire Line".FieldCaption(Description))
            {
            }
            column(Profile_Questionnaire_Line_TypeCaption; "Profile Questionnaire Line".FieldCaption(Type))
            {
            }
            column(Profile_Questionnaire_Line__Line_No__Caption; "Profile Questionnaire Line".FieldCaption("Line No."))
            {
            }
            dataitem("Profile Questionnaire Line"; "Profile Questionnaire Line")
            {
                DataItemLink = "Profile Questionnaire Code" = field(Code);
                DataItemTableView = sorting("Profile Questionnaire Code", "Line No.");
                column(Profile_Questionnaire_Line__Line_No__; "Line No.")
                {
                }
                column(Profile_Questionnaire_Line_Type; Type)
                {
                }
                column(Profile_Questionnaire_Line_Description; Description)
                {
                }
                dataitem("Integer"; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(ErrorText_Number_; ErrorText[Number])
                    {
                    }
                    column(ErrorText_Number_Caption; ErrorText_Number_CaptionLbl)
                    {
                    }

                    trigger OnPostDataItem()
                    begin
                        ErrorCounter := 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, ErrorCounter);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    case Type of
                        Type::Question:
                            TestQuestion();
                        Type::Answer:
                            TestAnswer();
                    end;
                end;
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Questionnaire - Test';
        AboutText = 'Show test reports of your profile questionnaires.';

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You must specify the Class. Field when %1 is set.';
        Text002: Label '%1 must be specified when %2 is set.';
        Text003: Label '%1 must be specified when %2 = %3.';
#pragma warning restore AA0470
        Text004: Label 'No Answer created.';
#pragma warning disable AA0470
        Text005: Label '%1 and/or %2 must be specified.';
        Text006: Label '%1 cannot be %2 when %3 is %4.';
#pragma warning restore AA0470
        Text007: Label 'No Question created.';
#pragma warning restore AA0074
        ProfileQuestnLine: Record "Profile Questionnaire Line";
        ProfileQuestnLine2: Record "Profile Questionnaire Line";
        ErrorCounter: Integer;
        ErrorText: array[50] of Text[250];
        Profile_Questionnaire_LineCaptionLbl: Label 'Profile Questionnaire Line';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        ErrorText_Number_CaptionLbl: Label 'Warning!';

    local procedure TestQuestion()
    begin
        ProfileQuestnLine.Reset();
        ProfileQuestnLine2.Reset();
        if "Profile Questionnaire Line"."Auto Contact Classification" then begin
            if ("Profile Questionnaire Line"."Customer Class. Field" = "Profile Questionnaire Line"."Customer Class. Field"::" ") and
               ("Profile Questionnaire Line"."Vendor Class. Field" = "Profile Questionnaire Line"."Vendor Class. Field"::" ") and
               ("Profile Questionnaire Line"."Contact Class. Field" = "Profile Questionnaire Line"."Contact Class. Field"::" ")
            then
                AddError(StrSubstNo(Text000, "Profile Questionnaire Line".FieldCaption("Auto Contact Classification")));
            if "Profile Questionnaire Line"."Contact Class. Field" <> "Profile Questionnaire Line"."Contact Class. Field"::Rating then begin
                if Format("Profile Questionnaire Line"."Starting Date Formula") = '' then
                    AddError(StrSubstNo(
                        Text002,
                        "Profile Questionnaire Line".FieldCaption("Starting Date Formula"), "Profile Questionnaire Line".FieldCaption("Auto Contact Classification")));
                if Format("Profile Questionnaire Line"."Ending Date Formula") = '' then
                    AddError(StrSubstNo(
                        Text002,
                        "Profile Questionnaire Line".FieldCaption("Ending Date Formula"), "Profile Questionnaire Line".FieldCaption("Auto Contact Classification")));
            end;
            if "Profile Questionnaire Line"."Classification Method" = "Profile Questionnaire Line"."Classification Method"::" " then
                AddError(StrSubstNo(
                    Text002,
                    "Profile Questionnaire Line".FieldCaption("Classification Method"), "Profile Questionnaire Line".FieldCaption("Auto Contact Classification")));
            if ("Profile Questionnaire Line"."Classification Method"
                in ["Profile Questionnaire Line"."Classification Method"::"Percentage of Value", "Profile Questionnaire Line"."Classification Method"::"Percentage of Contacts"]) and
               ("Profile Questionnaire Line"."Sorting Method" = "Profile Questionnaire Line"."Sorting Method"::" ")
            then
                AddError(StrSubstNo(
                    Text003,
                    "Profile Questionnaire Line".FieldCaption("Sorting Method"), "Profile Questionnaire Line".FieldCaption("Classification Method"), "Profile Questionnaire Line"."Classification Method"));
        end;
        ProfileQuestnLine := "Profile Questionnaire Line";
        ProfileQuestnLine.SetRange("Profile Questionnaire Code", "Profile Questionnaire Line"."Profile Questionnaire Code");
        ProfileQuestnLine.SetRange(Type, "Profile Questionnaire Line".Type::Question);
        if ProfileQuestnLine.Find('>') then
            ProfileQuestnLine2.SetRange("Line No.", "Profile Questionnaire Line"."Line No.", ProfileQuestnLine."Line No.")
        else
            ProfileQuestnLine2.SetFilter("Line No.", '%1..', "Profile Questionnaire Line"."Line No.");
        ProfileQuestnLine2.SetRange("Profile Questionnaire Code", "Profile Questionnaire Line"."Profile Questionnaire Code");
        ProfileQuestnLine2.SetRange(Type, "Profile Questionnaire Line".Type::Answer);
        if not ProfileQuestnLine2.FindFirst() then
            AddError(Text004);
    end;

    local procedure TestAnswer()
    begin
        ProfileQuestnLine.Reset();
        ProfileQuestnLine2.Reset();
        ProfileQuestnLine := "Profile Questionnaire Line";
        ProfileQuestnLine.SetRange("Profile Questionnaire Code", "Profile Questionnaire Line"."Profile Questionnaire Code");
        ProfileQuestnLine.SetRange(Type, "Profile Questionnaire Line".Type::Question);
        if ProfileQuestnLine.Find('<') then begin
            if ProfileQuestnLine."Auto Contact Classification" and
               ("Profile Questionnaire Line"."From Value" = 0) and ("Profile Questionnaire Line"."To Value" = 0)
            then
                AddError(StrSubstNo(
                    Text005, "Profile Questionnaire Line".FieldCaption("From Value"), "Profile Questionnaire Line".FieldCaption("To Value")));
            if "Profile Questionnaire Line"."From Value" <> Round("Profile Questionnaire Line"."From Value", 1 / Power(10, ProfileQuestnLine."No. of Decimals")) then
                AddError(StrSubstNo(
                    Text006, "Profile Questionnaire Line".FieldCaption("From Value"), "Profile Questionnaire Line"."From Value",
                    "Profile Questionnaire Line".FieldCaption("No. of Decimals"), ProfileQuestnLine."No. of Decimals"));
            if "Profile Questionnaire Line"."To Value" <> Round("Profile Questionnaire Line"."To Value", 1 / Power(10, ProfileQuestnLine."No. of Decimals")) then
                AddError(StrSubstNo(
                    Text006, "Profile Questionnaire Line".FieldCaption("To Value"), "Profile Questionnaire Line"."To Value",
                    "Profile Questionnaire Line".FieldCaption("No. of Decimals"), ProfileQuestnLine."No. of Decimals"));
        end else
            AddError(Text007);
    end;

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;
}

