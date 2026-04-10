// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Foundation.Comment;

page 9093 "Vendor Details FactBox"
{
    Caption = 'Vendor Details';
    PageType = CardPart;
    SourceTable = Vendor;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = All;
                Caption = 'Vendor No.';

                trigger OnDrillDown()
                begin
                    ShowDetails();
                end;
            }
            field(Name; Rec.Name)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the vendor''s name.';
            }
            field("Phone No."; Rec."Phone No.")
            {
                ApplicationArea = Basic, Suite;
            }
            field("E-Mail"; Rec."E-Mail")
            {
                ApplicationArea = Basic, Suite;
                ExtendedDatatype = EMail;
            }
            field("Fax No."; Rec."Fax No.")
            {
                ApplicationArea = Basic, Suite;
            }
            field(Contact; Rec.Contact)
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("Actions")
            {
                Caption = 'Actions';
                Image = "Action";
                action(Comments)
                {
                    ApplicationArea = Comments;
                    Caption = 'Comments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const(Vendor),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
    }

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Vendor Card", Rec);
    end;
}

