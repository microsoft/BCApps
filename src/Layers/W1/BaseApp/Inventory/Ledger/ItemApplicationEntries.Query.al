namespace Microsoft.Inventory.Ledger;

query 302 "Item Application Entries"
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;
    Caption = 'Item Application Entries';

    elements
    {
        dataitem(Item_Application_Entry; "Item Application Entry")
        {
            column(Entry_No_; "Entry No.") { }
            column(Item_Ledger_Entry_No; "Item Ledger Entry No.") { }
            column(Inbound_Item_Entry_No; "Inbound Item Entry No.") { }
            column(Outbound_Item_Entry_No; "Outbound Item Entry No.") { }
            column(Quantity; Quantity) { }
            column(Posting_Date; "Posting Date") { }
            column(Transferred_from_Entry_No; "Transferred-from Entry No.") { }
            column(Cost_Application; "Cost Application") { }
            column(Output_Completely_Invd__Date; "Output Completely Invd. Date") { }
            column(Outbound_Entry_is_Updated; "Outbound Entry is Updated") { }
        }
    }
}