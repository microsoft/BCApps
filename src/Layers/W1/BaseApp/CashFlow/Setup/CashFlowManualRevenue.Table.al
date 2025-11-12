// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Setup;

using Microsoft.CashFlow.Account;
using Microsoft.Finance.Dimension;

table 849 "Cash Flow Manual Revenue"
{
    Caption = 'Cash Flow Manual Revenue';
    DrillDownPageID = "Cash Flow Manual Revenues";
    LookupPageID = "Cash Flow Manual Revenues";
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(3; "Cash Flow Account No."; Code[20])
        {
            Caption = 'Cash Flow Account No.';
            TableRelation = "Cash Flow Account";

            trigger OnValidate()
            var
                CFAccount: Record "Cash Flow Account";
            begin
                if "Cash Flow Account No." <> '' then begin
                    CFAccount.Get("Cash Flow Account No.");
                    CFAccount.TestField("Account Type", CFAccount."Account Type"::Entry);
                    if "Cash Flow Account No." <> xRec."Cash Flow Account No." then
                        Description := CFAccount.Name;
                end;
            end;
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(5; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(6; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
        }
        field(7; "Recurring Frequency"; DateFormula)
        {
            Caption = 'Recurring Frequency';
        }
        field(8; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount';
        }
        field(9; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Global Dimension 1 Code");
                Modify();
            end;
        }
        field(10; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Global Dimension 2 Code");
                Modify();
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Starting Date")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DimMgt.DeleteDefaultDim(DATABASE::"Cash Flow Manual Revenue", Code);
    end;

    trigger OnInsert()
    var
        BlankCashFlowAccount: Record "Cash Flow Account";
        ExistingCashFlowManualRevenue: Record "Cash Flow Manual Revenue";
    begin
        if Rec.Code = '' then
            if ExistingCashFlowManualRevenue.Get('') then
                Error(CodeIsNotSetErr, BlankCashFlowAccount.TableCaption(), BlankCashFlowAccount.FieldCaption(BlankCashFlowAccount."Source Type"), BlankCashFlowAccount."Source Type"::"Cash Flow Manual Revenue");

        DimMgt.UpdateDefaultDim(
          DATABASE::"Cash Flow Manual Revenue", Code,
          "Global Dimension 1 Code", "Global Dimension 2 Code");
    end;

    trigger OnRename()
    begin
        DimMgt.RenameDefaultDim(DATABASE::"Cash Flow Manual Revenue", xRec.Code, Code);
    end;

    var
        DimMgt: Codeunit DimensionManagement;
        RevTxt: Label 'REV', Comment = 'Abbreviation of Revenue, used as prefix for code (e.g. REV000001)';

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then
            DimMgt.SaveDefaultDim(DATABASE::"Cash Flow Manual Revenue", Code, FieldNumber, ShortcutDimCode);

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure InitNewRecord()
    var
        CashFlowManualRevenue: Record "Cash Flow Manual Revenue";
        CashFlowAccount: Record "Cash Flow Account";
        CashFlowCode: Code[10];
    begin
        CashFlowManualRevenue.SetFilter(Code, '%1', RevTxt + '0*');
        if not CashFlowManualRevenue.FindLast() then
            CashFlowCode := PadStr(RevTxt, MaxStrLen(CashFlowManualRevenue.Code), '0')
        else
            CashFlowCode := CashFlowManualRevenue.Code;
        CashFlowCode := IncStr(CashFlowCode);

        CashFlowAccount.SetRange("Source Type", CashFlowAccount."Source Type"::"Cash Flow Manual Revenue");
        if not CashFlowAccount.FindFirst() then
            exit;

        Code := CashFlowCode;
        "Cash Flow Account No." := CashFlowAccount."No.";
        "Starting Date" := WorkDate();
        "Ending Date" := 0D;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var CashFlowManualRevenue: Record "Cash Flow Manual Revenue"; var xCashFlowManualRevenue: Record "Cash Flow Manual Revenue"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var CashFlowManualRevenue: Record "Cash Flow Manual Revenue"; var xCashFlowManualRevenue: Record "Cash Flow Manual Revenue"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    var
        CodeIsNotSetErr: Label 'Cannot insert the line because no code value is set. Please verify that you have set up the %1 with the %2 set to %3.', Comment = '%1 is Cash Flow Account, %2 is Source Type, %3 is Cash Flow Manual Revenue';
}
