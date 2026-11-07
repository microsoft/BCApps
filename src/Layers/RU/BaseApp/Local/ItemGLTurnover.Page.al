#pragma warning disable AA0247
page 12449 "Item G/L Turnover"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Item G/L Turnover';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = Item;
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                        CurrPage.Update();
                    end;
                }
            }
            repeater(Matrix)
            {
                Editable = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Base Unit of Measure"; Rec."Base Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the base unit used to measure the item, such as piece, box, or pallet. The base unit of measure also serves as the conversion basis for alternate units of measure.';
                }
                field(StartingQuantity; StartingQuantity)
                {
                    AutoFormatType = 0;
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Starting Quantity';
                    DecimalPlaces = 0 : 5;

                    trigger OnDrillDown()
                    begin
                        DrillDown(0, 0);
                    end;
                }
                field(DebitQuantity; DebitQuantity)
                {
                    AutoFormatType = 0;
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Debit Quantity';
                    DecimalPlaces = 0 : 5;

                    trigger OnDrillDown()
                    begin
                        DrillDown(1, 0);
                    end;
                }
                field(CreditQuantity; CreditQuantity)
                {
                    AutoFormatType = 0;
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Credit Quantity';
                    DecimalPlaces = 0 : 5;

                    trigger OnDrillDown()
                    begin
                        DrillDown(2, 0);
                    end;
                }
                field(EndingQuantity; EndingQuantity)
                {
                    AutoFormatType = 0;
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Ending Quantity';
                    DecimalPlaces = 0 : 5;

                    trigger OnDrillDown()
                    begin
                        DrillDown(3, 0);
                    end;
                }
                field(StartingCost; StartingCost)
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Starting Cost';

                    trigger OnDrillDown()
                    begin
                        DrillDown(0, 1);
                    end;
                }
                field(DebitCost; DebitCost)
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Debit Cost';
                    ToolTip = 'Specifies information about the cost of the item and is calculated on the basis of the cost amounts posted in the general ledger entry.';

                    trigger OnDrillDown()
                    begin
                        DrillDown(1, 1);
                    end;
                }
                field(CreditCost; CreditCost)
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Credit Cost';

                    trigger OnDrillDown()
                    begin
                        DrillDown(2, 1);
                    end;
                }
                field(EndingCost; EndingCost)
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ending Cost';

                    trigger OnDrillDown()
                    begin
                        DrillDown(3, 1);
                    end;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Item")
            {
                Caption = '&Item';
                Image = Item;
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Item Card";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'Shift+F7';
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
            group("&Print")
            {
                Caption = '&Print';
                Image = Print;
                action("Turnover Sheet")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Turnover Sheet';
                    Image = Turnover;
                    ToolTip = 'View the fixed asset turnover information. You can view information such as the fixed asset name, quantity, status, depreciation dates, and amounts. The report can be used as documentation for the correction of quantities and for auditing purposes.';

                    trigger OnAction()
                    begin
                        Item.Copy(Rec);
                        REPORT.RunModal(REPORT::"Item Turnover (Qty.)", true, false, Item);
                    end;
                }
            }
        }
        area(reporting)
        {
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
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Turnover Sheet_Promoted"; "Turnover Sheet")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcBalance();
    end;

    trigger OnOpenPage()
    begin
        if PeriodType = PeriodType::"Accounting Period" then
            FindPeriodUser('')
        else
            FindPeriod('');
    end;

    var
        UserSetup: Record "User Setup";
        Item: Record Item;
        ValueEntry: Record "Value Entry";
        PeriodType: Enum "Analysis Period Type";
        StartDateFilter: Text[50];
        EndDateFilter: Text[50];
        DebitQuantity: Decimal;
        CreditQuantity: Decimal;
        StartingQuantity: Decimal;
        EndingQuantity: Decimal;
        DebitCost: Decimal;
        CreditCost: Decimal;
        StartingCost: Decimal;
        EndingCost: Decimal;

    local procedure FindPeriod(SearchText: Code[10])
    var
        Calendar: Record Date;
        PeriodPageManagement: Codeunit PeriodPageManagement;
    begin
        if Rec.GetFilter("Date Filter") <> '' then begin
            Calendar.SetFilter("Period Start", Rec.GetFilter("Date Filter"));
            if not PeriodPageManagement.FindDate('+', Calendar, PeriodType) then
                PeriodPageManagement.FindDate('+', Calendar, PeriodType::Day);
            Calendar.SetRange("Period Start");
        end;
        PeriodPageManagement.FindDate(SearchText, Calendar, PeriodType);
        Rec.SetRange("Date Filter", Calendar."Period Start", Calendar."Period End");
        if Rec.GetRangeMin("Date Filter") = Rec.GetRangeMax("Date Filter") then
            Rec.SetRange("Date Filter", Rec.GetRangeMin("Date Filter"));

        CalcFilters();
    end;

    [Scope('OnPrem')]
    procedure CalcBalance()
    begin
        DebitQuantity := 0;
        CreditQuantity := 0;
        StartingQuantity := 0;
        EndingQuantity := 0;

        ValueEntry.Reset();
        ValueEntry.SetCurrentKey(
          "Item No.", "Location Code",
          "Global Dimension 1 Code", "Global Dimension 2 Code",
          "Expected Cost", Positive, "Posting Date", "Red Storno");
        ValueEntry.SetRange("Item No.", Rec."No.");
        ValueEntry.SetRange("Expected Cost", false);
        Rec.CopyFilter("Global Dimension 1 Filter", ValueEntry."Global Dimension 1 Code");
        Rec.CopyFilter("Global Dimension 2 Filter", ValueEntry."Global Dimension 2 Code");
        Rec.CopyFilter("Location Filter", ValueEntry."Location Code");
        Rec.CopyFilter("Date Filter", ValueEntry."Posting Date");

        CalculateAmounts(ValueEntry, DebitCost, CreditCost, DebitQuantity, CreditQuantity);

        if EndDateFilter <> '' then
            ValueEntry.SetFilter("Posting Date", EndDateFilter);
        ValueEntry.CalcSums("Invoiced Quantity", "Cost Amount (Actual)");
        EndingQuantity := ValueEntry."Invoiced Quantity";
        EndingCost := ValueEntry."Cost Amount (Actual)";

        StartingQuantity := 0;
        StartingCost := 0;
        if StartDateFilter <> '' then begin
            ValueEntry.SetFilter("Posting Date", StartDateFilter);
            ValueEntry.CalcSums("Invoiced Quantity", "Cost Amount (Actual)");
            StartingQuantity := ValueEntry."Invoiced Quantity";
            StartingCost := ValueEntry."Cost Amount (Actual)";
        end;
    end;

    local procedure FindPeriodUser(SearchText: Code[10])
    var
        Calendar: Record Date;
        PeriodPageManagement: Codeunit PeriodPageManagement;
    begin
        if UserSetup.Get(UserId) then begin
            Rec.SetRange("Date Filter", UserSetup."Allow Posting From", UserSetup."Allow Posting To");
            if Rec.GetRangeMin("Date Filter") = Rec.GetRangeMax("Date Filter") then
                Rec.SetRange("Date Filter", Rec.GetRangeMin("Date Filter"));
        end else begin
            if Rec.GetFilter("Date Filter") <> '' then begin
                Calendar.SetFilter("Period Start", Rec.GetFilter("Date Filter"));
                if not PeriodPageManagement.FindDate('+', Calendar, PeriodType) then
                    PeriodPageManagement.FindDate('+', Calendar, PeriodType::Day);
                Calendar.SetRange("Period Start");
            end;
            PeriodPageManagement.FindDate(SearchText, Calendar, PeriodType);
            Rec.SetRange("Date Filter", Calendar."Period Start", Calendar."Period End");
            if Rec.GetRangeMin("Date Filter") = Rec.GetRangeMax("Date Filter") then
                Rec.SetRange("Date Filter", Rec.GetRangeMin("Date Filter"));
        end;
    end;

    [Scope('OnPrem')]
    procedure DrillDown(Show: Option Start,Debit,Credit,Ending; Value: Option Quantity,Cost)
    var
        TempValueEntry: Record "Value Entry" temporary;
    begin
        ValueEntry.Reset();
        ValueEntry.SetCurrentKey(
          "Item No.", "Location Code",
          "Global Dimension 1 Code", "Global Dimension 2 Code",
          "Expected Cost", Positive, "Posting Date");
        ValueEntry.SetRange("Item No.", Rec."No.");
        ValueEntry.SetFilter("Location Code", Rec.GetFilter("Location Filter"));
        ValueEntry.SetFilter("Global Dimension 1 Code", Rec.GetFilter("Global Dimension 1 Filter"));
        case Show of
            Show::Start:
                ValueEntry.SetFilter("Posting Date", StartDateFilter);
            Show::Debit, Show::Credit:
                FillTempValueEntry(Show, TempValueEntry);
            Show::Ending:
                ValueEntry.SetFilter("Posting Date", EndDateFilter);
        end;
        ValueEntry.SetRange("Expected Cost", false);

        if (Show = Show::Debit) or (Show = Show::Credit) then
            if Value = Value::Quantity then
                PAGE.Run(0, TempValueEntry, TempValueEntry."Invoiced Quantity")
            else
                PAGE.Run(0, TempValueEntry, TempValueEntry."Cost Amount (Actual)")
        else
            if Value = Value::Quantity then
                PAGE.Run(0, ValueEntry, ValueEntry."Invoiced Quantity")
            else
                PAGE.Run(0, ValueEntry, ValueEntry."Cost Amount (Actual)");
    end;

    [Scope('OnPrem')]
    procedure CalcFilters()
    begin
        StartDateFilter := '';
        EndDateFilter := '';
        if Rec.GetFilter("Date Filter") <> '' then begin
            EndDateFilter := StrSubstNo('..%1', Rec.GetRangeMax("Date Filter"));
            if Rec.GetRangeMin("Date Filter") > 0D then
                StartDateFilter := StrSubstNo('..%1', CalcDate('<-1D>', Rec.GetRangeMin("Date Filter")));
        end;
    end;

    [Scope('OnPrem')]
    procedure FillTempValueEntry(Show: Option Start,Debit,Credit,Ending; var TempValueEntry: Record "Value Entry" temporary)
    begin
        TempValueEntry.CopyFilters(ValueEntry);
        TempValueEntry.SetFilter("Posting Date", Rec.GetFilter("Date Filter"));
        if ValueEntry.FindSet() then
            repeat
                TempValueEntry.Init();
                TempValueEntry := ValueEntry;
                if ((Show = Show::Debit) and TempValueEntry.IsDebit()) or
                   ((Show = Show::Credit) and not TempValueEntry.IsDebit())
                then
                    if TempValueEntry.Insert() then;
            until ValueEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CalculateAmounts(var ValueEntry: Record "Value Entry"; var DebitCost: Decimal; var CreditCost: Decimal; var DebitQty: Decimal; var CreditQty: Decimal)
    var
        TempValueEntry: Record "Value Entry";
    begin
        TempValueEntry.CopyFilters(ValueEntry);

        DebitCost := 0;
        CreditCost := 0;
        DebitQty := 0;
        CreditQty := 0;

        if TempValueEntry.FindSet() then
            repeat
                if TempValueEntry.IsDebit() then begin
                    DebitCost := DebitCost + TempValueEntry."Cost Amount (Actual)";
                    DebitQty := DebitQty + TempValueEntry."Invoiced Quantity";
                end else begin
                    CreditCost := CreditCost - TempValueEntry."Cost Amount (Actual)";
                    CreditQty := CreditQty - TempValueEntry."Invoiced Quantity";
                end;
            until TempValueEntry.Next() = 0;
    end;
}

