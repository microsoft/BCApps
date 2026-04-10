// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Posting;
using Microsoft.Foundation.Enums;
using Microsoft.Projects.Project.Job;

/// <summary>
/// Temporary buffer table for accumulating and organizing invoice posting entries before G/L posting.
/// Groups posting entries by account, dimensions, and posting characteristics for efficient batch processing.
/// </summary>
/// <remarks>
/// Central accumulation mechanism for invoice posting operations across sales, purchase, and service modules.
/// Supports complex posting scenarios including VAT, deferrals, fixed assets, and job-related postings.
/// Provides grouping and summarization capabilities to optimize G/L entry creation during document posting.
/// Extensible design supports custom posting logic through the invoice posting interface framework.
/// </remarks>
table 55 "Invoice Posting Buffer"
{
    Caption = 'Invoice Posting Buffer';
    ReplicateData = false;
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Primary key grouping identifier for consolidating similar posting entries.
        /// </summary>
        field(1; "Group ID"; Text[1000])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Type of posting line indicating the specific posting purpose and characteristics.
        /// </summary>
        field(2; Type; Enum "Invoice Posting Line Type")
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// G/L account number for posting the accumulated amounts.
        /// </summary>
        field(3; "G/L Account"; Code[20])
        {
            Caption = 'G/L Account';
            DataClassification = SystemMetadata;
            TableRelation = "G/L Account";
        }
        /// <summary>
        /// Global dimension 1 code for the posting entry.
        /// </summary>
        field(4; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        /// <summary>
        /// Global dimension 2 code for cost center or department classification.
        /// </summary>
        field(5; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        /// <summary>
        /// Project number for project-related invoice postings.
        /// </summary>
        field(6; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            DataClassification = SystemMetadata;
            TableRelation = Job;
        }
        /// <summary>
        /// Net amount for the invoice posting entry in local currency.
        /// </summary>
        field(7; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// VAT amount calculated for this invoice posting entry.
        /// </summary>
        field(8; "VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Amount';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// General business posting group for determining G/L accounts and setup.
        /// </summary>
        field(10; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Business Posting Group";
        }
        /// <summary>
        /// General product posting group for determining G/L accounts and setup.
        /// </summary>
        field(11; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Product Posting Group";
        }
        /// <summary>
        /// VAT calculation type determining how VAT is calculated for this entry.
        /// </summary>
        field(12; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// VAT base amount for calculating VAT on this entry.
        /// </summary>
        field(14; "VAT Base Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Base Amount';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Indicates whether this entry was created automatically by the system.
        /// </summary>
        field(17; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Tax area code for sales tax calculation and reporting.
        /// </summary>
        field(18; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            DataClassification = SystemMetadata;
            TableRelation = "Tax Area";
        }
        /// <summary>
        /// Indicates whether this entry is subject to sales tax.
        /// </summary>
        field(19; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Tax group code for categorizing items for sales tax calculation.
        /// </summary>
        field(20; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            DataClassification = SystemMetadata;
            TableRelation = "Tax Group";
        }
        /// <summary>
        /// Quantity of items or services for this posting entry.
        /// </summary>
        field(21; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            DataClassification = SystemMetadata;
            DecimalPlaces = 1 : 5;
        }
        /// <summary>
        /// Indicates whether use tax applies to this entry.
        /// </summary>
        field(22; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// VAT business posting group for determining VAT rates and accounts.
        /// </summary>
        field(23; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>
        /// VAT product posting group for determining VAT rates and accounts.
        /// </summary>
        field(24; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Product Posting Group";
        }
        /// <summary>
        /// Amount in additional reporting currency (ACY).
        /// </summary>
        field(25; "Amount (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Amount (ACY)';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// VAT amount in additional reporting currency (ACY).
        /// </summary>
        field(26; "VAT Amount (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'VAT Amount (ACY)';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// VAT base amount in additional reporting currency (ACY).
        /// </summary>
        field(29; "VAT Base Amount (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'VAT Base Amount (ACY)';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// VAT difference amount for manual VAT adjustments.
        /// </summary>
        field(31; "VAT Difference"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Difference';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// VAT percentage rate used for this posting entry.
        /// </summary>
        field(32; "VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT %';
            DataClassification = SystemMetadata;
            DecimalPlaces = 1 : 1;
        }
        /// <summary>
        /// VAT base amount before payment discount calculation.
        /// </summary>
        field(35; "VAT Base Before Pmt. Disc."; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Base Before Pmt. Disc.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Journal template name for the posting operation.
        /// </summary>
        field(40; "Journal Templ. Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Description text for the posting entry.
        /// </summary>
        field(215; "Entry Description"; Text[100])
        {
            Caption = 'Entry Description';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Dimension set ID linking to dimension values for this posting entry.
        /// </summary>
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
        /// <summary>
        /// Additional identifier for grouping entries with same characteristics.
        /// </summary>
        field(1000; "Additional Grouping Identifier"; Code[20])
        {
            Caption = 'Additional Grouping Identifier';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Deferral code for revenue or expense recognition scheduling.
        /// </summary>
        field(1700; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            DataClassification = SystemMetadata;
            TableRelation = "Deferral Template"."Deferral Code";
        }
        /// <summary>
        /// Line number for deferral schedule entries.
        /// </summary>
        field(1701; "Deferral Line No."; Integer)
        {
            Caption = 'Deferral Line No.';
            DataClassification = SystemMetadata;
        }
        field(5600; "FA Posting Date"; Date)
        {
            Caption = 'FA Posting Date';
            DataClassification = SystemMetadata;
        }
        field(5601; "FA Posting Type"; Enum "Purchase FA Posting Type")
        {
            Caption = 'FA Posting Type';
            DataClassification = SystemMetadata;
        }
        field(5602; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            DataClassification = SystemMetadata;
            TableRelation = "Depreciation Book";
        }
        field(5603; "Salvage Value"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Salvage Value';
            DataClassification = SystemMetadata;
        }
        field(5605; "Depr. until FA Posting Date"; Boolean)
        {
            Caption = 'Depr. until FA Posting Date';
            DataClassification = SystemMetadata;
        }
        field(5606; "Depr. Acquisition Cost"; Boolean)
        {
            Caption = 'Depr. Acquisition Cost';
            DataClassification = SystemMetadata;
        }
        field(5609; "Maintenance Code"; Code[10])
        {
            Caption = 'Maintenance Code';
            DataClassification = SystemMetadata;
            TableRelation = Maintenance;
        }
        field(5610; "Insurance No."; Code[20])
        {
            Caption = 'Insurance No.';
            DataClassification = SystemMetadata;
            TableRelation = Insurance;
        }
        field(5611; "Budgeted FA No."; Code[20])
        {
            Caption = 'Budgeted FA No.';
            DataClassification = SystemMetadata;
            TableRelation = "Fixed Asset";
        }
        field(5612; "Duplicate in Depreciation Book"; Code[10])
        {
            Caption = 'Duplicate in Depreciation Book';
            DataClassification = SystemMetadata;
            TableRelation = "Depreciation Book";
        }
        field(5613; "Use Duplication List"; Boolean)
        {
            Caption = 'Use Duplication List';
            DataClassification = SystemMetadata;
        }
        field(5614; "Fixed Asset Line No."; Integer)
        {
            Caption = 'Fixed Asset Line No.';
            DataClassification = SystemMetadata;
        }
        field(6200; "Non-Deductible VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Non-Deductible VAT %';
            DecimalPlaces = 0 : 5;
            DataClassification = SystemMetadata;
        }
        field(6201; "Non-Deductible VAT Base"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Non-Deductible VAT Base';
            DataClassification = SystemMetadata;
        }
        field(6202; "Non-Deductible VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Non-Deductible VAT Amount';
            DataClassification = SystemMetadata;
        }
        field(6203; "Non-Deductible VAT Base ACY"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Base ACY';
            DataClassification = SystemMetadata;
        }
        field(6204; "Non-Deductible VAT Amount ACY"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Amount ACY';
            DataClassification = SystemMetadata;
        }
        field(6205; "Non-Deductible VAT Diff."; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Non-Deductible VAT Difference';
            Editable = false;
        }
        field(12102; "No. of Fixed Asset Cards"; Integer)
        {
            BlankZero = true;
            Caption = 'No. of Fixed Asset Cards';
            DataClassification = SystemMetadata;
            MinValue = 0;
        }
    }

    keys
    {
        key(key1; "Group ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        TempInvoicePostingBufferRounding: Record "Invoice Posting Buffer" temporary;
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";

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
    /// Calculates and applies discount amounts to the invoice posting buffer.
    /// </summary>
    /// <param name="PricesInclVAT">Whether prices include VAT</param>
    /// <param name="DiscountAmount">Discount amount in LCY</param>
    /// <param name="DiscountAmountACY">Discount amount in additional currency</param>
    procedure CalcDiscount(PricesInclVAT: Boolean; DiscountAmount: Decimal; DiscountAmountACY: Decimal)
    var
        CurrencyLCY: Record Currency;
        CurrencyACY: Record Currency;
        GLSetup: Record "General Ledger Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcDiscount(Rec, IsHandled);
        if IsHandled then
            exit;

        CurrencyLCY.InitRoundingPrecision();
        GLSetup.Get();
        if GLSetup."Additional Reporting Currency" <> '' then
            CurrencyACY.Get(GLSetup."Additional Reporting Currency")
        else
            CurrencyACY := CurrencyLCY;
        "VAT Amount" := Round(
            CalcVATAmount(PricesInclVAT, DiscountAmount, "VAT %"),
            CurrencyLCY."Amount Rounding Precision",
            CurrencyLCY.VATRoundingDirection());
        "VAT Amount (ACY)" := Round(
            CalcVATAmount(PricesInclVAT, DiscountAmountACY, "VAT %"),
            CurrencyACY."Amount Rounding Precision",
            CurrencyACY.VATRoundingDirection());

        OnCalcDiscountOnAfterUpdateVATAmount(Rec, PricesInclVAT, DiscountAmount, DiscountAmountACY);

        if PricesInclVAT and ("VAT %" <> 0) then begin
            "VAT Base Amount" := DiscountAmount - "VAT Amount";
            "VAT Base Amount (ACY)" := DiscountAmountACY - "VAT Amount (ACY)";
        end else begin
            "VAT Base Amount" := DiscountAmount;
            "VAT Base Amount (ACY)" := DiscountAmountACY;
        end;
        Amount := "VAT Base Amount";
        "Amount (ACY)" := "VAT Base Amount (ACY)";
        "VAT Base Before Pmt. Disc." := "VAT Base Amount";
        NonDeductibleVAT.Calculate(Rec);
    end;

    local procedure CalcVATAmount(ValueInclVAT: Boolean; Value: Decimal; VATPercent: Decimal): Decimal
    begin
        if VATPercent = 0 then
            exit(0);
        if ValueInclVAT then
            exit(Value / (1 + (VATPercent / 100)) * (VATPercent / 100));

        exit(Value * (VATPercent / 100));
    end;

    /// <summary>
    /// Sets the G/L account and updates total amounts for posting buffer entry.
    /// </summary>
    /// <param name="AccountNo">G/L account number to set</param>
    /// <param name="TotalVAT">Total VAT amount to update</param>
    /// <param name="TotalVATACY">Total VAT amount in ACY to update</param>
    /// <param name="TotalAmount">Total amount to update</param>
    /// <param name="TotalAmountACY">Total amount in ACY to update</param>
    procedure SetAccount(AccountNo: Code[20]; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal)
    begin
        TotalVAT := TotalVAT - "VAT Amount";
        TotalVATACY := TotalVATACY - "VAT Amount (ACY)";
        TotalAmount := TotalAmount - Amount;
        TotalAmountACY := TotalAmountACY - "Amount (ACY)";
        "G/L Account" := AccountNo;
        OnAfterSetAccount(Rec, "G/L Account");
    end;

    /// <summary>
    /// Sets all amount fields in the invoice posting buffer from total calculations.
    /// </summary>
    /// <param name="TotalVAT">Total VAT amount</param>
    /// <param name="TotalVATACY">Total VAT amount in ACY</param>
    /// <param name="TotalAmount">Total amount</param>
    /// <param name="TotalAmountACY">Total amount in ACY</param>
    /// <param name="VATDifference">VAT difference amount</param>
    /// <param name="TotalVATBase">Total VAT base amount</param>
    /// <param name="TotalVATBaseACY">Total VAT base amount in ACY</param>
    procedure SetAmounts(TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; VATDifference: Decimal; TotalVATBase: Decimal; TotalVATBaseACY: Decimal)
    begin
        Amount := TotalAmount;
        "VAT Base Amount" := TotalVATBase;
        "VAT Amount" := TotalVAT;
        "Amount (ACY)" := TotalAmountACY;
        "VAT Base Amount (ACY)" := TotalVATBaseACY;
        "VAT Amount (ACY)" := TotalVATACY;
        "VAT Difference" := VATDifference;
        "VAT Base Before Pmt. Disc." := TotalAmount;
    end;


    procedure CalcDiscountNoVAT(DiscountAmount: Decimal; DiscountAmountACY: Decimal)
    var
        IsHandled: boolean;
    begin
        IsHandled := false;
        OnBeforeCalcDiscountNoVAT(Rec, IsHandled);
        if IsHandled then
            exit;

        "VAT Base Amount" := DiscountAmount;
        "VAT Base Amount (ACY)" := DiscountAmountACY;
        Amount := "VAT Base Amount";
        "Amount (ACY)" := "VAT Base Amount (ACY)";
        "VAT Base Before Pmt. Disc." := "VAT Base Amount";
    end;



    procedure ReverseAmounts()
    begin
        Amount := -Amount;
        "VAT Base Amount" := -"VAT Base Amount";
        "Amount (ACY)" := -"Amount (ACY)";
        "VAT Base Amount (ACY)" := -"VAT Base Amount (ACY)";
        "VAT Amount" := -"VAT Amount";
        "VAT Amount (ACY)" := -"VAT Amount (ACY)";
        NonDeductibleVAT.Reverse(Rec);
        OnAfterReverseAmounts(Rec);
    end;

    procedure SetAmountsNoVAT(TotalAmount: Decimal; TotalAmountACY: Decimal; VATDifference: Decimal)
    begin
        Amount := TotalAmount;
        "VAT Base Amount" := TotalAmount;
        "VAT Amount" := 0;
        "Amount (ACY)" := TotalAmountACY;
        "VAT Base Amount (ACY)" := TotalAmountACY;
        "VAT Amount (ACY)" := 0;
        "VAT Difference" := VATDifference;
    end;


    procedure PreparePrepmtAdjBuffer(InvoicePostingBuffer: Record "Invoice Posting Buffer"; GLAccountNo: Code[20]; AdjAmount: Decimal; RoundingEntry: Boolean)
    var
        PrepmtAdjInvoicePostingBuffer: Record "Invoice Posting Buffer";
    begin
        PrepmtAdjInvoicePostingBuffer.Init();
        PrepmtAdjInvoicePostingBuffer.Type := Type::"Prepmt. Exch. Rate Difference";
        PrepmtAdjInvoicePostingBuffer."G/L Account" := GLAccountNo;
        PrepmtAdjInvoicePostingBuffer.Amount := AdjAmount;
        if RoundingEntry then
            PrepmtAdjInvoicePostingBuffer."Amount (ACY)" := AdjAmount
        else
            PrepmtAdjInvoicePostingBuffer."Amount (ACY)" := 0;
        PrepmtAdjInvoicePostingBuffer."Dimension Set ID" := InvoicePostingBuffer."Dimension Set ID";
        PrepmtAdjInvoicePostingBuffer."Global Dimension 1 Code" := InvoicePostingBuffer."Global Dimension 1 Code";
        PrepmtAdjInvoicePostingBuffer."Global Dimension 2 Code" := InvoicePostingBuffer."Global Dimension 2 Code";
        PrepmtAdjInvoicePostingBuffer."Journal Templ. Name" := InvoicePostingBuffer."Journal Templ. Name";
        PrepmtAdjInvoicePostingBuffer."System-Created Entry" := true;
        PrepmtAdjInvoicePostingBuffer."Entry Description" := InvoicePostingBuffer."Entry Description";
        OnFillPrepmtAdjBufferOnBeforeAssignInvoicePostingBuffer(PrepmtAdjInvoicePostingBuffer, InvoicePostingBuffer);
        InvoicePostingBuffer := PrepmtAdjInvoicePostingBuffer;
        InvoicePostingBuffer.BuildPrimaryKey();

        Rec := InvoicePostingBuffer;
        if Rec.Find() then begin
            Rec.Amount += InvoicePostingBuffer.Amount;
            Rec."Amount (ACY)" += InvoicePostingBuffer."Amount (ACY)";
            Rec.Modify();
        end else begin
            Rec := InvoicePostingBuffer;
            Rec.Insert();
        end;
    end;

    procedure Update(InvoicePostingBuffer: Record "Invoice Posting Buffer")
    var
        InvDefLineNo: Integer;
        DeferralLineNo: Integer;
    begin
        Update(InvoicePostingBuffer, InvDefLineNo, DeferralLineNo);
    end;

    procedure Update(InvoicePostingBuffer: Record "Invoice Posting Buffer"; var InvDefLineNo: Integer; var DeferralLineNo: Integer)
    begin
        InvoicePostingBuffer.BuildPrimaryKey();

        OnBeforeUpdate(Rec, InvoicePostingBuffer);

        Rec := InvoicePostingBuffer;
        if Find() then begin
            Amount += InvoicePostingBuffer.Amount;
            "VAT Amount" += InvoicePostingBuffer."VAT Amount";
            "VAT Base Amount" += InvoicePostingBuffer."VAT Base Amount";
            "Amount (ACY)" += InvoicePostingBuffer."Amount (ACY)";
            "VAT Amount (ACY)" += InvoicePostingBuffer."VAT Amount (ACY)";
            "VAT Difference" += InvoicePostingBuffer."VAT Difference";
            "VAT Base Amount (ACY)" += InvoicePostingBuffer."VAT Base Amount (ACY)";
            NonDeductibleVAT.Increment(Rec, InvoicePostingBuffer);
            Quantity += InvoicePostingBuffer.Quantity;
            "VAT Base Before Pmt. Disc." += InvoicePostingBuffer."VAT Base Before Pmt. Disc.";
            if not InvoicePostingBuffer."System-Created Entry" then
                "System-Created Entry" := false;
            if "Deferral Code" = '' then
                AdjustRoundingForUpdate();
            OnUpdateOnBeforeModify(Rec, InvoicePostingBuffer);
            Modify();
            OnUpdateOnAfterModify(Rec, InvoicePostingBuffer);
            InvDefLineNo := "Deferral Line No.";
        end else begin
            if "Deferral Code" <> '' then begin
                DeferralLineNo := DeferralLineNo + 1;
                "Deferral Line No." := DeferralLineNo;
                InvDefLineNo := "Deferral Line No.";
            end;
            Insert();
        end;

        OnAfterUpdate(Rec, InvoicePostingBuffer);
    end;

    procedure BuildPrimaryKey()
    var
        GroupID: Text;
        TypeValue: Integer;
    begin
        TypeValue := Type.AsInteger();
        GroupID :=
          PadField("Journal Templ. Name", MaxStrLen("Journal Templ. Name")) +
          Format(TypeValue) +
          PadField("G/L Account", MaxStrLen("G/L Account")) +
          PadField("Gen. Bus. Posting Group", MaxStrLen("Gen. Bus. Posting Group")) +
          PadField("Gen. Prod. Posting Group", MaxStrLen("Gen. Prod. Posting Group")) +
          PadField("VAT Bus. Posting Group", MaxStrLen("VAT Bus. Posting Group")) +
          PadField("VAT Prod. Posting Group", MaxStrLen("VAT Prod. Posting Group")) +
          PadField("Tax Area Code", MaxStrLen("Tax Area Code")) +
          PadField("Tax Group Code", MaxStrLen("Tax Group Code")) +
          Format("Tax Liable") +
          Format("Use Tax") +
          PadField(Format("Dimension Set ID"), 20) +
          PadField("Job No.", MaxStrLen("Job No.")) +
          PadField(Format("Fixed Asset Line No."), 20) +
          PadField("Deferral Code", MaxStrLen("Deferral Code"));
        OnBuildPrimaryKeyAfterDeferralCode(GroupID, Rec);
        GroupID := GroupID + PadField("Additional Grouping Identifier", MaxStrLen("Additional Grouping Identifier"));

        "Group ID" := CopyStr(GroupID, 1, MaxStrLen("Group ID"));

        OnAfterBuildPrimaryKey(Rec);
    end;

    procedure PadField(TextField: Text; MaxLength: Integer): Text
    var
        TextLength: Integer;
    begin
        TextLength := StrLen(TextField);
        if TextLength < MaxLength then
            TextField := PadStr('', MaxLength - TextLength, ' ') + TextField;
        exit(TextField);
    end;

    procedure UpdateVATBase(var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal)
    begin
        TotalVATBase := TotalVATBase - "VAT Base Amount";
        TotalVATBaseACY := TotalVATBaseACY - "VAT Base Amount (ACY)"
    end;

    procedure UpdateEntryDescription(CopyLineDescrToGLEntry: Boolean; LineNo: Integer; LineDescription: text[100]; HeaderDescription: Text[100])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateEntryDescription(Rec, HeaderDescription, LineDescription, IsHandled);
        if IsHandled then
            exit;

        if CopyLineDescrToGLEntry and (Type = type::"G/L Account") then begin
            "Entry Description" := LineDescription;
            "Fixed Asset Line No." := LineNo;
        end else
            "Entry Description" := HeaderDescription;
    end;

    local procedure AdjustRoundingForUpdate()
    begin
        AdjustRoundingFieldsPair(TempInvoicePostingBufferRounding.Amount, Amount, "Amount (ACY)");
        AdjustRoundingFieldsPair(TempInvoicePostingBufferRounding."VAT Amount", "VAT Amount", "VAT Amount (ACY)");
        AdjustRoundingFieldsPair(TempInvoicePostingBufferRounding."VAT Base Amount", "VAT Base Amount", "VAT Base Amount (ACY)");
        NonDeductibleVAT.AdjustRoundingForInvoicePostingBufferUpdate(TempInvoicePostingBufferRounding, Rec);
        OnAfterAdjustRoundingForUpdate(Rec, TempInvoicePostingBufferRounding);
    end;

    local procedure AdjustRoundingFieldsPair(var TotalRoundingAmount: Decimal; var AmountLCY: Decimal; AmountFCY: Decimal)
    begin
        if (AmountLCY <> 0) and (AmountFCY = 0) then begin
            TotalRoundingAmount += AmountLCY;
            AmountLCY := 0;
        end;
    end;

    procedure ApplyRoundingForFinalPosting()
    begin
        ApplyRoundingValueForFinalPosting(TempInvoicePostingBufferRounding.Amount, Amount);
        ApplyRoundingValueForFinalPosting(TempInvoicePostingBufferRounding."VAT Amount", "VAT Amount");
        ApplyRoundingValueForFinalPosting(TempInvoicePostingBufferRounding."VAT Base Amount", "VAT Base Amount");
        NonDeductibleVAT.ApplyRoundingForFinalPostingFromInvoicePostingBuffer(TempInvoicePostingBufferRounding, Rec);
        OnAfterApplyRoundingForFinalPosting(Rec, TempInvoicePostingBufferRounding);
    end;

    local procedure ApplyRoundingValueForFinalPosting(var Rounding: Decimal; var Value: Decimal)
    begin
        if (Rounding <> 0) and (Value <> 0) then begin
            Value += Rounding;
            Rounding := 0;
        end;
    end;

    procedure ClearVATFields()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeClearVATFields(Rec, IsHandled);
        if IsHandled then
            exit;

        "VAT Amount" := 0;
        "VAT Base Amount" := 0;
        "VAT Amount (ACY)" := 0;
        "VAT Base Amount (ACY)" := 0;
        NonDeductibleVAT.ClearNonDeductibleVAT(Rec);
        "VAT Difference" := 0;
        "VAT %" := 0;
    end;

    procedure CopyToGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine."Account No." := Rec."G/L Account";
        GenJnlLine."System-Created Entry" := Rec."System-Created Entry";
        GenJnlLine."Gen. Bus. Posting Group" := Rec."Gen. Bus. Posting Group";
        GenJnlLine."Gen. Prod. Posting Group" := Rec."Gen. Prod. Posting Group";
        GenJnlLine."VAT Bus. Posting Group" := Rec."VAT Bus. Posting Group";
        GenJnlLine."VAT Prod. Posting Group" := Rec."VAT Prod. Posting Group";
        GenJnlLine."Tax Area Code" := Rec."Tax Area Code";
        GenJnlLine."Tax Liable" := Rec."Tax Liable";
        GenJnlLine."Tax Group Code" := Rec."Tax Group Code";
        GenJnlLine."Use Tax" := Rec."Use Tax";
        GenJnlLine.Quantity := Rec.Quantity;
        GenJnlLine."VAT %" := Rec."VAT %";
        GenJnlLine."VAT Calculation Type" := Rec."VAT Calculation Type";
        GenJnlLine."VAT Posting" := GenJnlLine."VAT Posting"::"Manual VAT Entry";
        GenJnlLine."Job No." := Rec."Job No.";
        GenJnlLine."Deferral Code" := Rec."Deferral Code";
        GenJnlLine."Deferral Line No." := Rec."Deferral Line No.";
        GenJnlLine.Amount := Rec.Amount;
        GenJnlLine."Source Currency Amount" := Rec."Amount (ACY)";
        GenJnlLine."VAT Base Amount" := Rec."VAT Base Amount";
        GenJnlLine."Source Curr. VAT Base Amount" := Rec."VAT Base Amount (ACY)";
        GenJnlLine."VAT Amount" := Rec."VAT Amount";
        GenJnlLine."Source Curr. VAT Amount" := Rec."VAT Amount (ACY)";
        GenJnlLine."VAT Difference" := Rec."VAT Difference";
        GenJnlLine."VAT Base Before Pmt. Disc." := Rec."VAT Base Before Pmt. Disc.";
        NonDeductibleVAT.Copy(GenJnlLine, Rec);

        OnAfterCopyToGenJnlLine(GenJnlLine, Rec);
    end;

    procedure CopyToGenJnlLineFA(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine."Account Type" := "Gen. Journal Account Type"::"Fixed Asset";
        GenJnlLine."FA Posting Date" := Rec."FA Posting Date";
        GenJnlLine."Depreciation Book Code" := Rec."Depreciation Book Code";
        GenJnlLine."Salvage Value" := Rec."Salvage Value";
        GenJnlLine."Depr. until FA Posting Date" := Rec."Depr. until FA Posting Date";
        GenJnlLine."Depr. Acquisition Cost" := Rec."Depr. Acquisition Cost";
        GenJnlLine."Maintenance Code" := Rec."Maintenance Code";
        GenJnlLine."Insurance No." := Rec."Insurance No.";
        GenJnlLine."Budgeted FA No." := Rec."Budgeted FA No.";
        GenJnlLine."Duplicate in Depreciation Book" := Rec."Duplicate in Depreciation Book";
        GenJnlLine."Use Duplication List" := Rec."Use Duplication List";

        OnAfterCopyToGenJnlLineFA(GenJnlLine, Rec);
    end;




    [IntegrationEvent(false, false)]
    local procedure OnAfterBuildPrimaryKey(var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateOnAfterModify(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; FromInvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdate(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var FromInvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcDiscount(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcDiscountNoVAT(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdate(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var FromInvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateOnBeforeModify(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; FromInvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnFillPrepmtAdjBufferOnBeforeAssignInvoicePostingBuffer(var PrepmtAdjInvoicePostingBuffer: Record "Invoice Posting Buffer"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyToGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyToGenJnlLineFA(var GenJnlLine: Record "Gen. Journal Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAdjustRoundingForUpdate(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; TempInvoicePostingBufferRounding: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyRoundingForFinalPosting(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; TempInvoicePostingBufferRounding: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBuildPrimaryKeyAfterDeferralCode(var GroupID: Text; InvoicePostingBuffer: Record "Invoice Posting Buffer");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcDiscountOnAfterUpdateVATAmount(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; PricesInclVAT: Boolean; DiscountAmount: Decimal; DiscountAmountACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearVATFields(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAccount(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; AccountNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReverseAmounts(var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateEntryDescription(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var HeaderDescription: Text[100]; var LineDescription: Text[100]; var IsHandled: Boolean)
    begin
    end;
}