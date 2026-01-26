// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

table 11410 "Elec. Tax Declaration Line"
{
    Caption = 'Elec. Tax Declaration Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Declaration Type"; Option)
        {
            Caption = 'Declaration Type';
            OptionCaption = 'VAT Declaration,ICP Declaration';
            OptionMembers = "VAT Declaration","ICP Declaration";
        }
        field(2; "Declaration No."; Code[20])
        {
            Caption = 'Declaration No.';
            TableRelation = "Elec. Tax Declaration Header"."No." where("Declaration Type" = field("Declaration Type"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; "Line Type"; Option)
        {
            Caption = 'Line Type';
            Editable = false;
            OptionCaption = 'Element,Attribute';
            OptionMembers = Element,Attribute;
        }
        field(20; "Indentation Level"; Integer)
        {
            Caption = 'Indentation Level';
            Editable = false;
        }
        field(30; Name; Text[80])
        {
            Caption = 'Name';
            Editable = false;
        }
        field(40; Data; Text[250])
        {
            Caption = 'Data';
            Editable = false;
        }
        field(50; "Parent Line No."; Integer)
        {
            Caption = 'Parent Line No.';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Declaration Type", "Declaration No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Declaration Type", "Declaration No.", "Indentation Level")
        {
        }
        key(Key3; "Declaration Type", "Declaration No.", "Parent Line No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        ElecTaxDeclarationLine: Record "Elec. Tax Declaration Line";
    begin
        if "Line No." = 0 then begin
            ElecTaxDeclarationLine.SetRange("Declaration Type", "Declaration Type");
            ElecTaxDeclarationLine.SetRange("Declaration No.", "Declaration No.");
            if not ElecTaxDeclarationLine.FindLast() then;
            "Line No." := ElecTaxDeclarationLine."Line No." + 10000;
        end;

        if "Indentation Level" > 0 then begin
            ElecTaxDeclarationLine.SetFilter("Line No.", '<%1', "Line No.");
            ElecTaxDeclarationLine.SetRange("Indentation Level", "Indentation Level" - 1);
            ElecTaxDeclarationLine.FindLast();
            "Parent Line No." := ElecTaxDeclarationLine."Line No.";
        end else
            "Parent Line No." := 0;
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        Text000: Label 'You cannot rename a %1.';
}

