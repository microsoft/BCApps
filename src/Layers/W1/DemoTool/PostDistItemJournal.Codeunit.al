codeunit 118849 "Post Dist. Item Journal"
{

    trigger OnRun()
    begin
        "Item Journal Line".SetRange("Posting Date", CA.AdjustDate(19030126D));
        if "Item Journal Line".FindFirst() then
            ItemJnlPostBatch.Run("Item Journal Line");
    end;

    var
        "Item Journal Line": Record "Item Journal Line";
        CA: Codeunit "Make Adjustments";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
}

