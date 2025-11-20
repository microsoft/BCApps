// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

page 9151 "My Vendors"
{
    Caption = 'My Vendors';
    PageType = ListPart;
    SourceTable = "My Vendor";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor numbers that are displayed in the My Vendor Cue on the Role Center.';

                    trigger OnValidate()
                    begin
                        SyncFieldsWithVendor();
                    end;
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Phone No.';
                    DrillDown = false;
                    ExtendedDatatype = PhoneNo;
                    Lookup = false;
                    ToolTip = 'Specifies the vendor''s phone number.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    DrillDown = false;
                    Lookup = false;
                    ToolTip = 'Specifies the name of the record.';
                }
                field("<Balance>"; Rec."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance';
                    ToolTip = 'Specifies the balance.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        Vendor: Record Vendor;
                    begin
                        Vendor.Get(Rec."Vendor No.");
                        Vendor.OpenVendorLedgerEntries(false);
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
                RunObject = Page "Vendor Card";
                RunPageLink = "No." = field("Vendor No.");
                RunPageMode = View;
                RunPageView = sorting("No.");
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SyncFieldsWithVendor();
    end;

    trigger OnOpenPage()
    begin
        Rec.SetRange("User ID", UserId);
    end;

    local procedure SyncFieldsWithVendor()
    var
        Vendor: Record Vendor;
    begin
        Vendor.ReadIsolation(IsolationLevel::ReadCommitted);
        Vendor.SetLoadFields(Name, "Phone No.");
        if Vendor.Get(Rec."Vendor No.") then
            if (Rec.Name <> Vendor.Name) or (Rec."Phone No." <> Vendor."Phone No.") then begin
                Rec.Name := Vendor.Name;
                Rec."Phone No." := Vendor."Phone No.";
                if not IsNullGuid(Rec.SystemId) then
                    Rec.Modify();
            end;
    end;
}

