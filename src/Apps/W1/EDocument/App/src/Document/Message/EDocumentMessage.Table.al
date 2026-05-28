// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
// V3 Messages: a Message is its own artifact. Messages are not discriminated records inside the
// existing "E-Document" table — they fail the "becomes a BC document" test that defines an
// E-Document. They live here, with a mandatory FK to a parent E-Document.
namespace Microsoft.eServices.EDocument;

table 6142 "E-Document Message"
{
    Caption = 'E-Document Message';
    DataClassification = CustomerContent;
    LookupPageId = "E-Document Message Card";
    DrillDownPageId = "E-Document Message Card";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Related E-Document No."; Integer)
        {
            Caption = 'Related E-Document No.';
            TableRelation = "E-Document"."Entry No";
            NotBlank = true;
        }
        field(3; "Message Type"; Enum "E-Document Message Type")
        {
            Caption = 'Message Type';
        }
        field(4; Direction; Enum "E-Document Direction")
        {
            Caption = 'Direction';
        }
        field(5; "Status Code"; Code[20])
        {
            Caption = 'Status Code';                                // raw protocol code: AP / RE / PD / Collected / Refused / ...
        }
        field(6; Status; Enum "E-Doc. Message Status")
        {
            Caption = 'Status';
        }
        field(7; "Data Storage Entry No."; Integer)
        {
            Caption = 'Data Storage Entry No.';
            TableRelation = "E-Doc. Data Storage"."Entry No.";
        }
        field(8; "Service Code"; Code[20])
        {
            Caption = 'Service Code';
            TableRelation = "E-Document Service"."Code";
        }
        field(9; "Sent / Received At"; DateTime)
        {
            Caption = 'Sent / Received At';
        }
        field(10; "Created At"; DateTime)
        {
            Caption = 'Created At';
        }
        field(11; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12; "Last Error"; Text[2048])
        {
            Caption = 'Last Error';
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Parent; "Related E-Document No.", Direction, "Created At") { }
        key(Status; Status) { }
    }

    trigger OnInsert()
    begin
        if Rec."Related E-Document No." = 0 then
            Error(ParentRequiredErr);
        if Rec."Created At" = 0DT then
            Rec."Created At" := CurrentDateTime();
        if Rec."Created By" = '' then
            Rec."Created By" := CopyStr(UserId(), 1, MaxStrLen(Rec."Created By"));
    end;

    trigger OnModify()
    begin
        if Rec."Related E-Document No." = 0 then
            Error(ParentRequiredErr);
    end;

    var
        ParentRequiredErr: Label 'Every E-Document Message must reference a parent E-Document (Related E-Document No.).';
}
