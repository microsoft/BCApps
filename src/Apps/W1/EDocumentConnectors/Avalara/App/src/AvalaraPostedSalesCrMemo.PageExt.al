namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.Sales.History;

pageextension 6377 "Avalara Posted Sales Cr.Memo" extends "Posted Sales Credit Memo"
{
    layout
    {
        addafter("Applies-to Doc. No.")
        {
            field("Avalara Doc. ID"; Rec."Avalara Doc. ID")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the value of the Avalara Doc. ID field.';
                Visible = AvalaraDocIdVisable;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        AvalaraDocIdVisable := Rec."Avalara Doc. ID" <> '';
    end;

    var
        AvalaraDocIdVisable: Boolean;
}
