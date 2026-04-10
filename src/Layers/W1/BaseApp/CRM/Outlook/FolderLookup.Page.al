namespace Microsoft.CRM.Outlook;

page 7030 "Folder Lookup"
{
    PageType = List;
    ApplicationArea = All;
    Caption = 'Select Contact Folder';
    SourceTable = "Contact Sync Folder";
    SourceTableTemporary = true;
    Editable = false;
    ShowFilter = false;
    LinksAllowed = false;
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                ShowCaption = false;

                field("Display Name"; Rec."Display Name")
                {
                    ApplicationArea = All;
                    Caption = '';
                    ShowCaption = false;
                }
            }
        }
    }

    actions
    {
    }

    procedure SetData(var TempFolder: Record "Contact Sync Folder" temporary)
    begin
        Rec.Copy(TempFolder, true);
    end;
}
