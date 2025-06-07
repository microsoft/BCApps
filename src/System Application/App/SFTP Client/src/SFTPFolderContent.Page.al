page 50101 "SFTP Folder Content"
{
    Caption = 'SFTP Folder Content';
    PageType = List;
    UsageCategory = None;
    ApplicationArea = None;
    SourceTable = "SFTP Folder Content";
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {

                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
                field("Full Name"; Rec."Full Name")
                {
                    ApplicationArea = All;
                }
                field("Is Directory"; Rec."Is Directory")
                {
                    ApplicationArea = All;
                }
                field(Length; Rec.Length)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}