// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Item;

using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using System.Security.AccessControl;

table 5942 "Service Item Log"
{
    Caption = 'Service Item Log';
    DataCaptionFields = "Service Item No.";
    DrillDownPageID = "Service Item Log";
    LookupPageID = "Service Item Log";
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Service Item No."; Code[20])
        {
            Caption = 'Service Item No.';
            NotBlank = true;
            TableRelation = "Service Item";
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(3; "Event No."; Integer)
        {
            Caption = 'Event No.';
        }
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = if ("Document Type" = const(Quote)) "Service Header"."No." where("Document Type" = const(Quote))
            else
            if ("Document Type" = const(Order)) "Service Header"."No." where("Document Type" = const(Order))
            else
            if ("Document Type" = const(Contract)) "Service Contract Header"."Contract No." where("Contract Type" = const(Contract));
        }
        field(5; After; Text[50])
        {
            Caption = 'After';
        }
        field(6; Before; Text[50])
        {
            Caption = 'Before';
        }
        field(7; "Change Date"; Date)
        {
            Caption = 'Change Date';
        }
        field(8; "Change Time"; Time)
        {
            Caption = 'Change Time';
        }
        field(9; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(10; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Quote,Order,Contract';
            OptionMembers = " ",Quote,"Order",Contract;
        }
    }

    keys
    {
        key(Key1; "Service Item No.", "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Change Date")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        ServItemLog.LockTable();
        ServItemLog.Reset();
        ServItemLog.SetRange("Service Item No.", "Service Item No.");
        if ServItemLog.FindLast() then
            "Entry No." := ServItemLog."Entry No." + 1
        else
            "Entry No." := 1;

        "Change Date" := Today;
        "Change Time" := Time;
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
    end;

    var
        ServItemLog: Record "Service Item Log";
}

