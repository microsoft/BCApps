// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using System.Text;

table 1150 "Report Totals Buffer"
{
    Caption = 'Report Totals Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(3; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(4; "Amount Formatted"; Text[30])
        {
            Caption = 'Amount Formatted';
            DataClassification = SystemMetadata;
        }
        field(5; "Font Bold"; Boolean)
        {
            Caption = 'Font Bold';
            DataClassification = SystemMetadata;
        }
        field(6; "Font Underline"; Boolean)
        {
            Caption = 'Font Underline';
            DataClassification = SystemMetadata;
        }
        field(7; "Font Italics"; Boolean)
        {
            Caption = 'Font Italics';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure Add(NewDescription: Text[250]; NewAmount: Decimal; NewBold: Boolean; NewUnderline: Boolean; NewItalics: Boolean)
    begin
        AddTotal(NewDescription, NewAmount, NewBold, NewUnderline, NewItalics, Format(NewAmount, 0, '<Precision,2><Standard Format,0>'));
    end;

    procedure Add(NewDescription: Text[250]; NewAmount: Decimal; NewBold: Boolean; NewUnderline: Boolean; NewItalics: Boolean; AutoFormatExp: Text[80])
    var
        AutoFormat: Codeunit "Auto Format";
    begin
        AddTotal(NewDescription, NewAmount, NewBold, NewUnderline, NewItalics, Format(NewAmount, 0, AutoFormat.ResolveAutoFormat("Auto Format"::AmountFormat, AutoFormatExp)));
    end;

    local procedure AddTotal(NewDescription: Text[250]; NewAmount: Decimal; NewBold: Boolean; NewUnderline: Boolean; NewItalics: Boolean; AmountFormatted: Text[30])
    begin
        if FindLast() then;
        Init();
        "Line No." += 1;
        Description := NewDescription;
        Amount := NewAmount;
        "Amount Formatted" := AmountFormatted;
        "Font Bold" := NewBold;
        "Font Underline" := NewUnderline;
        "Font Italics" := NewItalics;
        Insert(true);
    end;
}

