report 134301 "Workflow Event Advanced Args"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            RequestFilterFields = "Buy-from Vendor No.", "Document Date", Amount;
            dataitem("Purchase Line"; "Purchase Line")
            {
                DataItemLink = "Document Type" = field("Document Type"), "Buy-from Vendor No." = field("Buy-from Vendor No."), "Document No." = field("No.");
                RequestFilterFields = Type, "No.", "Unit Cost";
            }
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group("Purchase Header")
                {
                    Caption = 'Purchase Header';
                    field(DueDate; "Purchase Header"."Due Date")
                    {
                        Caption = 'Due Date';
                    }
                    field(CurrencyCode; "Purchase Header"."Currency Code")
                    {
                        Caption = 'Currency Code';
                    }
                    group("Purchase Line")
                    {
                        Caption = 'Purchase Line';
                        field(Description; "Purchase Line".Description)
                        {
                            Caption = 'Description';
                        }
                        field(Quantity; "Purchase Line".Quantity)
                        {
                            Caption = 'Quantity';
                            AutoFormatType = 0;
                        }
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }
}
