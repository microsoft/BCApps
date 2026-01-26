// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

table 11413 "Elec. Tax Decl. Response Msg."
{
    Caption = 'Elec. Tax Decl. Response Msg.';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
        }
        field(10; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = ' ,,,Received,,,Processed';
            OptionMembers = " ",,,Received,,,Processed;
        }
        field(20; "Date Sent"; Text[80])
        {
            Caption = 'Date Sent';
        }
        field(50; Subject; Text[80])
        {
            Caption = 'Subject';
        }
        field(100; Message; BLOB)
        {
            Caption = 'Message';
            SubType = UserDefined;
        }
        field(150; "Declaration Type"; Option)
        {
            Caption = 'Declaration Type';
            Editable = false;
            OptionCaption = 'VAT Declaration,ICP Declaration';
            OptionMembers = "VAT Declaration","ICP Declaration";
        }
        field(160; "Declaration No."; Code[20])
        {
            Caption = 'Declaration No.';
            Editable = false;
            TableRelation = "Elec. Tax Declaration Header"."No." where("Declaration Type" = field("Declaration Type"));
        }
        field(170; "Status Code"; Code[10])
        {
            Caption = 'Status Code';
        }
        field(171; "Status Description"; Text[150])
        {
            Caption = 'Status Description';
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
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; Status)
        {
        }
        key(Key3; "Declaration Type", "Declaration No.")
        {
        }
        key(Key4; "Status Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if "No." = 0 then begin
            ElecTaxDeclResponseMsg.Reset();
            ElecTaxDeclResponseMsg."No." := 0;
            if not ElecTaxDeclResponseMsg.FindLast() then;
            "No." := ElecTaxDeclResponseMsg."No." + 1;
        end;
    end;

    var
        ElecTaxDeclResponseMsg: Record "Elec. Tax Decl. Response Msg.";
}

