#pragma warning disable AA0247
query 12400 "Value Entry Item Tariff No."
{
    Caption = 'Value Entry Item Tariff No.';
    OrderBy = ascending(Tariff_No);

    elements
    {
        dataitem(Value_Entry; "Value Entry")
        {
            DataItemTableFilter = "Item No." = filter(<> '');
            column(Source_Type; "Source Type")
            {
            }
            column(Source_No; "Source No.")
            {
            }
            column(Document_No; "Document No.")
            {
            }
            column(Item_No; "Item No.")
            {
            }
            column(Document_Type; "Document Type")
            {
            }
            column(Document_Line_No; "Document Line No.")
            {
            }
            dataitem(Item; Item)
            {
                DataItemLink = "No." = Value_Entry."Item No.";
                DataItemTableFilter = "Tariff No." = filter(<> '');
                column(Tariff_No; "Tariff No.")
                {
                }
            }
        }
    }
}

