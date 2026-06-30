codeunit 103020 GLUtil
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure SetRndgPrec(AmtRndgPrec: Decimal;UnitAmtRndgPrec: Decimal)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup."Amount Rounding Precision" := AmtRndgPrec;
        GLSetup."Unit-Amount Rounding Precision" := UnitAmtRndgPrec;
        GLSetup.Modify();
    end;

    [Scope('OnPrem')]
    procedure SetAddCurr(ACYCode: Code[10];ExchRateNumerator: Decimal;ExchRateDenominator: Decimal;AmtRndgPrecACY: Decimal;UnitAmtRndgPrecACY: Decimal)
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        AdjAddReportingCurr: Report "Adjust Add. Reporting Currency";
    begin
        GLSetup.Get();
        GLSetup."Additional Reporting Currency" := ACYCode;
        GLSetup.Modify();

        if ACYCode = '' then
          exit;

        Currency.Get(ACYCode);
        Currency."Amount Rounding Precision" := AmtRndgPrecACY;
        Currency."Unit-Amount Rounding Precision" := UnitAmtRndgPrecACY;
        Currency."Realized G/L Gains Account" := '9330';
        Currency."Realized G/L Losses Account" := '9340';
        Currency."Residual Gains Account" := '9310';
        Currency."Residual Losses Account" := '9320';
        Currency.Modify();

        SetExchRate(ACYCode,19990101D,ExchRateNumerator,ExchRateDenominator,ExchRateNumerator,ExchRateDenominator);

        AdjAddReportingCurr.SetAddCurr(ACYCode);
        AdjAddReportingCurr.InitializeRequest(ACYCode,'3120');
        AdjAddReportingCurr.UseRequestPage(false);
        AdjAddReportingCurr.Run();
    end;

    [Scope('OnPrem')]
    procedure SetExchRate(CurrencyCode: Code[20];StartingDate: Date;ExchRateAmt: Decimal;RelExchRateAmt: Decimal;AdjmtExchRateAmt: Decimal;RelAdjmtExchRateAmt: Decimal)
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        CurrExchRate."Currency Code" := CurrencyCode;
        CurrExchRate."Starting Date" := StartingDate;
        CurrExchRate."Exchange Rate Amount" := ExchRateAmt;
        CurrExchRate."Relational Exch. Rate Amount" := RelExchRateAmt;
        CurrExchRate."Adjustment Exch. Rate Amount" := AdjmtExchRateAmt;
        CurrExchRate."Relational Adjmt Exch Rate Amt" := RelAdjmtExchRateAmt;
        if not CurrExchRate.Insert() then
          CurrExchRate.Modify();
    end;

    [Scope('OnPrem')]
    procedure GetGLBalanceAtDate(GLAccountNo: Code[20];PostingDate: Date;ACY: Boolean): Decimal
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetCurrentKey("G/L Account No.","Posting Date");
        GLEntry.SetRange("G/L Account No.",GLAccountNo);
        GLEntry.SetRange("Posting Date",PostingDate);
        if ACY then begin
          GLEntry.CalcSums("Additional-Currency Amount");
          exit(GLEntry."Additional-Currency Amount");
        end;
        GLEntry.CalcSums(Amount);
        exit(GLEntry.Amount);
    end;

    [Scope('OnPrem')]
    procedure GetLastestPostingDate(): Date
    var
        GLEntry: Record "G/L Entry";
        OK: Boolean;
    begin
        GLEntry.SetCurrentKey("G/L Account No.","Posting Date");
        OK := true;
        repeat
          GLEntry.SetFilter("G/L Account No.",'>%1',GLEntry."G/L Account No.");
          GLEntry.SetFilter("Posting Date",'>%1',GLEntry."Posting Date");
          if GLEntry.FindFirst() then begin
            GLEntry.SetRange("G/L Account No.",GLEntry."G/L Account No.");
            GLEntry.SetRange("Posting Date");
            GLEntry.FindLast();
          end else
            OK := false
        until not OK;

        if GLEntry."Posting Date" = 0D then
          exit(WorkDate());

        exit(GLEntry."Posting Date");
    end;

    [Scope('OnPrem')]
    procedure GetLastGLEntryNo(): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        if GLEntry.FindLast() then;
        exit(GLEntry."Entry No.");
    end;

    [Scope('OnPrem')]
    procedure IncrLineNo(var LineNo: Integer)
    begin
        LineNo += 10000;
    end;

    [Scope('OnPrem')]
    procedure GetLastDocNo(SeriesCode: Code[20]): Code[20]
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code",SeriesCode);
        NoSeriesLine.SetRange(Open,true);
        NoSeriesLine.FindFirst();
        exit(NoSeriesLine."Last No. Used");
    end;
}

