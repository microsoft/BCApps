#pragma warning disable AA0247
report 17302 "Calculate FE Depreciation"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Calculate FE Depreciation';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            DataItemTableView = sorting("No.") where("FA Type" = const("Future Expense"));
            RequestFilterFields = "No.";
            dataitem("FA Depreciation Book"; "FA Depreciation Book")
            {
                DataItemLink = "FA No." = field("No.");
                DataItemTableView = sorting("Depreciation Book Code", "FA No.");

                trigger OnAfterGetRecord()
                begin
                    if "Depreciation Book Code" <> DeprBook.Code then begin
                        DeprBook.Get("Depreciation Book Code");
                        if (DeprUntilDate <> PostingDate) and DeprBook."Use Same FA+G/L Posting Dates" then
                            Error(
                              Text002,
                              FAJnlLine.FieldCaption("FA Posting Date"),
                              FAJnlLine.FieldCaption("Posting Date"),
                              DeprBook.FieldCaption("Use Same FA+G/L Posting Dates"),
                              false,
                              DeprBook.TableCaption(),
                              DeprBook.FieldCaption(Code),
                              DeprBook.Code);
                        if not (DeprBook."No. of Days in Fiscal Year" in [0, 360]) then
                            if not Confirm(Text12412, false, DeprBook.Code, DeprBook."No. of Days in Fiscal Year") then
                                CurrReport.Break();
                    end;

                    if not (DeprBook."Posting Book Type" in
                            [DeprBook."Posting Book Type"::Accounting, DeprBook."Posting Book Type"::"Tax Accounting"])
                    then
                        exit;

                    Clear(CalculateDepr);
                    CalculateDepr.Calculate(
                      DeprAmount, Custom1Amount, NumberOfDays, Custom1NumberOfDays,
                      "FA No.", "Depreciation Book Code", DeprUntilDate, EntryAmounts, 0D, DaysInPeriod);
                    if (DeprAmount <> 0) or (Custom1Amount <> 0) then
                        Window.Update(1, "FA No.")
                    else
                        Window.Update(2, "FA No.");

                    if Custom1Amount <> 0 then
                        if not DeprBook."G/L Integration - Custom 1" or "Fixed Asset"."Budgeted Asset" then begin
                            FAJnlSetup.FAJnlName(DeprBook, FAJnlLineTmp, JnlNextLineNoLoc);
                            CheckFEJnlTemplate(FAJnlLineTmp."Journal Template Name");
                            FAJnlLineTmp."FA No." := "FA No.";
                            FAJnlLineTmp."FA Posting Type" := FAJnlLineTmp."FA Posting Type"::"Custom 1";
                            FAJnlLineTmp.Amount := Custom1Amount;
                            FAJnlLineTmp."No. of Depreciation Days" := Custom1NumberOfDays;
                            FAJnlLineTmp."Line No." := FAJnlLineTmp."Line No." + 1;
                            FAJnlLineTmp."Location Code" := "Fixed Asset"."FA Location Code";
                            FAJnlLineTmp."Employee No." := "Fixed Asset"."Responsible Employee";
                            FAJnlLineTmp."Depr. Period Starting Date" := Period;
                            FAJnlLineTmp."Depreciation Book Code" := "Depreciation Book Code";
                            FAJnlLineTmp.Insert();
                        end else begin
                            FAJnlSetup.GenJnlName(DeprBook, GenJnlLine, JnlNextLineNoLoc);
                            GenJnlLineTmp."Account No." := "FA No.";
                            GenJnlLineTmp."FA Posting Type" := GenJnlLineTmp."FA Posting Type"::"Custom 1";
                            GenJnlLineTmp.Amount := Custom1Amount;
                            GenJnlLineTmp."No. of Depreciation Days" := Custom1NumberOfDays;
                            GenJnlLineTmp."Line No." := GenJnlLineTmp."Line No." + 1;
                            GenJnlLineTmp."FA Location Code" := "Fixed Asset"."FA Location Code";
                            GenJnlLineTmp."Employee No." := "Fixed Asset"."Responsible Employee";
                            GenJnlLineTmp."Depr. Period Starting Date" := Period;
                            GenJnlLineTmp."Depreciation Book Code" := "Depreciation Book Code";
                            GenJnlLineTmp.Insert();
                        end;

                    if DeprAmount <> 0 then
                        if not DeprBook."G/L Integration - Depreciation" or "Fixed Asset"."Budgeted Asset" then begin
                            FAJnlSetup.FAJnlName(DeprBook, FAJnlLineTmp, JnlNextLineNoLoc);
                            CheckFEJnlTemplate(FAJnlLineTmp."Journal Template Name");
                            FAJnlLineTmp."FA No." := "FA No.";
                            FAJnlLineTmp."FA Posting Type" := FAJnlLineTmp."FA Posting Type"::Depreciation;
                            FAJnlLineTmp.Amount := DeprAmount;
                            FAJnlLineTmp."No. of Depreciation Days" := NumberOfDays;
                            FAJnlLineTmp."Line No." := FAJnlLineTmp."Line No." + 1;
                            FAJnlLineTmp."Depr. Period Starting Date" := Period;
                            FAJnlLineTmp."Location Code" := "Fixed Asset"."FA Location Code";
                            FAJnlLineTmp."Employee No." := "Fixed Asset"."Responsible Employee";
                            FAJnlLineTmp."Depreciation Book Code" := "Depreciation Book Code";
                            FAJnlLineTmp.Insert();
                        end else begin
                            FAJnlSetup.GenJnlName(DeprBook, GenJnlLine, JnlNextLineNoLoc);
                            GenJnlLineTmp."Account No." := "FA No.";
                            GenJnlLineTmp."FA Posting Type" := GenJnlLineTmp."FA Posting Type"::Depreciation;
                            GenJnlLineTmp.Amount := DeprAmount;
                            GenJnlLineTmp."No. of Depreciation Days" := NumberOfDays;
                            GenJnlLineTmp."Line No." := GenJnlLineTmp."Line No." + 1;
                            GenJnlLineTmp."FA Location Code" := "Fixed Asset"."FA Location Code";
                            GenJnlLineTmp."Employee No." := "Fixed Asset"."Responsible Employee";
                            GenJnlLineTmp."Depr. Period Starting Date" := Period;
                            GenJnlLineTmp."Depreciation Book Code" := "Depreciation Book Code";
                            GenJnlLineTmp.Insert();
                        end;
                end;

                trigger OnPreDataItem()
                begin
                    if DepreciationBookFilter <> '' then
                        SetFilter("Depreciation Book Code", DepreciationBookFilter);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if Inactive or Blocked or "Undepreciable FA" then
                    CurrReport.Skip();
            end;

            trigger OnPostDataItem()
            begin
                FAJnlLineTmp.Reset();
                if FAJnlLineTmp.Find('-') then begin
                    FAJnlLine.LockTable();
                    repeat
                        if (FAJnlLineTmp."Journal Template Name" <> FAJnlLine."Journal Template Name") or
                           (FAJnlLineTmp."Journal Batch Name" <> FAJnlLine."Journal Batch Name")
                        then begin
                            DeprBook.Get(FAJnlLineTmp."Depreciation Book Code");
                            FAJnlSetup.FAJnlName(DeprBook, FAJnlLine, FAJnlNextLineNo);
                            NoSeries := FAJnlSetup.GetFANoSeries(FAJnlLine);
                            if DocumentNo = '' then
                                DocumentNo2 := FAJnlSetup.GetFAJnlDocumentNo(FAJnlLine, DeprUntilDate, true)
                            else
                                DocumentNo2 := DocumentNo;
                        end;
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
                        FAJnlLine.Validate("Depreciation Book Code", FAJnlLineTmp."Depreciation Book Code");
                        FAJnlLine.Validate(Amount, FAJnlLineTmp.Amount);
                        FAJnlLine."No. of Depreciation Days" := FAJnlLineTmp."No. of Depreciation Days";
                        FAJnlLine."FA Error Entry No." := FAJnlLineTmp."FA Error Entry No.";
                        FAJnlNextLineNo := FAJnlNextLineNo + 10000;
                        FAJnlLine."Line No." := FAJnlNextLineNo;
                        FAJnlLine."Location Code" := FAJnlLineTmp."Location Code";
                        FAJnlLine."Employee No." := FAJnlLineTmp."Employee No.";
                        FAJnlLine."Depr. Period Starting Date" := FAJnlLineTmp."Depr. Period Starting Date";
                        FAJnlLine.Insert(true);
                    until FAJnlLineTmp.Next() = 0;
                end;

                GenJnlLineTmp.Reset();
                if GenJnlLineTmp.Find('-') then begin
                    GenJnlLine.LockTable();
                    repeat
                        if (GenJnlLineTmp."Journal Template Name" <> GenJnlLine."Journal Template Name") or
                           (GenJnlLineTmp."Journal Batch Name" <> GenJnlLine."Journal Batch Name")
                        then begin
                            DeprBook.Get(GenJnlLineTmp."Depreciation Book Code");
                            FAJnlSetup.GenJnlName(DeprBook, GenJnlLine, GenJnlNextLineNo);
                            NoSeries := FAJnlSetup.GetGenNoSeries(GenJnlLine);
                            if DocumentNo = '' then
                                DocumentNo2 := FAJnlSetup.GetGenJnlDocumentNo(GenJnlLine, DeprUntilDate, true)
                            else
                                DocumentNo2 := DocumentNo;
                        end;
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
                        GenJnlLine.Validate("Depreciation Book Code", GenJnlLineTmp."Depreciation Book Code");
                        GenJnlLine.Validate(Amount, GenJnlLineTmp.Amount);
                        GenJnlLine."No. of Depreciation Days" := GenJnlLineTmp."No. of Depreciation Days";
                        GenJnlLine."FA Error Entry No." := GenJnlLineTmp."FA Error Entry No.";
                        GenJnlNextLineNo := GenJnlNextLineNo + 10000;
                        GenJnlLine."Line No." := GenJnlNextLineNo;
                        GenJnlLine."Employee No." := GenJnlLineTmp."Employee No.";
                        GenJnlLine."FA Location Code" := GenJnlLineTmp."FA Location Code";
                        GenJnlLine."Depr. Period Starting Date" := GenJnlLineTmp."Depr. Period Starting Date";
                        GenJnlLine.Insert(true);
                        if BalAccount then begin
                            FAInsertGLAcc.GetBalAcc(GenJnlLine);
                            if GenJnlLine.FindLast() then;
                            GenJnlNextLineNo := GenJnlLine."Line No.";
                        end;
                    until GenJnlLineTmp.Next() = 0;
                end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DepreciationBookFilter; DepreciationBookFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Depreciation Book Filter';
                        TableRelation = "Depreciation Book";
                    }
                    field(AccountingPeriod; AccountPeriod)
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
                            DatePeriod.Copy(CalendarPeriod);
                            PeriodReportManagement.PeriodSetup(DatePeriod, ProgressiveTotal);

                            Period := DatePeriod."Period Start";
                            SetProperties();
                            AccountPeriodOnAfterValidate();
                        end;
                    }
                    field("<Control1210005>"; DatePeriod."Period Start")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'From';
                        Editable = false;
                        ToolTip = 'Specifies the starting point.';
                    }
                    field("<Control1210003>"; DatePeriod."Period End")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'To';
                        Editable = false;
                        ToolTip = 'Specifies the ending point.';
                    }
                    field(ChangeDetails; Details)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Change Details';

                        trigger OnValidate()
                        begin
                            DaysFieldEnable := Details;
                        end;
                    }
                    field(DeprDate; DeprUntilDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'FA Posting Date';
                        Enabled = Details;
                        ToolTip = 'Specifies the posting date of the related fixed asset transaction, such as a depreciation.';

                        trigger OnValidate()
                        begin
                            if DeprUntilDate <> 0D then
                                if (DeprUntilDate < Period) or (DeprUntilDate > CalcDate('<CM>', Period)) then
                                    Error(Text12407);
                        end;
                    }
                    field(PostDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        Enabled = Details;
                        ToolTip = 'Specifies the posting date of the entries that you want to include in the report or batch job.';

                        trigger OnValidate()
                        begin
                            if PostingDate <> 0D then
                                if (PostingDate < Period) or (PostingDate > CalcDate('<CM>', Period)) then
                                    Error(Text12409);
                        end;
                    }
                    field(DocNo; DocumentNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        Enabled = Details;
                        ToolTip = 'Specifies the number of the related document.';
                    }
                    field(PostingDescr; PostingDescription)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Description';
                        Enabled = Details;
                        ToolTip = 'Specifies the description that will be added to the resulting posting.';
                    }
                    field(UseNumbDays; UseForceNoOfDays)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use Force No. of Days';
                        Enabled = Details;

                        trigger OnValidate()
                        begin
                            if not UseForceNoOfDays then
                                DaysInPeriod := 0;
                            DaysFieldEnable := UseForceNoOfDays;
                        end;
                    }
                    field(DaysField; DaysInPeriod)
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'Force No. of Days';
                        Enabled = DaysFieldEnable;
                        MinValue = 0;
                    }
                    field(BalAccount; BalAccount)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Insert Bal. Account';
                        Enabled = Details;
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

            Period := DatePeriod."Period Start";
            SetProperties();

            UseForceNoOfDays := true;
            DaysInPeriod := 30;
            BalAccount := true;
            Details := false;

            if not UseForceNoOfDays then
                DaysInPeriod := 0;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if DeprUntilDate = 0D then
            Error(Text000, FAJnlLine.FieldCaption("FA Posting Date"));
        if PostingDate = 0D then
            PostingDate := DeprUntilDate;
        if UseForceNoOfDays and (DaysInPeriod = 0) then
            Error(Text001);

        Window.Open(
          Text003 +
          Text004 +
          Text005);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You must specify %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text001: Label 'Force No. of Days must be activated.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label '%1 and %2 must be identical. %3 must be %4 in %5 %6 = %7.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label 'Depreciating future expense      #1##########\';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text004: Label 'Not depreciating future expense  #2##########\';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text005: Label 'Inserting journal lines          #3##########';
#pragma warning restore AA0470
#pragma warning restore AA0074
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLineTmp: Record "Gen. Journal Line" temporary;
        FAJnlLine: Record "FA Journal Line";
        FAJnlLineTmp: Record "FA Journal Line" temporary;
        DeprBook: Record "Depreciation Book";
        FAJnlSetup: Record "FA Journal Setup";
        CalendarPeriod: Record Date;
        DatePeriod: Record Date;
        CalculateDepr: Codeunit "Calculate Depreciation";
        FAInsertGLAcc: Codeunit "FA Insert G/L Account";
        PeriodReportManagement: Codeunit PeriodReportManagement;
        Window: Dialog;
        DeprUntilDate: Date;
        UseForceNoOfDays: Boolean;
        PostingDate: Date;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        NoSeries: Code[20];
        PostingDescription: Text[50];
        BalAccount: Boolean;
        DaysInPeriod: Integer;
        FAJnlNextLineNo: Integer;
        GenJnlNextLineNo: Integer;
        LineNo: Integer;
        Period: Date;
#pragma warning disable AA0074
        Text12407: Label 'FE Posting Date must be into Accounting Period.';
#pragma warning restore AA0074
        DeprAmount: Decimal;
        Custom1Amount: Decimal;
        NumberOfDays: Integer;
        Custom1NumberOfDays: Integer;
        EntryAmounts: array[4] of Decimal;
        JnlNextLineNoLoc: Integer;
        AccountPeriod: Text[30];
        ProgressiveTotal: Boolean;
#pragma warning disable AA0074
        Text12409: Label 'Posting Date must be into Accounting Period.';
#pragma warning restore AA0074
        Details: Boolean;
#pragma warning disable AA0074
        Text12411: Label 'FED-';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text12410: Label ' FE Depreciation';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12412: Label 'No. of Days in Fiscal Year for Depr. Book %1 = %2 will calculate incorrect depreciation amounts. Continue?';
#pragma warning restore AA0470
#pragma warning restore AA0074
        DepreciationBookFilter: Code[250];
        DaysFieldEnable: Boolean;

    [Scope('OnPrem')]
    procedure SetProperties()
    begin
        PostingDate := DatePeriod."Period End";
        DeprUntilDate := DatePeriod."Period End";
        PostingDescription := Format(DatePeriod."Period Start", 0, '<Month Text> ') +
          Format(Date2DMY(DatePeriod."Period Start", 3)) + Text12410;
        if Date2DMY(DatePeriod."Period Start", 2) > 9 then
            DocumentNo := Text12411 + Format(DatePeriod."Period Start", 0, '<Year>-<Month>')
        else
            DocumentNo := Text12411 + Format(DatePeriod."Period Start", 2, '<Year>') + '-0' + Format(DatePeriod."Period Start", 0, '<Month>');
    end;

    [Scope('OnPrem')]
    procedure CheckFEJnlTemplate(JnlTemplateName: Code[10])
    var
        FAJnlTemplate: Record "FA Journal Template";
    begin
        FAJnlTemplate.Get(JnlTemplateName);
        FAJnlTemplate.TestField(Type, FAJnlTemplate.Type::"Future Expenses");
    end;

    local procedure AccountPeriodOnAfterValidate()
    begin
        UseForceNoOfDays := true;
        DaysInPeriod := 30;
        DaysFieldEnable := false;
    end;
}

