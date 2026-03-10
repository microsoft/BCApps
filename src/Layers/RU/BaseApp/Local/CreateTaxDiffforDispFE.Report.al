#pragma warning disable AA0247
report 17305 "Create Tax Diff. for Disp. FE"
{
    Caption = 'Create Tax Diff. for Disp. FE';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Future Expense"; "Fixed Asset")
        {
            DataItemTableView = sorting("No.") where("FA Type" = const("Future Expense"), Blocked = const(false), Inactive = const(false));
            dataitem(DeprecnBookAccount; "Depreciation Book")
            {
                DataItemTableView = sorting(Code) where("Posting Book Type" = const(Accounting));
                dataitem(FEDepreciationBookAccount; "FA Depreciation Book")
                {
                    CalcFields = Depreciation;
                    DataItemLink = "Depreciation Book Code" = field(Code);
                    DataItemTableView = sorting("FA No.", "Depreciation Book Code");

                    trigger OnAfterGetRecord()
                    begin
                        CalcFields("Book Value on Disposal", "Acquisition Cost", "Book Value");
                        if "Book Value" = 0 then begin
                            BookValueOnDisposal += "Book Value on Disposal";
                            AcquisitionCost += "Acquisition Cost";
                            if DisposalDate = 0D then
                                DisposalDate := "Disposal Date"
                            else
                                TestField("Disposal Date", DisposalDate);
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange("FA No.", "Future Expense"."No.");
                        SetRange("Disposal Date", CalendarPeriod."Period Start", CalendarPeriod."Period End");
                    end;
                }
            }
            dataitem(DeprecnBookTaxAccount; "Depreciation Book")
            {
                DataItemTableView = sorting(Code) where("Posting Book Type" = const("Tax Accounting"));
                dataitem(FEDepreciationBookTaxAccount; "FA Depreciation Book")
                {
                    CalcFields = Depreciation;
                    DataItemLink = "Depreciation Book Code" = field(Code);
                    DataItemTableView = sorting("FA No.", "Depreciation Book Code") where(Depreciation = filter(<> 0));

                    trigger OnAfterGetRecord()
                    begin
                        CalcFields("Book Value on Disposal", "Acquisition Cost");
                        TaxBookValueOnDisposal += "Book Value on Disposal";
                        TaxAcquisitionCost += "Acquisition Cost";
                        TestField("Disposal Date", DisposalDate);
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange("FA No.", "Future Expense"."No.");
                        SetRange("Disposal Date", CalendarPeriod."Period Start", CalendarPeriod."Period End");
                    end;
                }

                trigger OnPreDataItem()
                begin
                    if DisposalDate = 0D then
                        CurrReport.Break();
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;

                trigger OnAfterGetRecord()
                begin
                    xRecTaxDiffJnlLine := TaxDiffJnlLine;
                    TaxDiffJnlLine."Line No." += 10000;
                    TaxDiffJnlLine.Init();
                    TaxDiffJnlLine.SetUpNewLine(xRecTaxDiffJnlLine);
                    TaxDiffJnlLine."Posting Date" := PostingDate;
                    if TaxDiffJnlLine."Document No." = '' then
                        TaxDiffJnlLine."Document No." := DocumentNo;
                    TaxDiffJnlLine.Description := PostingDescription;
                    TaxDiffJnlLine."Source Type" := TaxDiffJnlLine."Source Type"::"Future Expense";
                    TaxDiffJnlLine.Validate("Source No.", "Future Expense"."No.");
                    TaxDiffJnlLine."Amount (Base)" := Abs(BookValueOnDisposal) + Abs(AcquisitionCost);
                    TaxDiffJnlLine.Validate(
                      "Amount (Tax)", Abs(TaxBookValueOnDisposal) + Abs(TaxAcquisitionCost));
                    if (TaxDiff."Tax Period Limited" <> TaxDiff."Tax Period Limited"::" ") and (DisposalDate <> 0D) then begin
                        TaxDiffJnlLine."Disposal Mode" := TaxDiffJnlLine."Disposal Mode"::Transform;
                        TaxDiffJnlLine."Disposal Date" := DisposalDate;
                    end else begin
                        TaxDiffJnlLine.Validate("Disposal Mode", TaxDiffJnlLine."Disposal Mode"::"Write Down");
                        TaxDiffJnlLine.Validate("Partial Disposal", true);
                    end;
                    TaxDiffJnlLine.Insert();
                end;

                trigger OnPreDataItem()
                begin
                    if DisposalDate = 0D then
                        CurrReport.Break();

                    if (BookValueOnDisposal = 0) and (AcquisitionCost = 0) and
                       (TaxBookValueOnDisposal = 0) and (TaxAcquisitionCost = 0)
                    then
                        CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not TaxDiff.Get("Tax Difference Code") then
                    CurrReport.Skip();

                if not Choice[Choices::Fixed] and (TaxDiff.Type = TaxDiff.Type::Constant) or
                   not Choice[Choices::"Temporary"] and (TaxDiff.Type = TaxDiff.Type::"Temporary")
                then
                    CurrReport.Skip();

                BookValueOnDisposal := 0;
                AcquisitionCost := 0;
                TaxAcquisitionCost := 0;
                TaxBookValueOnDisposal := 0;
                DisposalDate := 0D;
            end;

            trigger OnPreDataItem()
            begin
                CalendarPeriod.Reset();
                CalendarPeriod.SetRange("Period Type", CalendarPeriod."Period Type"::Month);
                CalendarPeriod.SetRange("Period Start", NormalDate(DatePeriod."Period Start"), NormalDate(DatePeriod."Period End"));
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
                    field(Periodicity; Periodicity)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Periodicity';
                        OptionCaption = 'Month,Quarter,Year';
                        ToolTip = 'Specifies if the accounting period is Month, Quarter, or Year.';

                        trigger OnValidate()
                        begin
                            PeriodReportManagement.InitPeriod(CalendarPeriod, Periodicity);
                            AccountPeriod := '';
                            PeriodReportManagement.SetCaptionPeriodYear(AccountPeriod, CalendarPeriod, false);
                            DatePeriod.Copy(CalendarPeriod);
                            PeriodReportManagement.PeriodSetup(DatePeriod, false);
                            PeriodicityOnAfterValidate();
                        end;
                    }
                    field(AccountPeriod; AccountPeriod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Accounting Period';
                        ToolTip = 'Specifies the accounting period to include data for.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            PeriodReportManagement.SelectPeriod(Text, CalendarPeriod, false);
                            DatePeriod.Copy(CalendarPeriod);
                            PeriodReportManagement.PeriodSetup(DatePeriod, false);
                            RequestOptionsPage.Update();
                            exit(true);
                        end;

                        trigger OnValidate()
                        begin
                            DatePeriod.Copy(CalendarPeriod);
                            PeriodReportManagement.PeriodSetup(DatePeriod, false);
                            AccountPeriodOnAfterValidate();
                        end;
                    }
                    field("DatePeriod.""Period Start"""; DatePeriod."Period Start")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'From';
                        Editable = false;
                        ToolTip = 'Specifies the starting point.';
                    }
                    field("»«"; DatePeriod."Period End")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'To';
                        Editable = false;
                        ToolTip = 'Specifies the ending point.';
                    }
                    field("Choice[Choices::Fixed]"; Choice[Choices::Fixed])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Fixed Differences';
                        ToolTip = 'Specifies if the tax difference amount is fixed.';
                    }
                    field("Choice[Choices::""Temporary""]"; Choice[Choices::"Temporary"])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Temporary Differences';
                    }
                    field(TemplateName; TemplateName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Jnl. Template Name';
                        TableRelation = "Tax Detail";
                        ToolTip = 'Specifies the name of the journal template, the basis of the journal batch, that the entries were posted from.';
                    }
                    field(BatchName; BatchName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Jnl. Batch Name';
                        ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the journal is based on.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if TemplateName <> '' then begin
                                TaxDiffJnlBatch.SetRange("Journal Template Name", TemplateName);
                                TaxDiffJnlBatch.SetRange(Name, BatchName);
                                if TaxDiffJnlBatch.FindFirst() then;
                                TaxDiffJnlBatch.SetRange(Name);
                                if ACTION::LookupOK = PAGE.RunModal(0, TaxDiffJnlBatch) then begin
                                    TemplateName := TaxDiffJnlBatch."Journal Template Name";
                                    BatchName := TaxDiffJnlBatch.Name;
                                end;
                            end;
                        end;
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date of the entries that you want to include in the report or batch job.';
                    }
                    field(DocumentNo; DocumentNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the number of the related document.';
                    }
                    field(PostingDescription; PostingDescription)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Description';
                        ToolTip = 'Specifies a description of the record or entry.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            PeriodReportManagement.InitPeriod(CalendarPeriod, Periodicity);
            PeriodReportManagement.SetCaptionPeriodYear(AccountPeriod, CalendarPeriod, false);
            DatePeriod.Copy(CalendarPeriod);
            PeriodReportManagement.PeriodSetup(DatePeriod, false);

            Choice[Choices::Fixed] := true;
            Choice[Choices::"Temporary"] := true;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if TemplateName = '' then
            Error(Text001);

        if BatchName = '' then
            Error(Text002);

        TaxDiffJnlLine."Journal Template Name" := TemplateName;
        TaxDiffJnlLine."Journal Batch Name" := BatchName;
        TaxDiffJnlLine.SetRange("Journal Template Name", TaxDiffJnlLine."Journal Template Name");
        TaxDiffJnlLine.SetRange("Journal Batch Name", TaxDiffJnlLine."Journal Batch Name");
        if not TaxDiffJnlLine.FindLast() then
            TaxDiffJnlLine."Line No." := 0;

        DisposalDate := 0D;
        if CalcDate('<CM>', PostingDate) = CalcDate('<CY>', PostingDate) then
            DisposalDate := CalcDate('<CM>', PostingDate);

        if DisposalDate <> 0D then
            if not Confirm(TaxDiffJnlLine.FieldCaption("Posting Date"), true) then
                DisposalDate := 0D;

        SetProperties();
    end;

    var
        TaxDiffJnlBatch: Record "Tax Diff. Journal Batch";
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        xRecTaxDiffJnlLine: Record "Tax Diff. Journal Line";
        TaxDiff: Record "Tax Difference";
        CalendarPeriod: Record Date;
        DatePeriod: Record Date;
        PeriodReportManagement: Codeunit PeriodReportManagement;
        PostingDate: Date;
        DisposalDate: Date;
        Choices: Option ,"Fixed","Temporary";
        Choice: array[4] of Boolean;
        Periodicity: Option Month,Quarter,Year;
        AccountPeriod: Text[30];
#pragma warning disable AA0074
        Text001: Label 'Please enter a journal template name.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text002: Label 'Please enter a journal batch name.';
#pragma warning restore AA0074
        DocumentNo: Code[20];
        PostingDescription: Text[50];
        TemplateName: Code[10];
        BatchName: Code[10];
        BookValueOnDisposal: Decimal;
        AcquisitionCost: Decimal;
#pragma warning disable AA0074
        Text12411: Label 'DT-';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12410: Label '%1 %2 FE Tax Deferrals';
#pragma warning restore AA0470
#pragma warning restore AA0074
        TaxBookValueOnDisposal: Decimal;
        TaxAcquisitionCost: Decimal;

    [Scope('OnPrem')]
    procedure SetProperties()
    begin
        PostingDate := DatePeriod."Period End";
        PostingDescription :=
          StrSubstNo(Text12410,
            Format(DatePeriod."Period Start", 0, '<Month Text> '),
            Date2DMY(DatePeriod."Period Start", 3));

        if Date2DMY(DatePeriod."Period Start", 2) > 9 then
            DocumentNo := Text12411 + Format(DatePeriod."Period Start", 0, '<Year>-<Month>')
        else
            DocumentNo := Text12411 + Format(DatePeriod."Period Start", 2, '<Year>') + '-0' + Format(DatePeriod."Period Start", 0, '<Month>');
    end;

    local procedure AccountPeriodOnAfterValidate()
    begin
        SetProperties();
    end;

    local procedure PeriodicityOnAfterValidate()
    begin
        SetProperties();
    end;
}

