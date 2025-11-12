// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

using Microsoft.CRM.Setup;

table 5060 "Contact Web Source"
{
    Caption = 'Contact Web Source';
    DataClassification = CustomerContent;
    DrillDownPageID = "Contact Web Sources";

    fields
    {
        field(1; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            NotBlank = true;
            TableRelation = Contact where(Type = const(Company));
        }
        field(2; "Web Source Code"; Code[10])
        {
            Caption = 'Web Source Code';
            NotBlank = true;
            TableRelation = "Web Source";
        }
        field(3; "Search Word"; Text[30])
        {
            Caption = 'Search Word';
        }
        field(4; "Web Source Description"; Text[100])
        {
            CalcFormula = lookup("Web Source".Description where(Code = field("Web Source Code")));
            Caption = 'Web Source Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Contact Name"; Text[100])
        {
            CalcFormula = lookup(Contact.Name where("No." = field("Contact No.")));
            Caption = 'Contact Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Contact No.", "Web Source Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure Launch()
    var
        WebSource: Record "Web Source";
    begin
        WebSource.Get("Web Source Code");
        WebSource.TestField(URL);
        HyperLink(StrSubstNo(WebSource.URL, "Search Word"));
    end;
}

