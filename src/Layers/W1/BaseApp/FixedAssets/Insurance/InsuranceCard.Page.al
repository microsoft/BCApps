// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Comment;

page 5644 "Insurance Card"
{
    Caption = 'Insurance Card';
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = Insurance;

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
                    Importance = Promoted;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                }
                field("Insurance Vendor No."; Rec."Insurance Vendor No.")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Effective Date"; Rec."Effective Date")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Expiration Date"; Rec."Expiration Date")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                }
                field("Insurance Type"; Rec."Insurance Type")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Policy No."; Rec."Policy No.")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                }
                field("Search Description"; Rec."Search Description")
                {
                    ApplicationArea = Comments;
                }
                field("Annual Premium"; Rec."Annual Premium")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Policy Coverage"; Rec."Policy Coverage")
                {
                    ApplicationArea = FixedAssets;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = FixedAssets;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = FixedAssets;
                }
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("FA Class Code"; Rec."FA Class Code")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                }
                field("FA Subclass Code"; Rec."FA Subclass Code")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                }
                field("FA Location Code"; Rec."FA Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ins&urance")
            {
                Caption = 'Ins&urance';
                Image = Insurance;
                action("Coverage Ledger E&ntries")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Coverage Ledger E&ntries';
                    Image = GeneralLedger;
                    RunObject = Page "Ins. Coverage Ledger Entries";
                    RunPageLink = "Insurance No." = field("No.");
                    RunPageView = sorting("Insurance No.", "Disposed FA", "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View insurance ledger entries that were created when you post to an insurance account from a purchase invoice, credit memo or journal line.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const(Insurance),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(5628),
                                  "No." = field("No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
                separator(Action24)
                {
                }
                action(Statistics)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Insurance Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View detailed historical information about the fixed asset.';
                }
                action("Total Value Ins&ured per FA")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Total Value Ins&ured per FA';
                    Image = TotalValueInsuredperFA;
                    RunObject = Page "Total Value Insured per FA";
                    ToolTip = 'View, in a matrix window, the amount of insurance registered with each insurance policy. These are the insurance-related amounts that you posted from a journal.';
                }
            }
        }
        area(reporting)
        {
            action(List)
            {
                ApplicationArea = FixedAssets;
                Caption = 'List';
                Image = OpportunitiesList;
                RunObject = Report "Insurance - List";
                ToolTip = 'View or edit the list of insurance policies in the system.';
            }
            action("Uninsured FAs")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Uninsured FAs';
                Image = "Report";
                RunObject = Report "Insurance - Uninsured FAs";
                ToolTip = 'View the individual fixed assets for which amounts have not been posted to an insurance policy. For each fixed asset, the report shows the asset''s acquisition cost, accumulated depreciation, and book value.';
            }
            action("Tot. Value Insured")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Tot. Value Insured';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Insurance - Tot. Value Insured";
                ToolTip = 'View each fixed asset with the amounts that you posted to each insurance policy. The entries in this report correspond to all of the entries in the Ins. Coverage Ledger Entry table. The amounts shown for each asset can be more or less than the actual insurance policy''s coverage. The amounts shown can differ from the actual book value of the asset.';
            }
            action("Coverage Details")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Coverage Details';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Insurance - Coverage Details";
                ToolTip = 'View the individual fixed assets that are linked to each insurance policy. For each insurance policy, the report shows one or more amounts for each asset. These are the amounts that need insurance coverage. These amounts can differ from the actual insurance policy''s coverage.';
            }
            action(Register)
            {
                ApplicationArea = FixedAssets;
                Caption = 'Register';
                Image = Confirm;
                RunObject = Report "Insurance Register";
                ToolTip = 'View registers containing all the fixed asset entries that are created. Every register shows the first and last entry number of its entries.';
            }
            action(Analysis)
            {
                ApplicationArea = FixedAssets;
                Caption = 'Analysis';
                Image = "Report";
                RunObject = Report "Insurance - Analysis";
                ToolTip = 'View an analysis of your fixed assets with various types of data for both individual assets and groups of assets.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Total Value Ins&ured per FA_Promoted"; "Total Value Ins&ured per FA")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref(List_Promoted; List)
                {
                }
                actionref("Uninsured FAs_Promoted"; "Uninsured FAs")
                {
                }
                actionref(Register_Promoted; Register)
                {
                }
                actionref(Analysis_Promoted; Analysis)
                {
                }
            }
        }
    }
}

