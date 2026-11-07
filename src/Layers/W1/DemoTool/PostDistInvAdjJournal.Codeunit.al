codeunit 118850 "Post Dist. Inv. Adj. Journal"
{

    trigger OnRun()
    begin
        WhseJnlLine.SetRange("Registering Date", CA.AdjustDate(19030126D));
        if WhseJnlLine.FindFirst() then
            WhseJnlPostBatch.Run(WhseJnlLine);
    end;

    var
        WhseJnlLine: Record "Warehouse Journal Line";
        CA: Codeunit "Make Adjustments";
        WhseJnlPostBatch: Codeunit "Whse. Jnl.-Register Batch";
}

