// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.ADCS;

using System;
using System.Reflection;
using System.Xml;

table 7700 "Miniform Header"
{
    Caption = 'Miniform Header';
    LookupPageID = Miniforms;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(11; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(12; "No. of Records in List"; Integer)
        {
            Caption = 'No. of Records in List';
        }
        field(13; "Form Type"; Option)
        {
            Caption = 'Form Type';
            OptionCaption = 'Card,Selection List,Data List,Data List Input', Locked = true;
            OptionMembers = Card,"Selection List","Data List","Data List Input";
        }
        field(15; "Start Miniform"; Boolean)
        {
            Caption = 'Start Miniform';

            trigger OnValidate()
            var
                MiniformHeader: Record "Miniform Header";
            begin
                MiniformHeader.SetFilter(Code, '<>%1', Code);
                MiniformHeader.SetRange("Start Miniform", true);
                if not MiniformHeader.IsEmpty() then
                    Error(Text002);
            end;
        }
        field(20; "Handling Codeunit"; Integer)
        {
            Caption = 'Handling Codeunit';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Codeunit));
        }
        field(21; "Next Miniform"; Code[20])
        {
            Caption = 'Next Miniform';
            TableRelation = "Miniform Header";

            trigger OnValidate()
            begin
                if "Next Miniform" = Code then
                    Error(Text000);

                if "Form Type" in ["Form Type"::"Selection List", "Form Type"::"Data List Input"] then
                    Error(Text001, FieldCaption("Form Type"), "Form Type");
            end;
        }
        field(25; XMLin; BLOB)
        {
            Caption = 'XMLin';
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
        MiniFormLine: Record "Miniform Line";
        MiniFormFunc: Record "Miniform Function";
    begin
        MiniFormLine.Reset();
        MiniFormLine.SetRange("Miniform Code", Code);
        MiniFormLine.DeleteAll();

        MiniFormFunc.Reset();
        MiniFormFunc.SetRange("Miniform Code", Code);
        MiniFormFunc.DeleteAll();
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Recursion is not allowed.';
#pragma warning disable AA0470
        Text001: Label '%1 must not be %2.';
#pragma warning restore AA0470
        Text002: Label 'There can only be one login form.';
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure SaveXMLin(DOMxmlin: DotNet XmlDocument)
    var
        InStrm: InStream;
    begin
        XMLin.CreateInStream(InStrm);
        DOMxmlin.Save(InStrm);
    end;

    [Scope('OnPrem')]
    procedure LoadXMLin(var DOMxmlin: DotNet XmlDocument)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        OutStrm: OutStream;
    begin
        XMLin.CreateOutStream(OutStrm);
        XMLDOMManagement.LoadXMLDocumentFromOutStream(OutStrm, DOMxmlin);
    end;
}

