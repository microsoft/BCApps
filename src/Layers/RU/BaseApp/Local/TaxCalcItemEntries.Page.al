#pragma warning disable AA0247
page 17326 "Tax Calc. Item Entries"
{
    Caption = 'Tax Calc. Item Entries';
    DataCaptionExpression = Rec.FormTitle();
    Editable = false;
    PageType = Worksheet;
    SourceTable = "Tax Calc. Item Entry";
    SourceTableView = sorting("Section Code", "Posting Date");

    layout
    {
        area(content)
        {
            repeater(Control100)
            {
                Editable = false;
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with the tax calculation item entry.';
                }
                field("UOMName()"; Rec.UOMName())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'UOM Name';
                }
                field("Credit Quantity"; Rec."Credit Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit quantity associated with the tax calculation item entry.';
                }
                field("Credit Amount (Tax)"; Rec."Credit Amount (Tax)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit amount, including tax, associated with the tax calculation item entry.';
                }
                field("Credit Amount (Actual)"; Rec."Credit Amount (Actual)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the actual credit amount associated with the tax calculation item entry.';
                }
                field("Debit Quantity"; Rec."Debit Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit quantity associated with the tax calculation item entry.';
                }
                field("Debit Amount (Tax)"; Rec."Debit Amount (Tax)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit amount, including tax, associated with the tax calculation item entry.';
                }
                field("Debit Amount (Actual)"; Rec."Debit Amount (Actual)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the actual debit amount associated with the tax calculation item entry.';
                }
                field("Outstand. Quantity"; Rec."Outstand. Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the outstanding quantity of the tax calculation item entry.';
                }
                field("Ledger Entry No."; Rec."Ledger Entry No.")
                {
                    ToolTip = 'Specifies the ledger entry number associated with the tax calculation item entry.';
                    Visible = false;
                }
                field("Appl. Entry No."; Rec."Appl. Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the applied entry number associated with the tax calculation item entry.';
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

    trigger OnAfterGetRecord()
    begin
        OutstandQuantityOnFormat(Format(Rec."Outstand. Quantity"));
    end;

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
        TaxRegMgt.SetPeriodAmountType(Calendar, DateFilterText, PeriodType, AmountType);
        Calendar.Reset();
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

        Rec.SetFilter("Posting Date", DateFilterText);
        Rec.SetFilter("Date Filter", DateFilterText);
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

        Rec.SetFilter("Posting Date", '%1..%2', Calendar."Period Start", Calendar."Period End");
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

    local procedure CurrentPeriodAmountTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure TaxPeriodAmountTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure OutstandQuantityOnFormat(Text: Text[1024])
    begin
        if Rec."Appl. Entry No." = 0 then
            Text := '0';
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

