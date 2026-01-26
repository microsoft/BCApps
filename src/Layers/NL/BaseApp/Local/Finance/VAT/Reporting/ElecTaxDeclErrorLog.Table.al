// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

table 11412 "Elec. Tax Decl. Error Log"
{
    Caption = 'Elec. Tax Decl. Error Log';
    DrillDownPageID = "Elec. Tax Decl. Error Log";
    LookupPageID = "Elec. Tax Decl. Error Log";
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
            NotBlank = true;
            TableRelation = "Elec. Tax Declaration Header"."No." where("Declaration Type" = field("Declaration Type"));
        }
        field(9; "No."; Integer)
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(10; "Error Class"; Text[30])
        {
            Caption = 'Error Class';
            Editable = false;
        }
        field(30; "Error Description"; Text[250])
        {
            Caption = 'Error Description';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(200; "VAT Report No."; Code[20])
        {
            Caption = 'VAT Report No.';
        }
        field(201; "VAT Report Config. Code"; Option)
        {
            OptionMembers = "EC Sales List","VAT Return";
            TableRelation = "VAT Reports Configuration"."VAT Report Type";
            Caption = 'VAT Report Config. Code';
        }
    }

    keys
    {
        key(Key1; "Declaration Type", "Declaration No.", "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

