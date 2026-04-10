// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Setup;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Posting;

page 5607 "Fixed Asset Setup"
{
    AdditionalSearchTerms = 'fa setup';
    ApplicationArea = FixedAssets;
    Caption = 'Fixed Asset Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "FA Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Default Depr. Book"; Rec."Default Depr. Book")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Allow Posting to Main Assets"; Rec."Allow Posting to Main Assets")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Allow FA Posting From"; Rec."Allow FA Posting From")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Allow FA Posting To"; Rec."Allow FA Posting To")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Insurance Depr. Book"; Rec."Insurance Depr. Book")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Additional;
                }
                field("Automatic Insurance Posting"; Rec."Automatic Insurance Posting")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Additional;
                }
                field("Bonus Depreciation Percentage"; Rec."Bonus Depreciation %")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Additional;
                }
                field("Bonus Depr. Effective Date"; Rec."Bonus Depr. Effective Date")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Additional;
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Fixed Asset Nos."; Rec."Fixed Asset Nos.")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Insurance Nos."; Rec."Insurance Nos.")
                {
                    ApplicationArea = FixedAssets;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action("Depreciation Books")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Depreciation Books';
                Image = DepreciationBooks;
                RunObject = Page "Depreciation Book List";
                ToolTip = 'Set up depreciation books for various depreciation purposes, such as tax and financial statements.';
            }
            action("Depreciation Tables")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Depreciation Tables';
                Image = "Table";
                RunObject = Page "Depreciation Table List";
                ToolTip = 'Set up the different depreciation methods that you will use to depreciate fixed assets.';
            }
            action("FA Classes")
            {
                ApplicationArea = FixedAssets;
                Caption = 'FA Classes';
                Image = FARegisters;
                RunObject = Page "FA Classes";
                ToolTip = 'Set up different asset classes, such as Tangible Assets and Intangible Assets, to group your fixed assets by categories.';
            }
            action("FA Subclasses")
            {
                ApplicationArea = FixedAssets;
                Caption = 'FA Subclasses';
                Image = FARegisters;
                RunObject = Page "FA Subclasses";
                ToolTip = 'Set up different asset subclasses, such as Plant and Property and Machinery and Equipment, that you can assign to fixed assets and insurance policies.';
            }
            action("FA Locations")
            {
                ApplicationArea = FixedAssets;
                Caption = 'FA Locations';
                Image = FixedAssets;
                RunObject = Page "FA Locations";
                ToolTip = 'Set up different locations, such as a warehouse or a location within a warehouse, that you can assign to fixed assets.';
            }
            group(Posting)
            {
                Caption = 'Posting';
                action("FA Posting Type Setup")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Posting Type Setup';
                    Image = GeneralPostingSetup;
                    RunObject = Page "FA Posting Type Setup";
                    ToolTip = 'Define how to handle the Write-Down, Appreciation, Custom 1, and Custom 2 posting types that you use when posting to fixed assets.';
                }
                action("FA Posting Groups")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Posting Groups';
                    Image = GeneralPostingSetup;
                    RunObject = Page "FA Posting Groups";
                    ToolTip = 'Set up the accounts to which transactions are posted for fixed assets for each posting group, so that you can assign them to the relevant fixed assets.';
                }
                action("FA Journal Templates")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Journal Templates';
                    Image = JournalSetup;
                    RunObject = Page "FA Journal Templates";
                    ToolTip = 'Set up number series and reason codes in the journals that you use for fixed asset posting. By using different templates you can design windows with different layouts and you can assign trace codes, number series, and reports to each template.';
                }
                action("FA Reclass. Journal Templates")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Reclass. Journal Templates';
                    Image = JournalSetup;
                    RunObject = Page "FA Reclass. Journal Templates";
                    ToolTip = 'Set up number series and reason codes in the journal that you use to reclassify fixed assets. By using different templates you can design windows with different layouts and you can assign trace codes, number series, and reports to each template.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'General', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("FA Classes_Promoted"; "FA Classes")
                {
                }
                actionref("FA Subclasses_Promoted"; "FA Subclasses")
                {
                }
                actionref("FA Locations_Promoted"; "FA Locations")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Depreciation', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref("Depreciation Books_Promoted"; "Depreciation Books")
                {
                }
                actionref("Depreciation Tables_Promoted"; "Depreciation Tables")
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Posting', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref("FA Posting Type Setup_Promoted"; "FA Posting Type Setup")
                {
                }
                actionref("FA Posting Groups_Promoted"; "FA Posting Groups")
                {
                }
            }
            group(Category_Category7)
            {
                Caption = 'Journal Templates', Comment = 'Generated from the PromotedActionCategories property index 6.';

                actionref("FA Journal Templates_Promoted"; "FA Journal Templates")
                {
                }
                actionref("FA Reclass. Journal Templates_Promoted"; "FA Reclass. Journal Templates")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}

