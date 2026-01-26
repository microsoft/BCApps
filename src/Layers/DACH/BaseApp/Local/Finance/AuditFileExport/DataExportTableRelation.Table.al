// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using System.Reflection;

table 11006 "Data Export Table Relation"
{
    Caption = 'Data Export Table Relationship';
    DataCaptionFields = "Data Export Code", "Data Exp. Rec. Type Code";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Data Export Code"; Code[10])
        {
            Caption = 'Data Export Code';
            NotBlank = true;
            TableRelation = "Data Export";
        }
        field(2; "Data Exp. Rec. Type Code"; Code[10])
        {
            Caption = 'Data Exp. Rec. Type Code';
            NotBlank = true;
            TableRelation = "Data Export Record Type";
        }
        field(3; "From Table No."; Integer)
        {
            BlankZero = true;
            Caption = 'From Table No.';
            NotBlank = true;
            TableRelation = AllObj."Object ID" where("Object Type" = const(Table));
        }
        field(4; "From Table Name"; Text[80])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                           "Object ID" = field("From Table No.")));
            Caption = 'From Table Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "From Field No."; Integer)
        {
            BlankZero = true;
            Caption = 'From Field No.';
            NotBlank = true;
            TableRelation = Field."No." where(TableNo = field("From Table No."),
                                               Type = filter(Option | Text | Code | Integer | Decimal | Date | Boolean),
                                               Class = const(Normal),
                                               ObsoleteState = filter(<> Removed));

            trigger OnLookup()
            begin
                FromField.Reset();
                FromField.FilterGroup(4);
                FromField.SetRange(TableNo, "From Table No.");
                FromField.SetFilter(Type, '%1|%2|%3|%4|%5|%6|%7',
                  FromField.Type::Option,
                  FromField.Type::Text,
                  FromField.Type::Code,
                  FromField.Type::Integer,
                  FromField.Type::Decimal,
                  FromField.Type::Date,
                  FromField.Type::Boolean);
                FromField.SetRange(Class, FromField.Class::Normal);
                FromField.FilterGroup(0);
                if PAGE.RunModal(PAGE::"Data Export Field List", FromField) = ACTION::LookupOK then
                    Validate("From Field No.", FromField."No.");
            end;

            trigger OnValidate()
            begin
                CalcFields("From Field Name");
            end;
        }
        field(6; "From Field Name"; Text[80])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("From Table No."),
                                                              "No." = field("From Field No.")));
            Caption = 'From Field Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "To Table No."; Integer)
        {
            BlankZero = true;
            Caption = 'To Table No.';
            NotBlank = true;
            TableRelation = AllObj."Object ID" where("Object Type" = const(Table));
        }
        field(8; "To Table Name"; Text[80])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                           "Object ID" = field("To Table No.")));
            Caption = 'To Table Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "To Field No."; Integer)
        {
            BlankZero = true;
            Caption = 'To Field No.';
            NotBlank = true;
            TableRelation = Field."No." where(TableNo = field("To Table No."),
                                               Type = filter(Option | Text | Code | Integer | Decimal | Date | Boolean),
                                               ObsoleteState = filter(<> Removed));

            trigger OnLookup()
            begin
                if "From Table No." = 0 then
                    Error(MustSpecifyErr, FieldCaption("From Table No."));

                if "From Field No." = 0 then
                    Error(MustSpecifyErr, FieldCaption("From Field No."));

                FromField.Get("From Table No.", "From Field No.");
                TestField("To Table No.");
                ToField.Reset();
                ToField.FilterGroup(4);
                ToField.SetRange(TableNo, "To Table No.");
                ToField.SetRange(Type, FromField.Type);
                ToField.SetRange(Class, FromField.Class);
                ToField.FilterGroup(0);
                if PAGE.RunModal(PAGE::"Data Export Field List", ToField) = ACTION::LookupOK then
                    Validate("To Field No.", ToField."No.");
            end;

            trigger OnValidate()
            begin
                CalcFields("To Field Name");
            end;
        }
        field(10; "To Field Name"; Text[80])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("To Table No."),
                                                              "No." = field("To Field No.")));
            Caption = 'To Field Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Data Export Code", "Data Exp. Rec. Type Code", "From Table No.", "From Field No.", "To Table No.", "To Field No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        FromField.Get("From Table No.", "From Field No.");
        ToField.Get("To Table No.", "To Field No.");
        if ToField.Type <> FromField.Type then
            Error(
              MustBeSameErr,
              FieldCaption("From Field No."),
              FromField.Type,
              FieldCaption("To Field No."),
              ToField.Type);
    end;

    var
        MustSpecifyErr: Label 'You must specify %1.';
        MustBeSameErr: Label 'Fields %1 (data type %2) and %3 (data type %4) should have same data type.';
        FromField: Record "Field";
        ToField: Record "Field";
}

