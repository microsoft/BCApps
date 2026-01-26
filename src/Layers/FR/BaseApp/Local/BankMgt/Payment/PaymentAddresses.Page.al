// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

page 10875 "Payment Addresses"
{
    Caption = 'Payment Address';
    DataCaptionExpression = Legend;
    PageType = List;
    SourceTable = "Payment Address";

    layout
    {
        area(content)
        {
            repeater(Control1120000)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a payment address code.';
                }
                field("Default Value"; Rec."Default Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this address is the default payment address.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name associated with the payment address.';
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a search name.';
                }
                field("Name 2"; Rec."Name 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional part of the name associated with the payment address.';
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment address.';
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional part of the payment address.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payer''s post code.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the payment address.';
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the person you contact about payments to this address.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payer''s country/region code.';
                }
                field(County; Rec.County)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payer''s county name.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        AfterGetCurrentRecord();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        AfterGetCurrentRecord();
    end;

    var
        Text001: Label 'Customer';
        Text002: Label 'Vendor';
        Cust: Record Customer;
        Vend: Record Vendor;
        Legend: Text[250];

    local procedure AfterGetCurrentRecord()
    begin
        xRec := Rec;
        if Rec."Account Type" = Rec."Account Type"::Customer then begin
            Cust.Get(Rec."Account No.");
            Legend := Text001 + ' ' + Format(Rec."Account No.") + ' ' + Cust.Name;
        end else begin
            Vend.Get(Rec."Account No.");
            Legend := Text002 + ' ' + Format(Rec."Account No.") + ' ' + Vend.Name;
        end;
    end;
}

