codeunit 50024 "CWM Widget Query Reader"
{
    procedure ReadWidgetsForCustomer(CustomerNoFilter: Code[20])
    var
        WidgetSales: Query "CWM Widget Sales";
    begin
        WidgetSales.Open();
        WidgetSales.SetRange(LinkedCustomerNo, CustomerNoFilter);
        while WidgetSales.Read() do
            ProcessRow(WidgetSales.WidgetNo);
    end;

    local procedure ProcessRow(WidgetNo: Code[20])
    begin
    end;
}
