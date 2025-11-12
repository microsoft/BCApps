// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

using System.Utilities;

report 87 "Copy - General Posting Setup"
{
    Caption = 'Copy - General Posting Setup';
    ProcessingOnly = true;

    dataset
    {
        dataitem("General Posting Setup"; "General Posting Setup")
        {
            DataItemTableView = sorting("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");

            trigger OnAfterGetRecord()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                GenPostingSetup.Find();
                if CopySales then begin
                    "Sales Account" := GenPostingSetup."Sales Account";
                    "Sales Credit Memo Account" := GenPostingSetup."Sales Credit Memo Account";
                    "Sales Line Disc. Account" := GenPostingSetup."Sales Line Disc. Account";
                    "Sales Inv. Disc. Account" := GenPostingSetup."Sales Inv. Disc. Account";
                    "Sales Pmt. Disc. Debit Acc." := GenPostingSetup."Sales Pmt. Disc. Debit Acc.";
                    "Sales Pmt. Disc. Credit Acc." := GenPostingSetup."Sales Pmt. Disc. Credit Acc.";
                    "Sales Pmt. Tol. Debit Acc." := GenPostingSetup."Sales Pmt. Tol. Debit Acc.";
                    "Sales Pmt. Tol. Credit Acc." := GenPostingSetup."Sales Pmt. Tol. Credit Acc.";
                    "Sales Prepayments Account" := GenPostingSetup."Sales Prepayments Account";
                end;

                if CopyPurchases then begin
                    "Purch. Account" := GenPostingSetup."Purch. Account";
                    "Purch. Credit Memo Account" := GenPostingSetup."Purch. Credit Memo Account";
                    "Purch. Line Disc. Account" := GenPostingSetup."Purch. Line Disc. Account";
                    "Purch. Inv. Disc. Account" := GenPostingSetup."Purch. Inv. Disc. Account";
                    "Purch. Pmt. Disc. Debit Acc." := GenPostingSetup."Purch. Pmt. Disc. Debit Acc.";
                    "Purch. Pmt. Disc. Credit Acc." := GenPostingSetup."Purch. Pmt. Disc. Credit Acc.";
                    "Purch. FA Disc. Account" := GenPostingSetup."Purch. FA Disc. Account";
                    "Purch. Pmt. Tol. Debit Acc." := GenPostingSetup."Purch. Pmt. Tol. Debit Acc.";
                    "Purch. Pmt. Tol. Credit Acc." := GenPostingSetup."Purch. Pmt. Tol. Credit Acc.";
                    "Purch. Prepayments Account" := GenPostingSetup."Purch. Prepayments Account";
                end;

                if CopyInventory then begin
                    "COGS Account" := GenPostingSetup."COGS Account";
                    "COGS Account (Interim)" := GenPostingSetup."COGS Account (Interim)";
                    "Inventory Adjmt. Account" := GenPostingSetup."Inventory Adjmt. Account";
                    "Invt. Accrual Acc. (Interim)" := GenPostingSetup."Invt. Accrual Acc. (Interim)";
                end;

                if CopyManufacturing then begin
                    "Direct Cost Applied Account" := GenPostingSetup."Direct Cost Applied Account";
                    "Overhead Applied Account" := GenPostingSetup."Overhead Applied Account";
                    "Purchase Variance Account" := GenPostingSetup."Purchase Variance Account";
                end;

                OnAfterCopyGenPostingSetup("General Posting Setup", GenPostingSetup, CopySales, CopyPurchases, CopyInventory, CopyManufacturing);

                if ConfirmManagement.GetResponseOrDefault(Text000, true) then
                    Modify();
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Gen. Bus. Posting Group", UseGenPostingSetup."Gen. Bus. Posting Group");
                SetRange("Gen. Prod. Posting Group", UseGenPostingSetup."Gen. Prod. Posting Group");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(GenBusPostingGroup; GenPostingSetup."Gen. Bus. Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Gen. Bus. Posting Group';
                        TableRelation = "Gen. Business Posting Group";
                        ToolTip = 'Specifies the general business posting group to copy from.';
                    }
                    field(GenProdPostingGroup; GenPostingSetup."Gen. Prod. Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Gen. Prod. Posting Group';
                        TableRelation = "Gen. Product Posting Group";
                        ToolTip = 'Specifies general product posting group to copy from.';
                    }
                    field(Copy; Selection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Copy';
                        OptionCaption = 'All fields,Selected fields';
                        ToolTip = 'Specifies if all fields or only selected fields are copied.';

                        trigger OnValidate()
                        begin
                            if Selection = Selection::"All fields" then
                                AllFieldsSelectionOnValidate();
                        end;
                    }
                    field(SalesAccounts; CopySales)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Accounts';
                        ToolTip = 'Specifies if you want to copy sales accounts.';

                        trigger OnValidate()
                        begin
                            Selection := Selection::"Selected fields";
                        end;
                    }
                    field(PurchaseAccounts; CopyPurchases)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Accounts';
                        ToolTip = 'Specifies if you want to copy purchase accounts.';

                        trigger OnValidate()
                        begin
                            Selection := Selection::"Selected fields";
                        end;
                    }
                    field(InventoryAccounts; CopyInventory)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Accounts';
                        ToolTip = 'Specifies if you want to copy inventory accounts.';

                        trigger OnValidate()
                        begin
                            Selection := Selection::"Selected fields";
                        end;
                    }
                    field(ManufacturingAccounts; CopyManufacturing)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Manufacturing Accounts';
                        ToolTip = 'Specifies if you want to copy manufacturing accounts.';

                        trigger OnValidate()
                        begin
                            Selection := Selection::"Selected fields";
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if Selection = Selection::"All fields" then begin
                CopySales := true;
                CopyPurchases := true;
                CopyInventory := true;
                CopyManufacturing := true;
            end;
        end;
    }

    labels
    {
    }

    var
        UseGenPostingSetup: Record "General Posting Setup";
        GenPostingSetup: Record "General Posting Setup";
        CopySales: Boolean;
        CopyPurchases: Boolean;
        CopyInventory: Boolean;
        CopyManufacturing: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Copy General Posting Setup?';
#pragma warning restore AA0074

    protected var
        Selection: Option "All fields","Selected fields";

    procedure SetGenPostingSetup(GenPostingSetup2: Record "General Posting Setup")
    begin
        UseGenPostingSetup := GenPostingSetup2;
    end;

    local procedure AllFieldsSelectionOnPush()
    begin
        CopySales := true;
        CopyPurchases := true;
        CopyInventory := true;
        CopyManufacturing := true;
    end;

    local procedure AllFieldsSelectionOnValidate()
    begin
        AllFieldsSelectionOnPush();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyGenPostingSetup(var ToGeneralPostingSetup: Record "General Posting Setup"; FromGeneralPostingSetup: Record "General Posting Setup"; var CopySales: Boolean; var CopyPurchases: Boolean; var CopyInventory: Boolean; var CopyManufacturing: Boolean)
    begin
    end;
}

