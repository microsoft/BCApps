page 30048 "APIV2 - Cust Financial Details"
{
    PageType = API;
    APIVersion = 'v2.0';
    EntityName = 'customerFinancialDetail';
    EntitySetName = 'customerFinancialDetails';
    EntityCaption = 'Customer Financial Detail';
    EntitySetCaption = 'Customer Financial Details';
    SourceTable = Customer;
    Editable = false;
    ODataKeyFields = SystemId;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    DelayedInsert = true;
    Extensible = false;


    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(number; Rec."No.")
                {
                    Caption = 'No.';
                    Editable = false;
                }
                field(balance; Rec."Balance (LCY)")
                {
                    Caption = 'Balance';
                    Editable = false;
                }
                field(totalSalesExcludingTax; Rec."Sales (LCY)")
                {
                    Caption = 'Total Sales Excluding Tax';
                    Editable = false;
                }
                field(overdueAmount; Rec."Balance Due (LCY)")
                {
                    Caption = 'Overdue Amount';
                    Editable = false;
                }
            }
        }

    }

    actions
    {
    }
    trigger OnAfterGetRecord()
    begin
        Rec.SetRange("Date Filter", 0D, WorkDate() - 1);
        Rec.CalcFields("Balance Due (LCY)", "Sales (LCY)", "Balance (LCY)");
    end;

}