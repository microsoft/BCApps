tableextension 50100 "PTE Purchase Header" extends "Purchase Header"
{
    fields
    {
        field(50100; "PTE Purchase Purpose"; Text[100])
        {
            Caption = 'Purchase Purpose';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies why the goods or services are being purchased. The purpose is retained on the posted purchase invoice.';
        }
    }
}
