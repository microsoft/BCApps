// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

table 461 "Prepayment Inv. Line Buffer"
{
    Caption = 'Prepayment Inv. Line Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            DataClassification = SystemMetadata;
            TableRelation = "G/L Account";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        field(3; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(5; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Business Posting Group";
        }
        field(6; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Product Posting Group";
        }
        field(7; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Business Posting Group";
        }
        field(8; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Product Posting Group";
        }
        field(9; "VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Amount';
            DataClassification = SystemMetadata;
        }
        field(10; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            DataClassification = SystemMetadata;
        }
        field(11; "VAT Base Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Base Amount';
            DataClassification = SystemMetadata;
        }
        field(12; "Amount (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Amount (ACY)';
            DataClassification = SystemMetadata;
        }
        field(13; "VAT Amount (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'VAT Amount (ACY)';
            DataClassification = SystemMetadata;
        }
        field(14; "VAT Base Amount (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'VAT Base Amount (ACY)';
            DataClassification = SystemMetadata;
        }
        field(15; "VAT Difference"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Difference';
            DataClassification = SystemMetadata;
        }
        field(16; "VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT %';
            DataClassification = SystemMetadata;
            DecimalPlaces = 1 : 1;
        }
        field(17; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(19; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(20; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(21; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            DataClassification = SystemMetadata;
            TableRelation = Job;
        }
        field(22; "Amount Incl. VAT"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount Incl. VAT';
            DataClassification = SystemMetadata;
        }
        field(24; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            DataClassification = SystemMetadata;
            TableRelation = "Tax Area";
        }
        field(25; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            DataClassification = SystemMetadata;
        }
        field(26; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            DataClassification = SystemMetadata;
            TableRelation = "Tax Group";
        }
        field(27; "Invoice Rounding"; Boolean)
        {
            Caption = 'Invoice Rounding';
            DataClassification = SystemMetadata;
        }
        field(28; Adjustment; Boolean)
        {
            Caption = 'Adjustment';
            DataClassification = SystemMetadata;
        }
        field(29; "VAT Base Before Pmt. Disc."; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Base Before Pmt. Disc.';
            DataClassification = SystemMetadata;
        }
        field(30; "Orig. Pmt. Disc. Possible"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Original Pmt. Disc. Possible';
            DataClassification = SystemMetadata;
        }
        field(31; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = SystemMetadata;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
        field(1001; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            DataClassification = SystemMetadata;
            TableRelation = "Job Task";
        }
    }

    keys
    {
        key(Key1; "G/L Account No.", "Job No.", "Tax Area Code", "Tax Liable", "Tax Group Code", "Invoice Rounding", Adjustment, "Line No.", "Dimension Set ID")
        {
            Clustered = true;
        }
        key(Key2; Adjustment)
        {
        }
    }

    fieldgroups
    {
    }

    protected var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralLedgerSetupRead: Boolean;

    local procedure GetAdditionalReportingCurrencyCode(): Code[10]
    begin
        if not GeneralLedgerSetupRead then begin
            GeneralLedgerSetup.Get();
            GeneralLedgerSetupRead := true;
        end;
        exit(GeneralLedgerSetup."Additional Reporting Currency")
    end;

    procedure IncrAmounts(PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer")
    begin
        Amount := Amount + PrepmtInvLineBuf.Amount;
        "Amount Incl. VAT" := "Amount Incl. VAT" + PrepmtInvLineBuf."Amount Incl. VAT";
        "VAT Amount" := "VAT Amount" + PrepmtInvLineBuf."VAT Amount";
        "VAT Base Amount" := "VAT Base Amount" + PrepmtInvLineBuf."VAT Base Amount";
        "Amount (ACY)" := "Amount (ACY)" + PrepmtInvLineBuf."Amount (ACY)";
        "VAT Amount (ACY)" := "VAT Amount (ACY)" + PrepmtInvLineBuf."VAT Amount (ACY)";
        "VAT Base Amount (ACY)" := "VAT Base Amount (ACY)" + PrepmtInvLineBuf."VAT Base Amount (ACY)";
        "VAT Difference" := "VAT Difference" + PrepmtInvLineBuf."VAT Difference";
        "Orig. Pmt. Disc. Possible" := "Orig. Pmt. Disc. Possible" + PrepmtInvLineBuf."Orig. Pmt. Disc. Possible";
        OnAfterIncrAmounts(Rec, PrepmtInvLineBuf);
    end;

    procedure ReverseAmounts()
    begin
        Amount := -Amount;
        "Amount Incl. VAT" := -"Amount Incl. VAT";
        "VAT Amount" := -"VAT Amount";
        "VAT Base Amount" := -"VAT Base Amount";
        "Amount (ACY)" := -"Amount (ACY)";
        "VAT Amount (ACY)" := -"VAT Amount (ACY)";
        "VAT Base Amount (ACY)" := -"VAT Base Amount (ACY)";
        "VAT Difference" := -"VAT Difference";
        "Orig. Pmt. Disc. Possible" := -"Orig. Pmt. Disc. Possible";
        OnAfterReverseAmounts()
    end;

    procedure SetAmounts(AmountLCY: Decimal; AmountInclVAT: Decimal; VATBaseAmount: Decimal; AmountACY: Decimal; VATBaseAmountACY: Decimal; VATDifference: Decimal)
    begin
        Amount := AmountLCY;
        "Amount Incl. VAT" := AmountInclVAT;
        "VAT Base Amount" := VATBaseAmount;
        "Amount (ACY)" := AmountACY;
        "VAT Base Amount (ACY)" := VATBaseAmountACY;
        "VAT Difference" := VATDifference;
    end;

    procedure InsertInvLineBuffer(PrepmtInvLineBuf2: Record "Prepayment Inv. Line Buffer")
    begin
        Rec := PrepmtInvLineBuf2;
        if Get(
               "G/L Account No.", "Job No.", "Tax Area Code", "Tax Liable", "Tax Group Code",
               "Invoice Rounding", Adjustment, "Line No.", "Dimension Set ID")
        then begin
            IncrAmounts(PrepmtInvLineBuf2);
            Modify();
        end else
            Insert();
    end;

    procedure CopyWithLineNo(PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; LineNo: Integer)
    begin
        Rec := PrepmtInvLineBuf;
        "Line No." := LineNo;
        Insert();
    end;

    procedure CopyFromPurchLine(PurchLine: Record "Purchase Line")
    begin
        "Gen. Prod. Posting Group" := PurchLine."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := PurchLine."VAT Prod. Posting Group";
        "Gen. Bus. Posting Group" := PurchLine."Gen. Bus. Posting Group";
        "VAT Bus. Posting Group" := PurchLine."VAT Bus. Posting Group";
        "VAT Calculation Type" := PurchLine."Prepmt. VAT Calc. Type";
        "VAT Identifier" := PurchLine."Prepayment VAT Identifier";
        "VAT %" := PurchLine."Prepayment VAT %";
        "Global Dimension 1 Code" := PurchLine."Shortcut Dimension 1 Code";
        "Global Dimension 2 Code" := PurchLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := PurchLine."Dimension Set ID";
        "Job No." := PurchLine."Job No.";
        "Job Task No." := PurchLine."Job Task No.";
        "Tax Area Code" := PurchLine."Tax Area Code";
        "Tax Liable" := PurchLine."Tax Liable";
        "Tax Group Code" := PurchLine."Tax Group Code";
        OnAfterCopyFromPurchLine(Rec, PurchLine);
    end;

    procedure CopyFromSalesLine(SalesLine: Record "Sales Line")
    begin
        "Gen. Prod. Posting Group" := SalesLine."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := SalesLine."VAT Prod. Posting Group";
        "Gen. Bus. Posting Group" := SalesLine."Gen. Bus. Posting Group";
        "VAT Bus. Posting Group" := SalesLine."VAT Bus. Posting Group";
        "VAT Calculation Type" := SalesLine."Prepmt. VAT Calc. Type";
        "VAT Identifier" := SalesLine."Prepayment VAT Identifier";
        "VAT %" := SalesLine."Prepayment VAT %";
        "Global Dimension 1 Code" := SalesLine."Shortcut Dimension 1 Code";
        "Global Dimension 2 Code" := SalesLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := SalesLine."Dimension Set ID";
        "Job No." := SalesLine."Job No.";
        "Job Task No." := SalesLine."Job Task No.";
        "Tax Area Code" := SalesLine."Tax Area Code";
        "Tax Liable" := SalesLine."Tax Liable";
        "Tax Group Code" := SalesLine."Tax Group Code";
        OnAfterCopyFromSalesLine(Rec, SalesLine);
    end;

    procedure SetFilterOnPKey(PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer")
    begin
        Reset();
        SetRange("G/L Account No.", PrepmtInvLineBuf."G/L Account No.");
        SetRange("Dimension Set ID", PrepmtInvLineBuf."Dimension Set ID");
        SetRange("Job No.", PrepmtInvLineBuf."Job No.");
        SetRange("Tax Area Code", PrepmtInvLineBuf."Tax Area Code");
        SetRange("Tax Liable", PrepmtInvLineBuf."Tax Liable");
        SetRange("Tax Group Code", PrepmtInvLineBuf."Tax Group Code");
        SetRange("Invoice Rounding", PrepmtInvLineBuf."Invoice Rounding");
        SetRange(Adjustment, PrepmtInvLineBuf.Adjustment);
        if PrepmtInvLineBuf."Line No." <> 0 then
            SetRange("Line No.", PrepmtInvLineBuf."Line No.");
    end;

    procedure FillAdjInvLineBuffer(PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; GLAccountNo: Code[20]; CorrAmount: Decimal; CorrAmountACY: Decimal)
    begin
        Init();
        Adjustment := true;
        "G/L Account No." := GLAccountNo;
        Amount := CorrAmount;
        "Amount Incl. VAT" := CorrAmount;
        "Amount (ACY)" := CorrAmountACY;
        "Line No." := PrepmtInvLineBuf."Line No.";
        "Global Dimension 1 Code" := PrepmtInvLineBuf."Global Dimension 1 Code";
        "Global Dimension 2 Code" := PrepmtInvLineBuf."Global Dimension 2 Code";
        "Dimension Set ID" := PrepmtInvLineBuf."Dimension Set ID";
        Description := PrepmtInvLineBuf.Description;

        OnAfterFillAdjInvLineBuffer(PrepmtInvLineBuf, Rec);
    end;

    procedure FillFromGLAcc(CompressPrepayment: Boolean)
    var
        GLAcc: Record "G/L Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFillFromGLAcc(Rec, IsHandled);
        if IsHandled then
            exit;

        GLAcc.Get("G/L Account No.");
        "Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
        if CompressPrepayment then
            Description := GLAcc.Name;

        OnAfterFillFromGLAcc(Rec, GLAcc, CompressPrepayment);
    end;

    procedure AdjustVATBase(VATAdjustment: array[2] of Decimal)
    begin
        if Amount <> "Amount Incl. VAT" then begin
            Amount := Amount + VATAdjustment[1];
            "VAT Base Amount" := Amount;
            "VAT Amount" := "VAT Amount" + VATAdjustment[2];
            "Amount Incl. VAT" := Amount + "VAT Amount";
        end;
    end;

    procedure AmountsToArray(var VATAmount: array[2] of Decimal)
    begin
        VATAmount[1] := Amount;
        VATAmount[2] := "Amount Incl. VAT" - Amount;
    end;

    procedure CompressBuffer()
    var
        TempPrepmtInvLineBuffer2: Record "Prepayment Inv. Line Buffer" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCompressBuffer(Rec, IsHandled);
        if IsHandled then
            exit;

        Find('-');
        repeat
            TempPrepmtInvLineBuffer2 := Rec;
            TempPrepmtInvLineBuffer2."Line No." := 0;
            if TempPrepmtInvLineBuffer2.Find() then begin
                TempPrepmtInvLineBuffer2.IncrAmounts(Rec);
                TempPrepmtInvLineBuffer2.Modify();
            end else
                TempPrepmtInvLineBuffer2.Insert();
        until Next() = 0;

        DeleteAll();

        TempPrepmtInvLineBuffer2.Find('-');
        repeat
            Rec := TempPrepmtInvLineBuffer2;
            Insert();
        until TempPrepmtInvLineBuffer2.Next() = 0;
    end;

    procedure UpdateVATAmounts()
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        GLSetup.Get();
        Currency.Initialize(GLSetup."Additional Reporting Currency");
        VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group");
        "VAT Amount" := Round(Amount * VATPostingSetup."VAT %" / 100);
        "VAT Amount (ACY)" := Round("Amount (ACY)" * VATPostingSetup."VAT %" / 100, Currency."Amount Rounding Precision");
        OnAfterUpdateVATAmounts(Rec, Currency);
    end;

    internal procedure GetVATPct() VATPct: Decimal
    begin
        VATPct := "VAT %";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromPurchLine(var PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromSalesLine(var PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIncrAmounts(var PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillFromGLAcc(var PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; GLAccount: Record "G/L Account"; CompressPayment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillAdjInvLineBuffer(PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; var PrepaymentInvLineBufferRec: Record "Prepayment Inv. Line Buffer")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterReverseAmounts()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCompressBuffer(var PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeFillFromGLAcc(var PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateVATAmounts(var PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; Currency: Record Currency)
    begin
    end;
}
