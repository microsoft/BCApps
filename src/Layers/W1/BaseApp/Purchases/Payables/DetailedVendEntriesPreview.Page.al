// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using System.Security.User;

page 129 "Detailed Vend. Entries Preview"
{
    Caption = 'Detailed Vend. Ledg. Entries Preview';
    DataCaptionFields = "Vendor Ledger Entry No.", "Vendor No.";
    Editable = false;
    PageType = List;
    SourceTable = "Detailed Vendor Ledg. Entry";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Initial Entry Global Dim. 1"; Rec."Initial Entry Global Dim. 1")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Initial Entry Global Dim. 2"; Rec."Initial Entry Global Dim. 2")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the entry in LCY.';
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Debit Amount (LCY)"; Rec."Debit Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits, expressed in LCY.';
                    Visible = false;
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Credit Amount (LCY)"; Rec."Credit Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits, expressed in LCY.';
                    Visible = false;
                }
                field("Initial Entry Due Date"; Rec."Initial Entry Due Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
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
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field(Unapplied; Rec.Unapplied)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Unapplied by Entry No."; Rec."Unapplied by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Vendor Ledger Entry No."; Rec."Vendor Ledger Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    procedure Set(var TempDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry" temporary)
    begin
        if TempDtldVendLedgEntry.FindSet() then
            repeat
                Rec := TempDtldVendLedgEntry;
                Rec.Insert();
            until TempDtldVendLedgEntry.Next() = 0;
    end;
}

