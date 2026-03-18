// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Globalization;

using System.Reflection;

table 377 "Object Translation"
{
    Caption = 'Object Translation';
    DataPerCompany = false;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Object Type"; Option)
        {
            Caption = 'Object Type';
            OptionCaption = ' ,Table,Form,Report,,Codeunit,XMLPort,MenuSuite,Page';
            OptionMembers = " ","Table",Form,"Report",,"Codeunit","XMLPort",MenuSuite,"Page";
        }
        field(2; "Object ID"; Integer)
        {
            Caption = 'Object ID';
            NotBlank = true;
            TableRelation = if ("Object Type" = filter(> " ")) AllObj."Object ID" where("Object Type" = field("Object Type"));
        }
        field(3; "Language ID"; Integer)
        {
            BlankZero = true;
            Caption = 'Language ID';
            NotBlank = true;
            TableRelation = "Windows Language";

            trigger OnValidate()
            begin
                CalcFields("Language Name");
            end;
        }
        field(4; "Language Name"; Text[80])
        {
            CalcFormula = lookup("Windows Language".Name where("Language ID" = field("Language ID")));
            Caption = 'Language Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(6; "Object Name"; Text[30])
        {
            CalcFormula = lookup(AllObj."Object Name" where("Object Type" = field("Object Type"),
                                                    "Object ID" = field("Object ID")));
            Caption = 'Object Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Object Type", "Object ID", "Language ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure TranslateObject(ObjectType: Option " ","Table",Form,"Report",,"Codeunit","XMLPort",MenuSuite,"Page"; ObjectID: Integer): Text[250]
    var
        "Object": Record AllObjWithCaption;
    begin
        if Object.Get(ObjectType, ObjectID) then
            exit(Object."Object Caption");
    end;

    procedure TranslateTable(ObjectID: Integer): Text[250]
    begin
        exit(TranslateObject("Object Type"::Table, ObjectID));
    end;
}
