// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

page 9150 "My Customers"
{
    Caption = 'My Customers';
    PageType = ListPart;
    SourceTable = "My Customer";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Width = 4;

                    trigger OnValidate()
                    begin
                        SyncFieldsWithCustomer();
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Lookup = false;
                    Width = 20;
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ExtendedDatatype = PhoneNo;
                    Lookup = false;
                    Width = 8;
                }
                field("Balance (LCY)"; Rec."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    trigger OnDrillDown()
                    begin
                        Customer.OpenCustomerLedgerEntries(false);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Open)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open';
                Image = ViewDetails;
                RunObject = Page "Customer Card";
                RunPageLink = "No." = field("Customer No.");
                RunPageMode = View;
                RunPageView = sorting("No.");
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SyncFieldsWithCustomer();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(Customer)
    end;

    trigger OnOpenPage()
    begin
        Rec.SetRange("User ID", UserId);
    end;

    protected var
        Customer: Record Customer;

    local procedure SyncFieldsWithCustomer()
    begin
        Clear(Customer);

        Customer.ReadIsolation(IsolationLevel::ReadCommitted);
        Customer.SetLoadFields(Name, "Phone No.");
        if Customer.Get(Rec."Customer No.") then
            if (Rec.Name <> Customer.Name) or (Rec."Phone No." <> Customer."Phone No.") then begin
                Rec.Name := Customer.Name;
                Rec."Phone No." := Customer."Phone No.";
                if not IsNullGuid(Rec.SystemId) then
                    Rec.Modify();
            end;
    end;
}

