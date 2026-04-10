// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Security.User;

/// <summary>
/// Preview page displaying G/L entries before posting for verification and validation.
/// Shows expected G/L entries from posting preview functionality using temporary table.
/// </summary>
/// <remarks>
/// PageType = List with SourceTableTemporary = true. Data source: G/L Entry (temporary).
/// Used in posting preview processes to display expected G/L entries before commitment.
/// Read-only interface for reviewing posting results with dimension and account details.
/// </remarks>
page 122 "G/L Entries Preview"
{
    Caption = 'G/L Entries Preview';
    DataCaptionExpression = GetCaption();
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "G/L Entry";
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
                field("VAT Date"; Rec."VAT Reporting Date")
                {
                    ApplicationArea = VAT;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("G/L Account No."; Rec."G/L Account No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("G/L Account Name"; Rec."G/L Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the entry or record.';
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
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
                field("IC Partner Code"; Rec."IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    Visible = false;
                }
                field("Gen. Posting Type"; Rec."Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = AmountVisible;
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = DebitCreditVisible;
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = DebitCreditVisible;
                }
                field("Source Currency Code"; Rec."Source Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the source currency code for G/L entries.';
                }
                field("Source Currency Amount"; Rec."Source Currency Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Additional-Currency Amount"; Rec."Additional-Currency Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    ApplicationArea = VAT;
                    Visible = false;
                }
                field("Source Currency VAT Amount"; Rec."Source Currency VAt Amount")
                {
                    ApplicationArea = VAT;
                    Editable = false;
                }
                field(NonDeductibleVATAmount; Rec."Non-Deductible VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field("Src. Curr. Non-Ded. VAT Amount"; Rec."Src. Curr. Non-Ded. VAT Amount")
                {
                    ApplicationArea = VAT;
                    Editable = false;
                    Visible = false;
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
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
                field(Reversed; Rec.Reversed)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Reversed by Entry No."; Rec."Reversed by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Reversed Entry No."; Rec."Reversed Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("FA Entry Type"; Rec."FA Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("FA Entry No."; Rec."FA Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
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
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        GenJnlPostPreview.ShowDimensions(DATABASE::"G/L Entry", Rec."Entry No.", Rec."Dimension Set ID");
                    end;
                }
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
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(SetDimensionFilter_Promoted; SetDimensionFilter)
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        AmountVisible := true;
    end;

    trigger OnOpenPage()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        SetDimVisibility();
        GLSetup.Get();
        AmountVisible := not (GLSetup."Show Amounts" = GLSetup."Show Amounts"::"Debit/Credit Only");
        DebitCreditVisible := not (GLSetup."Show Amounts" = GLSetup."Show Amounts"::"Amount Only");
    end;

    var
        GLAcc: Record "G/L Account";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
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
        AmountVisible, DebitCreditVisible : Boolean;

    local procedure SetDimVisibility()
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.UseShortcutDims(Dim1Visible, Dim2Visible, Dim3Visible, Dim4Visible, Dim5Visible, Dim6Visible, Dim7Visible, Dim8Visible);
    end;

    local procedure GetCaption(): Text[250]
    begin
        if GLAcc."No." <> Rec."G/L Account No." then
            if not GLAcc.Get(Rec."G/L Account No.") then
                if Rec.GetFilter(Rec."G/L Account No.") <> '' then
                    if GLAcc.Get(Rec.GetRangeMin("G/L Account No.")) then;
        exit(StrSubstNo('%1 %2', GLAcc."No.", GLAcc.Name))
    end;
}
