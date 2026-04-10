// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Navigate;
using System.Security.User;

page 5647 "Ins. Coverage Ledger Entries"
{
    ApplicationArea = FixedAssets;
    Caption = 'Insurance Coverage Ledger Entries';
    DataCaptionFields = "Insurance No.";
    Editable = false;
    PageType = List;
    SourceTable = "Ins. Coverage Ledger Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Insurance No."; Rec."Insurance No.")
                {
                    ApplicationArea = FixedAssets;
                }
                field("FA No."; Rec."FA No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the related fixed asset. ';
                }
                field("FA Description"; Rec."FA Description")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = FixedAssets;
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = FixedAssets;
                }
                field("Index Entry"; Rec."Index Entry")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Disposed FA"; Rec."Disposed FA")
                {
                    ApplicationArea = FixedAssets;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
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
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
            }
        }
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Navigate.SetDoc(Rec."Posting Date", Rec."Document No.");
                    Navigate.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                group(Category_Entry)
                {
                    Caption = 'Entry';

                    actionref(Dimensions_Promoted; Dimensions)
                    {
                    }
                }
            }
        }
    }

    var
        Navigate: Page Navigate;
}

