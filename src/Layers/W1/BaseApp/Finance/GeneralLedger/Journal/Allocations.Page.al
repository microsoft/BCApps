// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;

/// <summary>
/// Provides interface for managing general journal line allocations to distribute transaction amounts across multiple G/L accounts.
/// Supports percentage-based, amount-based, and quantity-based allocation methods with dimension management capabilities.
/// </summary>
/// <remarks>
/// Primary data source: Gen. Jnl. Allocation table. Enables allocation of journal line amounts using predefined allocation keys and distribution methods.
/// Key workflows: Allocation key setup, distribution percentage/amount configuration, dimension assignment for allocated amounts.
/// Extensibility: Integration with dimension management system and G/L account validation for allocation targets.
/// </remarks>
page 284 Allocations
{
    AutoSplitKey = true;
    Caption = 'Allocations';
    DataCaptionFields = "Journal Batch Name";
    PageType = Worksheet;
    SourceTable = "Gen. Jnl. Allocation";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Suite;

                    trigger OnValidate()
                    begin
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field("Account Name"; Rec."Account Name")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
                field("Gen. Posting Type"; Rec."Gen. Posting Type")
                {
                    ApplicationArea = Suite;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Suite;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Suite;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Allocation Quantity"; Rec."Allocation Quantity")
                {
                    ApplicationArea = Suite;

                    trigger OnValidate()
                    begin
                        AllocationQuantityOnAfterValid();
                    end;
                }
                field("Allocation %"; Rec."Allocation %")
                {
                    ApplicationArea = Suite;

                    trigger OnValidate()
                    begin
                        Allocation37OnAfterValidate();
                    end;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Suite;

                    trigger OnValidate()
                    begin
                        AmountOnAfterValidate();
                    end;
                }
            }
            group(Control18)
            {
                ShowCaption = false;
                fixed(Control1902205101)
                {
                    ShowCaption = false;
                    group(Control1903867001)
                    {
                        Caption = 'Amount';
                        field("AllocationAmount + Amount - xRec.Amount"; AllocationAmount + Rec.Amount - xRec.Amount)
                        {
                            ApplicationArea = All;
                            AutoFormatExpression = Rec.GetCurrencyCode();
                            AutoFormatType = 1;
                            Caption = 'AllocationAmount';
                            Editable = false;
                            ToolTip = 'Specifies the total amount that has been entered in the allocation journal up to the line where the cursor is.';
                            Visible = AllocationAmountVisible;
                        }
                    }
                    group("Total Amount")
                    {
                        Caption = 'Total Amount';
                        field(TotalAllocationAmount; TotalAllocationAmount + Rec.Amount - xRec.Amount)
                        {
                            ApplicationArea = All;
                            AutoFormatExpression = Rec.GetCurrencyCode();
                            AutoFormatType = 1;
                            Caption = 'Total Amount';
                            Editable = false;
                            ToolTip = 'Specifies the total amount that is allocated in the allocation journal.';
                            Visible = TotalAllocationAmountVisible;
                        }
                    }
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
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
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
                        CurrPage.SaveRecord();
                    end;
                }
            }
            group("A&ccount")
            {
                Caption = 'A&ccount';
                Image = ChartOfAccounts;
                action(Card)
                {
                    ApplicationArea = Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "G/L Account Card";
                    RunPageLink = "No." = field("Account No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the allocation.';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Suite;
                    Caption = 'Ledger E&ntries';
                    Image = GLRegisters;
                    RunObject = Page "General Ledger Entries";
                    RunPageLink = "G/L Account No." = field("Account No.");
                    RunPageView = sorting("G/L Account No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
            }
            group("&Process")
            {
                action(ImportFromAllocationAccount)
                {
                    ApplicationArea = Suite;
                    Caption = 'Import from Allocation Account';
                    Image = Import;
                    ToolTip = 'Create general journal allocation lines based on allocation account setup.';

                    trigger OnAction()
                    begin
                        Rec.ChooseAndImportFromAllocationAccount();
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
                actionref(ImportFromAllocationAccount_Promoted; ImportFromAllocationAccount)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Line', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Category5)
            {
                Caption = 'Account', Comment = 'Generated from the PromotedActionCategories property index 4.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateAllocationAmount();
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnInit()
    begin
        TotalAllocationAmountVisible := true;
        AllocationAmountVisible := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        UpdateAllocationAmount();
        Clear(ShortcutDimCode);
    end;

    var
        AllocationAmount: Decimal;
        TotalAllocationAmount: Decimal;
        ShowAllocationAmount: Boolean;
        ShowTotalAllocationAmount: Boolean;
        AllocationAmountVisible: Boolean;
        TotalAllocationAmountVisible: Boolean;

    protected var
        ShortcutDimCode: array[8] of Code[20];

    local procedure UpdateAllocationAmount()
    var
        TempGenJnlAlloc: Record "Gen. Jnl. Allocation";
    begin
        TempGenJnlAlloc.CopyFilters(Rec);
        ShowTotalAllocationAmount := TempGenJnlAlloc.CalcSums(Amount);
        if ShowTotalAllocationAmount then begin
            TotalAllocationAmount := TempGenJnlAlloc.Amount;
            if Rec."Line No." = 0 then
                TotalAllocationAmount := TotalAllocationAmount + xRec.Amount;
        end;

        if Rec."Line No." <> 0 then begin
            TempGenJnlAlloc.SetRange("Line No.", 0, Rec."Line No.");
            ShowAllocationAmount := TempGenJnlAlloc.CalcSums(Amount);
            if ShowAllocationAmount then
                AllocationAmount := TempGenJnlAlloc.Amount;
        end else begin
            TempGenJnlAlloc.SetRange("Line No.", 0, xRec."Line No.");
            ShowAllocationAmount := TempGenJnlAlloc.CalcSums(Amount);
            if ShowAllocationAmount then begin
                AllocationAmount := TempGenJnlAlloc.Amount;
                TempGenJnlAlloc.CopyFilters(Rec);
                TempGenJnlAlloc := xRec;
                if TempGenJnlAlloc.Next() = 0 then
                    AllocationAmount := AllocationAmount + xRec.Amount;
            end;
        end;

        AllocationAmountVisible := ShowAllocationAmount;
        TotalAllocationAmountVisible := ShowTotalAllocationAmount;
    end;

    local procedure AllocationQuantityOnAfterValid()
    begin
        CurrPage.Update(false);
    end;

    local procedure Allocation37OnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure AmountOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;
}

