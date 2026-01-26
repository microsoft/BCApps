// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Setup;

table 10745 "Operation Code"
{
    Caption = 'Operation Code';
    DrillDownPageID = "Operation Codes";
    LookupPageID = "Operation Codes";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[1])
        {
            Caption = 'Code';
            CharAllowed = 'AZaz18';
            NotBlank = true;

            trigger OnValidate()
            begin
                if Code in ['C', 'D', 'I'] then
                    Error(Text001);
            end;
        }
        field(2; Description; Text[30])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        GenProductPostingGroup.SetRange("Operation Code", Code);
        if not GenProductPostingGroup.IsEmpty() then
            Error(Text002, Code);
    end;

    var
        Text001: Label 'You cannot set up C, D and I operations key because they are system-created codes.';
        Text002: Label 'Operation Code %1 has been mapped to one or more General Product Posting group and cannot be deleted ';
}

