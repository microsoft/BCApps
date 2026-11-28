// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Registration;

using Microsoft.Foundation.Address;

table 7402 "Registration No. Format"
{
    Caption = 'Registration No. Format';
    DataClassification = CustomerContent;
    LookupPageId = "Registration No. Formats";
    DrillDownPageId = "Registration No. Formats";

    fields
    {
        field(1; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            NotBlank = true;
            TableRelation = "Country/Region";
            ToolTip = 'Specifies the country or region whose legal registration number format is defined.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Format; Text[50])
        {
            Caption = 'Format';
            NotBlank = true;
            ToolTip = 'Specifies a complete registration number pattern. Use # for an ASCII digit, @ for a Unicode letter, ? for any character, and \ to escape the next character. Other characters are case-sensitive literals.';

            trigger OnValidate()
            begin
                CheckFormat();
            end;
        }
    }

    keys
    {
        key(PK; "Country/Region Code", "Line No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        TestField("Country/Region Code");
        CheckFormat();
    end;

    trigger OnModify()
    begin
        TestField("Country/Region Code");
        CheckFormat();
    end;

    trigger OnRename()
    begin
        TestField("Country/Region Code");
    end;

    local procedure CheckFormat()
    var
        RegistrationNoMgt: Codeunit "Registration No. Mgt.";
    begin
        TestField(Format);
        RegistrationNoMgt.ValidateFormat(Format);
    end;
}
