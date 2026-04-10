#pragma warning disable AA0247
page 17221 "Tax Register (1.3) Item"
{
    Caption = 'Tax Register (1.3) Item';
    DataCaptionExpression = Rec.FormTitle();
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SourceTable = "Tax Register Item Entry";
    SourceTableView = sorting("Section Code", "Entry Type", "Posting Date");

    layout
    {
        area(content)
        {
            repeater(Control100)
            {
                Editable = false;
                ShowCaption = false;
                field(ObjectName; Rec.ObjectName())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Name';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document description associated with this item entry.';
                }
                field("Qty. (Document)"; Rec."Qty. (Document)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document quantity associated with this item entry.';
                }
                field("Batch Date"; Rec."Batch Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the batch date associated with this item entry.';
                }
                field("Appl. Entry No."; Rec."Appl. Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the applied entry number associated with this item entry.';
                }
                field("Debit Qty."; Rec."Debit Qty.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit quantity associated with this item entry.';
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';
                }
                field("Amount (Document)"; Rec."Amount (Document)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document amount associated with this item entry.';
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
                field("Ledger Entry No."; Rec."Ledger Entry No.")
                {
                    ToolTip = 'Specifies the ledger entry number associated with this item entry.';
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
}

