namespace System.Environment.Configuration;

page 9169 "Profile Extension List"
{
    Caption = 'Profile Extensions';
    PageType = List;
    SourceTable = "All Profile Extension";
    Editable = false;
    Extensible = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(ProfileIdField; Rec."Profile ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Base Profile ID';
                    ToolTip = 'Specifies the ID of the profile that this profile extension is applied to.';
                }
                field(BaseProfileAppNameField; Rec."Profile App Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Base Profile Source';
                    ToolTip = 'Specifies the origin of the profile that this profile extension applies to, which can be either an extension (as indicated by its name) or a custom profile created by a user (indicated as user-created).';
                }
                field(AppNameField; Rec."App Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profile Extension Source';
                    ToolTip = 'Specifies that the profile extension was either made by users (indicated as user-created) or it is part of an installed extension (indicated by the extension name).';
                }
            }
        }
    }
}
