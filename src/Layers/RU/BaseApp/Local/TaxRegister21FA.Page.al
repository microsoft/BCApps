#pragma warning disable AA0247
page 17225 "Tax Register (2.1) FA"
{
    Caption = 'Tax Register (2.1) FA';
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
                field("Acquisition Date"; Rec."Acquisition Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the acquisition date associated with the tax register fixed asset entry.';
                }
                field("Acquisition Cost"; Rec."Acquisition Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the acquisition cost associated with the tax register fixed asset entry.';
                }
                field("Valuation Changes"; Rec."Valuation Changes")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the valuation changes that are associated with the tax register fixed asset entry.';
                }
                field("Depreciation Group"; Rec."Depreciation Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the depreciation group associated with the tax register fixed asset entry.';
                }
                field("No. of Depreciation Months"; Rec."No. of Depreciation Months")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the length of the depreciation period, expressed in months.';
                }
                field("Depreciation Method"; Rec."Depreciation Method")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the depreciation method associated with the tax register fixed asset entry.';
                }
                field("Belonging to Manufacturing"; Rec."Belonging to Manufacturing")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies how the fixed asset is used in manufacturing.';
                }
                field("Depreciation Starting Date"; Rec."Depreciation Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which depreciation of the fixed asset starts.';
                }
                field("Total Depreciation Amount"; Rec."Total Depreciation Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total depreciation amount associated with the tax register fixed asset entry.';
                }
                field("Taken Off Books Date"; Rec."Taken Off Books Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the depreciation associated with the tax register fixed asset entry is removed from the books.';
                }
                field("Taken Off Books Reason"; Rec."Taken Off Books Reason")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason that the depreciation associated with the tax register fixed asset entry is removed from the books.';
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
                    Image = Card;
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

