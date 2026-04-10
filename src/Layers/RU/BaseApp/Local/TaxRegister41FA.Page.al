#pragma warning disable AA0247
page 17232 "Tax Register (4.1) FA"
{
    Caption = 'Tax Register (4.1) FA';
    DataCaptionExpression = Rec.FormTitle();
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SourceTable = "Tax Register FA Entry";
    SourceTableView = sorting("Section Code");

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field(GetMonthYear; Rec.GetMonthYear())
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
                field("Depreciation Group"; Rec."Depreciation Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the depreciation group associated with the tax register fixed asset entry.';
                }
                field(ObjectName; Rec.ObjectName())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the related record.';
                }
                field("Belonging to Manufacturing"; Rec."Belonging to Manufacturing")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies how the fixed asset is used in manufacturing.';
                }
                field("Depreciation Method"; Rec."Depreciation Method")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the depreciation method associated with the tax register fixed asset entry.';
                }
                field("Acquisition Cost"; Rec."Acquisition Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the acquisition cost associated with the tax register fixed asset entry.';
                }
                field("Book Value Amount"; Rec."Book Value Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the book value amount associated with the tax register fixed asset entry.';
                }
                field(CalcQtyMonthsUsefulLife; Rec.CalcQtyMonthsUsefulLife())
                {
                    AutoFormatType = 0;
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. Month Expensive';
                    DecimalPlaces = 2 : 8;
                }
                field("Depreciation Amount"; Rec."Depreciation Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the depreciation amount associated with the tax register fixed asset entry.';
                }
                field("Total Depreciation Amount"; Rec."Total Depreciation Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total depreciation amount associated with the tax register fixed asset entry.';
                }
                field("Depr. Group Elimination"; Rec."Depr. Group Elimination")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the depreciation group elimination associated with the tax register fixed asset entry.';
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
}

