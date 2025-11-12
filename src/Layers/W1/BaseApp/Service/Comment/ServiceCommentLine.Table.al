// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Comment;

using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Loaner;

table 5906 "Service Comment Line"
{
    Caption = 'Service Comment Line';
    DataCaptionFields = Type, "No.";
    DrillDownPageID = "Service Comment Sheet";
    LookupPageID = "Service Comment Sheet";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Enum "Service Comment Line Type")
        {
            Caption = 'Type';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
            TableRelation = if ("Table Name" = const("Service Contract")) "Service Contract Header"."Contract No."
            else
            if ("Table Name" = const("Service Header")) "Service Header"."No."
            else
            if ("Table Name" = const("Service Item")) "Service Item"
            else
            if ("Table Name" = const(Loaner)) Loaner;
        }
        field(3; "Table Line No."; Integer)
        {
            Caption = 'Table Line No.';
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(6; Comment; Text[80])
        {
            Caption = 'Comment';
        }
        field(7; Date; Date)
        {
            Caption = 'Date';
        }
        field(8; "Table Subtype"; Enum "Service Comment Table Subtype")
        {
            Caption = 'Table Subtype';
        }
        field(9; "Table Name"; Enum "Service Comment Table Name")
        {
            Caption = 'Table Name';
        }
    }

    keys
    {
        key(Key1; "Table Name", "Table Subtype", "No.", Type, "Table Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TestTableLineNo();
    end;

    var
        ServCommentLine: Record "Service Comment Line";

    local procedure TestTableLineNo()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestTableLineNo(Rec, IsHandled);
        if IsHandled then
            exit;

        if Type in ["Service Comment Line Type"::Fault, "Service Comment Line Type"::Resolution,
                    "Service Comment Line Type"::Accessory, "Service Comment Line Type"::Internal]
        then
            TestField("Table Line No.");
    end;

    procedure SetUpNewLine()
    begin
        ServCommentLine.Reset();
        ServCommentLine.SetRange("Table Name", "Table Name");
        ServCommentLine.SetRange("Table Subtype", "Table Subtype");
        ServCommentLine.SetRange("No.", "No.");
        ServCommentLine.SetRange(Type, Type);
        ServCommentLine.SetRange("Table Line No.", "Table Line No.");
        ServCommentLine.SetRange(Date, WorkDate());
        if not ServCommentLine.FindFirst() then
            Date := WorkDate();

        OnAfterSetUpNewLine(Rec, ServCommentLine);
    end;

    procedure DeleteComments(TableName: Option; TableType: Option; DocNo: Code[20])
    begin
        SetRange("Table Name", TableName);
        SetRange("Table Subtype", TableType);
        SetRange("No.", DocNo);
        if not IsEmpty() then
            DeleteAll();
    end;

    procedure DeleteServiceInvoiceLinesRelatedComments(ServiceHeader: Record "Service Header")
    begin
        SetRange("Table Name", "Service Comment Table Name"::"Service Header");
        SetRange("Table Subtype", ServiceHeader."Document Type");
        SetRange("No.", ServiceHeader."No.");
        SetRange(Type, "Service Comment Line Type"::General);
        if not IsEmpty() then
            DeleteAll();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var ServiceCommentLineRec: Record "Service Comment Line"; var ServiceCommentLineFilter: Record "Service Comment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestTableLineNo(ServiceCommentLine: Record "Service Comment Line"; var IsHandled: Boolean)
    begin
    end;
}

