query 50050 "CWM Widget Sales"
{
    QueryType = Normal;

    elements
    {
        dataitem(Widget; "CWM Widget")
        {
            column(WidgetNo; "No.") { }
            column(WidgetDescription; Description) { }
            column(LinkedCustomerNo; "Linked Customer No.") { }
        }
    }
}
