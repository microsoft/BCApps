// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

codeunit 6110 "E-Doc. MLLM Verify Tools"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure VerifyLineMath(UnitPrice: Decimal; Quantity: Decimal; DiscountPct: Decimal; LineExtensionAmount: Decimal; var ErrorText: Text): Boolean
    var
        Expected: Decimal;
        LineMathErrLbl: Label '%1 × %2 × (1 − %3/100) = %4, but line_extension_amount = %5. Re-check which price column is the gross (pre-discount) unit price.', Comment = '%1=UnitPrice, %2=Quantity, %3=DiscountPct, %4=Expected, %5=LineExtensionAmount';
    begin
        if LineExtensionAmount = 0 then
            exit(true);

        Expected := UnitPrice * Quantity * (1 - DiscountPct / 100);

        if IsWithinTolerance(Expected, LineExtensionAmount) then
            exit(true);

        ErrorText := StrSubstNo(LineMathErrLbl, UnitPrice, Quantity, DiscountPct, Expected, LineExtensionAmount);
        exit(false);
    end;

    procedure VerifyInvoiceTotals(LineAmounts: List of [Decimal]; TaxExclusiveAmount: Decimal; var ErrorText: Text): Boolean
    var
        LineAmount: Decimal;
        SumOfLines: Decimal;
        InvoiceTotalsErrLbl: Label 'Sum of line_extension_amounts = %1, but tax_exclusive_amount = %2. Check for missing or duplicated lines.', Comment = '%1=SumOfLines, %2=TaxExclusiveAmount';
    begin
        if TaxExclusiveAmount = 0 then
            exit(true);

        SumOfLines := 0;
        foreach LineAmount in LineAmounts do
            SumOfLines += LineAmount;

        if IsWithinTolerance(SumOfLines, TaxExclusiveAmount) then
            exit(true);

        ErrorText := StrSubstNo(InvoiceTotalsErrLbl, SumOfLines, TaxExclusiveAmount);
        exit(false);
    end;

    procedure VerifyVAT(TaxExclusiveAmount: Decimal; VATRate: Decimal; TaxAmount: Decimal; var ErrorText: Text): Boolean
    var
        Expected: Decimal;
        VATErrLbl: Label '%1 × %2% = %3, but tax_amount = %4. Re-check the VAT rate.', Comment = '%1=TaxExclusiveAmount, %2=VATRate, %3=Expected, %4=TaxAmount';
    begin
        if TaxAmount = 0 then
            exit(true);

        Expected := TaxExclusiveAmount * VATRate / 100;

        if IsWithinTolerance(Expected, TaxAmount) then
            exit(true);

        ErrorText := StrSubstNo(VATErrLbl, TaxExclusiveAmount, VATRate, Expected, TaxAmount);
        exit(false);
    end;

    procedure VerifyDates(IssueDateText: Text; DueDateText: Text; var ErrorText: Text): Boolean
    var
        IssueDate: Date;
        DueDate: Date;
        MissingIssueDateErrLbl: Label 'issue_date is missing.';
        InvalidIssueDateErrLbl: Label 'issue_date ''%1'' is not a valid date.', Comment = '%1=IssueDateText';
        IssueDateYearErrLbl: Label 'issue_date ''%1'' has year %2 which is outside the expected range 1900–2100.', Comment = '%1=IssueDateText, %2=Year';
        InvalidDueDateErrLbl: Label 'due_date ''%1'' is not a valid date.', Comment = '%1=DueDateText';
        DueDateBeforeIssueDateErrLbl: Label 'due_date %1 is before issue_date %2.', Comment = '%1=DueDate, %2=IssueDate';
    begin
        if IssueDateText = '' then begin
            ErrorText := MissingIssueDateErrLbl;
            exit(false);
        end;

        if not Evaluate(IssueDate, IssueDateText, 9) then begin
            ErrorText := StrSubstNo(InvalidIssueDateErrLbl, IssueDateText);
            exit(false);
        end;

        if (Date2DMY(IssueDate, 3) < 1900) or (Date2DMY(IssueDate, 3) > 2100) then begin
            ErrorText := StrSubstNo(IssueDateYearErrLbl, IssueDateText, Date2DMY(IssueDate, 3));
            exit(false);
        end;

        if DueDateText <> '' then begin
            if not Evaluate(DueDate, DueDateText, 9) then begin
                ErrorText := StrSubstNo(InvalidDueDateErrLbl, DueDateText);
                exit(false);
            end;

            if DueDate < IssueDate then begin
                ErrorText := StrSubstNo(DueDateBeforeIssueDateErrLbl, DueDate, IssueDate);
                exit(false);
            end;
        end;

        exit(true);
    end;

    procedure VerifyRequiredFields(VendorName: Text; InvoiceNo: Text; LineCount: Integer; var ErrorText: Text): Boolean
    var
        Missing: Text;
        MissingFieldsErrLbl: Label 'Missing required fields: %1', Comment = '%1=comma-separated list of missing fields';
        VendorNameLbl: Label 'vendor name', Locked = true;
        InvoiceNumberLbl: Label 'invoice number', Locked = true;
        InvoiceLineCountLbl: Label 'invoice lines (line_count = 0)', Locked = true;
    begin
        Missing := '';

        if VendorName = '' then
            AppendMissing(Missing, VendorNameLbl);

        if InvoiceNo = '' then
            AppendMissing(Missing, InvoiceNumberLbl);

        if LineCount = 0 then
            AppendMissing(Missing, InvoiceLineCountLbl);

        if Missing = '' then
            exit(true);

        ErrorText := StrSubstNo(MissingFieldsErrLbl, Missing);
        exit(false);
    end;

    procedure VerifyRanges(Quantities: List of [Decimal]; Prices: List of [Decimal]; VATRates: List of [Decimal]; DiscountPcts: List of [Decimal]; var ErrorText: Text): Boolean
    var
        i: Integer;
        Value: Decimal;
        NegativeQtyErrLbl: Label 'Line %1: quantity %2 must be greater than 0.', Comment = '%1=LineIndex, %2=Value';
        NonPositivePriceErrLbl: Label 'Line %1: unit price %2 must be greater than 0.', Comment = '%1=LineIndex, %2=Value';
        VATRateRangeErrLbl: Label 'Line %1: VAT rate %2 is outside the range 0–100.', Comment = '%1=LineIndex, %2=Value';
        DiscountRangeErrLbl: Label 'Line %1: discount %2 is outside the range 0–100.', Comment = '%1=LineIndex, %2=Value';
    begin
        for i := 1 to Quantities.Count() do begin
            Quantities.Get(i, Value);
            if Value <= 0 then begin
                ErrorText := StrSubstNo(NegativeQtyErrLbl, i, Value);
                exit(false);
            end;
        end;

        for i := 1 to Prices.Count() do begin
            Prices.Get(i, Value);
            if Value <= 0 then begin
                ErrorText := StrSubstNo(NonPositivePriceErrLbl, i, Value);
                exit(false);
            end;
        end;

        for i := 1 to VATRates.Count() do begin
            VATRates.Get(i, Value);
            if (Value < 0) or (Value > 100) then begin
                ErrorText := StrSubstNo(VATRateRangeErrLbl, i, Value);
                exit(false);
            end;
        end;

        for i := 1 to DiscountPcts.Count() do begin
            DiscountPcts.Get(i, Value);
            if (Value < 0) or (Value > 100) then begin
                ErrorText := StrSubstNo(DiscountRangeErrLbl, i, Value);
                exit(false);
            end;
        end;

        exit(true);
    end;

    procedure IsWithinTolerance(Expected: Decimal; Actual: Decimal): Boolean
    var
        Denominator: Decimal;
    begin
        Denominator := Abs(Actual);
        if Denominator < 1 then
            Denominator := 1;
        exit(Abs(Expected - Actual) / Denominator < 0.01);
    end;

    local procedure AppendMissing(var Missing: Text; Field: Text)
    begin
        if Missing <> '' then
            Missing += ', ';
        Missing += Field;
    end;
}
