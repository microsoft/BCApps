query 132000 "Finishable Phys. Invt. Orders"
{

    elements
    {
        dataitem(Phys_Invt_Order_Header; "Phys. Invt. Order Header")
        {
            DataItemTableFilter = Status = const(Open);
            column(No; "No.")
            {
            }
            dataitem(Phys_Invt_Record_Header; "Phys. Invt. Record Header")
            {
                DataItemLink = "Order No." = Phys_Invt_Order_Header."No.";
                SqlJoinType = LeftOuterJoin;
                filter(Status; Status)
                {
                    ColumnFilter = Status = const(Finished);
                }
                dataitem(Phys_Invt_Order_Line; "Phys. Invt. Order Line")
                {
                    DataItemLink = "Document No." = Phys_Invt_Record_Header."Order No.";
                    filter(Qty_Exp_Calculated; "Qty. Exp. Calculated")
                    {
                        ColumnFilter = Qty_Exp_Calculated = const(true);
                    }
                }
            }
        }
    }
}

