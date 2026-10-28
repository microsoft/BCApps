tableextension 50101 "PTE Purch. Inv. Header" extends "Purch. Inv. Header"
{
    fields
    {
        // Matching the source field ID and type preserves the value through posting's TransferFields.
        field(50100; "PTE Purchase Purpose"; Text[100])
        {
            Caption = 'Purchase Purpose';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies why the goods or services were purchased, as recorded when the purchase invoice was posted.';
        }
    }
}
