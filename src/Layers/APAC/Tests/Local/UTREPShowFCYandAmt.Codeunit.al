codeunit 141061 "UT REP Show FCY and Amt"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Amount in words] [UT]
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        AmountIncLCYCap: Label 'AmountIncLCY';
        AmountLangA1AmountLangA2Cap: Label 'AmountLangA1AmountLangA2';
        AmountLangB1AmountLangB2Cap: Label 'AmountLangB1AmountLangB2';
        AmountLCYCap: Label 'AmountLCY';
        PurchCrMemoLineAmountCap: Label 'Amount_PurchCrMemoLine';
        PurchCrMemoLineAmtInclVATCap: Label 'AmtInclVAT_PurchCrMemoLine';
        PurchInvLineAmountCap: Label 'Amount_PurchInvLine';
        PurchInvLineAmtInclVATCap: Label 'AmtInclVAT_PurchInvLine';

    [Test]
    [HandlerFunctions('PurchaseInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchInvHeaderPurchaseInvoice()
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        // [SCENARIO] verify Amount, Amount Including VAT and Amount in words on Report - 406 Purchase - Invoice.

        // Setup.
        Initialize();
        CreatePostedPurchaseInvoice(PurchInvLine);
        LibraryVariableStorage.Enqueue(PurchInvLine."Document No.");  // Enqueue for PurchaseInvoiceRequestPageHandler.
        Commit();  // COMMIT is explicitly called on OnRun of COD319 - Purch. Inv.-Printed.

        // Exercise.
        REPORT.Run(REPORT::"Purchase - Invoice");

        // Verify.
        VerifyValuesOnPostedPurchaseInvoice(PurchInvLine);
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchInvHeaderPurchaseCreditMemo()
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        // [SCENARIO] verify Amount, Amount Including VAT and Amount in words on Report - 407 Purchase - Credit Memo.

        // Setup.
        Initialize();
        CreatePostedPurchaseCreditMemo(PurchCrMemoLine);
        LibraryVariableStorage.Enqueue(PurchCrMemoLine."Document No.");  // Enqueue for PurchaseCreditMemoRequestPageHandler.
        Commit();  // COMMIT is explicitly called on OnRun of COD320 - PurchCrMemo-Printed.

        // Exercise.
        REPORT.Run(REPORT::"Purchase - Credit Memo");

        // Verify.
        VerifyValuesOnPostedPurchaseCreditMemo(PurchCrMemoLine);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Code := LibraryUTUtility.GetNewCode10();
        Currency.Insert();
        exit(Currency.Code);
    end;

    local procedure CreateCurrencyExchangeRate(): Code[10]
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate."Currency Code" := CreateCurrency();
        CurrencyExchangeRate."Exchange Rate Amount" := LibraryRandom.RandDec(10, 2);
        CurrencyExchangeRate."Relational Exch. Rate Amount" := LibraryRandom.RandDec(10, 2);
        CurrencyExchangeRate.Insert();
        exit(CurrencyExchangeRate."Currency Code");
    end;

    local procedure ConvertNumberToText(Amount: Decimal; CurrencyCode: Code[10]): Text[80]
    var
        SalesLine: Record "Sales Line";
        CheckAmountText: array[2] of Text[80];
    begin
        // Calculation from number to text.
        SalesLine.InitTextVariable();
        SalesLine.FormatNoText(CheckAmountText, Amount, CurrencyCode);
        exit(CheckAmountText[1]);
    end;

    local procedure ConvertNumberToTextTH(Amount: Decimal; CurrencyCode: Code[10]): Text[80]
    var
        SalesLine: Record "Sales Line";
        CheckAmountText: array[2] of Text[80];
    begin
        // Calculation from number to text.
        SalesLine.InitTextVariableTH();
        SalesLine.FormatNoTextTH(CheckAmountText, Amount, CurrencyCode);
        exit(CheckAmountText[1]);
    end;

    local procedure CreatePostedPurchaseCreditMemo(var PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr."No." := LibraryUTUtility.GetNewCode();
        PurchCrMemoHdr."Currency Code" := CreateCurrencyExchangeRate();
        PurchCrMemoHdr."Posting Date" := WorkDate();
        PurchCrMemoHdr."Currency Factor" := LibraryRandom.RandDec(10, 2);
        PurchCrMemoHdr.Insert();
        PurchCrMemoLine."Document No." := PurchCrMemoHdr."No.";
        PurchCrMemoLine.Amount := LibraryRandom.RandDec(100, 2);
        PurchCrMemoLine."Amount Including VAT" := LibraryRandom.RandDecInRange(100, 200, 2);
        PurchCrMemoLine.Insert();
    end;

    local procedure CreatePostedPurchaseInvoice(var PurchInvLine: Record "Purch. Inv. Line")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader."No." := LibraryUTUtility.GetNewCode();
        PurchInvHeader."Currency Code" := CreateCurrencyExchangeRate();
        PurchInvHeader."Posting Date" := WorkDate();
        PurchInvHeader."Currency Factor" := LibraryRandom.RandDec(10, 2);
        PurchInvHeader.Insert();
        PurchInvLine."Document No." := PurchInvHeader."No.";
        PurchInvLine.Amount := LibraryRandom.RandDec(100, 2);
        PurchInvLine."Amount Including VAT" := LibraryRandom.RandDecInRange(100, 200, 2);
        PurchInvLine.Insert();
    end;

    local procedure VerifyAmountConversionNumberToText(AmountInTextCap: Text; AmountInTextThCap: Text; CurrencyCode: Code[10]; AmountIncludingVAT: Decimal)
    var
        AmountInText: Text;
        AmountInTextTH: Text;
    begin
        AmountInText := ConvertNumberToText(AmountIncludingVAT, CurrencyCode);
        AmountInTextTH := ConvertNumberToTextTH(AmountIncludingVAT, CurrencyCode);
        LibraryReportDataset.AssertElementWithValueExists(AmountInTextCap, AmountInText + ' ');  // Using blank for space.
        LibraryReportDataset.AssertElementWithValueExists(AmountInTextThCap, AmountInTextTH + ' ');  // Using blank for space.
    end;

    local procedure VerifyValuesOnPostedPurchaseDocument(CurrencyCode: Code[10]; Amount: Decimal; AmountIncludingVAT: Decimal; AmountIncludingVATLCY: Decimal)
    begin
        LibraryReportDataset.AssertElementWithValueExists(AmountLCYCap, Round(Amount));
        LibraryReportDataset.AssertElementWithValueExists(AmountIncLCYCap, Round(AmountIncludingVAT));
        VerifyAmountConversionNumberToText(
          AmountLangA1AmountLangA2Cap, AmountLangB1AmountLangB2Cap, CurrencyCode, AmountIncludingVATLCY);
    end;

    local procedure VerifyValuesOnPostedPurchaseInvoice(PurchInvLine: Record "Purch. Inv. Line")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(PurchInvLine."Document No.");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(PurchInvLineAmountCap, PurchInvLine.Amount);
        LibraryReportDataset.AssertElementWithValueExists(PurchInvLineAmtInclVATCap, PurchInvLine."Amount Including VAT");
        VerifyValuesOnPostedPurchaseDocument(
          PurchInvHeader."Currency Code", PurchInvLine.Amount / PurchInvHeader."Currency Factor",
          PurchInvLine."Amount Including VAT" / PurchInvHeader."Currency Factor", PurchInvLine."Amount Including VAT");
    end;

    local procedure VerifyValuesOnPostedPurchaseCreditMemo(PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.Get(PurchCrMemoLine."Document No.");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(PurchCrMemoLineAmountCap, PurchCrMemoLine.Amount);
        LibraryReportDataset.AssertElementWithValueExists(PurchCrMemoLineAmtInclVATCap, PurchCrMemoLine."Amount Including VAT");
        VerifyValuesOnPostedPurchaseDocument(
          PurchCrMemoHdr."Currency Code", PurchCrMemoLine.Amount / PurchCrMemoHdr."Currency Factor",
          PurchCrMemoLine."Amount Including VAT" / PurchCrMemoHdr."Currency Factor", PurchCrMemoLine."Amount Including VAT");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceRequestPageHandler(var PurchaseInvoice: TestRequestPage "Purchase - Invoice")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        PurchaseInvoice."Purch. Inv. Header".SetFilter("No.", No);
        PurchaseInvoice.ShowTotalInWords.SetValue(true);
        PurchaseInvoice.ShowLCYForFCY.SetValue(true);
        PurchaseInvoice.ShowTHAmountInWords.SetValue(true);
        PurchaseInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoRequestPageHandler(var PurchaseCreditMemo: TestRequestPage "Purchase - Credit Memo")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        PurchaseCreditMemo."Purch. Cr. Memo Hdr.".SetFilter("No.", No);
        PurchaseCreditMemo.ShowTotalInWords.SetValue(true);
        PurchaseCreditMemo.ShowLCYForFCY.SetValue(true);
        PurchaseCreditMemo.ShowTHAmountInWords.SetValue(true);
        PurchaseCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}
