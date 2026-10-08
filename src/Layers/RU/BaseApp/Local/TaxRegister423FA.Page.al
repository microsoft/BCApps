#pragma warning disable AA0247
page 17234 "Tax Register (4.23) FA"
{
    Caption = 'Tax Register (4.23) FA';
    DataCaptionExpression = Rec.FormTitle();
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SourceTable = "Tax Register FA Entry";
    SourceTableView = sorting("Section Code")
                      where("Taken Off Books Date" = filter(<> 0D),
                            "Sales Gain/Loss" = filter(> 0));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Taken Off Books Date"; Rec."Taken Off Books Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the depreciation associated with the tax register fixed asset entry is removed from the books.';
                }
                field("FA No."; Rec."FA No.")
                {
                    ToolTip = 'Specifies the number of the related fixed asset. ';
                    Visible = false;
                }
                field(ObjectName; Rec.ObjectName())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the related record.';
                }
                field("Sales Amount"; Rec."Sales Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sales amount associated with the tax register fixed asset entry.';
                }
                field("Sales Original Amount"; Rec."Sales Original Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the original sales amount associated with the tax register fixed asset entry.';
                }
                field("Sales Depreciation Amount"; Rec."Sales Depreciation Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sales depreciation amount associated with the tax register fixed asset entry.';
                }
                field("Sales Gain/Loss"; Rec."Sales Gain/Loss")
                {
                    ApplicationArea = Basic, Suite;
                    BlankNumbers = BlankNegAndZero;
                    ToolTip = 'Specifies the sales gain or the sales loss of the tax register fixed asset entry.';
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
            field(AmountType; AmountType)
            {
                ApplicationArea = Basic, Suite;
                OptionCaption = 'Current Period,Tax Period';
                ToolTip = 'Current Period';

                trigger OnValidate()
                begin
                    FindPeriod('');
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
        Rec.SetFilter("Taken Off Books Date", DateFilterText);
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

    [Scope('OnPrem')]
    procedure FindDate(SearchString: Text[10]; var Calendar: Record Date; PeriodType: Option ,,Month,Quarter,Year) Found: Boolean
    begin
        Calendar.SetRange("Period Type", PeriodType);
        Calendar."Period Type" := PeriodType;
        if Calendar."Period End" = 0D then
            Calendar."Period End" := WorkDate();
        case PeriodType of
            PeriodType::Year:
                Calendar."Period Start" := CalcDate('<-CY>', NormalDate(Calendar."Period End"));
            PeriodType::Quarter:
                Calendar."Period Start" := CalcDate('<-CQ>', NormalDate(Calendar."Period End"));
            else
                Calendar."Period Start" := CalcDate('<-CM>', NormalDate(Calendar."Period End"));
        end;
        if SearchString in ['', '=><'] then
            SearchString := '=<>';
        Found := Calendar.Find(SearchString);
        if Found then begin
            Calendar."Period Start" := NormalDate(Calendar."Period Start");
            Calendar."Period End" := NormalDate(Calendar."Period End");
        end;
        exit(Found);
    end;
}

