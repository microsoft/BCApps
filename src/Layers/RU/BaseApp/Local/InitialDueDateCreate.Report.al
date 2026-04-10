#pragma warning disable AA0247
report 17205 "Initial Due Date Create"
{
    Caption = 'Initial Due Date Create';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Detailed Vendor Ledg. Entry"; "Detailed Vendor Ledg. Entry")
        {
            DataItemTableView = sorting("Entry No.");
            RequestFilterFields = "Entry No.";

            trigger OnAfterGetRecord()
            begin
                VendLedgEntry.Get("Vendor Ledger Entry No.");
                "Initial Entry Positive" := VendLedgEntry.Positive;
                Modify();
            end;
        }
        dataitem("Detailed Cust. Ledg. Entry"; "Detailed Cust. Ledg. Entry")
        {

            trigger OnAfterGetRecord()
            begin
                CustLedgEntry.Get("Cust. Ledger Entry No.");
                "Initial Entry Positive" := CustLedgEntry.Positive;
                Modify();
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
}

