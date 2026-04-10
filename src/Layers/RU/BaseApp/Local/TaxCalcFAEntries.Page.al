#pragma warning disable AA0247
page 17327 "Tax Calc. FA Entries"
{
    Caption = 'Tax Calc. FA Entries';
    DataCaptionExpression = Rec.FormTitle();
    Editable = false;
    PageType = Worksheet;
    SourceTable = "Tax Calc. FA Entry";
    SourceTableView = sorting("Section Code");

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("GetMonthYear()"; Rec.GetMonthYear())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Date';
                    ToolTip = 'Specifies the posting date of the entries that you want to include in the report or batch job.';
                }
                field("FA No."; Rec."FA No.")
                {
                    ToolTip = 'Specifies the number of the related fixed asset. ';
                    Visible = false;
                }
                field("ObjectName()"; Rec.ObjectName())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the related record.';
                }
                field(Disposed; Rec.Disposed)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the fixed asset has been disposed.';
                }
                field("Depreciation Book Code (Base)"; Rec."Depreciation Book Code (Base)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the depreciation book code that is based on book accounting transactions.';
                }
                field("Depreciation Amount (Base)"; Rec."Depreciation Amount (Base)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the depreciation amount that is based on book accounting transactions.';
                }
                field("Total Depr. Amount (Base)"; Rec."Total Depr. Amount (Base)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total depreciation amount that is based on book accounting transactions.';
                }
                field("Depreciation Book Code (Tax)"; Rec."Depreciation Book Code (Tax)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the depreciation book code that is based on tax accounting transactions.';
                }
                field("Depreciation Amount (Tax)"; Rec."Depreciation Amount (Tax)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the depreciation amount that is based on tax accounting transactions.';
                }
                field("Total Depr. Amount (Tax)"; Rec."Total Depr. Amount (Tax)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total depreciation amount that is based on tax accounting transactions.';
                }
                field("FA Type"; Rec."FA Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the fixed asset type associated with the tax calculation fixed asset entry.';
                }
                field("Belonging to Manufacturing"; Rec."Belonging to Manufacturing")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies if the fixed asset entry belongs to production or nonproduction.';
                }
                field("Depreciation Group"; Rec."Depreciation Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the depreciation group associated with the tax calculation fixed asset entry.';
                }
                field("Depr. Group Elimination"; Rec."Depr. Group Elimination")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the depreciation group elimination that is based on tax accounting transactions.';
                }
            }
            field(PeriodType; PeriodType)
            {
                ApplicationArea = Basic, Suite;
                OptionCaption = ',,Month,Quarter,Year';
                ToolTip = 'Month';

                trigger OnValidate()
                begin
                    if PeriodType = PeriodType::Year then
                        YearPeriodTypeOnValidate();
                    if PeriodType = PeriodType::Quarter then
                        QuarterPeriodTypeOnValidate();
                    if PeriodType = PeriodType::Month then
                        MonthPeriodTypeOnValidate();
                end;
            }
            field(AmountType; AmountType)
            {
                ApplicationArea = Basic, Suite;
                OptionCaption = 'Current Period,Tax Period';
                ToolTip = 'Current Period';

                trigger OnValidate()
                begin
                    if AmountType = AmountType::"Tax Period" then
                        TaxPeriodAmountTypeOnValidate();
                    if AmountType = AmountType::"Current Period" then
                        CurrentPeriodAmountTypeOnValid();
                end;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Fixed Asset")
            {
                Caption = 'Fixed Asset';
                Image = FixedAssets;
                action(Card)
                {
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Fixed Asset Card";
                    RunPageLink = "No." = field("FA No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit details about the selected entity.';
                }
            }
        }
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
        DateFilterText := '*';
    end;

    var
        Calendar: Record Date;
        TaxRegMgt: Codeunit "Tax Register Mgt.";
        DateFilterText: Text;
        PeriodType: Option ,,Month,Quarter,Year;
        AmountType: Option "Current Period","Tax Period";

    [Scope('OnPrem')]
    procedure ShowNewData()
    begin
        FindPeriod('');
        DateFilterText := Rec.GetFilter("Date Filter");

        Rec.SetFilter("Date Filter", DateFilterText);
        Rec.SetFilter("Ending Date", DateFilterText);
    end;

    local procedure FindPeriod(SearchText: Code[10])
    var
        Calendar: Record Date;
    begin
        if Rec.GetFilter("Date Filter") <> '' then begin
            Calendar."Period End" := Rec.GetRangeMax("Date Filter");
            if not TaxRegMgt.FindDate('', Calendar, PeriodType, AmountType) then
                TaxRegMgt.FindDate('', Calendar, PeriodType::Month, AmountType);
        end;
        TaxRegMgt.FindDate(SearchText, Calendar, PeriodType, AmountType);

        Rec.SetFilter("Date Filter", '%1..%2', Calendar."Period Start", Calendar."Period End");
    end;

    local procedure MonthPeriodTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure QuarterPeriodTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure YearPeriodTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure TaxPeriodAmountTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure CurrentPeriodAmountTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure MonthPeriodTypeOnValidate()
    begin
        MonthPeriodTypeOnPush();
    end;

    local procedure QuarterPeriodTypeOnValidate()
    begin
        QuarterPeriodTypeOnPush();
    end;

    local procedure YearPeriodTypeOnValidate()
    begin
        YearPeriodTypeOnPush();
    end;

    local procedure CurrentPeriodAmountTypeOnValid()
    begin
        CurrentPeriodAmountTypeOnPush();
    end;

    local procedure TaxPeriodAmountTypeOnValidate()
    begin
        TaxPeriodAmountTypeOnPush();
    end;
}

