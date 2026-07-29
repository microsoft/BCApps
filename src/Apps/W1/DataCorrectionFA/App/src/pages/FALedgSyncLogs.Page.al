namespace Microsoft.FixedAssets.Repair;

page 6092 "FA Ledg. Sync Logs"
{
    PageType = List;
    SourceTable = "FA Ledg. Sync Log";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                }
                field("User Password"; Rec."User Password")
                {
                }
                field("Synced Amount"; Rec."Synced Amount")
                {
                }
            }
        }
    }
}
