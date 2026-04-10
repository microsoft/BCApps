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

/// <summary>
/// Buffer table for accumulating prepayment invoice line data before posting operations.
/// Stores temporary line information for prepayment invoice creation and G/L posting.
/// </summary>
/// <remarks>
/// Used during prepayment invoice posting to organize and structure line data before creating the final invoice.
/// Supports complex prepayment scenarios including VAT calculations, dimensions, and job-related prepayments.
/// Provides grouping and accumulation capabilities for efficient prepayment invoice line processing.
/// Integrates with sales and purchase prepayment posting workflows for consistent prepayment handling.
/// </remarks>
table 461 "Prepayment Inv. Line Buffer"
{
    Caption = 'Prepayment Inv. Line Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// G/L account number for posting the prepayment invoice line.
        /// </summary>
        field(1; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            DataClassification = SystemMetadata;
            TableRelation = "G/L Account";
        }
        /// <summary>
        /// Line number for ordering and identifying the prepayment invoice line.
        /// </summary>
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Prepayment amount for the invoice line in document currency.
        /// </summary>
        field(3; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Description text for the prepayment invoice line.
        /// </summary>
        field(4; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// General business posting group for VAT and posting determination.
        /// </summary>
        field(5; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Business Posting Group";
        }
        /// <summary>
        /// General product posting group for VAT and posting determination.
        /// </summary>
        field(6; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Product Posting Group";
        }
        /// <summary>
        /// VAT business posting group for VAT calculation.
        /// </summary>
        field(7; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>
        /// VAT product posting group for VAT calculation.
        /// </summary>
        field(8; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Product Posting Group";
        }
        /// <summary>
        /// VAT amount calculated for the prepayment line.
        /// </summary>
        field(9; "VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Amount';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// VAT calculation type used for prepayment line tax calculation.
        /// </summary>
        field(10; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// VAT base amount for prepayment tax calculation.
        /// </summary>
        field(11; "VAT Base Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Base Amount';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Prepayment amount in additional reporting currency.
        /// </summary>
        field(12; "Amount (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Amount (ACY)';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// VAT amount in additional reporting currency.
        /// </summary>
        field(13; "VAT Amount (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'VAT Amount (ACY)';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// VAT base amount in additional reporting currency.
        /// </summary>
        field(14; "VAT Base Amount (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'VAT Base Amount (ACY)';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// VAT difference amount for manual VAT adjustments.
        /// </summary>
        field(15; "VAT Difference"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Difference';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// VAT percentage rate for tax calculation.
        /// </summary>
        field(16; "VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT %';
            DataClassification = SystemMetadata;
            DecimalPlaces = 1 : 1;
        }
        /// <summary>
        /// VAT identifier for grouping VAT entries.
        /// </summary>
        field(17; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        /// <summary>
        /// Global dimension 1 code for analytical reporting.
        /// </summary>
        field(19; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        /// <summary>
        /// Global dimension 2 code for analytical reporting.
        /// </summary>
        field(20; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        /// <summary>
        /// Project number for project-related prepayment tracking.
        /// </summary>
        field(21; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            DataClassification = SystemMetadata;
            TableRelation = Job;
        }
        /// <summary>
        /// Total amount including VAT for the prepayment line.
        /// </summary>
        field(22; "Amount Incl. VAT"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount Incl. VAT';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Tax area code for sales tax calculation.
        /// </summary>
        field(24; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            DataClassification = SystemMetadata;
            TableRelation = "Tax Area";
        }
        /// <summary>
        /// Indicates if the line is subject to sales tax.
        /// </summary>
        field(25; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Tax group code for sales tax calculation.
        /// </summary>
        field(26; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            DataClassification = SystemMetadata;
            TableRelation = "Tax Group";
        }
        /// <summary>
        /// Indicates if this line is for invoice rounding adjustment.
        /// </summary>
        field(27; "Invoice Rounding"; Boolean)
        {
            Caption = 'Invoice Rounding';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Indicates if this line is an adjustment entry.
        /// </summary>
        field(28; Adjustment; Boolean)
        {
            Caption = 'Adjustment';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// VAT base amount before payment discount application.
        /// </summary>
        field(29; "VAT Base Before Pmt. Disc."; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Base Before Pmt. Disc.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Original payment discount amount possible for the prepayment.
        /// </summary>
        field(30; "Orig. Pmt. Disc. Possible"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Original Pmt. Disc. Possible';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Location code for inventory tracking.
        /// </summary>
        field(31; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Dimension set ID for linking to dimension values.
        /// </summary>
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
        /// <summary>
        /// Project task number for project-related prepayment tracking.
        /// </summary>
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

    /// <summary>
    /// Increments amounts in the current record with amounts from another prepayment invoice line buffer.
    /// Adds all financial amounts including VAT, base amounts, and discount amounts.
    /// </summary>
    /// <param name="PrepmtInvLineBuf">Prepayment invoice line buffer with amounts to add</param>
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

    /// <summary>
    /// Reverses all amounts in the current record by changing signs.
    /// Used for creating credit memo entries or reversing prepayment entries.
    /// </summary>
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

    /// <summary>
    /// Sets the financial amounts for the prepayment invoice line buffer.
    /// Updates amount, VAT amounts, and base amounts in both LCY and ACY.
    /// </summary>
    /// <param name="AmountLCY">Amount in local currency</param>
    /// <param name="AmountInclVAT">Amount including VAT</param>
    /// <param name="VATBaseAmount">VAT base amount</param>
    /// <param name="AmountACY">Amount in additional currency</param>
    /// <param name="VATBaseAmountACY">VAT base amount in additional currency</param>
    /// <param name="VATDifference">VAT difference amount</param>
    procedure SetAmounts(AmountLCY: Decimal; AmountInclVAT: Decimal; VATBaseAmount: Decimal; AmountACY: Decimal; VATBaseAmountACY: Decimal; VATDifference: Decimal)
    begin
        Amount := AmountLCY;
        "Amount Incl. VAT" := AmountInclVAT;
        "VAT Base Amount" := VATBaseAmount;
        "Amount (ACY)" := AmountACY;
        "VAT Base Amount (ACY)" := VATBaseAmountACY;
        "VAT Difference" := VATDifference;
    end;

    /// <summary>
    /// Inserts or updates a prepayment invoice line buffer record.
    /// If record exists, increments amounts; otherwise inserts new record.
    /// </summary>
    /// <param name="PrepmtInvLineBuf2">Prepayment invoice line buffer to insert or merge</param>
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

    /// <summary>
    /// Copies a prepayment invoice line buffer record with a new line number.
    /// Creates a new record with the specified line number.
    /// </summary>
    /// <param name="PrepmtInvLineBuf">Source prepayment invoice line buffer to copy</param>
    /// <param name="LineNo">New line number for the copied record</param>
    procedure CopyWithLineNo(PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; LineNo: Integer)
    begin
        Rec := PrepmtInvLineBuf;
        "Line No." := LineNo;
        Insert();
    end;

    /// <summary>
    /// Copies posting group information from a purchase line to the prepayment buffer.
    /// Transfers VAT and posting group settings for prepayment processing.
    /// </summary>
    /// <param name="PurchLine">Purchase line to copy posting groups from</param>
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

    /// <summary>
    /// Copies posting group information from a sales line to the prepayment buffer.
    /// Transfers VAT and posting group settings for prepayment processing.
    /// </summary>
    /// <param name="SalesLine">Sales line to copy posting groups from</param>
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

    /// <summary>
    /// Sets filters on the primary key fields of the prepayment invoice line buffer.
    /// Used for finding existing records with matching key values.
    /// </summary>
    /// <param name="PrepmtInvLineBuf">Prepayment invoice line buffer with key values to filter by</param>
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

    /// <summary>
    /// Fills the buffer with adjustment invoice line data for amount corrections.
    /// Creates adjustment entries for prepayment amount differences.
    /// </summary>
    /// <param name="PrepmtInvLineBuf">Source prepayment invoice line buffer</param>
    /// <param name="GLAccountNo">G/L account number for the adjustment</param>
    /// <param name="CorrAmount">Correction amount in local currency</param>
    /// <param name="CorrAmountACY">Correction amount in additional currency</param>
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

    /// <summary>
    /// Fills the buffer with G/L account information for prepayment processing.
    /// Copies posting group information from the specified G/L account.
    /// </summary>
    /// <param name="CompressPrepayment">Whether to use compressed description from G/L account name</param>
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

    /// <summary>
    /// Adjusts VAT base amount and VAT amount based on provided adjustment values.
    /// Recalculates amount including VAT after adjustments.
    /// </summary>
    /// <param name="VATAdjustment">Array containing base amount and VAT amount adjustments</param>
    procedure AdjustVATBase(VATAdjustment: array[2] of Decimal)
    begin
        if Amount <> "Amount Incl. VAT" then begin
            Amount := Amount + VATAdjustment[1];
            "VAT Base Amount" := Amount;
            "VAT Amount" := "VAT Amount" + VATAdjustment[2];
            "Amount Incl. VAT" := Amount + "VAT Amount";
        end;
    end;

    /// <summary>
    /// Converts buffer amounts to an array format for processing.
    /// Returns base amount and VAT amount in array elements.
    /// </summary>
    /// <param name="VATAmount">Array to receive amount and VAT amount values</param>
    procedure AmountsToArray(var VATAmount: array[2] of Decimal)
    begin
        VATAmount[1] := Amount;
        VATAmount[2] := "Amount Incl. VAT" - Amount;
    end;

    /// <summary>
    /// Compresses multiple buffer lines with same key into consolidated entries.
    /// Combines amounts for lines with identical posting group and dimension combinations.
    /// </summary>
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

    /// <summary>
    /// Updates VAT amounts based on VAT posting setup and calculated percentages.
    /// Recalculates VAT amount in both local and additional reporting currency.
    /// </summary>
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

    /// <summary>
    /// Integration event raised after copying data from a purchase line.
    /// Allows customization of purchase line data transfer to prepayment buffer.
    /// </summary>
    /// <param name="PrepaymentInvLineBuffer">Prepayment invoice line buffer being updated</param>
    /// <param name="PurchaseLine">Source purchase line</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromPurchLine(var PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    /// <summary>
    /// Integration event raised after copying data from a sales line.
    /// Allows customization of sales line data transfer to prepayment buffer.
    /// </summary>
    /// <param name="PrepaymentInvLineBuffer">Prepayment invoice line buffer being updated</param>
    /// <param name="SalesLine">Source sales line</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromSalesLine(var PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; SalesLine: Record "Sales Line")
    begin
    end;

    /// <summary>
    /// Integration event raised after incrementing amounts in the buffer.
    /// Allows custom amount processing during buffer consolidation.
    /// </summary>
    /// <param name="PrepaymentInvLineBuffer">Target prepayment invoice line buffer</param>
    /// <param name="PrepmtInvLineBuf">Source prepayment invoice line buffer with amounts to add</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterIncrAmounts(var PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer")
    begin
    end;

    /// <summary>
    /// Integration event raised after filling buffer from G/L account.
    /// Allows customization of G/L account data transfer to prepayment buffer.
    /// </summary>
    /// <param name="PrepaymentInvLineBuffer">Prepayment invoice line buffer being updated</param>
    /// <param name="GLAccount">Source G/L account</param>
    /// <param name="CompressPayment">Whether compression is enabled</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterFillFromGLAcc(var PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; GLAccount: Record "G/L Account"; CompressPayment: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after filling adjustment invoice line buffer.
    /// Allows customization of adjustment line processing.
    /// </summary>
    /// <param name="PrepaymentInvLineBuffer">Source prepayment invoice line buffer</param>
    /// <param name="PrepaymentInvLineBufferRec">Target adjustment line buffer</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterFillAdjInvLineBuffer(PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; var PrepaymentInvLineBufferRec: Record "Prepayment Inv. Line Buffer")
    begin
    end;

    /// <summary>
    /// Integration event raised after reversing amounts in the buffer.
    /// Allows custom processing after amount reversal operations.
    /// </summary>
    [IntegrationEvent(true, false)]
    local procedure OnAfterReverseAmounts()
    begin
    end;

    /// <summary>
    /// Integration event raised before compressing the buffer.
    /// Allows custom buffer compression logic or skipping standard compression.
    /// </summary>
    /// <param name="PrepaymentInvLineBuffer">Prepayment invoice line buffer to compress</param>
    /// <param name="IsHandled">Set to true to skip standard compression</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCompressBuffer(var PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before filling buffer from G/L account.
    /// Allows custom G/L account processing or skipping standard fill logic.
    /// </summary>
    /// <param name="PrepaymentInvLineBuffer">Prepayment invoice line buffer to fill</param>
    /// <param name="IsHandled">Set to true to skip standard fill processing</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeFillFromGLAcc(var PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after updating VAT amounts.
    /// Allows custom VAT amount processing after standard calculations.
    /// </summary>
    /// <param name="PrepaymentInvLineBuffer">Prepayment invoice line buffer with updated VAT amounts</param>
    /// <param name="Currency">Currency record used for calculations</param>
    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateVATAmounts(var PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; Currency: Record Currency)
    begin
    end;
}
