// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SpendRequest;

using Microsoft.Finance.Currency;
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
        field(5; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency used for estimation. The currency amount will automatically be converted into Total Expected Amount (LCY)';
            DataClassification = CustomerContent;
            TableRelation = Currency;

            trigger OnValidate()
            begin
                TestReqStatusOpen();
                ChangeCurrency(xRec."Currency Code");
            end;
        }
        field(6; "Expected Amount"; Decimal)
        {
            Caption = 'Expected Amount';
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            ToolTip = 'Specifies the expected amount of the spend request detail.';

            trigger OnValidate()
            begin
                TestReqStatusOpen();
                "Expected Amount (LCY)" := Round("Currency Exchange Rate" * "Expected Amount");
                ApplyAmountDelta("Expected Amount (LCY)" - xRec."Expected Amount (LCY)");
            end;
        }
        field(7; "Currency Exchange Rate"; Decimal)
        {
            Caption = 'Currency Exchange Rate';
            Editable = false;
            DecimalPlaces = 0 : 5;
            InitValue = 1;
            AutoFormatType = 0;
            ToolTip = 'Specifies the most recent exchange rate for the specified currency (1 = pari).';

            trigger OnValidate()
            begin
                TestReqStatusOpen();
                "Expected Amount (LCY)" := Round("Currency Exchange Rate" * "Expected Amount");
                ApplyAmountDelta("Expected Amount (LCY)" - xRec."Expected Amount (LCY)");
            end;
        }
        field(8; "Expected Amount (LCY)"; Decimal)
        {
            Caption = 'Expected Amount (LCY)';
            ToolTip = 'Specifies the expected amount of the spend request detail. Automatically calculated from the Amount field.';
            Editable = false;
            AutoFormatExpression = '';
            AutoFormatType = 1;

            trigger OnValidate()
            begin
                TestReqStatusOpen();
                ApplyAmountDelta("Expected Amount (LCY)" - xRec."Expected Amount (LCY)");
            end;
        }
        field(10; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            ToolTip = 'The G/L Account that the expenses will be posted to.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                TestReqStatusOpen();
            end;
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
            IncludedFields = "Expected Amount (LCY)";
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
        ApplyAmountDelta(-"Expected Amount (LCY)");
    end;

    local procedure ApplyAmountDelta(DeltaLCY: Decimal)
    var
        SpendRequest: Record "Spend Request";
    begin
        if DeltaLCY = 0 then
            exit;

        SpendRequest.Get("Spend Request No.");

        SpendRequest.AddToTotalExpectedAmount(DeltaLCY);
    end;

    local procedure InitHeaderDefaults()
    var
        SpendRequest: Record "Spend Request";
        SpendReqDetail: Record "Spend Request Detail";
    begin
        SpendRequest.Get(Rec."Spend Request No.");
        if Rec."G/L Account No." = '' then
            Rec."G/L Account No." := SpendRequest."G/L Account No.";
        if Rec."Expected Amount (LCY)" = 0 then begin
            SpendReqDetail.SetRange("Spend Request No.", Rec."Spend Request No.");
            SpendReqDetail.CalcSums("Expected Amount (LCY)");
            if SpendReqDetail."Expected Amount (LCY)" < SpendRequest."Total Expected Amount (LCY)" then
                Rec."Expected Amount (LCY)" := SpendRequest."Total Expected Amount (LCY)" - SpendReqDetail."Expected Amount (LCY)";
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

    internal procedure ChangeCurrency(xCurrencyCode: Code[10])
    var
        Currency: Record Currency;
    begin
        if Rec."Currency code" = xCurrencyCode then
            exit;
        if Rec."Currency code" = '' then begin
            Currency.InitRoundingPrecision();
            Rec."Currency Exchange Rate" := 1
        end else begin
            Currency.Get(Rec."Currency Code");
            Rec."Currency Exchange Rate" := Currency.GetExchangeRate(Today());
        end;
        if Rec."Currency Exchange Rate" = 0 then
            Rec."Currency Exchange Rate" := 1;

        "Expected Amount" := Round(Rec."Expected Amount (LCY)" / Rec."Currency Exchange Rate", Currency."Amount Rounding Precision");
    end;

    internal procedure UpdateCurrencyExchangeRate()
    var
        Currency: Record Currency;
    begin
        if Rec."Currency code" = '' then
            Rec."Currency Exchange Rate" := 1
        else begin
            Currency.Get(Rec."Currency Code");
            Rec."Currency Exchange Rate" := Currency.GetExchangeRate(Today());
        end;
        "Expected Amount (LCY)" := Round("Currency Exchange Rate" * "Expected Amount");
    end;
}
