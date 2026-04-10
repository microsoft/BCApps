#pragma warning disable AA0247
report 17303 "Calculate FE Depr. with Norm"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/CalculateFEDeprwithNorm.rdlc';
    Caption = 'Calculate FE Depr. with Norm';

    dataset
    {
        dataitem("Tax Difference"; "Tax Difference")
        {
            DataItemTableView = where(Type = const(Temporary), "Calc. Norm Jurisdiction Code" = filter(<> ''), "Calc. Norm Code" = filter(<> ''));
            RequestFilterFields = "Code";
            column(Tax_Difference_Code; Code)
            {
            }
            dataitem("Fixed Asset"; "Fixed Asset")
            {
                DataItemLink = "Tax Difference Code" = field(Code);
                DataItemTableView = sorting("No.");
                dataitem("Depreciation Book"; "Depreciation Book")
                {
                    DataItemTableView = sorting(Code) where("Posting Book Type" = filter(Accounting | "Tax Accounting"));
                    dataitem("FA Depreciation Book"; "FA Depreciation Book")
                    {
                        DataItemLink = "Depreciation Book Code" = field(Code);
                        DataItemLinkReference = "Depreciation Book";
                        DataItemTableView = sorting("Depreciation Book Code", "FA No.") where("Disposal Date" = filter(0D));
                        dataitem("FA Journal Template"; "FA Journal Template")
                        {
                            DataItemTableView = sorting(Name) where(Type = const("Future Expenses"));
                            dataitem("FA Journal Batch"; "FA Journal Batch")
                            {
                                DataItemLink = "Journal Template Name" = field(Name);
                                DataItemLinkReference = "FA Journal Template";
                                DataItemTableView = sorting("Journal Template Name", Name);
                                dataitem("FA Journal Line"; "FA Journal Line")
                                {
                                    DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field(Name);
                                    DataItemLinkReference = "FA Journal Batch";
                                    DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.") where("FA Posting Type" = const(Depreciation));

                                    trigger OnAfterGetRecord()
                                    begin
                                        FAJnlLine := "FA Journal Line";
                                        if "Depreciation Book"."Posting Book Type" = "Depreciation Book"."Posting Book Type"::"Tax Accounting" then begin
                                            if FAJnlLine."Depr. Amount w/o Normalization" <> 0 then begin
                                                FAJnlLine.Amount := "Depr. Amount w/o Normalization";
                                                FAJnlLine."Depr. Amount w/o Normalization" := 0;
                                                FAJnlLine.Modify();
                                            end;

                                            TempFAJnlLine := FAJnlLine;
                                            TempFAJnlLine.Insert();

                                            CurrentAmountDeprPlaning -= FAJnlLine.Amount;
                                            PrevAmountDeprActual -= AmountForAddingToAmntActual;
                                            AmountForAddingToAmntActual := 0;
                                            PrevAmountDeprPlaning -= AmountForAddingToAmntPlaning;
                                            AmountForAddingToAmntPlaning := 0;
                                        end else
                                            if FAJnlLine."Depr. Amount w/o Normalization" <> FAJnlLine.Amount then begin
                                                FAJnlLine."Depr. Amount w/o Normalization" := FAJnlLine.Amount;
                                                FAJnlLine.Modify();
                                            end;
                                    end;

                                    trigger OnPreDataItem()
                                    begin
                                        SetRange("Depreciation Book Code", "FA Depreciation Book"."Depreciation Book Code");
                                        SetRange("FA No.", "FA Depreciation Book"."FA No.");
                                        SetRange("FA Posting Date", CalcDate('<-CM>', DateEnd), DateEnd);
                                    end;
                                }
                            }
                        }

                        trigger OnAfterGetRecord()
                        begin
                            FALedgerEntry.SetRange("Depreciation Book Code", "Depreciation Book Code");
                            FALedgerEntry.CalcSums(Amount, "Depr. Amount w/o Normalization");

                            AmountForAddingToAmntActual := FALedgerEntry.Amount;
                            AmountForAddingToAmntPlaning := FALedgerEntry."Depr. Amount w/o Normalization";
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange("FA No.", "Fixed Asset"."No.");
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    FALedgerEntry.SetRange("FA No.", "No.");
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(USERID; UserId)
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(Tax_Difference__Code; "Tax Difference".Code)
                {
                }
                column(CurrentAmountDeprPlaning; CurrentAmountDeprPlaning)
                {
                }
                column(PrevAmountDeprActual; PrevAmountDeprActual)
                {
                }
                column(PrevAmountDeprPlaning; PrevAmountDeprPlaning)
                {
                }
                column(TotalAmountDeprAfterRating; TotalAmountDeprAfterRating)
                {
                }
                column(Tax_Difference__Description; "Tax Difference".Description)
                {
                }
                column(TotalAmountDeprAfterRating___PrevAmountDeprActual; TotalAmountDeprAfterRating - PrevAmountDeprActual)
                {
                }
                column(FAJnlLine__Journal_Template_Name_; FAJnlLine."Journal Template Name")
                {
                }
                column(FAJnlLine__Journal_Batch_Name_; FAJnlLine."Journal Batch Name")
                {
                }
                column(FAJnlLine__FA_No__; FAJnlLine."FA No.")
                {
                }
                column(FAJnlLine__Depreciation_Book_Code_; FAJnlLine."Depreciation Book Code")
                {
                }
                column(FAJnlLine__FA_Posting_Date_; FAJnlLine."FA Posting Date")
                {
                }
                column(FAJnlLine__Document_No__; FAJnlLine."Document No.")
                {
                }
                column(FAJnlLine_Description; FAJnlLine.Description)
                {
                }
                column(FAJnlLine__Depr__Amount_w_o_Normalization_; FAJnlLine."Depr. Amount w/o Normalization")
                {
                }
                column(FAJnlLine_Amount; FAJnlLine.Amount)
                {
                }
                column(FAJnlLine__Depr__Amount_w_o_Normalization__Control1000000021; FAJnlLine."Depr. Amount w/o Normalization")
                {
                }
                column(FAJnlLine_Amount_Control1000000022; FAJnlLine.Amount)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Control1000000040Caption; Control1000000040CaptionLbl)
                {
                }
                column(Tax_Difference__CodeCaption; Tax_Difference__CodeCaptionLbl)
                {
                }
                column(CurrentAmountDeprPlaningCaption; CurrentAmountDeprPlaningCaptionLbl)
                {
                }
                column(PrevAmountDeprActualCaption; PrevAmountDeprActualCaptionLbl)
                {
                }
                column(PrevAmountDeprPlaningCaption; PrevAmountDeprPlaningCaptionLbl)
                {
                }
                column(TotalAmountDeprAfterRatingCaption; TotalAmountDeprAfterRatingCaptionLbl)
                {
                }
                column(TotalAmountDeprAfterRating___PrevAmountDeprActualCaption; TotalAmountDeprAfterRating___PrevAmountDeprActualCaptionLbl)
                {
                }
                column(Journal_Template_NameCaption; Journal_Template_NameCaptionLbl)
                {
                }
                column(Journal_Batch_NameCaption; Journal_Batch_NameCaptionLbl)
                {
                }
                column(FE_No_Caption; FE_No_CaptionLbl)
                {
                }
                column(Depreciation_Book_CodeCaption; Depreciation_Book_CodeCaptionLbl)
                {
                }
                column(FE_Posting_DateCaption; FE_Posting_DateCaptionLbl)
                {
                }
                column(Document_No_Caption; Document_No_CaptionLbl)
                {
                }
                column(DescriptionCaption; DescriptionCaptionLbl)
                {
                }
                column(Depr__Amount_w_o_NormalizationCaption; Depr__Amount_w_o_NormalizationCaptionLbl)
                {
                }
                column(AmountCaption; AmountCaptionLbl)
                {
                }
                column(Integer_Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then begin
                        if not TempFAJnlLine.Find('-') then
                            CurrReport.Break();
                    end else
                        if TempFAJnlLine.Next(1) = 0 then
                            CurrReport.Break();

                    FAJnlLine := TempFAJnlLine;
                    FAJnlLine."Depr. Amount w/o Normalization" := TempFAJnlLine.Amount;
                    RoundingAmount := (TempFAJnlLine.Amount * RatingFactor) + RoundingAmount;
                    FAJnlLine.Amount := Round(RoundingAmount);
                    RoundingAmount := RoundingAmount - FAJnlLine.Amount;
                    FAJnlLine.Modify();
                end;

                trigger OnPreDataItem()
                begin
                    TotalAmountDeprAfterRating := NormGroup.CalcDinamicNorm(
                        DateBegin, DateEnd,
                        "Tax Difference"."Calc. Norm Jurisdiction Code", "Tax Difference"."Calc. Norm Code",
                        PrevAmountDeprPlaning + CurrentAmountDeprPlaning);

                    if TotalAmountDeprAfterRating < PrevAmountDeprActual then
                        Error(
                          Text1001 + Text1002 + Text1003 + Text1004 + Text1005,
                          "Tax Difference".TableCaption(), "Tax Difference".Code, "Tax Difference".Description,
                          PrevAmountDeprPlaning, CurrentAmountDeprPlaning,
                          TotalAmountDeprAfterRating, PrevAmountDeprActual);

                    RoundingAmount := 0;
                    if CurrentAmountDeprPlaning = 0 then
                        RatingFactor := 1
                    else
                        RatingFactor :=
                          (TotalAmountDeprAfterRating - PrevAmountDeprActual) / CurrentAmountDeprPlaning;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CurrentAmountDeprPlaning := 0;
                PrevAmountDeprActual := 0;
                PrevAmountDeprPlaning := 0;
                TempFAJnlLine.Reset();
                TempFAJnlLine.DeleteAll();
            end;

            trigger OnPreDataItem()
            begin
                FALedgerEntry.SetCurrentKey(
                  "FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "FA Posting Date");

                FALedgerEntry.SetRange("FA Posting Category", FALedgerEntry."FA Posting Category"::" ");
                FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
                FALedgerEntry.SetRange("FA Posting Date", CalcDate('<-CY>', DateEnd), DateEnd);
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
                    field(Period; AccountPeriod)
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
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        DateBegin := NormalDate(DatePeriod."Period Start");
        DateEnd := NormalDate(DatePeriod."Period End");
    end;

    var
        NormGroup: Record "Tax Register Norm Group";
        FALedgerEntry: Record "FA Ledger Entry";
        FAJnlLine: Record "FA Journal Line";
        TempFAJnlLine: Record "FA Journal Line" temporary;
        CalendarPeriod: Record Date;
        DatePeriod: Record Date;
        PeriodReportManagement: Codeunit PeriodReportManagement;
        CurrentAmountDeprPlaning: Decimal;
        TotalAmountDeprAfterRating: Decimal;
        AmountForAddingToAmntActual: Decimal;
        AmountForAddingToAmntPlaning: Decimal;
        PrevAmountDeprActual: Decimal;
        PrevAmountDeprPlaning: Decimal;
        RatingFactor: Decimal;
        RoundingAmount: Decimal;
        DateBegin: Date;
        DateEnd: Date;
        Periodicity: Option Month,Quarter,Year;
        AccountPeriod: Text[30];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1001: Label '%1 %2 %3\\';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1002: Label 'Planned depreciation amount in current period %4\ ';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1003: Label 'Planned depreciation amount in previous period %5\\';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1004: Label 'Calculated FE depreciation amount after normalization %6\ ';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1005: Label 'is less than actual depreciation amount for previous period %7.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CurrReport_PAGENOCaptionLbl: Label 'Label1000000039';
        Control1000000040CaptionLbl: Label 'Label1000000040';
        Tax_Difference__CodeCaptionLbl: Label 'Tax Diff. Code';
        CurrentAmountDeprPlaningCaptionLbl: Label ' Planing Current Amount Planing';
        PrevAmountDeprActualCaptionLbl: Label 'Actual Prev. Amount';
        PrevAmountDeprPlaningCaptionLbl: Label ' Planing Prev. Amoun';
        TotalAmountDeprAfterRatingCaptionLbl: Label 'Amount after Rating';
        TotalAmountDeprAfterRating___PrevAmountDeprActualCaptionLbl: Label 'Amount after Rating';
        Journal_Template_NameCaptionLbl: Label 'Journal Template Name';
        Journal_Batch_NameCaptionLbl: Label 'Journal Batch Name';
        FE_No_CaptionLbl: Label 'FE No.';
        Depreciation_Book_CodeCaptionLbl: Label 'Depreciation Book Code';
        FE_Posting_DateCaptionLbl: Label 'FE Posting Date';
        Document_No_CaptionLbl: Label 'Document No.';
        DescriptionCaptionLbl: Label 'Description';
        Depr__Amount_w_o_NormalizationCaptionLbl: Label 'Depr. Amount w/o Normalization';
        AmountCaptionLbl: Label 'Amount';
}

