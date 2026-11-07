#pragma warning disable AA0247
codeunit 17302 "Tax Diff.-Post Jnl. Batch"
{
    TableNo = "Tax Diff. Journal Line";

    trigger OnRun()
    begin
        ClearAll();
        TaxDiffJnlLine.Copy(Rec);
        if TaxDiffJnlLine.FindSet() then begin
            Wnd.Open(Text1001 + Text1002);
            Total := TaxDiffJnlLine.Count;
            repeat
                if not TaxDiffJnlLine."Partial Disposal" then begin
                    Processing += 1;
                    Wnd.Update(1, TaxDiffJnlLine."Journal Batch Name");
                    Wnd.Update(2, Processing);
                    Wnd.Update(3, Round((Processing / Total) * 10000, 1));
                    if not EmptyLine() then
                        TaxDiffPostJnlLine.RunWithCheck(TaxDiffJnlLine);
                    TaxDiffJnlLine.Delete();
                end;
            until TaxDiffJnlLine.Next() = 0;
            if TaxDiffJnlLine.FindSet() then
                repeat
                    if TaxDiffJnlLine."Partial Disposal" then begin
                        Processing += 1;
                        Wnd.Update(1, TaxDiffJnlLine."Journal Batch Name");
                        Wnd.Update(2, Processing);
                        Wnd.Update(3, Round((Processing / Total) * 10000, 1));
                        if not EmptyLine() then
                            TaxDiffPostJnlLine.RunWithCheck(TaxDiffJnlLine);
                        TaxDiffJnlLine.Delete();
                    end;
                until TaxDiffJnlLine.Next() = 0;
            Wnd.Close();
        end;
    end;

    var
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        TaxDiffPostJnlLine: Codeunit "Tax Diff.-Post Jnl. Line";
        Wnd: Dialog;
        Total: Integer;
        Processing: Integer;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1001: Label 'Journal Batch Name  #1##########\';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1002: Label 'Posting lines       #2###### @3@@@@@@@@@@@@@';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure EmptyLine(): Boolean
    begin
        exit(
              (TaxDiffJnlLine."Asset Tax Amount" = 0) and
              (TaxDiffJnlLine."Liability Tax Amount" = 0) and
              (TaxDiffJnlLine."Disposal Mode" = TaxDiffJnlLine."Disposal Mode"::" "));
    end;
}

