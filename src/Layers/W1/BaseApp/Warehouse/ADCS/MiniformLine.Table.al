// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.ADCS;

using System.Reflection;

table 7701 "Miniform Line"
{
    Caption = 'Miniform Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Miniform Code"; Code[20])
        {
            Caption = 'Miniform Code';
            NotBlank = true;
            TableRelation = "Miniform Header".Code;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(11; "Area"; Option)
        {
            Caption = 'Area';
            ToolTip = 'Specifies the area of the customer or vendor, for the purpose of reporting to INTRASTAT.';
            OptionCaption = 'Header,Body,Footer', Locked = true;
            OptionMembers = Header,Body,Footer;
        }
        field(12; "Field Type"; Option)
        {
            Caption = 'Field Type';
            ToolTip = 'Specifies the type of data that is defined in the miniform line.';
            OptionCaption = 'Text,Input,Output,Asterisk', Locked = true;
            OptionMembers = Text,Input,Output,Asterisk;

            trigger OnValidate()
            begin
                if "Field Type" = "Field Type"::Input then begin
                    GetMiniFormHeader();
                    if ((MiniFormHeader."Form Type" = MiniFormHeader."Form Type"::"Selection List") or
                        (MiniFormHeader."Form Type" = MiniFormHeader."Form Type"::"Data List"))
                    then
                        Error(
                          Text000,
                          "Field Type", MiniFormHeader.FieldCaption("Form Type"), MiniFormHeader."Form Type");
                end;
            end;
        }
        field(13; "Table No."; Integer)
        {
            Caption = 'Table No.';
            ToolTip = 'Specifies the number of the table in the program from which the data comes or in which it is entered.';

            trigger OnLookup()
            var
                FieldSelection: Codeunit "Field Selection";
            begin
                if "Field Type" in ["Field Type"::Input, "Field Type"::Output] then begin
                    Field.Reset();
                    if FieldSelection.Open(Field) then begin
                        "Table No." := Field.TableNo;
                        Validate("Field No.", Field."No.");
                    end;
                end;
            end;

            trigger OnValidate()
            begin
                if "Table No." <> 0 then begin
                    Field.Reset();
                    Field.SetRange(TableNo, "Table No.");
                    Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
                    Field.FindFirst();
                end else
                    Validate("Field No.", 0);
            end;
        }
        field(14; "Field No."; Integer)
        {
            Caption = 'Field No.';
            ToolTip = 'Specifies the number of the field from which the data comes or in which the data is entered.';

            trigger OnLookup()
            var
                FieldSelection: Codeunit "Field Selection";
            begin
                Field.Reset();
                Field.SetRange(TableNo, "Table No.");
                if FieldSelection.Open(Field) then
                    Validate("Field No.", Field."No.");
            end;

            trigger OnValidate()
            var
                TypeHelper: Codeunit "Type Helper";
            begin
                if "Field No." <> 0 then begin
                    Field.Get("Table No.", "Field No.");
                    TypeHelper.TestFieldIsNotObsolete(Field);
                    Validate(Text, Field."Field Caption");
                    Validate("Field Length", Field.Len);
                end else begin
                    Validate(Text, '');
                    Validate("Field Length", 0);
                end;
            end;
        }
        field(15; Text; Text[30])
        {
            Caption = 'Text';
            ToolTip = 'Specifies text if the field type is Text.';
        }
        field(16; "Field Length"; Integer)
        {
            Caption = 'Field Length';
            ToolTip = 'Specifies the maximum length of the field value.';
        }
        field(21; "Call Miniform"; Code[20])
        {
            Caption = 'Call Miniform';
            ToolTip = 'Specifies which miniform will be called when the user on the handheld selects the choice on the line.';
            TableRelation = "Miniform Header";

            trigger OnValidate()
            begin
                GetMiniFormHeader();
            end;
        }
    }

    keys
    {
        key(Key1; "Miniform Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Area")
        {
        }
    }

    fieldgroups
    {
    }

    var
        MiniFormHeader: Record "Miniform Header";
        "Field": Record "Field";
#pragma warning disable AA0074
        Text000: Label '%1 not allowed for %2 %3.', Comment = '%1 = Field type, %2= Form Type field caption, %3 = Form type';
#pragma warning restore AA0074

    local procedure GetMiniFormHeader()
    begin
        if MiniFormHeader.Code <> "Miniform Code" then
            MiniFormHeader.Get("Miniform Code");
    end;
}

