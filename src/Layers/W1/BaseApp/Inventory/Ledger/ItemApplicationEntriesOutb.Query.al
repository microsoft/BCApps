namespace Microsoft.Inventory.Ledger;

query 304 "Item Application Entries Outb."
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;
    Caption = 'Item Application Entries';
    Description = 'Item application entries retrieved for outbound entries check.';
    OrderBy = ascending(Inbound_Item_Entry_No, Item_Ledger_Entry_No, Outbound_Item_Entry_No, Cost_Application);

    elements
    {
        dataitem(Item_Application_Entry; "Item Application Entry")
        {
            column(Entry_No_; "Entry No.") { }
            column(Item_Ledger_Entry_No; "Item Ledger Entry No.") { }
            column(Inbound_Item_Entry_No; "Inbound Item Entry No.") { }
            column(Outbound_Item_Entry_No; "Outbound Item Entry No.") { }
            column(Quantity; Quantity) { }
            column(Transferred_from_Entry_No; "Transferred-from Entry No.") { }
            column(Cost_Application; "Cost Application") { }
            column(Outbound_Entry_is_Updated; "Outbound Entry is Updated") { }
        }
    }
}