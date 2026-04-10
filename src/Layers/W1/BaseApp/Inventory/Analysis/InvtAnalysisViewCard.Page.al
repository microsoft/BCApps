// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;

page 7150 "Invt. Analysis View Card"
{
    Caption = 'Invt. Analysis View Card';
    PageType = Card;
    SourceTable = "Item Analysis View";
    SourceTableView = where("Analysis Area" = const(Inventory));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Item Filter"; Rec."Item Filter")
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemList: Page "Item List";
                    begin
                        ItemList.LookupMode(true);
                        if ItemList.RunModal() = ACTION::LookupOK then begin
                            Text := ItemList.GetSelectionFilter();
                            exit(true);
                        end;
                    end;
                }
                field("Location Filter"; Rec."Location Filter")
                {
                    ApplicationArea = Location;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        LocList: Page "Location List";
                    begin
                        LocList.LookupMode(true);
                        if LocList.RunModal() = ACTION::LookupOK then begin
                            Text := LocList.GetSelectionFilter();
                            exit(true);
                        end;
                    end;
                }
                field("Date Compression"; Rec."Date Compression")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Last Date Updated"; Rec."Last Date Updated")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Last Entry No."; Rec."Last Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Last Budget Entry No."; Rec."Last Budget Entry No.")
                {
                    ApplicationArea = ItemBudget;
                }
                field("Update on Posting"; Rec."Update on Posting")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Dimensions)
            {
                Caption = 'Dimensions';
                field("Dimension 1 Code"; Rec."Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Dimension 2 Code"; Rec."Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Dimension 3 Code"; Rec."Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
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
            group("&Analysis")
            {
                Caption = '&Analysis';
                Image = AnalysisView;
                action("Filter")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Filter';
                    Image = "Filter";
                    RunObject = Page "Item Analysis View Filter";
                    RunPageLink = "Analysis Area" = field("Analysis Area"),
                                  "Analysis View Code" = field(Code);
                    ToolTip = 'Apply the filter.';
                }
            }
        }
        area(processing)
        {
            action("&Update")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Update';
                Image = Refresh;
                RunObject = Codeunit "Update Item Analysis View";
                ToolTip = 'Get the latest entries into the analysis view.';
            }
            action("Enable Update on Posting")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Enable Update on Posting';
                Image = Apply;
                ToolTip = 'Ensure that the analysis view is updated when new ledger entries are posted.';

                trigger OnAction()
                begin
                    Rec.SetUpdateOnPosting(true);
                end;
            }
            action("Disable Update on Posting")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Disable Update on Posting';
                Image = UnApply;
                ToolTip = 'Ensure that the analysis view is not updated when new ledger entries are posted.';

                trigger OnAction()
                begin
                    Rec.SetUpdateOnPosting(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Update_Promoted"; "&Update")
                {
                }
            }
        }
    }
}

