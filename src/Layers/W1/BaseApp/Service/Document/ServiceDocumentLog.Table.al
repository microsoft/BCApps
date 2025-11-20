// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Service.History;
using System.Security.AccessControl;

table 5912 "Service Document Log"
{
    Caption = 'Service Document Log';
    DrillDownPageID = "Service Document Log";
    LookupPageID = "Service Document Log";
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = if ("Document Type" = const(Quote)) "Service Header"."No." where("Document Type" = const(Quote))
            else
            if ("Document Type" = const(Order)) "Service Header"."No." where("Document Type" = const(Order))
            else
            if ("Document Type" = const(Invoice)) "Service Header"."No." where("Document Type" = const(Invoice))
            else
            if ("Document Type" = const("Credit Memo")) "Service Header"."No." where("Document Type" = const("Credit Memo"))
            else
            if ("Document Type" = const(Shipment)) "Service Shipment Header"
            else
            if ("Document Type" = const("Posted Invoice")) "Service Invoice Header"
            else
            if ("Document Type" = const("Posted Credit Memo")) "Service Cr.Memo Header";
            ValidateTableRelation = false;
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(3; "Event No."; Integer)
        {
            Caption = 'Event No.';
        }
        field(4; "Service Item Line No."; Integer)
        {
            Caption = 'Service Item Line No.';
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
        field(10; "Document Type"; Enum "Service Log Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Change Date", "Change Time")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        ServOrderLog.Reset();
        ServOrderLog.SetRange("Document Type", "Document Type");
        ServOrderLog.SetRange("Document No.", "Document No.");
        if ServOrderLog.FindLast() then
            "Entry No." := ServOrderLog."Entry No." + 1
        else
            "Entry No." := 1;

        "Change Date" := Today;
        "Change Time" := Time;
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
    end;

    var
        ServOrderLog: Record "Service Document Log";

    procedure CopyServLog(DocType: Option; DocNo: Code[20])
    var
        ServDocLog: Record "Service Document Log";
    begin
        ServDocLog.Reset();
        ServDocLog.SetRange("Document Type", DocType);
        ServDocLog.SetRange("Document No.", DocNo);
        if ServDocLog.FindSet() then
            repeat
                Rec := ServDocLog;
                Insert();
            until ServDocLog.Next() = 0;
    end;

    local procedure FillTempServDocLog(var ServHeader: Record "Service Header"; var TempServDocLog: Record "Service Document Log" temporary)
    var
        ServDocLog: Record "Service Document Log";
    begin
        TempServDocLog.Reset();
        TempServDocLog.DeleteAll();

        if ServHeader."No." <> '' then begin
            TempServDocLog.CopyServLog(ServHeader."Document Type".AsInteger(), ServHeader."No.");
            TempServDocLog.CopyServLog(ServDocLog."Document Type"::Shipment.AsInteger(), ServHeader."No.");
            TempServDocLog.CopyServLog(ServDocLog."Document Type"::"Posted Invoice".AsInteger(), ServHeader."No.");
            TempServDocLog.CopyServLog(ServDocLog."Document Type"::"Posted Credit Memo".AsInteger(), ServHeader."No.");
        end;

        TempServDocLog.Reset();
        TempServDocLog.SetCurrentKey("Change Date", "Change Time");
        TempServDocLog.Ascending(false);
    end;

    procedure ShowServDocLog(var ServHeader: Record "Service Header")
    var
        TempServDocLog: Record "Service Document Log" temporary;
    begin
        FillTempServDocLog(ServHeader, TempServDocLog);
        PAGE.Run(0, TempServDocLog);
    end;
}

