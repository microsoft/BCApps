#pragma warning disable AA0247
page 8049 "General Ledger Setup API"
{
    APIGroup = 'subsBilling';
    APIPublisher = 'microsoft';
    APIVersion = 'v1.0';
    ApplicationArea = All;
    ModifyAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    EntityName = 'generalLedgerSetup';
    EntitySetName = 'generalLedgerSetup';
    PageType = API;
    SourceTable = "General Ledger Setup";
    ODataKeyFields = SystemId;
    AboutText = 'Exposes general ledger setup data including the local currency code and shortcut dimension codes for dimensions one through eight. Provides read-only access for external systems to retrieve ledger configuration needed for proper dimension mapping and currency handling in subscription billing integrations.';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(systemId; Rec.SystemId)
                {
                }
                field(lcyCode; Rec."LCY Code")
                {
                }
                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code")
                {
                }
                field(shortcutDimension2Code; Rec."Shortcut Dimension 2 Code")
                {
                }
                field(shortcutDimension3Code; Rec."Shortcut Dimension 3 Code")
                {
                }
                field(shortcutDimension4Code; Rec."Shortcut Dimension 4 Code")
                {
                }
                field(shortcutDimension5Code; Rec."Shortcut Dimension 5 Code")
                {
                }
                field(shortcutDimension6Code; Rec."Shortcut Dimension 6 Code")
                {
                }
                field(shortcutDimension7Code; Rec."Shortcut Dimension 7 Code")
                {
                }
                field(shortcutDimension8Code; Rec."Shortcut Dimension 8 Code")
                {
                }
            }
        }
    }
}
