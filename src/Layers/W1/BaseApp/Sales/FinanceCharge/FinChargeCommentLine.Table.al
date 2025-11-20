// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

table 306 "Fin. Charge Comment Line"
{
    Caption = 'Fin. Charge Comment Line';
    DrillDownPageID = "Fin. Charge Comment List";
    LookupPageID = "Fin. Charge Comment List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Finance Charge Memo,Issued Finance Charge Memo';
            OptionMembers = "Finance Charge Memo","Issued Finance Charge Memo";
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
            TableRelation = if (Type = const("Finance Charge Memo")) "Finance Charge Memo Header"
            else
            if (Type = const("Issued Finance Charge Memo")) "Issued Fin. Charge Memo Header";
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
        FinChrgCommentLine: Record "Fin. Charge Comment Line";
    begin
        FinChrgCommentLine.SetRange(Type, Type);
        FinChrgCommentLine.SetRange("No.", "No.");
        FinChrgCommentLine.SetRange(Date, WorkDate());
        if not FinChrgCommentLine.FindFirst() then
            Date := WorkDate();

        OnAfterSetUpNewLine(Rec, FinChrgCommentLine);
    end;

    procedure CopyComments(FromType: Integer; ToType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    var
        FinChrgCommentLine: Record "Fin. Charge Comment Line";
        FinChrgCommentLine2: Record "Fin. Charge Comment Line";
        IsHandled: Boolean;
    begin
        OnBeforeCopyComments(FinChrgCommentLine, ToType, IsHandled, FromType, FromNumber, ToNumber);
        if IsHandled then
            exit;

        FinChrgCommentLine.SetRange(Type, FromType);
        FinChrgCommentLine.SetRange("No.", FromNumber);
        if FinChrgCommentLine.FindSet() then
            repeat
                FinChrgCommentLine2 := FinChrgCommentLine;
                FinChrgCommentLine2.Type := ToType;
                FinChrgCommentLine2."No." := ToNumber;
                FinChrgCommentLine2.Insert();
            until FinChrgCommentLine.Next() = 0;
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
        FinChargeCommentSheet: Page "Fin. Charge Comment Sheet";
    begin
        SetRange(Type, DocType);
        SetRange("No.", DocNo);
        SetRange("Line No.", DocLineNo);
        Clear(FinChargeCommentSheet);
        FinChargeCommentSheet.SetTableView(Rec);
        FinChargeCommentSheet.RunModal();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var FinChargeCommentLineRec: Record "Fin. Charge Comment Line"; var FinChargeCommentLineFilter: Record "Fin. Charge Comment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyComments(var FinChargeCommentLine: Record "Fin. Charge Comment Line"; ToType: Integer; var IsHandled: Boolean; FromType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    begin
    end;
}

