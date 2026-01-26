// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.VAT.Setup;
using System.Reflection;

table 11600 "BAS Setup"
{
    Caption = 'BAS Setup';
    DataCaptionFields = "Row No.", "Field No.", "Field Label No.";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Field No."; Integer)
        {
            Caption = 'Field No.';
            TableRelation = Field."No." where(TableNo = filter(11601));

            trigger OnValidate()
            begin
                BASManagement.CheckBASFieldID("Field No.", true);
                CalcFields("Field Label No.", "Field Description");
            end;
        }
        field(2; "Field Label No."; Text[30])
        {
            CalcFormula = lookup(Field.FieldName where(TableNo = filter(11601),
                                                        "No." = field("Field No.")));
            Caption = 'Field Label No.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(3; "Field Description"; Text[80])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = filter(11601),
                                                              "No." = field("Field No.")));
            Caption = 'Field Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Row No."; Code[10])
        {
            Caption = 'Row No.';
        }
        field(6; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Account Totaling,GST Entry Totaling,Row Totaling,Description';
            OptionMembers = "Account Totaling","GST Entry Totaling","Row Totaling",Description;

            trigger OnValidate()
            begin
                if Type <> xRec.Type then begin
                    TempType := Type;
                    Init();
                    "Line No." := xRec."Line No.";
                    "Field No." := xRec."Field No.";
                    "Row No." := xRec."Row No.";
                    CalcFields("Field Label No.", "Field Description");
                    Type := TempType;
                end;
                if (Type = Type::"Account Totaling") or (Type = Type::"Row Totaling") then
                    Print := true;
            end;
        }
        field(7; "Account Totaling"; Text[80])
        {
            Caption = 'Account Totaling';
            TableRelation = "G/L Account";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if "Account Totaling" <> '' then begin
                    GLAcc.SetFilter("No.", "Account Totaling");
                    GLAcc.SetFilter("Account Type", '<>%1', 0);
                    if GLAcc.FindFirst() then
                        GLAcc.TestField("Account Type", GLAcc."Account Type"::Posting);
                end;
            end;
        }
        field(8; "Gen. Posting Type"; Option)
        {
            Caption = 'Gen. Posting Type';
            OptionCaption = ' ,Purchase,Sale,Settlement';
            OptionMembers = " ",Purchase,Sale,Settlement;
        }
        field(9; "GST Bus. Posting Group"; Code[20])
        {
            Caption = 'GST Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(10; "GST Prod. Posting Group"; Code[20])
        {
            Caption = 'GST Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(11; "Row Totaling"; Text[80])
        {
            Caption = 'Row Totaling';
        }
        field(12; "Amount Type"; Option)
        {
            Caption = 'Amount Type';
            OptionCaption = ' ,Amount,Base,Unrealized Amount,Unrealized Base,GST Amount';
            OptionMembers = " ",Amount,Base,"Unrealized Amount","Unrealized Base","GST Amount";
        }
        field(13; "Calculate with"; Option)
        {
            Caption = 'Calculate with';
            OptionCaption = 'Sign,Opposite Sign';
            OptionMembers = Sign,"Opposite Sign";

            trigger OnValidate()
            begin
                if ("Calculate with" = "Calculate with"::"Opposite Sign") and (Type = Type::"Row Totaling") then
                    FieldError(Type, StrSubstNo(Text000, Type));
            end;
        }
        field(14; "BAS Adjustment"; Boolean)
        {
            Caption = 'BAS Adjustment';
        }
        field(15; "Print with"; Option)
        {
            Caption = 'Print with';
            OptionCaption = 'Sign,Opposite Sign';
            OptionMembers = Sign,"Opposite Sign";
        }
        field(16; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(17; "New Page"; Boolean)
        {
            Caption = 'New Page';
        }
        field(20; "Setup Name"; Code[20])
        {
            Caption = 'Setup Name';
            TableRelation = "BAS Setup Name";
        }
        field(21; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(22; Print; Boolean)
        {
            Caption = 'Print';

            trigger OnValidate()
            begin
                if (Type = Type::"Account Totaling") or (Type = Type::"Row Totaling") then
                    TestField(Print, true);
            end;
        }
    }

    keys
    {
        key(Key1; "Setup Name", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Text000: Label 'must not be %1';
        GLAcc: Record "G/L Account";
        BASManagement: Codeunit "BAS Management";
        TempType: Integer;
}

