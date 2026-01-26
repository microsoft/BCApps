// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Telemetry;

table 10710 "AEAT Transference Format XML"
{
    Caption = 'AEAT Transference Format XML';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "VAT Statement Name"; Code[10])
        {
            Caption = 'VAT Statement Name';
            TableRelation = "VAT Statement Name".Name where(Name = field("VAT Statement Name"));
        }
        field(2; "No."; Integer)
        {
            Caption = 'No.';
        }
        field(3; "Indentation Level"; Integer)
        {
            Caption = 'Indentation Level';

            trigger OnValidate()
            begin
                if "Indentation Level" > 0 then begin
                    AEATTransferenceFormatXML.Reset();
                    AEATTransferenceFormatXML.SetRange("VAT Statement Name", "VAT Statement Name");
                    AEATTransferenceFormatXML.SetFilter("No.", '<%1', "No.");
                    AEATTransferenceFormatXML.SetRange("Indentation Level", "Indentation Level" - 1);
                    if AEATTransferenceFormatXML.FindLast() then
                        "Parent Line No." := AEATTransferenceFormatXML."No.";
                end else
                    "Parent Line No." := 0;
            end;
        }
        field(4; "Parent Line No."; Integer)
        {
            Caption = 'Parent Line No.';
        }
        field(5; "Line Type"; Option)
        {
            Caption = 'Line Type';
            OptionCaption = ' ,Element,Attribute';
            OptionMembers = " ",Element,Attribute;
        }
        field(6; "Value Type"; Option)
        {
            Caption = 'Value Type';
            OptionCaption = ' ,Integer and Decimal Part,Integer Part,Decimal Part';
            OptionMembers = " ","Integer and Decimal Part","Integer Part","Decimal Part";
        }
        field(7; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(8; Value; Text[250])
        {
            Caption = 'Value';
        }
        field(9; Box; Code[5])
        {
            Caption = 'Box';
        }
        field(10; Ask; Boolean)
        {
            Caption = 'Ask';
        }
        field(11; "Exists Amount"; Boolean)
        {
            Caption = 'Exists Amount';
        }
    }

    keys
    {
        key(Key1; "VAT Statement Name", "No.")
        {
            Clustered = true;
        }
        key(Key2; "VAT Statement Name", "Indentation Level")
        {
        }
        key(Key3; "VAT Statement Name", "Parent Line No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnModify()
    begin
        if (Box <> '') and (Value <> '') then
            Error(Text1100000);
        if (Box <> '') and ("Value Type" = "Value Type"::" ") then
            Error(Text1100001);
        if ("Line Type" = "Line Type"::Attribute) and ((Value = '') and (Box = '')) then
            Error(Text1100002);
    end;

    trigger OnInsert()
    begin
        FeatureTelemetry.LogUptake('1000HW2', ESVATXMLTok, Enum::"Feature Uptake Status"::"Set up");
    end;

    var
        AEATTransferenceFormatXML: Record "AEAT Transference Format XML";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ESVATXMLTok: Label 'ES Export VAT Statements in XML Format', Locked = true;
        Text1100000: Label 'It is not possible to insert a value and a box at the same time. The data that will appear in this label in the XML file must either come from a Box in the VAT Statement or be introduced manually in the Value field.';
        Text1100001: Label 'If a value is introduced in the Box field, you must specify the format you want for the amounts that will be shown in this line. This means, you must select a format different than blank in the field Value Type.';
        Text1100002: Label 'A value or box is mandatory for Attributes';

    [Scope('OnPrem')]
    procedure Export()
    var
        AEATTransferenceFormatXML: Record "AEAT Transference Format XML";
    begin
        AEATTransferenceFormatXML := Rec;
        AEATTransferenceFormatXML.SetRecFilter();

        REPORT.RunModal(REPORT::"XML VAT Declaration", true, false, AEATTransferenceFormatXML);
    end;
}

