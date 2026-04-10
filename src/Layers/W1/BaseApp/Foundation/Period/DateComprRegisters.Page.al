// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Period;

using System.Reflection;
using System.Security.User;

page 107 "Date Compr. Registers"
{
    ApplicationArea = Suite;
    Caption = 'Date Compr. Registers';
    Editable = false;
    PageType = List;
    SourceTable = "Date Compr. Register";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Suite;
                }
                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = Suite;
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = Objects;
                }
                field("Table Caption"; Rec."Table Caption")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    DrillDownPageID = Objects;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Suite;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Suite;
                }
                field("Register No."; Rec."Register No.")
                {
                    ApplicationArea = Suite;
                }
                field("No. of New Records"; Rec."No. of New Records")
                {
                    ApplicationArea = Suite;
                }
                field("No. Records Deleted"; Rec."No. Records Deleted")
                {
                    ApplicationArea = Suite;
                }
                field("Filter"; Rec.Filter)
                {
                    ApplicationArea = Suite;
                }
                field("Period Length"; Rec."Period Length")
                {
                    ApplicationArea = Suite;
                }
                field("Retain Field Contents"; Rec."Retain Field Contents")
                {
                    ApplicationArea = Suite;
                }
                field("Retain Totals"; Rec."Retain Totals")
                {
                    ApplicationArea = Suite;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Suite;
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
                    ApplicationArea = Suite;
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

