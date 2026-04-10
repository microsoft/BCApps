// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Ledger;

using Microsoft.Finance.Dimension;
using System.Security.User;

page 5606 "FA Ledger Entries Preview"
{
    Caption = 'FA Ledger Entries Preview';
    DataCaptionFields = "FA No.", "Depreciation Book Code";
    Editable = false;
    PageType = List;
    SourceTable = "FA Ledger Entry";
    SourceTableTemporary = true;
    AboutTitle = 'About FA Ledger Entries Preview';
    AboutText = 'With the **FA Ledger Entries Preview**, you can review the FA ledger entry details that will be created when you post the document or journal with the fixed assets.';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("FA Posting Date"; Rec."FA Posting Date")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = FixedAssets;
                }
                field("FA No."; Rec."FA No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the related fixed asset. ';
                }
                field("Depreciation Book Code"; Rec."Depreciation Book Code")
                {
                    ApplicationArea = FixedAssets;
                }
                field("FA Posting Category"; Rec."FA Posting Category")
                {
                    ApplicationArea = FixedAssets;
                }
                field("FA Posting Type"; Rec."FA Posting Type")
                {
                    ApplicationArea = FixedAssets;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = FixedAssets;
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = Dim1Visible;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = Dim2Visible;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = FixedAssets;
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Reclassification Entry"; Rec."Reclassification Entry")
                {
                    ApplicationArea = Dimensions;
                }
                field("Index Entry"; Rec."Index Entry")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("No. of Depreciation Days"; Rec."No. of Depreciation Days")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = FixedAssets;
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
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field(Reversed; Rec.Reversed)
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Reversed by Entry No."; Rec."Reversed by Entry No.")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Reversed Entry No."; Rec."Reversed Entry No.")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Dimension Set ID"; Rec."Dimension Set ID")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Shortcut Dimension 3 Code"; Rec."Shortcut Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim3Visible;
                }
                field("Shortcut Dimension 4 Code"; Rec."Shortcut Dimension 4 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim4Visible;
                }
                field("Shortcut Dimension 5 Code"; Rec."Shortcut Dimension 5 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim5Visible;
                }
                field("Shortcut Dimension 6 Code"; Rec."Shortcut Dimension 6 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim6Visible;
                }
                field("Shortcut Dimension 7 Code"; Rec."Shortcut Dimension 7 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim7Visible;
                }
                field("Shortcut Dimension 8 Code"; Rec."Shortcut Dimension 8 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim8Visible;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(SetDimensionFilter)
            {
                ApplicationArea = Dimensions;
                Caption = 'Set Dimension Filter';
                Ellipsis = true;
                Image = "Filter";
                ToolTip = 'Limit the entries according to the dimension filters that you specify. NOTE: If you use a high number of dimension combinations, this function may not work and can result in a message that the SQL server only supports a maximum of 2100 parameters.';

                trigger OnAction()
                begin
                    Rec.SetFilter("Dimension Set ID", DimensionSetIDFilter.LookupFilter());
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetDimVisibility();
    end;

    var
        DimensionSetIDFilter: Page "Dimension Set ID Filter";

    protected var
        Dim1Visible: Boolean;
        Dim2Visible: Boolean;
        Dim3Visible: Boolean;
        Dim4Visible: Boolean;
        Dim5Visible: Boolean;
        Dim6Visible: Boolean;
        Dim7Visible: Boolean;
        Dim8Visible: Boolean;

    local procedure SetDimVisibility()
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.UseShortcutDims(Dim1Visible, Dim2Visible, Dim3Visible, Dim4Visible, Dim5Visible, Dim6Visible, Dim7Visible, Dim8Visible);
    end;

    procedure Set(var TempFALedgerEntry: Record "FA Ledger Entry" temporary)
    begin
        if TempFALedgerEntry.FindSet() then
            repeat
                Rec := TempFALedgerEntry;
                Rec.Insert();
            until TempFALedgerEntry.Next() = 0;
    end;
}

