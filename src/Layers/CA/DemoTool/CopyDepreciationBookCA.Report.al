report 168110 "Copy Depreciation Book - CA"
{
    Caption = 'Copy Depreciation Book';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "FA Class Code", "FA Subclass Code";

            trigger OnAfterGetRecord()
            begin
                DateByFA();

                Window.Update(1, "No.");
                if Inactive or Blocked then
                    CurrReport.Skip();
                if not FADeprBook.Get("No.", DeprBookCode) then
                    CurrReport.Skip();
                if not FADeprBook2.Get("No.", DeprBookCode2) then begin
                    FADeprBook2 := FADeprBook;
                    FADeprBook2."Depreciation Book Code" := DeprBookCode2;
                    FADeprBook2.Insert(true);
                end;
                FALedgEntry.SetRange("FA No.", "No.");
                if FALedgEntry.Find('-') then
                    repeat
                        SetJournalType(FALedgEntry);
                        case JournalType of
                            JournalType::SkipType:
                                ;
                            JournalType::GenJnlType:
                                InsertGenJnlLine(FALedgEntry);
                            JournalType::FAJnlType:
                                InsertFAJnlLine(FALedgEntry);
                        end;
                    until FALedgEntry.Next() = 0;
            end;

            trigger OnPreDataItem()
            begin
                DepreciationCalc.SetFAFilter(FALedgEntry, '', DeprBookCode, false);
                FALedgEntry.SetRange("FA Posting Category", FALedgEntry."FA Posting Category"::" ");
                FALedgEntry.SetRange(
                  "FA Posting Type",
                  FALedgEntry."FA Posting Type"::"Acquisition Cost", FALedgEntry."FA Posting Type"::"Salvage Value");
                //  SETRANGE("FA Posting Date",StartingDate,EndingDate2);
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        DeprBookCode := 'COMPANY';
        DeprBookCode2 := 'CCA';
        PostingDescription := 'Setup';
        BalAccount := true;
        CopyChoices[1] := true;

        if (EndingDate > 0D) and (StartingDate > EndingDate) then
            Error(Text000);
        if EndingDate = 0D then
            EndingDate2 := 99991231D
        else
            EndingDate2 := EndingDate;
        DeprBook.Get(DeprBookCode);
        DeprBook2.Get(DeprBookCode2);
        ExchangeRate := GetExchangeRate();
        DeprBook2.IndexGLIntegration(GLIntegration);
        FirstGenJnl := true;
        FirstFAJnl := true;
        Window.Open(Text001);
    end;

    var
        Text000: Label 'The Starting Date is later than the Ending Date.';
        Text001: Label 'Copying fixed asset    #1##########';
        GenJnlLine: Record "Gen. Journal Line";
        FAJnlLine: Record "FA Journal Line";
        FADeprBook: Record "FA Depreciation Book";
        FADeprBook2: Record "FA Depreciation Book";
        DeprBook: Record "Depreciation Book";
        DeprBook2: Record "Depreciation Book";
        FALedgEntry: Record "FA Ledger Entry";
        FAJnlSetup: Record "FA Journal Setup";
        DepreciationCalc: Codeunit "Depreciation Calculation";
        Window: Dialog;
        ExchangeRate: Decimal;
        CopyChoices: array[9] of Boolean;
        GLIntegration: array[9] of Boolean;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        DocumentNo3: Code[20];
        NoSeries2: Code[20];
        NoSeries3: Code[20];
        PostingDescription: Text[50];
        JournalType: Option SkipType,GenJnlType,FAJnlType;
        DeprBookCode: Code[10];
        DeprBookCode2: Code[10];
        BalAccount: Boolean;
        StartingDate: Date;
        EndingDate: Date;
        EndingDate2: Date;
        FirstGenJnl: Boolean;
        FirstFAJnl: Boolean;
        FAJnlNextLineNo: Integer;
        GenJnlNextLineNo: Integer;

    local procedure InsertGenJnlLine(var FALedgEntry: Record "FA Ledger Entry")
    var
        FAInsertGLAcc: Codeunit "FA Insert G/L Account";
    begin
        if FirstGenJnl then begin
            GenJnlLine.LockTable();
            FAJnlSetup.GenJnlName(DeprBook2, GenJnlLine, GenJnlNextLineNo);
            NoSeries2 := FAJnlSetup.GetGenNoSeries(GenJnlLine);
            if DocumentNo = '' then
                DocumentNo2 := FAJnlSetup.GetGenJnlDocumentNo(GenJnlLine, FALedgEntry."FA Posting Date", true)
            else
                DocumentNo2 := DocumentNo;
        end;
        FirstGenJnl := false;

        FALedgEntry.MoveToGenJnl(GenJnlLine);
        GenJnlLine.Validate("Depreciation Book Code", DeprBookCode2);
        GenJnlLine.Validate(Amount, Round(GenJnlLine.Amount * ExchangeRate));
        GenJnlLine."Document No." := DocumentNo2;
        GenJnlLine."Posting No. Series" := NoSeries2;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
        GenJnlLine."External Document No." := '';
        if PostingDescription <> '' then
            GenJnlLine.Description := PostingDescription;
        GenJnlNextLineNo := GenJnlNextLineNo + 10000;
        GenJnlLine."Line No." := GenJnlNextLineNo;
        GenJnlLine.Insert(true);
        GenJnlLine."Dimension Set ID" := FALedgEntry."Dimension Set ID";
        if BalAccount then begin
            FAInsertGLAcc.GetBalAcc(GenJnlLine);
            if GenJnlLine.Find('+') then;
            GenJnlNextLineNo := GenJnlLine."Line No.";
        end;
    end;

    local procedure InsertFAJnlLine(var FALedgEntry: Record "FA Ledger Entry")
    begin
        if FirstFAJnl then begin
            FAJnlLine.LockTable();
            FAJnlSetup.FAJnlName(DeprBook2, FAJnlLine, FAJnlNextLineNo);
            NoSeries3 := FAJnlSetup.GetFANoSeries(FAJnlLine);
            if DocumentNo = '' then
                DocumentNo3 := FAJnlSetup.GetFAJnlDocumentNo(FAJnlLine, FALedgEntry."FA Posting Date", true)
            else
                DocumentNo3 := DocumentNo;
        end;
        FirstFAJnl := false;

        FALedgEntry.MoveToFAJnl(FAJnlLine);
        FAJnlLine.Validate("Depreciation Book Code", DeprBookCode2);
        FAJnlLine.Validate(Amount, Round(FAJnlLine.Amount * ExchangeRate));
        FAJnlLine."Document No." := DocumentNo3;
        FAJnlLine."Posting No. Series" := NoSeries3;
        FAJnlLine."Document Type" := FAJnlLine."Document Type"::" ";
        FAJnlLine."External Document No." := '';
        if PostingDescription <> '' then
            FAJnlLine.Description := PostingDescription;
        FAJnlNextLineNo := FAJnlNextLineNo + 10000;
        FAJnlLine."Line No." := FAJnlNextLineNo;
        FAJnlLine.Insert(true);
        FAJnlLine."Dimension Set ID" := FALedgEntry."Dimension Set ID";
    end;

    local procedure SetJournalType(var FALedgEntry: Record "FA Ledger Entry")
    var
        Index: Integer;
    begin
        Index := FALedgEntry.ConvertPostingType() + 1;
        if CopyChoices[Index] then begin
            if GLIntegration[Index] and not "Fixed Asset"."Budgeted Asset" then
                JournalType := JournalType::GenJnlType
            else
                JournalType := JournalType::FAJnlType
        end else
            JournalType := JournalType::SkipType;
    end;

    local procedure GetExchangeRate(): Decimal
    var
        ExchangeRate2: Decimal;
        ExchangeRate3: Decimal;
    begin
        ExchangeRate2 := DeprBook."Default Exchange Rate";
        if ExchangeRate2 <= 0 then
            ExchangeRate2 := 100;
        if not DeprBook."Use FA Exch. Rate in Duplic." then
            ExchangeRate2 := 100;

        ExchangeRate3 := DeprBook2."Default Exchange Rate";
        if ExchangeRate3 <= 0 then
            ExchangeRate3 := 100;
        if not DeprBook2."Use FA Exch. Rate in Duplic." then
            ExchangeRate3 := 100;

        exit(ExchangeRate2 / ExchangeRate3);
    end;

    procedure DateByFA()
    begin
        //Set the StartingDate by FA NO.

        case "Fixed Asset"."No." of
            'FA000010', 'FA000040', 'FA000050':
                StartingDate := 20000101D;
            'FA000060', 'FA000090':
                StartingDate := 20000102D;
            'FA000020':
                StartingDate := 20000105D;
            'FA000030':
                StartingDate := 20000106D;
            'FA000070':
                StartingDate := 20000103D;
            'FA000080':
                StartingDate := 20000104D;
            else
                StartingDate := 20000101D;
        end;

        //fix the FA Ledger

        FALedgEntry.SetRange("FA Posting Date", StartingDate, EndingDate2);
    end;
}

