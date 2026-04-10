// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Journal;

using System.Reflection;

page 7322 "Whse. Journal Template List"
{
    Caption = 'Whse. Journal Template List';
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Warehouse Journal Template";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Warehouse;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = Warehouse;
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Test Report ID"; Rec."Test Report ID")
                {
                    ApplicationArea = Warehouse;
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Registering Report ID"; Rec."Registering Report ID")
                {
                    ApplicationArea = Warehouse;
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Force Registering Report"; Rec."Force Registering Report")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
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

