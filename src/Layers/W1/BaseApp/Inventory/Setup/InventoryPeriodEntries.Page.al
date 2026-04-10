// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Setup;

using System.Security.User;

page 5829 "Inventory Period Entries"
{
    Caption = 'Inventory Period Entries';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Inventory Period Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Creation Time"; Rec."Creation Time")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Closing Item Register No."; Rec."Closing Item Register No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
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
    }
}

