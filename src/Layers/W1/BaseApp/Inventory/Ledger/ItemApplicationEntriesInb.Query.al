namespace Microsoft.Inventory.Ledger;

query 303 "Item Application Entries Inb."
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;
    Caption = 'Item Application Entries';
    Description = 'Item application entries retrieved for inbound entries check.';
    OrderBy = ascending(Outbound_Item_Entry_No, Item_Ledger_Entry_No, Cost_Application, Transferred_from_Entry_No);

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
        }
    }
}