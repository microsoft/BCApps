namespace System.Security.Encryption;

using System.Security.User;

page 1264 "Change User"
{
    Caption = 'Change User';
    SourceTable = "Isolated Certificate";

    layout
    {
        area(content)
        {
            field("User ID"; Rec."User ID")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User assigned to the certificate';
                LookupPageID = "User Lookup";

                trigger OnValidate()
                begin
                    Rec.TestField("User ID");
                end;
            }
        }
    }

    actions
    {
    }
}

