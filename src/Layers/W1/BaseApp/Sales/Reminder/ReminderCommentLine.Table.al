// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

table 299 "Reminder Comment Line"
{
    Caption = 'Reminder Comment Line';
    DrillDownPageID = "Reminder Comment List";
    LookupPageID = "Reminder Comment List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Enum "Reminder Comment Line Type")
        {
            Caption = 'Type';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
            TableRelation = if (Type = const(Reminder)) "Reminder Header"
            else
            if (Type = const("Issued Reminder")) "Issued Reminder Header";
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; Date; Date)
        {
            Caption = 'Date';
        }
        field(5; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(6; Comment; Text[80])
        {
            Caption = 'Comment';
        }
    }

    keys
    {
        key(Key1; Type, "No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetUpNewLine()
    var
        ReminderCommentLine: Record "Reminder Comment Line";
    begin
        ReminderCommentLine.SetRange(Type, Type);
        ReminderCommentLine.SetRange("No.", "No.");
        ReminderCommentLine.SetRange(Date, WorkDate());
        if not ReminderCommentLine.FindFirst() then
            Date := WorkDate();

        OnAfterSetUpNewLine(Rec, ReminderCommentLine);
    end;

    procedure CopyComments(FromType: Integer; ToType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    var
        ReminderCommentLine: Record "Reminder Comment Line";
        ReminderCommentLine2: Record "Reminder Comment Line";
        IsHandled: Boolean;
    begin
        OnBeforeCopyComments(ReminderCommentLine, ToType, IsHandled, FromType, FromNumber, ToNumber);
        if IsHandled then
            exit;

        ReminderCommentLine.SetRange(Type, FromType);
        ReminderCommentLine.SetRange("No.", FromNumber);
        if ReminderCommentLine.FindSet() then
            repeat
                ReminderCommentLine2 := ReminderCommentLine;
                ReminderCommentLine2.Type := Enum::"Reminder Comment Line Type".FromInteger(ToType);
                ReminderCommentLine2."No." := ToNumber;
                ReminderCommentLine2.Insert();
            until ReminderCommentLine.Next() = 0;
    end;

    procedure DeleteComments(DocType: Option; DocNo: Code[20])
    begin
        SetRange(Type, DocType);
        SetRange("No.", DocNo);
        if not IsEmpty() then
            DeleteAll();
    end;

    procedure ShowComments(DocType: Option; DocNo: Code[20]; DocLineNo: Integer)
    var
        ReminderCommentSheet: Page "Reminder Comment Sheet";
    begin
        SetRange(Type, DocType);
        SetRange("No.", DocNo);
        SetRange("Line No.", DocLineNo);
        Clear(ReminderCommentSheet);
        ReminderCommentSheet.SetTableView(Rec);
        ReminderCommentSheet.RunModal();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var ReminderCommentLineRec: Record "Reminder Comment Line"; var ReminderCommentLineFilter: Record "Reminder Comment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyComments(var ReminderCommentLine: Record "Reminder Comment Line"; ToType: Integer; var IsHandled: Boolean; FromType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    begin
    end;
}

