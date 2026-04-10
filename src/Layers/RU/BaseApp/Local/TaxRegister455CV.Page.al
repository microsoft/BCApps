#pragma warning disable AA0247
page 17235 "Tax Register (4.55) CV"
{
    Caption = 'Tax Register (4.55) CV';
    DataCaptionExpression = Rec.FormTitle();
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Tax Register CV Entry";
    SourceTableView = sorting("Section Code", "Register Type")
                      where("Register Type" = const("Debit Balance"),
                            "CV Debit Balance Amnt 4" = filter(<> 0));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("C/V No."; Rec."C/V No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No.';
                    ToolTip = 'Specifies the creditor or debtor number associated with the tax register debtor or creditor entry.';
                }
                field(ObjectName; Rec.ObjectName())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the related record.';
                }
                field("CV Debit Balance Amnt 4"; Rec."CV Debit Balance Amnt 4")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the creditor or debtor debit balance amount associated with the tax register debtor or creditor entry.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownCVLedgerAmount(FilterDueDate3Years, true, true);
                    end;
                }
            }
            field(PeriodType; PeriodType)
            {
                ApplicationArea = Basic, Suite;
                OptionCaption = ',,Month,Quarter,Year';
                ToolTip = 'Month';

                trigger OnValidate()
                begin
                    FindPeriod('');
                end;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Previous Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Period';
                Image = PreviousRecord;
                ToolTip = 'Previous Period';

                trigger OnAction()
                begin
                    FindPeriod('<=');
                end;
            }
            action("Next Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Period';
                Image = NextRecord;
                ToolTip = 'Next Period';

                trigger OnAction()
                begin
                    FindPeriod('>=');
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Previous Period_Promoted"; "Previous Period")
                {
                }
                actionref("Next Period_Promoted"; "Next Period")
                {
                }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if DateFilterText <> Rec.GetFilter("Date Filter") then
            ShowNewData();

        exit(Rec.Find(Which));
    end;

    trigger OnOpenPage()
    begin
        Rec.CopyFilter("Date Filter", Calendar."Period End");
        TaxRegMgt.SetPeriodAmountType(Calendar, DateFilterText, PeriodType, AmountType);
        Rec.FilterGroup(2);
        SectionCode := Rec.GetRangeMin("Section Code");
        Rec.FilterGroup(0);
        ShowNewData();
        Calendar.Reset();
    end;

    var
        Calendar: Record Date;
        TaxRegMgt: Codeunit "Tax Register Mgt.";
        AmountType: Option "Current Period","Tax Period";
        FilterDueDateTotal45Days: Text[30];
        FilterDueDate45Days: Text[30];
        FilterDueDate90Days: Text[30];
        FilterDueDate3Years: Text[30];
        DateFilterText: Text;
        PeriodType: Option ,,Month,Quarter,Year;
        SectionCode: Code[10];

    [Scope('OnPrem')]
    procedure ShowNewData()
    var
        UsingDate: Date;
    begin
        if Rec.GetFilter("Date Filter") = '' then
            UsingDate := CalcDate('<CM-1M>', WorkDate())
        else
            UsingDate := Rec.GetRangeMax("Date Filter");

        Rec.SetRange("Ending Date", UsingDate);
        Rec.SetFilter("Date Filter", '..%1', UsingDate);
        DateFilterText := Rec.GetFilter("Date Filter");

        TaxRegMgt.CalcDebitBalancePointDate(SectionCode, Rec.GetRangeMax("Date Filter"),
          FilterDueDateTotal45Days, FilterDueDate45Days, FilterDueDate90Days, FilterDueDate3Years);
    end;

    local procedure FindPeriod(SearchText: Code[10])
    begin
        if Rec.GetFilter("Date Filter") <> '' then begin
            Calendar."Period End" := Rec.GetRangeMax("Date Filter");
            if not TaxRegMgt.FindDate('', Calendar, PeriodType, AmountType::"Tax Period") then
                TaxRegMgt.FindDate('', Calendar, PeriodType::Month, AmountType::"Tax Period");
        end;
        TaxRegMgt.FindDate(SearchText, Calendar, PeriodType, AmountType::"Tax Period");

        Rec.SetFilter("Date Filter", '..%1', Calendar."Period End");
    end;
}

