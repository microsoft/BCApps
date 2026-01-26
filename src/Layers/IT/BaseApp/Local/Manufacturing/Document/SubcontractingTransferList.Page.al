#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Transfer;

page 35491 "Subcontracting Transfer List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Subcontracting Transfer Orders';
    CardPageID = "Subcontr. Transfer Order";
    Editable = false;
    PageType = List;
    SourceTable = "Transfer Header";
    SourceTableView = sorting("No.")
                      where("Subcontracting Order" = const(true));
    UsageCategory = Lists;
    ObsoleteReason = 'Preparation for replacement by Subcontracting app';
    ObsoleteState = Pending;
    ObsoleteTag = '27.0';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the document number.';
                }
                field("Transfer-from Code"; Rec."Transfer-from Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code of the location that you are transferring items from.';
                }
                field("Transfer-to Code"; Rec."Transfer-to Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code of the location that you are transferring items to.';
                }
                field("In-Transit Code"; Rec."In-Transit Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the transfer route for transferring items between locations.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        DimMgt.LookupDimValueCodeNoUpdate(1);
                    end;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        DimMgt.LookupDimValueCodeNoUpdate(2);
                    end;
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the user that the document is assigned to.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Re&lease")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Re&lease';
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the document.';

                    trigger OnAction()
                    var
                        TransHeader: Record "Transfer Header";
                        ReleaseTransferDoc: Codeunit "Release Transfer Document";
                    begin
                        CurrPage.SetSelectionFilter(TransHeader);
                        if TransHeader.Find('-') then
                            repeat
                                ReleaseTransferDoc.Run(TransHeader);
                            until TransHeader.Next() = 0;
                    end;
                }
            }
        }
    }

    var
        DimMgt: Codeunit DimensionManagement;
}
#endif
