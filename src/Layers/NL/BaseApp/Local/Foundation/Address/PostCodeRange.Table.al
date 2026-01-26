// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

table 11406 "Post Code Range"
{
    Caption = 'Post Code Range';
    DrillDownPageID = "Post Code Ranges";
    LookupPageID = "Post Code Ranges";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            NotBlank = true;
            TableRelation = "Post Code".Code;
            ValidateTableRelation = false;
        }
        field(2; City; Text[30])
        {
            Caption = 'City';
            NotBlank = true;
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,Odd,Even,House Boat,House Trailer';
            OptionMembers = " ",Odd,Even,"House Boat","House Trailer";

            trigger OnValidate()
            begin
                if Type in [Type::" ", Type::"House Boat", Type::"House Trailer"] then begin
                    "From No." := 0;
                    "To No." := 0;
                end;
            end;
        }
        field(4; "From No."; Integer)
        {
            BlankZero = true;
            Caption = 'From No.';

            trigger OnValidate()
            begin
                case Type of
                    Type::" ", Type::"House Boat", Type::"House Trailer":
                        if "From No." <> 0 then
                            FieldError("From No.", StrSubstNo(Text001, FieldCaption(Type), Type));
                    Type::Odd:
                        if "From No." mod 2 <> 1 then
                            FieldError("From No.", StrSubstNo(Text002, FieldCaption(Type), Type));
                    Type::Even:
                        if "From No." mod 2 <> 0 then
                            FieldError("From No.", StrSubstNo(Text003, FieldCaption(Type), Type));
                end;
            end;
        }
        field(10; "To No."; Integer)
        {
            BlankZero = true;
            Caption = 'To No.';

            trigger OnValidate()
            begin
                case Type of
                    Type::" ", Type::"House Boat", Type::"House Trailer":
                        if "To No." <> 0 then
                            FieldError("To No.", StrSubstNo(Text001, FieldCaption(Type), Type));
                    Type::Odd:
                        if "To No." mod 2 <> 1 then
                            FieldError("To No.", StrSubstNo(Text002, FieldCaption(Type), Type));
                    Type::Even:
                        if "To No." mod 2 <> 0 then
                            FieldError("To No.", StrSubstNo(Text003, FieldCaption(Type), Type));
                end;
            end;
        }
        field(20; "Street Name"; Text[50])
        {
            Caption = 'Street Name';
        }
    }

    keys
    {
        key(Key1; "Post Code", City, Type, "From No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        PostCodeRange: Record "Post Code Range";
    begin
        PostCodeRange.SetRange("Post Code", "Post Code");
        PostCodeRange.SetRange(City, City);
        if PostCodeRange.Count > 1 then
            exit;

        PostCode.Code := "Post Code";
        PostCode.City := City;
        if PostCode.Delete(true) then;
    end;

    trigger OnInsert()
    begin
        PostCode.Code := "Post Code";
        PostCode.City := City;
        PostCode."Search City" := City;
        if not PostCode.Insert() then;
    end;

    var
        Text001: Label 'must be 0 if %1 is %2';
        Text002: Label 'must be odd if %1 is %2';
        Text003: Label 'must be even if %1 is %2';

    protected var
        PostCode: Record "Post Code";
}

