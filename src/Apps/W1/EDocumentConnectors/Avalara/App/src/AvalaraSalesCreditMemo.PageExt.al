pageextension 6380 "Avalara Sales Credit Memo" extends "Sales Credit Memo"
{
    layout
    {
        addafter("Applies-to ID")
        {
            field("Avalara Doc. ID"; Rec."Avalara Doc. ID")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Avalara Doc. ID field.';
                Visible = AvalaraDocIdVisible;
            }
        }
    }

    trigger OnOpenPage()
    var
        AvalaraFunctions: Codeunit "Avalara Functions";
    begin
        AvalaraDocIdVisible := AvalaraFunctions.IsAvalaraActive()
    end;

    var
        AvalaraDocIdVisible: Boolean;
}
