namespace Microsoft.Inventory.Location;

using Microsoft.HumanResources.Employee;

tableextension 12410 "Location RU" extends Location
{
    fields
    {
        field(12400; "Last Goods Report No."; Integer)
        {
            BlankZero = true;
            Caption = 'Last Goods Report No.';
            DataClassification = CustomerContent;
        }
        field(12401; "Last Goods Report Date"; Date)
        {
            Caption = 'Last Goods Report Date';
            DataClassification = CustomerContent;
        }
        field(12410; "Responsible Employee No."; Code[20])
        {
            Caption = 'Responsible Employee No.';
            DataClassification = CustomerContent;
            TableRelation = Employee;
        }
    }
}