// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SpendRequest;

using Microsoft.Finance.GeneralLedger.Account;

table 6841 "Spend Request Detail"
{
    Caption = 'Spend Request Document Detail';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Spend Request No."; Code[20])
        {
            Caption = 'Spend Request No.';
            DataClassification = CustomerContent;
            TableRelation = "Spend Request";
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the line number of the spend request detail.';
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the spend request detail.';
            trigger OnValidate()
            begin
                TestReqStatusOpen();
            end;
        }
        field(5; Amount; Decimal)
        {
            Caption = 'Amount';
            ToolTip = 'Specifies the expected amount of the spend request detail.';
            AutoFormatExpression = '';
            AutoFormatType = 1;

            trigger OnValidate()
            begin
                TestReqStatusOpen();
                ApplyAmountDelta(Amount - xRec.Amount);
            end;
        }
        field(6; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            ToolTip = 'The G/L Account that the expenses will be posted to.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
    }
    keys
    {
        key(Key1; "Spend Request No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "G/L Account No.")
        {
            IncludedFields = Amount;
        }
    }

    trigger OnInsert()
    begin
        TestReqStatusOpen();
        InitHeaderDefaults();
    end;

    trigger OnDelete()
    begin
        TestReqStatusOpen();
        ApplyAmountDelta(-Amount);
    end;

    local procedure ApplyAmountDelta(Delta: Decimal)
    var
        SpendRequest: Record "Spend Request";
    begin
        if Delta = 0 then
            exit;

        SpendRequest.Get("Spend Request No.");

        SpendRequest.AddToTotalExpectedAmount(Delta);
    end;

    local procedure InitHeaderDefaults()
    var
        SpendRequest: Record "Spend Request";
        SpendReqDetail: Record "Spend Request Detail";
    begin
        SpendRequest.Get(Rec."Spend Request No.");
        if Rec."G/L Account No." = '' then
            Rec."G/L Account No." := SpendRequest."G/L Account No.";
        if Rec.Amount = 0 then begin
            SpendReqDetail.SetRange("Spend Request No.", Rec."Spend Request No.");
            SpendReqDetail.CalcSums(Amount);
            if SpendReqDetail.Amount < SpendRequest."Total Expected Amount" then
                Rec.Amount := SpendRequest."Total Expected Amount" - SpendReqDetail.Amount;
        end;
    end;

    local procedure TestReqStatusOpen()
    var
        SpendRequest: Record "Spend Request";
    begin
        if Rec."Spend Request No." = '' then
            exit;

        SpendRequest.SetLoadFields(Status);
        SpendRequest.Get(Rec."Spend Request No.");

        SpendRequest.TestStatusOpen();
    end;
}
