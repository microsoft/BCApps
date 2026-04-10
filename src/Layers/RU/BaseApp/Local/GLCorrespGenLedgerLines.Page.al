#pragma warning disable AA0247
page 35613 "G/L Corresp. Gen. Ledger Lines"
{
    Caption = 'G/L Corresp. Gen. Ledger Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "G/L Correspondence";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Debit Account No."; Rec."Debit Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the debit account number associated with this correspondence.';
                }
                field("Credit Account No."; Rec."Credit Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the credit account number associated with this correspondence.';
                }
                field(DebitAmount; GLCorrDebit.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Debit Amount';
                    Editable = false;
                    ToolTip = 'Specifies the debit amount for the period on the line.';

                    trigger OnDrillDown()
                    begin
                        DrillDown();
                    end;
                }
                field(CreditAmount; GLCorrCredit.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Credit Amount';
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        DrillDown();
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        GLCorrDebitAmountOnFormat(Format(GLCorrDebit.Amount));
        GLCorrCreditAmountOnFormat(Format(GLCorrCredit.Amount));
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        Rec.FilterGroup(0);
        RebuildView();
        Rec.FilterGroup(0);

        GLCorr := Rec;
        FindResult := GLCorr.Find(Which);
        if FindResult then begin
            Rec := GLCorr;
            GLCorrDebit := Rec;
            GLCorrCredit := Rec;
            if not GLCorrDebit.Find() then
                GLCorrDebit := GLCorrEmpty;
            if not GLCorrCredit.Find() then
                GLCorrCredit := GLCorrEmpty;
        end;
        exit(FindResult);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        GLCorr := Rec;
        NextResult := GLCorr.Next(Steps);
        if NextResult <> 0 then begin
            Rec := GLCorr;
            GLCorrDebit := Rec;
            GLCorrCredit := Rec;
            if not GLCorrDebit.Find() then
                GLCorrDebit := GLCorrEmpty;
            if not GLCorrCredit.Find() then
                GLCorrCredit := GLCorrEmpty;
        end;
        exit(NextResult);
    end;

    var
        GLCorr: Record "G/L Correspondence";
        GLCorrDebit: Record "G/L Correspondence";
        GLCorrCredit: Record "G/L Correspondence";
        GLCorrFilter: Record "G/L Correspondence" temporary;
        GLCorrEmpty: Record "G/L Correspondence" temporary;
        GLCorrEntry: Record "G/L Correspondence Entry";
        FindResult: Boolean;
        NextResult: Integer;

    [Scope('OnPrem')]
    procedure RebuildView()
    begin
        GLCorr.ClearMarks();
        GLCorrDebit.ClearMarks();
        GLCorrCredit.ClearMarks();

        GLCorr.MarkedOnly := false;
        GLCorrDebit.MarkedOnly := false;
        GLCorrCredit.MarkedOnly := false;

        GLCorr.Reset();
        GLCorrDebit.Reset();
        GLCorrCredit.Reset();

        GLCorr.CopyFilters(Rec);
        GLCorrDebit.CopyFilters(Rec);
        GLCorrCredit.CopyFilters(Rec);

        GLCorrDebit.CopyFilters(Rec);
        GLCorrDebit.SetRange("Debit Account No.");
        GLCorrDebit.SetRange("Credit Account No.");

        GLCorrCredit.CopyFilters(Rec);
        GLCorrCredit.SetRange("Debit Account No.");
        GLCorrCredit.SetRange("Credit Account No.");

        GLCorr.CopyFilters(Rec);
        GLCorr.SetRange("Debit Account No.");
        GLCorr.SetRange("Credit Account No.");

        GLCorrFilter.SetFilter("Debit Account No.", Rec.GetFilter("Debit Account No."));
        GLCorrFilter.SetFilter("Debit Global Dim. 1 Filter", Rec.GetFilter("Debit Global Dim. 1 Filter"));
        GLCorrFilter.SetFilter("Debit Global Dim. 2 Filter", Rec.GetFilter("Debit Global Dim. 2 Filter"));
        Rec.FilterGroup(0);

        GLCorr.SetRange("Debit Account No.");
        GLCorr.SetRange("Credit Account No.");

        GLCorrDebit.SetRange("Debit Account No.");
        GLCorrDebit.SetRange("Credit Account No.");

        GLCorrCredit.SetRange("Debit Account No.");
        GLCorrCredit.SetRange("Credit Account No.");

        GLCorrDebit.SetCurrentKey("Debit Account No.", "Credit Account No.");
        GLCorrDebit.SetFilter("Debit Account No.", GLCorrFilter.GetFilter("Debit Account No."));
        if GLCorrDebit.Find('-') then
            repeat
                GLCorrDebit.CalcFields(Amount);
                if GLCorrDebit.Amount <> 0 then begin
                    GLCorrDebit.Mark := true;
                    GLCorr.Get(GLCorrDebit."Debit Account No.", GLCorrDebit."Credit Account No.");
                    GLCorr.Mark := true;
                end;
            until GLCorrDebit.Next(1) = 0;
        GLCorrDebit.SetRange("Debit Account No.");

        GLCorrCredit.SetCurrentKey("Credit Account No.", "Debit Account No.");
        GLCorrCredit.SetFilter("Credit Account No.", GLCorrFilter.GetFilter("Debit Account No."));
        if GLCorrCredit.Find('-') then
            repeat
                GLCorrCredit.CalcFields(Amount);
                if GLCorrCredit.Amount <> 0 then begin
                    GLCorrCredit.Mark := true;
                    GLCorr.Get(GLCorrCredit."Debit Account No.", GLCorrCredit."Credit Account No.");
                    GLCorr.Mark := true;
                end;
            until GLCorrCredit.Next(1) = 0;
        GLCorrCredit.SetRange("Credit Account No.");

        GLCorr.MarkedOnly := true;
        GLCorrDebit.MarkedOnly := true;
        GLCorrCredit.MarkedOnly := true;
    end;

    [Scope('OnPrem')]
    procedure SeparateDebetCredit()
    begin
        GLCorrDebit := Rec;
        GLCorrCredit := Rec;
        if not GLCorrDebit.Find() then
            GLCorrDebit := GLCorrEmpty;
        if not GLCorrCredit.Find() then
            GLCorrCredit := GLCorrEmpty;
        GLCorrDebit.CalcFields(Amount);
        GLCorrCredit.CalcFields(Amount);
    end;

    [Scope('OnPrem')]
    procedure FormatAmount(Value: Decimal): Text[260]
    begin
        if Value = 0 then
            exit('');
        exit(Format(Value));
    end;

    [Scope('OnPrem')]
    procedure DrillDown()
    begin
        GLCorrEntry.Reset();
        GLCorrEntry.SetCurrentKey("Debit Account No.", "Credit Account No.");
        GLCorrEntry.SetRange("Debit Account No.", Rec."Debit Account No.");
        GLCorrEntry.SetRange("Credit Account No.", Rec."Credit Account No.");
        GLCorrEntry.SetFilter("Debit Global Dimension 1 Code", GLCorr.GetFilter("Debit Global Dim. 1 Filter"));
        GLCorrEntry.SetFilter("Debit Global Dimension 2 Code", GLCorr.GetFilter("Debit Global Dim. 2 Filter"));
        GLCorrEntry.SetFilter("Business Unit Code", GLCorr.GetFilter("Business Unit Filter"));
        GLCorrEntry.SetFilter("Posting Date", GLCorr.GetFilter("Date Filter"));
        PAGE.Run(0, GLCorrEntry);
    end;

    local procedure GLCorrDebitAmountOnFormat(Text: Text[1024])
    begin
        SeparateDebetCredit();
        Text := FormatAmount(GLCorrDebit.Amount);
    end;

    local procedure GLCorrCreditAmountOnFormat(Text: Text[1024])
    begin
        SeparateDebetCredit();
        Text := FormatAmount(GLCorrCredit.Amount);
    end;
}

