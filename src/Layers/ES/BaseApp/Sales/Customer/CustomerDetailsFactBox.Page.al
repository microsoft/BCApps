// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Foundation.Comment;

page 9084 "Customer Details FactBox"
{
    Caption = 'Customer Details';
    PageType = CardPart;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = All;
                Caption = 'Customer No.';
                trigger OnDrillDown()
                begin
                    ShowDetails();
                end;
            }
            field(Name; Rec.Name)
            {
                ApplicationArea = Basic, Suite;
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
            field("Credit Limit (LCY)"; Rec."Credit Limit (LCY)")
            {
                ApplicationArea = Basic, Suite;
                StyleExpr = StyleTxt;
            }
            field(AvailableCreditLCY; Rec.CalcAvailableCreditUI())
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Available Credit (LCY)';
                ToolTip = 'Specifies a customer''s available credit. If the available credit is 0 and the customer''s credit limit is also 0, then the customer has unlimited credit because no credit limit has been defined.';

                trigger OnDrillDown()
                begin
                    PAGE.Run(PAGE::"Available Credit", Rec);
                end;
            }
            field("Payment Terms Code"; Rec."Payment Terms Code")
            {
                ApplicationArea = Basic, Suite;
            }
            field("Payment Method Code"; Rec."Payment Method Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies how payment for the document must be submitted, such as bank transfer or check.';
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
                action("Ship-to Address")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ship-to Address';
                    RunObject = Page "Ship-to Address List";
                    RunPageLink = "Customer No." = field("No.");
                    ToolTip = 'View the ship-to address that is specified for the customer.';
                }
                action(Comments)
                {
                    ApplicationArea = Comments;
                    Caption = 'Comments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const(Customer),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        StyleTxt := Rec.SetStyle();
    end;

    var
        StyleTxt: Text;

    local procedure ShowDetails()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDetails(Rec, IsHandled);
        if not IsHandled then
            PAGE.Run(PAGE::"Customer Card", Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDetails(var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;
}

