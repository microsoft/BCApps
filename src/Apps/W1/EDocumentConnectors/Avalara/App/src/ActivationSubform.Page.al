namespace Microsoft.EServices.EDocumentConnector.Avalara;

page 6375 "Activation Subform"
{
    ApplicationArea = All;
    Caption = 'Mandates';
    PageType = ListPart;
    SourceTable = "Activation Mandate";
    SourceTableTemporary = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Country Mandate"; Rec."Country Mandate")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Country Mandate field.';
                }
                field("Country Code"; Rec."Country Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Country Code field.';
                }
                field("Mandate Type"; Rec."Mandate Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Mandate Type field.';
                }
                field("Company ID"; Rec."Company Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Company Id field.';
                }
                field(Activated; Rec.Activated)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Activated field.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Blocked field.';
                }
            }
        }
    }

    procedure LoadForActivation(ActivationId: Guid; var Buffer: Record "Activation Mandate")
    begin
        if Buffer.FindSet() then
            repeat
                if Buffer."Activation ID" = ActivationId then begin
                    Rec := Buffer;

                    Rec.Insert();
                end;
            until Buffer.Next() = 0;
        CurrPage.Update(false);
    end;
}