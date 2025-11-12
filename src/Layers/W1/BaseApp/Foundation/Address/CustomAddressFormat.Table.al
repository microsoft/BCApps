// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

using Microsoft.Foundation.Company;
using System.Reflection;

table 725 "Custom Address Format"
{
    Caption = 'Custom Address Format';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(2; "Line Position"; Option)
        {
            Caption = 'Line Position';
            OptionCaption = '1,2,3,4,5,6,7,8';
            OptionMembers = "1","2","3","4","5","6","7","8";
        }
        field(3; "Line Format"; Text[80])
        {
            Caption = 'Line Format';
        }
        field(4; "Line No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        field(5; "Field ID"; Integer)
        {
            Caption = 'Field ID';
            DataClassification = SystemMetadata;
            TableRelation = Field."No." where(TableNo = const(79),
                                               "No." = filter(2 | 3 | 4 | 5 | 6 | 30 | 31 | 36 | 51));

            trigger OnValidate()
            var
                "Field": Record "Field";
            begin
                if "Field ID" <> xRec."Field ID" then begin
                    if "Field ID" = 0 then
                        CheckOtherCompositeParts();
                    UpdateRelatedCustomerAddressFormatLines();
                end;

                if Field.Get(DATABASE::"Company Information", "Field ID") then
                    "Line Format" := StrSubstNo('[%1]', Field.FieldName)
                else
                    "Line Format" := '';
            end;
        }
    }

    keys
    {
        key(Key1; "Country/Region Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Country/Region Code", "Line Position")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        CustomAddressFormatLine: Record "Custom Address Format Line";
    begin
        CustomAddressFormatLine.Reset();
        CustomAddressFormatLine.SetRange("Country/Region Code", "Country/Region Code");
        CustomAddressFormatLine.SetRange("Line No.", "Line No.");
        CustomAddressFormatLine.DeleteAll();
    end;

    var
        MultyCompositePartsErr: Label 'Only one composite custom address line format can be used.';

    procedure BuildAddressFormat()
    var
        CustomAddressFormatLine: Record "Custom Address Format Line";
    begin
        "Line Format" := '';

        CustomAddressFormatLine.Reset();
        CustomAddressFormatLine.SetCurrentKey("Country/Region Code", "Line No.", "Field Position");
        CustomAddressFormatLine.SetRange("Country/Region Code", "Country/Region Code");
        CustomAddressFormatLine.SetRange("Line No.", "Line No.");
        CustomAddressFormatLine.SetFilter("Field Name", '<>%1', '');
        if CustomAddressFormatLine.FindSet() then
            repeat
                "Line Format" += StrSubstNo('[%1]', CustomAddressFormatLine."Field Name");
                if CustomAddressFormatLine.Separator <> '' then
                    "Line Format" += CustomAddressFormatLine.Separator;
                "Line Format" += ' ';
            until CustomAddressFormatLine.Next() = 0;

        if CustomAddressFormatLine.Count > 1 then
            "Field ID" := 0;
    end;

    procedure UseCounty(CountryCode: Code[10]): Boolean
    var
        CustomAddressFormatLine: Record "Custom Address Format Line";
        CompanyInformation: Record "Company Information";
    begin
        CustomAddressFormatLine.Reset();
        CustomAddressFormatLine.SetRange("Country/Region Code", CountryCode);
        CustomAddressFormatLine.SetRange("Field ID", CompanyInformation.FieldNo(County));
        exit(not CustomAddressFormatLine.IsEmpty);
    end;

    procedure ShowCustomAddressFormatLines()
    var
        CustomAddressFormatLine: Record "Custom Address Format Line";
        CustomAddressFormatLines: Page "Custom Address Format Lines";
    begin
        TestField("Field ID", 0);
        TestField("Line No.");
        TestField("Country/Region Code");
        Clear(CustomAddressFormatLines);
        CustomAddressFormatLine.Reset();
        CustomAddressFormatLine.SetRange("Country/Region Code", "Country/Region Code");
        CustomAddressFormatLine.SetRange("Line No.", "Line No.");
        CustomAddressFormatLine.SetCurrentKey("Country/Region Code", "Line No.", "Field Position");
        CustomAddressFormatLines.SetTableView(CustomAddressFormatLine);
        CustomAddressFormatLines.RunModal();

        BuildAddressFormat();
    end;

    local procedure CheckOtherCompositeParts()
    var
        CustomAddressFormat: Record "Custom Address Format";
    begin
        CustomAddressFormat.SetRange("Country/Region Code", "Country/Region Code");
        CustomAddressFormat.SetFilter("Line No.", '<>%1', "Line No.");
        CustomAddressFormat.SetRange("Field ID", 0);
        if not CustomAddressFormat.IsEmpty() then
            Error(MultyCompositePartsErr);
    end;

    local procedure UpdateRelatedCustomerAddressFormatLines()
    var
        CustomAddressFormatLine: Record "Custom Address Format Line";
        CountryRegion: Record "Country/Region";
    begin
        CustomAddressFormatLine.SetRange("Country/Region Code", "Country/Region Code");
        CustomAddressFormatLine.SetRange("Line No.", "Line No.");
        CustomAddressFormatLine.DeleteAll();

        if "Field ID" <> 0 then
            CountryRegion.CreateAddressFormatLine("Country/Region Code", 1, "Field ID", "Line No.");
    end;

    procedure MoveLine(MoveBy: Integer)
    var
        CustomAddressFormat: Record "Custom Address Format";
    begin
        CustomAddressFormat.SetRange("Country/Region Code", "Country/Region Code");
        CustomAddressFormat.SetRange("Line Position", "Line Position" + MoveBy);
        if CustomAddressFormat.FindFirst() then begin
            CustomAddressFormat."Line Position" -= MoveBy;
            CustomAddressFormat.Modify();
            "Line Position" += MoveBy;
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
          '%1|%2|%3|%4|%5|%6|%7|%8|%9',
          CompanyInformation.FieldNo(Name),
          CompanyInformation.FieldNo("Name 2"),
          CompanyInformation.FieldNo(Address),
          CompanyInformation.FieldNo("Address 2"),
          CompanyInformation.FieldNo("Contact Person"),
          CompanyInformation.FieldNo(City),
          CompanyInformation.FieldNo("Post Code"),
          CompanyInformation.FieldNo(County),
          CompanyInformation.FieldNo("Country/Region Code"));
        Field.SetRange(TableNo, DATABASE::"Company Information");
        if FieldSelection.Open(Field) then
            Validate("Field ID", Field."No.");
    end;
}

