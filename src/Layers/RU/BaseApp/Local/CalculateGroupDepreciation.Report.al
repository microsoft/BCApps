#pragma warning disable AA0247
report 14933 "Calculate Group Depreciation"
{
    ApplicationArea = FixedAssets;
    Caption = 'Calculate Group Depreciation';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Depreciation Group"; "Depreciation Group")
        {
            RequestFilterFields = "Code";
            dataitem("Fixed Asset"; "Fixed Asset")
            {
                DataItemLink = "Depreciation Group" = field(Code);
                DataItemTableView = sorting("Depreciation Group") where(Blocked = const(false));

                trigger OnAfterGetRecord()
                var
                    DeprAmount: Decimal;
                    OK: Boolean;
                begin
                    if FADeprBook.Get("No.", DeprBookCode) then
                        if CheckDeprBook() then begin
                            OK := false;
                            case ExistingDeprPeriods("No.", DeprBookCode, Period) of
                                0:
                                    if FADeprBook."Depreciation Starting Date" < DatePeriod."Period Start" then // it's not first depr
                                        Message(Text12400 + Text12402, Period, "No.", DeprBookCode)
                                    else
                                        OK := true;
                                1, 3:
                                    Message(Text12401 + Text12402, Period, "No.", DeprBookCode);
                                4:
                                    Message(Text007, CalcDate('<+1M>', Period), "No.", DeprBookCode);
                                2:
                                    OK := true;
                            end;

                            if not OK then
                                CurrReport.Skip();

                            DeprAmount :=
                              DepreciationCalc.CalcRounding(DeprBookCode,
                                GetBookValue("No.", DatePeriod."Period Start", NormalDate(DatePeriod."Period End")) * DeprRate * 0.01);

                            TotalDeprAmount := TotalDeprAmount + DeprAmount;
                            NumberOfDays := DepreciationCalc.DeprDays(
                                DatePeriod."Period Start",
                                DatePeriod."Period End",
                                DeprBook."Fiscal Year 365 Days");

                            if not DeprBook."G/L Integration - Depreciation" or "Budgeted Asset" then begin
                                FAJnlLineTmp."FA No." := "No.";
                                FAJnlLineTmp."FA Posting Type" := FAJnlLineTmp."FA Posting Type"::Depreciation;
                                FAJnlLineTmp.Amount := -DeprAmount;
                                FAJnlLineTmp."No. of Depreciation Days" := NumberOfDays;
                                FAJnlLineTmp."Line No." := FAJnlLineTmp."Line No." + 1;
                                FAJnlLineTmp."Depr. Period Starting Date" := Period;
                                FAJnlLineTmp."Location Code" := "Fixed Asset"."FA Location Code";
                                FAJnlLineTmp."Employee No." := "Fixed Asset"."Responsible Employee";
                                FAJnlLineTmp.Insert();
                            end else begin
                                GenJnlLineTmp."Account No." := "No.";
                                GenJnlLineTmp."FA Posting Type" := GenJnlLineTmp."FA Posting Type"::Depreciation;
                                GenJnlLineTmp.Amount := -DeprAmount;
                                GenJnlLineTmp."No. of Depreciation Days" := NumberOfDays;
                                GenJnlLineTmp."Line No." := GenJnlLineTmp."Line No." + 1;
                                GenJnlLineTmp."FA Location Code" := "Fixed Asset"."FA Location Code";
                                GenJnlLineTmp."Employee No." := "Fixed Asset"."Responsible Employee";
                                GenJnlLineTmp."Depr. Period Starting Date" := Period;
                                GenJnlLineTmp.Insert();
                            end;
                        end;
                end;

                trigger OnPostDataItem()
                var
                    MaxAmountFAJnlLineNo: Integer;
                    MaxAmountGenJnlLineNo: Integer;
                    MaxAmountGenJnlBalLineNo: Integer;
                    MaxFAJnlAmount: Decimal;
                    MaxGenJnlAmount: Decimal;
                begin
                    DeprDiff := GroupDeprAmount - TotalDeprAmount;

                    if FAJnlLineTmp.FindSet() then begin
                        FAJnlLine.LockTable();
                        FAJnlSetup.FAJnlName(DeprBook, FAJnlLine, FAJnlNextLineNo);
                        NoSeries := FAJnlSetup.GetFANoSeries(FAJnlLine);
                        if DocumentNo = '' then
                            DocumentNo2 := FAJnlSetup.GetFAJnlDocumentNo(FAJnlLine, DeprUntilDate, true)
                        else
                            DocumentNo2 := DocumentNo;
                    end;
                    if FAJnlLineTmp.FindSet() then begin
                        repeat
                            FAJnlLine.Init();
                            FAJnlLine."Line No." := 0;
                            FAJnlSetup.SetFAJnlTrailCodes(FAJnlLine);
                            LineNo := LineNo + 1;
                            Window.Update(3, LineNo);
                            FAJnlLine."Posting Date" := PostingDate;
                            FAJnlLine."FA Posting Date" := DeprUntilDate;
                            if FAJnlLine."Posting Date" = FAJnlLine."FA Posting Date" then
                                FAJnlLine."Posting Date" := 0D;
                            FAJnlLine."FA Posting Type" := FAJnlLineTmp."FA Posting Type";
                            FAJnlLine.Validate("FA No.", FAJnlLineTmp."FA No.");
                            FAJnlLine."Document No." := DocumentNo2;
                            FAJnlLine."Posting No. Series" := NoSeries;
                            FAJnlLine.Description := PostingDescription;
                            FAJnlLine.Validate("Depreciation Book Code", DeprBookCode);
                            FAJnlLine.Validate(Amount, FAJnlLineTmp.Amount);
                            FAJnlLine."No. of Depreciation Days" := FAJnlLineTmp."No. of Depreciation Days";
                            FAJnlLine."FA Error Entry No." := FAJnlLineTmp."FA Error Entry No.";
                            FAJnlNextLineNo := FAJnlNextLineNo + 10000;
                            FAJnlLine."Line No." := FAJnlNextLineNo;
                            FAJnlLine."Location Code" := FAJnlLineTmp."Location Code";
                            FAJnlLine."Employee No." := FAJnlLineTmp."Employee No.";
                            FAJnlLine."Depr. Period Starting Date" := FAJnlLineTmp."Depr. Period Starting Date";
                            FAJnlLine.Insert(true);

                            if Abs(FAJnlLine.Amount) >= MaxFAJnlAmount then begin
                                MaxFAJnlAmount := Abs(FAJnlLine.Amount);
                                MaxAmountFAJnlLineNo := FAJnlLine."Line No.";
                            end;

                        until FAJnlLineTmp.Next() = 0;

                        if DeprDiff <> 0 then begin
                            FAJnlLine."Line No." := MaxAmountFAJnlLineNo;
                            FAJnlLine.Find();
                            FAJnlLine.Validate(Amount, FAJnlLine.Amount - DeprDiff);
                            FAJnlLine.Modify();
                        end;
                    end;

                    if GenJnlLineTmp.FindSet() then begin
                        GenJnlLine.LockTable();
                        FAJnlSetup.GenJnlName(DeprBook, GenJnlLine, GenJnlNextLineNo);
                        NoSeries := FAJnlSetup.GetGenNoSeries(GenJnlLine);
                        if DocumentNo = '' then
                            DocumentNo2 := FAJnlSetup.GetGenJnlDocumentNo(GenJnlLine, DeprUntilDate, true)
                        else
                            DocumentNo2 := DocumentNo;

                    end;
                    if GenJnlLineTmp.FindSet() then begin
                        repeat
                            GenJnlLine.Init();
                            GenJnlLine."Line No." := 0;
                            FAJnlSetup.SetGenJnlTrailCodes(GenJnlLine);
                            LineNo := LineNo + 1;
                            Window.Update(3, LineNo);
                            GenJnlLine."Posting Date" := PostingDate;
                            GenJnlLine."FA Posting Date" := DeprUntilDate;
                            if GenJnlLine."Posting Date" = GenJnlLine."FA Posting Date" then
                                GenJnlLine."FA Posting Date" := 0D;
                            GenJnlLine."FA Posting Type" := GenJnlLineTmp."FA Posting Type";
                            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Fixed Asset";
                            GenJnlLine.Validate("Account No.", GenJnlLineTmp."Account No.");
                            GenJnlLine.Description := PostingDescription;
                            GenJnlLine."Document No." := DocumentNo2;
                            GenJnlLine."Posting No. Series" := NoSeries;
                            GenJnlLine.Validate("Depreciation Book Code", DeprBookCode);
                            GenJnlLine.Validate(Amount, GenJnlLineTmp.Amount);
                            GenJnlLine."No. of Depreciation Days" := GenJnlLineTmp."No. of Depreciation Days";
                            GenJnlLine."FA Error Entry No." := GenJnlLineTmp."FA Error Entry No.";
                            GenJnlNextLineNo := GenJnlNextLineNo + 10000;
                            GenJnlLine."Line No." := GenJnlNextLineNo;
                            GenJnlLine."Employee No." := GenJnlLineTmp."Employee No.";
                            GenJnlLine."FA Location Code" := GenJnlLineTmp."FA Location Code";
                            GenJnlLine."Depr. Period Starting Date" := GenJnlLineTmp."Depr. Period Starting Date";
                            GenJnlLine.Insert(true);
                            if BalAccount then
                                FAInsertGLAcc.GetBalAcc(GenJnlLine, GenJnlNextLineNo);

                            if Abs(GenJnlLine.Amount) >= MaxGenJnlAmount then begin
                                MaxGenJnlAmount := Abs(GenJnlLine.Amount);
                                MaxAmountGenJnlLineNo := GenJnlLine."Line No.";
                                MaxAmountGenJnlBalLineNo := GenJnlNextLineNo;
                            end;
                        until GenJnlLineTmp.Next() = 0;

                        if DeprDiff <> 0 then begin
                            GenJnlLine."Line No." := MaxAmountGenJnlLineNo;
                            GenJnlLine.Find();
                            GenJnlLine.Validate(Amount, GenJnlLine.Amount - DeprDiff);
                            GenJnlLine.Modify();

                            if BalAccount then begin
                                GenJnlLine."Line No." := MaxAmountGenJnlBalLineNo;
                                GenJnlLine.Find();
                                GenJnlLine.Validate(Amount, GenJnlLine.Amount + DeprDiff);
                                GenJnlLine.Modify();
                            end;
                        end;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    GenJnlLineTmp.Reset();
                    GenJnlLineTmp.DeleteAll();

                    FAJnlLineTmp.Reset();
                    FAJnlLineTmp.DeleteAll();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TestField("Tax Depreciation Rate");
                TestField("Depreciation Factor");
                CheckGroupElimination(Code);

                DeprRate := "Tax Depreciation Rate" * "Depreciation Factor";

                TotalDeprAmount := 0;
                GroupBookValue := CalcGroupBookValue(Code, DatePeriod."Period Start", NormalDate(DatePeriod."Period End"));
                GroupDeprAmount :=
                  DepreciationCalc.CalcRounding(DeprBookCode, GroupBookValue * DeprRate * 0.01);

                if TaxRegisterSetup."Write-off in Charges" and
                   (GroupBookValue < TaxRegisterSetup."Min. Group Balance")
                then begin
                    CheckGroupDepreciation(Code);
                    GroupDisposal(Code);
                    CurrReport.Skip();
                end;

                if not ChangeDetails then
                    PostingDescription := StrSubstNo(Text008, Format(Period, 0, '<Month Text>'), Date2DMY(Period, 3), Code);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DeprBookCode; DeprBookCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Depreciation Book';
                        TableRelation = "Depreciation Book";
                        ToolTip = 'Specifies the code for the depreciation book to be included in the report or batch job.';
                    }
                    field(AccountPeriod; AccountPeriod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Accounting Period';
                        ToolTip = 'Specifies the accounting period to include data for.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            PeriodReportManagement.SelectPeriod(Text, CalendarPeriod, ProgressiveTotal);
                            DatePeriod.Copy(CalendarPeriod);
                            PeriodReportManagement.PeriodSetup(DatePeriod, ProgressiveTotal);
                            RequestOptionsPage.Update();
                            exit(true);
                        end;

                        trigger OnValidate()
                        begin
                            if not PeriodReportManagement.ParseCaptionPeriodName(AccountPeriod, CalendarPeriod, ProgressiveTotal) then begin
                                PeriodReportManagement.InitPeriod(CalendarPeriod, 0);
                                PeriodReportManagement.SetCaptionPeriodYear(AccountPeriod, CalendarPeriod, ProgressiveTotal);
                            end;

                            DatePeriod.Copy(CalendarPeriod);
                            PeriodReportManagement.PeriodSetup(DatePeriod, ProgressiveTotal);

                            Period := DatePeriod."Period Start";
                            SetProperties();
                        end;
                    }
                    field(From; DatePeriod."Period Start")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'From';
                        Editable = false;
                        ToolTip = 'Specifies the starting point.';
                    }
                    field("To"; DatePeriod."Period End")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'To';
                        Editable = false;
                        ToolTip = 'Specifies the ending point.';
                    }
                    field(ChangeDetails; ChangeDetails)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Change Details';
                    }
                    field(DeprUntilDate; DeprUntilDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'FA Posting Date';
                        Editable = ChangeDetails;
                        ToolTip = 'Specifies the posting date of the related fixed asset transaction, such as a depreciation.';

                        trigger OnValidate()
                        begin
                            if DeprUntilDate <> 0D then
                                if (DeprUntilDate < Period) or (DeprUntilDate > CalcDate('<CM>', Period)) then
                                    Error(Text12407);
                        end;
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        Editable = ChangeDetails;
                        ToolTip = 'Specifies the posting date of the entries that you want to include in the report or batch job.';

                        trigger OnValidate()
                        begin
                            if PostingDate <> 0D then
                                if (PostingDate < Period) or (PostingDate > CalcDate('<CM>', Period)) then
                                    Error(Text12409);
                        end;
                    }
                    field(DocumentNo; DocumentNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        Editable = ChangeDetails;
                        ToolTip = 'Specifies the number of the related document.';
                    }
                    field(PostingDescription; PostingDescription)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Description';
                        Editable = ChangeDetails;
                        ToolTip = 'Specifies the description that will be added to the resulting posting.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            PeriodReportManagement.InitPeriod(CalendarPeriod, 0);
            PeriodReportManagement.SetCaptionPeriodYear(AccountPeriod, CalendarPeriod, ProgressiveTotal);
            DatePeriod.Copy(CalendarPeriod);
            PeriodReportManagement.PeriodSetup(DatePeriod, ProgressiveTotal);

            if DeprBookCode = '' then begin
                TaxRegisterSetup.Get();
                TaxRegisterSetup.TestField("Tax Depreciation Book");
                DeprBookCode := TaxRegisterSetup."Tax Depreciation Book";
            end;

            Period := DatePeriod."Period Start";
            SetProperties();

            ChangeDetails := false;

            BalAccount := true;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        TaxRegisterSetup.Get();
        DeprBook.Get(DeprBookCode);
        DeprBook.TestField("Allow Depreciation", true);

        Window.Open(
          Text003 +
          Text004 +
          Text005);
    end;

    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLineTmp: Record "Gen. Journal Line" temporary;
        FAJnlLine: Record "FA Journal Line";
        FAJnlLineTmp: Record "FA Journal Line" temporary;
        FAJnlSetup: Record "FA Journal Setup";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        TaxRegisterSetup: Record "Tax Register Setup";
        CalendarPeriod: Record Date;
        DatePeriod: Record Date;
        DepreciationCalc: Codeunit "Depreciation Calculation";
        PeriodReportManagement: Codeunit PeriodReportManagement;
        FAInsertGLAcc: Codeunit "FA Insert G/L Account";
        Window: Dialog;
        Period: Date;
        PostingDate: Date;
        DeprUntilDate: Date;
        AccountPeriod: Text[30];
        PostingDescription: Text[50];
        ProgressiveTotal: Boolean;
        ChangeDetails: Boolean;
        BalAccount: Boolean;
        NumberOfDays: Integer;
        FAJnlNextLineNo: Integer;
        GenJnlNextLineNo: Integer;
        LineNo: Integer;
        NoSeries: Code[20];
        DeprBookCode: Code[10];
        DocumentNo: Code[20];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'Fixed Asset %1 has been disposed %2. Depreciation cannot be calculated for %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label 'Depreciating fixed asset      #1##########\';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text004: Label 'Not depreciating fixed asset  #2##########\';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text005: Label 'Inserting journal lines       #3##########';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text006: Label 'Group %4 cannot be written off.\';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text007: Label 'There is posted depreciation later then %1.\for FA Code %2\FA Depreciation Book Code %3 ';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text008: Label '%1 %2 Group Depreciation FA (%3)';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text12400: Label 'Previous periods Depreciation was not calculated';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text12401: Label 'Depreciation was already calculated';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12402: Label '\for Depr. Period Starting Date %1\FA Code %2\FA Depreciation Book Code %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        DocumentNo2: Code[20];
        TotalDeprAmount: Decimal;
        GroupDeprAmount: Decimal;
        GroupBookValue: Decimal;
        DeprRate: Decimal;
        DeprDiff: Decimal;
#pragma warning disable AA0074
        Text12407: Label 'FA Posting Date must be into Accounting Period.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text12409: Label 'Posting Date must be into Accounting Period.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text12410: Label 'Write-off the cost of group';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text12411: Label 'DP-';
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure SetProperties()
    begin
        PostingDate := DatePeriod."Period End";
        DeprUntilDate := DatePeriod."Period End";
        if Date2DMY(DatePeriod."Period Start", 2) > 9 then
            DocumentNo := Text12411 + Format(DatePeriod."Period Start", 0, '<Year>-<Month>')
        else
            DocumentNo := Text12411 + Format(DatePeriod."Period Start", 2, '<Year>') + '-0' + Format(DatePeriod."Period Start", 0, '<Month>');
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewDeprBookCode: Code[10]; NewPostingDate: Date; NewDeprUntilDate: Date; NewDocumentNo: Code[20]; NewPostingDescription: Text[50])
    begin
        ClearAll();
        DeprBookCode := NewDeprBookCode;
        PostingDate := NewPostingDate;
        DocumentNo := NewDocumentNo;
        PostingDescription := NewPostingDescription;
        DeprUntilDate := NewDeprUntilDate;
        BalAccount := true;
    end;

    [Scope('OnPrem')]
    procedure CalcGroupBookValue(DepreciationGroupCode: Code[10]; StartDate: Date; EndDate: Date) Amount: Decimal
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.SetCurrentKey("Depreciation Group");
        FixedAsset.SetRange("Depreciation Group", DepreciationGroupCode);
        FixedAsset.SetRange(Blocked, false);
        if FixedAsset.FindSet() then
            repeat
                if FADeprBook.Get(FixedAsset."No.", DeprBookCode) then
                    if CheckDeprBook() then
                        Amount := Amount + GetBookValue(FixedAsset."No.", StartDate, EndDate);
            until FixedAsset.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GroupDisposal(DepreciationGroupCode: Code[10])
    var
        FixedAsset: Record "Fixed Asset";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        FAJnlPostLine: Codeunit "FA Jnl.-Post Line";
    begin
        FixedAsset.SetCurrentKey("Depreciation Group");
        FixedAsset.SetRange("Depreciation Group", DepreciationGroupCode);
        FixedAsset.SetRange(Blocked, false);
        if FixedAsset.FindSet() then
            repeat
                if FADeprBook.Get(FixedAsset."No.", DeprBookCode) then
                    if CheckDeprBook() then
                        if not DeprBook."G/L Integration - Depreciation" or FixedAsset."Budgeted Asset" then begin
                            FAJnlLine.LockTable();
                            FAJnlSetup.FAJnlName(DeprBook, FAJnlLine, FAJnlNextLineNo);
                            NoSeries := FAJnlSetup.GetFANoSeries(FAJnlLine);
                            if DocumentNo = '' then
                                DocumentNo2 := FAJnlSetup.GetFAJnlDocumentNo(FAJnlLine, DeprUntilDate, true)
                            else
                                DocumentNo2 := DocumentNo;

                            FAJnlLine.Init();
                            FAJnlSetup.SetFAJnlTrailCodes(FAJnlLine);
                            FAJnlLine."Posting Date" := PostingDate;
                            FAJnlLine."FA Posting Date" := DeprUntilDate;
                            if FAJnlLine."Posting Date" = FAJnlLine."FA Posting Date" then
                                FAJnlLine."Posting Date" := 0D;
                            FAJnlLine.Validate("FA Posting Type", FAJnlLine."FA Posting Type"::Disposal);
                            FAJnlLine.Validate("FA No.", FixedAsset."No.");
                            FAJnlLine."Document No." := DocumentNo2;
                            FAJnlLine."Posting No. Series" := NoSeries;
                            FAJnlLine.Description := Text12410;
                            FAJnlLine.Validate("Depreciation Book Code", DeprBookCode);
                            FAJnlLine."Location Code" := FixedAsset."FA Location Code";
                            FAJnlLine."Employee No." := FixedAsset."Responsible Employee";
                            FAJnlLine."Depr. Group Elimination" := true;
                            FAJnlLine."Depr. until FA Posting Date" := false;

                            FAJnlPostLine.FAJnlPostLine(FAJnlLine, true);
                        end else begin
                            GenJnlLine.LockTable();
                            FAJnlSetup.GenJnlName(DeprBook, GenJnlLine, GenJnlNextLineNo);
                            NoSeries := FAJnlSetup.GetGenNoSeries(GenJnlLine);
                            if DocumentNo = '' then
                                DocumentNo2 := FAJnlSetup.GetGenJnlDocumentNo(GenJnlLine, DeprUntilDate, true)
                            else
                                DocumentNo2 := DocumentNo;

                            GenJnlLine.Init();
                            FAJnlSetup.SetGenJnlTrailCodes(GenJnlLine);
                            LineNo := LineNo + 1;
                            Window.Update(3, LineNo);
                            GenJnlLine."Posting Date" := PostingDate;
                            GenJnlLine."FA Posting Date" := DeprUntilDate;
                            if GenJnlLine."Posting Date" = GenJnlLine."FA Posting Date" then
                                GenJnlLine."FA Posting Date" := 0D;
                            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Fixed Asset";
                            GenJnlLine.Validate("FA Posting Type", GenJnlLine."FA Posting Type"::Disposal);
                            GenJnlLine.Validate("Account No.", FixedAsset."No.");
                            GenJnlLine.Description := Text12410;
                            GenJnlLine."Document No." := DocumentNo2;
                            GenJnlLine."Posting No. Series" := NoSeries;
                            GenJnlLine.Validate("Depreciation Book Code", DeprBookCode);
                            GenJnlLine."Employee No." := FixedAsset."Responsible Employee";
                            GenJnlLine."FA Location Code" := FixedAsset."FA Location Code";
                            GenJnlLine."Depr. Group Elimination" := true;
                            GenJnlLine."Depr. until FA Posting Date" := false;

                            GenJnlPostLine.RunWithCheck(GenJnlLine);
                        end;
            until FixedAsset.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetBookValue(FixedAssetNo: Code[20]; StartDate: Date; EndDate: Date): Decimal
    var
        BookValue: Decimal;
        DeprBonus: Decimal;
    begin
        FADeprBook.Get(FixedAssetNo, DeprBookCode);
        FADeprBook.TestField("Depreciation Method", FADeprBook."Depreciation Method"::"DB/SL-RU Tax Group");
        FADeprBook.SetFilter("FA Posting Date Filter", '..%1', StartDate);
        FADeprBook.CalcFields("Book Value");
        BookValue := FADeprBook."Book Value";
        FADeprBook.SetFilter("FA Posting Date Filter", '%1..%2', StartDate, EndDate);
        FADeprBook.CalcFields("Depreciation Bonus");
        DeprBonus := FADeprBook."Depreciation Bonus";
        exit(BookValue + DeprBonus);
    end;

    [Scope('OnPrem')]
    procedure CheckGroupElimination(DeprGroup: Code[10])
    var
        FixedAsset: Record "Fixed Asset";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FixedAsset.SetCurrentKey("Depreciation Group");
        FixedAsset.SetRange("Depreciation Group", DeprGroup);
        FixedAsset.SetRange(Blocked, false);
        if FixedAsset.FindSet() then
            repeat
                if FADeprBook.Get(FixedAsset."No.", DeprBookCode) then
                    if FADeprBook."Depreciation Method" = FADeprBook."Depreciation Method"::"DB/SL-RU Tax Group" then begin
                        FALedgerEntry.SetCurrentKey(
                          "FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "FA Posting Date",
                          "Part of Book Value", "Reclassification Entry", "FA Location Code", "Global Dimension 1 Code",
                          "Global Dimension 2 Code", "Initial Acquisition", "Employee No.", "Depr. Bonus", "Depr. Group Elimination");
                        FALedgerEntry.SetRange("FA No.", FixedAsset."No.");
                        FALedgerEntry.SetRange("Depreciation Book Code", DeprBookCode);
                        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Proceeds on Disposal");
                        FALedgerEntry.SetFilter("FA Posting Date", '%1..%2', DatePeriod."Period Start", DatePeriod."Period End");
                        FALedgerEntry.SetRange("Depr. Group Elimination", true);
                        FALedgerEntry.SetRange(Reversed, false);
                        if FALedgerEntry.FindFirst() then
                            Error(Text002,
                              FixedAsset."No.",
                              FALedgerEntry."FA Posting Date",
                              AccountPeriod);
                    end;
            until FixedAsset.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ExistingDeprPeriods(FANo: Code[20]; DeprBookCode: Code[10]; StartDate: Date) NoOfPeriods: Integer
    var
        FALedgEntry: Record "FA Ledger Entry";
        DeprCalculation: Codeunit "Depreciation Calculation";
    begin
        NoOfPeriods := 0;
        DeprCalculation.SetFAFilter(FALedgEntry, FANo, DeprBookCode, true);
        FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::Depreciation);
        FALedgEntry.SetRange("Depr. Bonus", false);
        FALedgEntry.SetRange("FA Posting Date", StartDate, CalcDate('<CM>', StartDate));
        if FALedgEntry.FindFirst() then
            NoOfPeriods := 1;
        // depreciation for current month already exists
        FALedgEntry.SetRange("FA Posting Date", CalcDate('<-1M>', StartDate), CalcDate('<-1M+CM>', StartDate));
        if FALedgEntry.FindFirst() then
            NoOfPeriods := NoOfPeriods + 2;
        // depreciation for previous month already exists
        FALedgEntry.SetFilter("FA Posting Date", '%1..', CalcDate('<+1M>', StartDate));
        if FALedgEntry.FindFirst() then
            NoOfPeriods := 4; // depreciation for next month already exists
        exit(NoOfPeriods);
    end;

    [Scope('OnPrem')]
    procedure CheckGroupDepreciation(DeprGroup: Code[10])
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.SetCurrentKey("Depreciation Group");
        FixedAsset.SetRange("Depreciation Group", DeprGroup);
        FixedAsset.SetRange(Blocked, false);
        if FixedAsset.FindSet() then
            repeat
                if FADeprBook.Get(FixedAsset."No.", DeprBookCode) then
                    if CheckDeprBook() then
                        case ExistingDeprPeriods(FixedAsset."No.", DeprBookCode, Period) of
                            0:
                                if FADeprBook."Depreciation Starting Date" < DatePeriod."Period Start" then // it's not first depr
                                    Error(Text006 + Text12400 + Text12402, Period, FixedAsset."No.", DeprBookCode, DeprGroup);
                            1, 3:
                                Error(Text006 + Text12401 + Text12402, Period, FixedAsset."No.", DeprBookCode, DeprGroup);
                            4:
                                Error(Text006 + Text007, CalcDate('<+1M>', Period), FixedAsset."No.", DeprBookCode, DeprGroup);
                        end;
            until FixedAsset.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CheckDeprBook(): Boolean
    begin
        exit(
          (FADeprBook."Depreciation Method" = FADeprBook."Depreciation Method"::"DB/SL-RU Tax Group") and
          (FADeprBook."Depreciation Starting Date" <= DatePeriod."Period Start") and
          (FADeprBook."Acquisition Date" <> 0D) and
          (FADeprBook."Disposal Date" = 0D) and
          (FADeprBook."Acquisition Date" <= DatePeriod."Period Start"));
    end;
}

