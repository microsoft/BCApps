#pragma warning disable AA0247
page 17325 "Tax Calc. Entries"
{
    Caption = 'Tax Calc. Entries';
    DataCaptionExpression = Rec.FormTitle();
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Tax Calc. G/L Entry";
    SourceTableView = sorting("Section Code");

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ToolTip = 'Specifies the type of the related document.';
                    Visible = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ToolTip = 'Specifies the number of the related document.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the term entry line code description associated with the tax calculation entry.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount associated with the tax calculation entry.';
                }
                field("Debit Account No."; Rec."Debit Account No.")
                {
                    ToolTip = 'Specifies the debit account number associated with the tax calculation entry.';
                    Visible = false;
                }
                field("Credit Account No."; Rec."Credit Account No.")
                {
                    ToolTip = 'Specifies the credit account number associated with the tax calculation entry.';
                    Visible = false;
                }
                field(DebitAccountName; Rec.DebitAccountName())
                {
                    Caption = 'Debit Account Name';
                    Visible = false;
                }
                field(CreditAccountName; Rec.CreditAccountName())
                {
                    Caption = 'Credit Account Name';
                    Visible = false;
                }
                field(Correction; Rec.Correction)
                {
                    ToolTip = 'Specifies the entry as a corrective entry. You can use the field if you need to post a corrective entry to an account.';
                    Visible = false;
                }
                field("Source Type"; Rec."Source Type")
                {
                    ToolTip = 'Specifies the source type that applies to the source number that is shown in the Source No. field.';
                    Visible = false;
                }
                field("Source No."; Rec."Source No.")
                {
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';
                    Visible = false;
                }
                field(SourceName; Rec.SourceName())
                {
                    Caption = 'Source Name';
                    Visible = false;
                }
                field("Ledger Entry No."; Rec."Ledger Entry No.")
                {
                    ToolTip = 'Specifies the ledger entry number associated with the tax calculation entry.';
                    Visible = false;
                }
                field("Dimension 1 Value Code"; Rec."Dimension 1 Value Code")
                {
                    ToolTip = 'Specifies the dimension value you selected for the analysis view dimension that you defined as Dimension 1 on the analysis view card.';
                    Visible = false;
                }
                field("Dimension 2 Value Code"; Rec."Dimension 2 Value Code")
                {
                    ToolTip = 'Specifies the dimension value you selected for the analysis view dimension that you defined as Dimension 2 on the analysis view card.';
                    Visible = false;
                }
                field("Dimension 3 Value Code"; Rec."Dimension 3 Value Code")
                {
                    ToolTip = 'Specifies the dimension value you selected for the analysis view dimension that you defined as Dimension 3 on the analysis view card.';
                    Visible = false;
                }
                field("Dimension 4 Value Code"; Rec."Dimension 4 Value Code")
                {
                    ToolTip = 'Specifies the dimension value you selected for the analysis view dimension that you defined as Dimension 4 on the analysis view card.';
                    Visible = false;
                }
                field("Tax Factor"; Rec."Tax Factor")
                {
                    DrillDown = false;
                    ToolTip = 'Specifies the tax factor associated with the tax calculation entry.';
                    Visible = false;
                }
                field("Tax Amount"; Rec."Tax Amount")
                {
                    DrillDown = false;
                    ToolTip = 'Specifies the tax amount associated with the tax calculation entry.';
                    Visible = false;
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
            action(Navigate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Rec.Navigating();
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
                actionref(Navigate_Promoted; Navigate)
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
        Rec.CopyFilter("Date Filter", Rec."Posting Date");
        TaxCalcMgt.SetPeriodAmountType(Calendar, DateFilterText, PeriodType, AmountType);
        Calendar.Reset();
    end;

    var
        Calendar: Record Date;
        TaxCalcMgt: Codeunit "Tax Calc. Mgt.";
        DateFilterText: Text;
        PeriodType: Option ,,Month,Quarter,Year;
        AmountType: Option "Current Period","Tax Period";

    [Scope('OnPrem')]
    procedure ShowNewData()
    begin
        FindPeriod('');
        DateFilterText := Rec.GetFilter("Date Filter");

        Rec.SetFilter("Posting Date", DateFilterText);
        Rec.SetFilter("Date Filter", DateFilterText);
    end;

    local procedure FindPeriod(SearchText: Code[10])
    var
        Calendar: Record Date;
    begin
        if Rec.GetFilter("Date Filter") <> '' then begin
            Calendar."Period End" := Rec.GetRangeMax("Date Filter");
            if not TaxCalcMgt.FindDate('', Calendar, PeriodType, AmountType) then
                TaxCalcMgt.FindDate('', Calendar, PeriodType::Month, AmountType);
        end;
        TaxCalcMgt.FindDate(SearchText, Calendar, PeriodType, AmountType);

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

