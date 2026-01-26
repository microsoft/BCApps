// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using System.Reflection;

table 11000005 "Export Protocol"
{
    Caption = 'Export Protocol';
    LookupPageID = "Export Protocols";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(8; "Export Object Type"; Option)
        {
            Caption = 'Export Object Type';
            OptionCaption = 'Report,XMLPort';
            OptionMembers = "Report","XMLPort";
        }
        field(10; "Check ID"; Integer)
        {
            Caption = 'Check ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Codeunit));

            trigger OnValidate()
            begin
                CalcFields("Check Name");
            end;
        }
        field(11; "Export ID"; Integer)
        {
            Caption = 'Export ID';
            TableRelation = if ("Export Object Type" = const(Report)) AllObjWithCaption."Object ID" where("Object Type" = const(Report))
            else
            if ("Export Object Type" = const(XMLPort)) AllObjWithCaption."Object ID" where("Object Type" = const(XMLport));

            trigger OnValidate()
            var
                AllObjWithCaption: Record AllObjWithCaption;
            begin
                AllObjWithCaption.SetRange("Object Type", GetObjectType());
                AllObjWithCaption.SetRange("Object ID", "Export ID");
                AllObjWithCaption.FindFirst();
                "Export Name" := AllObjWithCaption."Object Name";
            end;
        }
        field(12; "Docket ID"; Integer)
        {
            Caption = 'Docket ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));

            trigger OnValidate()
            begin
                CalcFields("Docket Name");
            end;
        }
        field(21; "Default File Names"; Text[250])
        {
            Caption = 'Default File Names';
        }
        field(22; "External Program"; Text[80])
        {
            Caption = 'External Program';
        }
        field(23; Parameter; Text[80])
        {
            Caption = 'Parameter';
        }
        field(30; "Check Name"; Text[30])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit),
                                                                           "Object ID" = field("Check ID")));
            Caption = 'Check Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "Export Name"; Text[30])
        {
            Caption = 'Export Name';
            Editable = false;
        }
        field(32; "Docket Name"; Text[30])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Docket ID")));
            Caption = 'Docket Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(33; "Generate Checksum"; Boolean)
        {
            Caption = 'Generate Checksum';
            InitValue = false;
            trigger OnValidate()

            begin
                if not rec."Generate Checksum" then begin
                    Rec."Append Checksum to File" := false;
                    Rec.Modify();
                end;
            end;
        }
        field(34; "Checksum Algorithm"; Option)
        {
            Caption = 'Checksum Algorithm';
            OptionMembers = MD5,SHA1,SHA256,SHA384,SHA512;

        }
        field(35; "Append Checksum to File"; Boolean)
        {
            Caption = 'Append Checksum to File';
            InitValue = false;
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

    local procedure GetObjectType(): Integer
    var
        AllObj: Record AllObj;
    begin
        case "Export Object Type" of
            "Export Object Type"::Report:
                exit(AllObj."Object Type"::Report);
            "Export Object Type"::XMLPort:
                exit(AllObj."Object Type"::XMLport);
        end;
    end;
}

