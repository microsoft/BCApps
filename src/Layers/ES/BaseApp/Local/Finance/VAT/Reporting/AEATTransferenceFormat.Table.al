// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Telemetry;

table 10705 "AEAT Transference Format"
{
    Caption = 'AEAT Transference Format';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "VAT Statement Name"; Code[10])
        {
            Caption = 'VAT Statement Name';
        }
        field(2; "No."; Integer)
        {
            Caption = 'No.';
        }
        field(3; Position; Integer)
        {
            Caption = 'Position';

            trigger OnValidate()
            begin
                TestField(Position);
            end;
        }
        field(4; Length; Integer)
        {
            Caption = 'Length';

            trigger OnValidate()
            begin
                if Length < 1 then
                    Error(Text1100000);
            end;
        }
        field(5; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Alphanumerical,Numerical,Fix,Ask,Currency';
            OptionMembers = Alphanumerical,Numerical,Fix,Ask,Currency;

            trigger OnValidate()
            begin
                if Type = Type::Numerical then
                    Subtype := Subtype::" ";
            end;
        }
        field(6; Subtype; Option)
        {
            Caption = 'Subtype';
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

            trigger OnValidate()
            begin
                if Type = Type::Fix then
                    i := StrLen(Value);
                if StrLen(Value) > Length then
                    Error(Text1100001);

                Validate(Length);
            end;
        }
        field(9; Box; Code[5])
        {
            Caption = 'Box';
        }
        field(10; "Exists Amount"; Boolean)
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
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        FeatureTelemetry.LogUptake('1000HV8', ESTelematicVATTok, Enum::"Feature Uptake Status"::"Set up");
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ESTelematicVATTok: Label 'ES Create Templates for Telematic VAT Statements in Text File Format', Locked = true;
        Text1100000: Label '''Length'' must be at least 1';
        Text1100001: Label 'The value typed is longer than the maximum length allowed';
        i: Integer;
}

