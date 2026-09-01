#pragma warning disable AA0247
page 17230 "Tax Register (2.9) CV"
{
    Caption = 'Tax Register (2.9) CV';
    DataCaptionExpression = Rec.FormTitle();
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Tax Register CV Entry";
    SourceTableView = sorting("Section Code", "Register Type")
                      where("Register Type" = const("Credit Balance"));

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
                field("CV Credit Balance Amnt 1"; Rec."CV Credit Balance Amnt 1")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the creditor or debtor credit balance amount associated with the tax register debtor or creditor entry.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownCVLedgerAmount(DateFilterText, false, false);
                    end;
                }
                field("CV Credit Balance Amnt 2"; Rec."CV Credit Balance Amnt 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the creditor or debtor credit balance amount associated with the tax register debtor or creditor entry.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownCVLedgerAmount(FilterDueDate3Years, false, true);
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
        Calendar.Reset();
        Rec.FilterGroup(2);
        SectionCode := Rec.GetRangeMin("Section Code");
        Rec.FilterGroup(0);
        ShowNewData();
    end;

    var
        Calendar: Record Date;
        TaxRegMgt: Codeunit "Tax Register Mgt.";
        AmountType: Option "Current Period","Tax Period";
        FilterDueDate3Years: Text[30];
        DateFilterText: Text;
        PeriodType: Option ,,Month,Quarter,Year;
        SectionCode: Code[10];

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

        TaxRegMgt.CalcCreditBalancePointDate(SectionCode, Rec.GetRangeMax("Date Filter"), FilterDueDate3Years);
    end;
}

