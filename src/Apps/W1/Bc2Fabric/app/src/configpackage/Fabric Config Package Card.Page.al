namespace Microsoft.Bc2Fabric;

page 150006 "Fabric Config Package Card"
{
    Caption = 'Fabric Config Package';
    PageType = Card;
    SourceTable = "Fabric Config Package";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique code for the configuration package.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the configuration package.';
                }
                field(Version; Rec.Version)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the version of the configuration package.';
                }
                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this configuration package is currently active.';
                }
                field("Activated On"; Rec."Activated On")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when this package was last activated.';
                }
                field("Activated By"; Rec."Activated By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies who activated this package.';
                }
            }
            part(Lines; "Fabric Config Package Subform")
            {
                ApplicationArea = All;
                SubPageLink = "Package Code" = field("Code");
            }
        }
    }
}
