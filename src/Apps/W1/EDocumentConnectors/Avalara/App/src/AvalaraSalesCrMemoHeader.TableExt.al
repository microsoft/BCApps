namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.Sales.History;

tableextension 6373 "Avalara Sales Cr.Memo Header" extends "Sales Cr.Memo Header"
{
    fields
    {
        field(6370; "Avalara Doc. ID"; Text[50])
        {
            Caption = 'Avalara Doc. ID';
            DataClassification = ToBeClassified;
        }
    }
}
