// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

using Microsoft.Foundation.Company;
using System.Reflection;

table 726 "Custom Address Format Line"
{
    Caption = 'Custom Address Format Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
        }
        field(3; "Field Position"; Option)
        {
            Caption = 'Field Position';
            DataClassification = SystemMetadata;
            OptionCaption = '1,2,3';
            OptionMembers = "1","2","3";
        }
        field(4; Separator; Text[10])
        {
            Caption = 'Separator';
            DataClassification = SystemMetadata;
        }
        field(5; "Field ID"; Integer)
        {
            Caption = 'Field ID';
            DataClassification = SystemMetadata;
            TableRelation = Field."No." where(TableNo = const(79),
                                               "No." = filter(2 | 3 | 4 | 5 | 6 | 30 | 31 | 36 | 51));

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    CheckFieldId();
                if Field.Get(DATABASE::"Company Information", "Field ID") then
                    "Field Name" := Field.FieldName
                else
                    "Field Name" := '';
            end;
        }
        field(6; "Field Name"; Text[30])
        {
            Caption = 'Field Name';
            DataClassification = SystemMetadata;
        }
        field(7; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Country/Region Code", "Line No.", "Field ID")
        {
            Clustered = true;
        }
        key(Key2; "Country/Region Code", "Line No.", "Field Position")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        CheckMaxRecords();
        InitFieldPosition();
    end;

    var
        "Field": Record "Field";
        LimitExceededErr: Label 'You cannot create more than three Custom Address Format Lines.';
        CompositeFieldErr: Label 'Only the City, Post Code, and County fields can be used.';

    procedure MoveLine(MoveBy: Integer)
    var
        CustomAddressFormatLine: Record "Custom Address Format Line";
    begin
        CustomAddressFormatLine.SetRange("Country/Region Code", "Country/Region Code");
        CustomAddressFormatLine.SetRange("Line No.", "Line No.");
        CustomAddressFormatLine.SetRange("Field Position", "Field Position" + MoveBy);
        if CustomAddressFormatLine.FindFirst() then begin
            CustomAddressFormatLine."Field Position" -= MoveBy;
            CustomAddressFormatLine.Modify();
            "Field Position" += MoveBy;
            Modify();
        end;
    end;

    procedure LookupField()
    var
        CompanyInformation: Record "Company Information";
        "Field": Record "Field";
        FieldSelection: Codeunit "Field Selection";
    begin
        Field.SetFilter(
          "No.",
          '%1|%2|%3',
          CompanyInformation.FieldNo(City),
          CompanyInformation.FieldNo("Post Code"),
          CompanyInformation.FieldNo(County));

        Field.SetRange(TableNo, DATABASE::"Company Information");
        if FieldSelection.Open(Field) then
            Validate("Field ID", Field."No.");
    end;

    local procedure InitFieldPosition()
    var
        CustomAddressFormatLine: Record "Custom Address Format Line";
    begin
        CustomAddressFormatLine.SetRange("Country/Region Code", "Country/Region Code");
        CustomAddressFormatLine.SetRange("Line No.", "Line No.");
        CustomAddressFormatLine.SetFilter("Field ID", '<>%1', "Field ID");
        CustomAddressFormatLine.SetCurrentKey("Country/Region Code", "Line No.", "Field Position");
        if CustomAddressFormatLine.FindLast() then
            "Field Position" := CustomAddressFormatLine."Field Position" + 1;
    end;

    local procedure CheckMaxRecords()
    var
        CustomAddressFormatLine: Record "Custom Address Format Line";
    begin
        CustomAddressFormatLine.SetRange("Country/Region Code", "Country/Region Code");
        CustomAddressFormatLine.SetRange("Line No.", "Line No.");
        if CustomAddressFormatLine.Count > 2 then
            Error(LimitExceededErr);
    end;

    local procedure CheckFieldId()
    var
        CompanyInformation: Record "Company Information";
        CustomAddressFormat: Record "Custom Address Format";
    begin
        CustomAddressFormat.Get("Country/Region Code", "Line No.");
        if CustomAddressFormat."Field ID" = 0 then
            if not ("Field ID" in [CompanyInformation.FieldNo(City),
                CompanyInformation.FieldNo("Post Code"),
                CompanyInformation.FieldNo(County)])
            then
                Error(CompositeFieldErr);
    end;
}

