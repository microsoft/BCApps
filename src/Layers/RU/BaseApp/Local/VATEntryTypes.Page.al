#pragma warning disable AA0247
page 14977 "VAT Entry Types"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Entry Types';
    PageType = Card;
    SourceTable = "VAT Entry Type";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if a comment is associated with this entry.';
                }
            }
        }
    }

    actions
    {
    }

    [Scope('OnPrem')]
    procedure GetSelection() SetOfVATEntryType: Code[20]
    var
        VATEntryType: Record "VAT Entry Type";
    begin
        CurrPage.SetSelectionFilter(VATEntryType);
        if VATEntryType.FindSet() then
            repeat
                if SetOfVATEntryType = '' then
                    SetOfVATEntryType := VATEntryType.Code
                else
                    SetOfVATEntryType := SetOfVATEntryType + ';' + VATEntryType.Code;
            until VATEntryType.Next() = 0;
    end;
}

