#pragma warning disable AA0247
page 14926 "VAT Allocation"
{
    AutoSplitKey = true;
    Caption = 'VAT Allocation';
    DataCaptionFields = "CV Ledger Entry No.";
    PageType = Worksheet;
    PopulateAllFields = true;
    SourceTable = "VAT Allocation Line";
    SourceTableView = sorting("CV Ledger Entry No.");

    layout
    {
        area(content)
        {
            repeater(Control1470000)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of VAT allocation.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to post the VAT allocation.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the VAT allocation entry.';
                }
                field(Base; Rec.Base)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the base amount is full, depreciated, or remaining.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Allocation %"; Rec."Allocation %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the percentage of the amount to be allocated to VAT.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount, including VAT, of the transaction.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("VAT Unreal. Account No."; Rec."VAT Unreal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account to temporarily post VAT amounts to pending settlement.';
                }
                field("VAT Entry No."; Rec."VAT Entry No.")
                {
                    ToolTip = 'Specifies the VAT entry number.';
                    Visible = false;
                }
            }
            group(Control1470021)
            {
                ShowCaption = false;
                field(AllocationAmount; AllocationAmount + Rec.Amount - xRec.Amount)
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    ApplicationArea = All;
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount.';
                    Visible = AllocationAmountVisible;
                }
                field(TotalAllocationAmount; TotalAllocationAmount + Rec.Amount - xRec.Amount)
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    ApplicationArea = All;
                    Caption = 'Total Amount';
                    Editable = false;
                    Visible = TotalAllocationAmountVisible;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                        CurrPage.Update();
                    end;
                }
                action(Allocations)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Allocations';
                    Image = Allocations;

                    trigger OnAction()
                    begin
                        Rec.ShowAllocationLines();
                    end;
                }
            }
            group("A&ccount")
            {
                Caption = 'A&ccount';
                Image = ChartOfAccounts;
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "G/L Account Card";
                    RunPageLink = "No." = field("Account No.");
                    ShortCutKey = 'Shift+F7';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    Image = VendorLedger;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    RunObject = Page "General Ledger Entries";
                    RunPageLink = "G/L Account No." = field("Account No.");
                    RunPageView = sorting("G/L Account No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateAllocationAmount();
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnInit()
    begin
        TotalAllocationAmountVisible := true;
        AllocationAmountVisible := true;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if Rec.GetFilter("VAT Entry No.") = '' then
            Error(Text001);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ShortcutDimCode);
    end;

    var
        CurrGenJnlLine: Record "Gen. Journal Line";
        AllocationAmount: Decimal;
        TotalAllocationAmount: Decimal;
        ShortcutDimCode: array[8] of Code[20];
#pragma warning disable AA0074
        Text001: Label 'You cannot insert new VAT Allocation lines.';
#pragma warning restore AA0074
        AllocationAmountVisible: Boolean;
        TotalAllocationAmountVisible: Boolean;

    local procedure UpdateAllocationAmount()
    var
        TempVATAlloc: Record "VAT Allocation Line";
        ShowAllocationAmount: Boolean;
        ShowTotalAllocationAmount: Boolean;
    begin
        TempVATAlloc.CopyFilters(Rec);
        TempVATAlloc.SetCurrentKey("CV Ledger Entry No.");
        ShowTotalAllocationAmount := TempVATAlloc.CalcSums(Amount);
        if ShowTotalAllocationAmount then begin
            TotalAllocationAmount := TempVATAlloc.Amount;
            if Rec."Line No." = 0 then
                TotalAllocationAmount := TotalAllocationAmount + xRec.Amount;
        end;

        if Rec."Line No." <> 0 then begin
            TempVATAlloc.SetRange("Line No.", 0, Rec."Line No.");
            ShowAllocationAmount := TempVATAlloc.CalcSums(Amount);
            if ShowAllocationAmount then
                AllocationAmount := TempVATAlloc.Amount;
        end else begin
            TempVATAlloc.SetRange("Line No.", 0, xRec."Line No.");
            ShowAllocationAmount := TempVATAlloc.CalcSums(Amount);
            if ShowAllocationAmount then begin
                AllocationAmount := TempVATAlloc.Amount;
                TempVATAlloc.CopyFilters(Rec);
                TempVATAlloc := xRec;
                if TempVATAlloc.Next() = 0 then
                    AllocationAmount := AllocationAmount + xRec.Amount;
            end;
        end;

        AllocationAmountVisible := ShowAllocationAmount;
        TotalAllocationAmountVisible := ShowTotalAllocationAmount;
    end;

    [Scope('OnPrem')]
    procedure SetCurrGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        CurrGenJnlLine := GenJnlLine;
    end;
}

