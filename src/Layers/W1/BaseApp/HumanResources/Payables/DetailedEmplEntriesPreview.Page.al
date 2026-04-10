// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Payables;

using System.Security.User;

page 5240 "Detailed Empl. Entries Preview"
{
    Caption = 'Detailed Empl. Entries Preview';
    DataCaptionFields = "Employee Ledger Entry No.", "Employee No.";
    Editable = false;
    PageType = List;
    SourceTable = "Detailed Employee Ledger Entry";
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
                    ApplicationArea = BasicHR;
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = BasicHR;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = BasicHR;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = BasicHR;
                }
                field("Employee No."; Rec."Employee No.")
                {
                    ApplicationArea = BasicHR;
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
                    ApplicationArea = BasicHR;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the amount of the entry in LCY.';
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = BasicHR;
                    Visible = false;
                }
                field("Debit Amount (LCY)"; Rec."Debit Amount (LCY)")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits, expressed in LCY.';
                    Visible = false;
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = BasicHR;
                    Visible = false;
                }
                field("Credit Amount (LCY)"; Rec."Credit Amount (LCY)")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits, expressed in the local currency.';
                    Visible = false;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = BasicHR;
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
                    ApplicationArea = BasicHR;
                    Visible = false;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = BasicHR;
                    Visible = false;
                }
                field(Unapplied; Rec.Unapplied)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies whether the entry has been unapplied (undone) from the Unapply Employee Entries window by the entry no. shown in the Unapplied by Entry No. field.';
                    Visible = false;
                }
                field("Unapplied by Entry No."; Rec."Unapplied by Entry No.")
                {
                    ApplicationArea = BasicHR;
                    Visible = false;
                }
                field("Employee Ledger Entry No."; Rec."Employee Ledger Entry No.")
                {
                    ApplicationArea = BasicHR;
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = BasicHR;
                }
            }
        }
    }

    actions
    {
    }

    procedure Set(var TempDtldEmplLedgEntry: Record "Detailed Employee Ledger Entry" temporary)
    begin
        if TempDtldEmplLedgEntry.FindSet() then
            repeat
                Rec := TempDtldEmplLedgEntry;
                Rec.Insert();
            until TempDtldEmplLedgEntry.Next() = 0;
    end;
}

