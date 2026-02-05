// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

page 7414 "Excise Tax Types"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Excise Tax Type";
    CardPageId = "Excise Tax Type Card";
    Caption = 'Excise Tax Types';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique tax identifier.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the tax name for UI display.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this tax type is active and available for use.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EntryPermissions)
            {
                ApplicationArea = All;
                Caption = 'Configure Entry Permissions';
                ToolTip = 'Configure entry type permissions for this tax type.';
                Image = Setup;
                RunObject = Page "Excise Tax Entry Permissions";
                RunPageLink = "Excise Tax Type Code" = field(Code);
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
            }
            action(ItemFARates)
            {
                ApplicationArea = All;
                Caption = 'Item/FA Rates';
                ToolTip = 'Configure tax rates for specific items and fixed assets.';
                Image = ItemAvailability;
                RunObject = Page "Excise Tax Item/FA Rates";
                RunPageLink = "Excise Tax Type Code" = field(Code);
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
            }
        }
        area(Navigation)
        {
            action(Card)
            {
                ApplicationArea = All;
                Caption = 'Card';
                ToolTip = 'Open the card for the selected tax type.';
                Image = EditLines;
                RunObject = Page "Excise Tax Type Card";
                RunPageLink = Code = field(Code);
                ShortCutKey = 'Shift+F7';
            }
        }
    }
}