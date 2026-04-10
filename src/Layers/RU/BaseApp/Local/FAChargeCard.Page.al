#pragma warning disable AA0247
page 14908 "FA Charge Card"
{
    Caption = 'FA Charge Card';
    PageType = Card;
    SourceTable = "FA Charge";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a description for the fixed asset charge.';
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Exclude Cost for TA"; Rec."Exclude Cost for TA")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies if a fixed asset charge should be excluded from tax accounting.';
                }
                field("G/L Acc. for Released FA"; Rec."G/L Acc. for Released FA")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the general ledger account to which any fixed asset changes should be applied.';
                }
                field("Tax Difference Code"; Rec."Tax Difference Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the tax difference code to apply to this fixed asset.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("FA Charge")
            {
                Caption = 'FA Charge';
                action(Dimensions)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(14907),
                                  "No." = field("No.");
                    ShortCutKey = 'Shift+Ctrl+D';
                }
                action("Ledger Entries")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Ledger Entries';
                    Image = LedgerEntries;
                    RunObject = Page "FA Ledger Entries";
                    RunPageLink = "FA Charge No." = field("No.");
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
            }
        }
    }
}

