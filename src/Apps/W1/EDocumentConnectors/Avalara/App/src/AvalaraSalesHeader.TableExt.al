tableextension 6371 "Avalara Sales Header" extends "Sales Header"
{
    fields
    {
        field(6370; "Avalara Doc. ID"; Text[50])
        {
            Caption = 'Avalara Doc. ID';
            Editable = false;
            TableRelation = "E-Document"."Avalara Document Id";
        }
    }
}
