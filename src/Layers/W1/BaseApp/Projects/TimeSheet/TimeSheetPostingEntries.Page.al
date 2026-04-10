// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using Microsoft.Foundation.Navigate;

page 958 "Time Sheet Posting Entries"
{
    Caption = 'Time Sheet Posting Entries';
    DataCaptionFields = "Time Sheet No.";
    Editable = false;
    PageType = List;
    SourceTable = "Time Sheet Posting Entry";

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("Time Sheet No."; Rec."Time Sheet No.")
                {
                    ApplicationArea = Jobs;
                }
                field("Time Sheet Line No."; Rec."Time Sheet Line No.")
                {
                    ApplicationArea = Jobs;
                }
                field("Time Sheet Date"; Rec."Time Sheet Date")
                {
                    ApplicationArea = Jobs;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Jobs;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Jobs;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Jobs;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Jobs;
                }
            }
        }
    }

    actions
    {
        area(creation)
        {
            action("&Navigate")
            {
                ApplicationArea = Jobs;
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
            }
        }
    }

    var
        Navigate: Page Navigate;
}

