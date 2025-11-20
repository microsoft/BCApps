// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Reflection;

table 746 "VAT Reports Configuration"
{
    Caption = 'VAT Reports Configuration';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "VAT Report Type"; Enum "VAT Report Configuration")
        {
            Caption = 'VAT Report Type';
        }
        field(2; "VAT Report Version"; Code[10])
        {
            Caption = 'VAT Report Version';
        }
        field(3; "Suggest Lines Codeunit ID"; Integer)
        {
            Caption = 'Suggest Lines Codeunit ID';
            TableRelation = "CodeUnit Metadata".ID;
        }
        field(4; "Suggest Lines Codeunit Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit),
                                                                           "Object ID" = field("Suggest Lines Codeunit ID")));
            Caption = 'Suggest Lines Codeunit Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Content Codeunit ID"; Integer)
        {
            Caption = 'Content Codeunit ID';
            TableRelation = "CodeUnit Metadata".ID;
        }
        field(6; "Content Codeunit Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit),
                                                                           "Object ID" = field("Content Codeunit ID")));
            Caption = 'Content Codeunit Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Submission Codeunit ID"; Integer)
        {
            Caption = 'Submission Codeunit ID';
            TableRelation = "CodeUnit Metadata".ID;
        }
        field(8; "Submission Codeunit Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit),
                                                                           "Object ID" = field("Submission Codeunit ID")));
            Caption = 'Submission Codeunit Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Response Handler Codeunit ID"; Integer)
        {
            Caption = 'Response Handler Codeunit ID';
            TableRelation = "CodeUnit Metadata".ID;
        }
        field(10; "Resp. Handler Codeunit Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit),
                                                                           "Object ID" = field("Response Handler Codeunit ID")));
            Caption = 'Resp. Handler Codeunit Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; "Validate Codeunit ID"; Integer)
        {
            Caption = 'Validate Codeunit ID';
            TableRelation = "CodeUnit Metadata".ID;
        }
        field(12; "Validate Codeunit Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit),
                                                                           "Object ID" = field("Validate Codeunit ID")));
            Caption = 'Validate Codeunit Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "VAT Statement Template"; Code[10])
        {
            Caption = 'VAT Statement Template';
            TableRelation = "VAT Statement Template".Name;
        }
        field(14; "VAT Statement Name"; Code[10])
        {
            Caption = 'VAT Statement Name';
            TableRelation = "VAT Statement Name".Name;
        }
    }

    keys
    {
        key(Key1; "VAT Report Type", "VAT Report Version")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

