// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
namespace Microsoft.FixedAssets.Ledger;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Reversal;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.Foundation.Navigate;
using System.Security.User;

page 5604 "FA Ledger Entries"
{
    AdditionalSearchTerms = 'fixed asset ledger entries';
    ApplicationArea = FixedAssets;
    Caption = 'FA Ledger Entries';
    DataCaptionFields = "FA No.", "Depreciation Book Code";
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "FA Ledger Entry";
    SourceTableView = sorting("Entry No.");
    UsageCategory = History;
    AboutTitle = 'About FA Ledger Entries';
    AboutText = 'With the **FA Ledger Entries**, you can review the fixed asset ledger entry that is created when you post to a fixed asset account. You can select the entry and create cancel entries / reverse transactions.When activating analysis mode on this page, you can also perform ad-hoc analysis on Fixed Assets transactions as an alternative to running reports.';

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
                    Editable = false;
                    ToolTip = 'Specifies the posting date of the related fixed asset transaction, such as a depreciation.';
                }
                field("Depr. Period Starting Date"; Rec."Depr. Period Starting Date")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the start date of the depreciation period associated with the fixed asset ledger entry.';
                    Visible = false;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the entry document type.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the document number on the entry.';
                }
                field("FA No."; Rec."FA No.")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the number of the related fixed asset. ';
                }
                field("Depreciation Book Code"; Rec."Depreciation Book Code")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                }
                field("FA Posting Group"; Rec."FA Posting Group")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies which posting group is used for the depreciation book when posting fixed asset transactions.';
                    Visible = false;
                }
                field("FA Posting Category"; Rec."FA Posting Category")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the posting category assigned to the entry when it was posted.';
                }
                field("FA Posting Type"; Rec."FA Posting Type")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the posting type, if Account Type field contains Fixed Asset.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies a description of the entry.';
                }
                field("Need Cost Posted to G/L"; Rec."Need Cost Posted to G/L")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies if the need cost is posted to general ledger.';
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = Dim1Visible;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = Dim2Visible;
                }
                field("Employee No."; Rec."Employee No.")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the number of the involved employee.';
                }
                field("FA Location Code"; Rec."FA Location Code")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the location, such as a building, where the fixed asset is located.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the record are processed.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the entry amount in currency.';
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
                field(RunningBalance; CalcRunningFABalance.GetFABalance(Rec))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Running Balance';
                    ToolTip = 'Specifies the running balance.';
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Visible = false;
                }
                field("Reclassification Entry"; Rec."Reclassification Entry")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies whether the entry was made to reclassify a fixed asset, for example, to change the dimension the fixed asset is linked to.';
                }
                field("Index Entry"; Rec."Index Entry")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    Visible = false;
                }
                field("No. of Depreciation Days"; Rec."No. of Depreciation Days")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    Visible = false;
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    Visible = false;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
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
                    Editable = false;
                    Visible = false;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    Visible = false;
                }
                field(Reversed; Rec.Reversed)
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    Visible = false;
                }
                field("Reversed by Entry No."; Rec."Reversed by Entry No.")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    Visible = false;
                }
                field("Reversed Entry No."; Rec."Reversed Entry No.")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    Visible = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("G/L Entry No."; Rec."G/L Entry No.")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                }
                field("Initial Acquisition"; Rec."Initial Acquisition")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies if the fixed asset ledger entry is an initial acquisition.';
                }
                field("Depr. Bonus"; Rec."Depr. Bonus")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies if the fixed asset ledger entry contains a depreciation bonus.';
                }
                field("Depr. Bonus Recovery Date"; Rec."Depr. Bonus Recovery Date")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies date of the depreciation bonus recovery associated with the fixed asset ledger entry.';
                }
                field("Depr. Group Elimination"; Rec."Depr. Group Elimination")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the depreciation group elimination of the fixed asset ledger entry.';
                    Visible = false;
                }
                field("Tax Difference Code"; Rec."Tax Difference Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the tax difference code associated with the fixed asset ledger entry.';
                    Visible = false;
                }
                field("Sales Gain Amount"; Rec."Sales Gain Amount")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the sales gain amount associated with the fixed asset ledger entry.';
                }
                field("Sales Loss Amount"; Rec."Sales Loss Amount")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the sales loss amount associated with the fixed asset ledger entry.';
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
        area(navigation)
        {
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
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
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CancelEntries)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Cancel Entries';
                    Ellipsis = true;
                    Image = CancelLine;
                    AboutTitle = 'Cancel the wrong entries';
                    AboutText = 'Use the Cancel Entries option to create the cancel entry in the Fixed Asset G/L Journal or Fixed Asset Journal with this the entry will get removed from the FA ledger entries.';
                    ToolTip = 'Remove one or more fixed asset ledger entries from the FA Ledger Entries window. If you posted erroneous transactions to one or more fixed assets, you can use this function to cancel the fixed asset ledger entries. In the FA Ledger Entries window, select the entry or entries that you want to cancel.';

                    trigger OnAction()
                    begin
                        FALedgEntry.Copy(Rec);
                        CurrPage.SetSelectionFilter(FALedgEntry);
                        Clear(CancelFAEntries);
                        CancelFAEntries.GetFALedgEntry(FALedgEntry);
                        CancelFAEntries.RunModal();
                        Clear(CancelFAEntries);
                    end;
                }
                separator(Action37)
                {
                }
                action(ReverseTransaction)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Reverse Transaction';
                    Ellipsis = true;
                    Image = ReverseRegister;
                    ToolTip = 'Undo an erroneous journal posting.';

                    trigger OnAction()
                    var
                        ReversalEntry: Record "Reversal Entry";
                        FADeprBook: Record "FA Depreciation Book";
                    begin
                        Clear(ReversalEntry);
                        if Rec.Reversed then
                            ReversalEntry.AlreadyReversedEntry(Rec.TableCaption, Rec."Entry No.");
                        if Rec."Journal Batch Name" = '' then
                            ReversalEntry.TestFieldError();
                        FADeprBook.Get(Rec."FA No.", Rec."Depreciation Book Code");
                        if FADeprBook."Disposal Date" > 0D then
                            Error(Text001);
                        if Rec."Transaction No." = 0 then
                            Error(CannotUndoErr, Rec."Entry No.", Rec."Depreciation Book Code");
                        Rec.TestField(Rec."G/L Entry No.");
                        ReversalEntry.ReverseTransaction(Rec."Transaction No.");
                        Clear(CalcRunningFABalance);
                    end;
                }
                separator(Action1470001)
                {
                }
                action("Mark As Depr. Bonus Base")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Mark As Depr. Bonus Base';
                    Image = ReOpen;
                    ToolTip = 'Set the selected entry to take part in calculating the depreciation bonus. A depreciation bonus is an accelerated depreciation method applied in tax accounting because of provisions in the Russian tax laws. A depreciation bonus enables you to include fixed asset and capital investment expenses in the current period at the rate of 10 percent or 30 percent.';

                    trigger OnAction()
                    var
                        FALedgEntry1: Record "FA Ledger Entry";
                    begin
                        FALedgEntry1.Reset();
                        CurrPage.SetSelectionFilter(FALedgEntry1);
                        FALedgEntry.UnMarkAsDeprBonusBase(FALedgEntry1, true);
                    end;
                }
                action("Unmark As Depr. Bonus Base")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Unmark As Depr. Bonus Base';
                    Image = ReopenCancelled;
                    ToolTip = 'Set the selected entry to not take part in calculating the depreciation bonus. A depreciation bonus is an accelerated depreciation method applied in tax accounting because of provisions in the Russian tax laws. A depreciation bonus enables you to include fixed asset and capital investment expenses in the current period at the rate of 10 percent or 30 percent.';

                    trigger OnAction()
                    var
                        FALedgEntry1: Record "FA Ledger Entry";
                    begin
                        FALedgEntry1.Reset();
                        CurrPage.SetSelectionFilter(FALedgEntry1);
                        FALedgEntry.UnMarkAsDeprBonusBase(FALedgEntry1, false);
                    end;
                }
            }
            action("&Navigate")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Navigate.SetDoc(Rec."Posting Date", Rec."Document No.");
                    Navigate.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                actionref(CancelEntries_Promoted; CancelEntries)
                {
                }
                actionref(ReverseTransaction_Promoted; ReverseTransaction)
                {
                }
            }
        }
    }

    analysisviews
    {
        analysisview("Asset value changes over time")
        {
            Caption = 'Asset value changes over time';
            DefinitionFile = './FixedAssets/FixedAsset/AssetValueChangesOverTime.analysis.json';
            ToolTip = 'Track asset value changes over time.';
        }
        analysisview("FA depreciations over time")
        {
            Caption = 'FA depreciations over time';
            DefinitionFile = './FixedAssets/FixedAsset/FADepreciationsOverTime.analysis.json';
            ToolTip = 'Track depreciations over time, both across all assets and on a single asset.';
        }
        analysisview("Fixed Assets (current value)")
        {
            Caption = 'Fixed Assets (current value)';
            DefinitionFile = './FixedAssets/FixedAsset/FixedAssetsCurrentValue.analysis.json';
            ToolTip = 'Track asset value, both across all assets and on a single asset.';
        }
    }

    trigger OnModifyRecord(): Boolean
    begin
        CODEUNIT.Run(CODEUNIT::"FA Entry - Edit", Rec);
        exit(false);
    end;

    trigger OnOpenPage()
    begin
        SetDimVisibility();
    end;

    var
        FALedgEntry: Record "FA Ledger Entry";
        CancelFAEntries: Report "Cancel FA Entries";
        CalcRunningFABalance: Codeunit "Calc. Running FA Balance";
        DimensionSetIDFilter: Page "Dimension Set ID Filter";
        Navigate: Page Navigate;
#pragma warning disable AA0470
        CannotUndoErr: Label 'You cannot undo the FA Ledger Entry No. %1 by using the Reverse Transaction function because Depreciation Book %2 does not have the appropriate G/L integration setup.';
#pragma warning restore AA0470
#pragma warning disable AA0074
        Text001: Label 'You cannot reverse the transaction because the fixed asset has been sold.';
#pragma warning restore AA0074

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
}
