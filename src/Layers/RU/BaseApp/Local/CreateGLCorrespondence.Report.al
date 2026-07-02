#pragma warning disable AA0247
report 12430 "Create G/L Correspondence"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Create G/L Correspondence';
    Permissions = TableData "G/L Entry" = rimd,
                  TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd,
                  TableData "Item Ledger Entry" = rimd,
                  TableData "Job Ledger Entry" = rimd,
                  TableData "Res. Ledger Entry" = rimd,
                  TableData "VAT Entry" = rimd,
                  TableData "Bank Account Ledger Entry" = rimd,
                  TableData "Check Ledger Entry" = rimd,
                  TableData "FA Ledger Entry" = rimd,
                  TableData "Value Entry" = rimd,
                  TableData "Service Ledger Entry" = rimd,
                  TableData "Warranty Ledger Entry" = rimd,
                  TableData "G/L Correspondence Entry" = rimd,
                  TableData "VAT Ledger" = rimd,
                  TableData "VAT Ledger Line" = rimd;
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("G/L Entry"; "G/L Entry")
        {
            DataItemTableView = sorting("Transaction No.");
            RequestFilterFields = "Transaction No.";

            trigger OnAfterGetRecord()
            begin
                CorrespManagement.CreateCorrespEntries("G/L Entry");
                CurrReport.Break();
            end;

            trigger OnPostDataItem()
            begin
                Commit();
            end;

            trigger OnPreDataItem()
            begin
                TransactionFilter := GetFilter("Transaction No.");
                CorrespEntry.SetCurrentKey("Transaction No.");
                if TransactionFilter = '' then begin
                    if CorrespEntry.Find('+') then
                        SetFilter("Transaction No.", '%1..', CorrespEntry."Transaction No." + 1);
                end else begin
                    CorrespEntry.SetFilter("Transaction No.", TransactionFilter);
                    CorrespEntry.DeleteAll();
                end;
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

    trigger OnPostReport()
    begin
        Message(Text001);
    end;

    var
        CorrespEntry: Record "G/L Correspondence Entry";
        CorrespManagement: Codeunit "G/L Corresp. Management";
        TransactionFilter: Text[260];
#pragma warning disable AA0074
        Text001: Label 'G/L Correspondence created.';
#pragma warning restore AA0074
}

