// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Archive;

using Microsoft.Utilities;
using System.Security.User;

page 6274 "Service List Archive"
{
    Caption = 'Service List Archive';
    Editable = false;
    PageType = List;
    SourceTable = "Service Header Archive";

    layout
    {
        area(content)
        {
            repeater(ServiceArchives)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field("Version No."; Rec."Version No.")
                {
                    ApplicationArea = Suite;
                }
                field("Date Archived"; Rec."Date Archived")
                {
                    ApplicationArea = Suite;
                }
                field("Time Archived"; Rec."Time Archived")
                {
                    ApplicationArea = Suite;
                }
                field("Archived By"; Rec."Archived By")
                {
                    ApplicationArea = Suite;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."Archived By");
                    end;
                }
                field("Interaction Exist"; Rec."Interaction Exist")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Suite;
                }
                field("Bill-to Contact No."; Rec."Bill-to Contact No.")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Bill-to Post Code"; Rec."Bill-to Post Code")
                {
                    ApplicationArea = Suite;
                }
                field("Bill-to Country/Region Code"; Rec."Bill-to Country/Region Code")
                {
                    ApplicationArea = Suite;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Suite;
                }
                field("Ship-to Name"; Rec."Ship-to Name")
                {
                    ApplicationArea = Suite;
                }
                field("Ship-to Contact"; Rec."Ship-to Contact")
                {
                    ApplicationArea = Suite;
                }
                field("Ship-to Post Code"; Rec."Ship-to Post Code")
                {
                    ApplicationArea = Suite;
                }
                field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the country/region code of the address that the items are shipped to.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Suite;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location from where inventory items to the customer on the sales document are to be shipped by default.';
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies which salesperson is associated with the sales list.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency that is used on the entry.';
                }
            }
        }
        area(factboxes)
        {
            systempart(RecordLinks; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(RecordNotes; Notes)
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
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;

                action(ShowDocument)
                {
                    ApplicationArea = Suite;
                    Caption = 'Show Document';
                    Image = EditLines;
                    ShortCutKey = 'Return';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    var
                        PageManagement: Codeunit "Page Management";
                    begin
                        PageManagement.PageRun(Rec);
                    end;
                }
            }
        }
    }
}