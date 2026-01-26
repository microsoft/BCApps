// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using System.Reflection;

page 10127 "Posted Bank Rec. Dep Lines Sub"
{
    Caption = 'Posted Bank Rec. Dep Lines Sub';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "Posted Bank Rec. Line";
    SourceTableView = sorting("Bank Account No.", "Statement No.", "Record Type", "Line No.")
                      where("Record Type" = const(Deposit));

    layout
    {
        area(content)
        {
            field("BankRecHdr.""Bank Account No."""; BankRecHdr."Bank Account No.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Account No.';
                Editable = false;
                ToolTip = 'Specifies the bank account that the bank statement line applies to.';
            }
            field("BankRecHdr.""Statement No."""; BankRecHdr."Statement No.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Statement No.';
                Editable = false;
                ToolTip = 'Specifies the bank reconciliation statement number that this line applies to.';
            }
            field("BankRecHdr.""Statement Date"""; BankRecHdr."Statement Date")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Statement Date';
                Editable = false;
                ToolTip = 'Specifies the bank reconciliation statement date that this line applies to.';
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the Posting Date field from the Bank Rec. Line table.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of document from the Bank Reconciliation Line table.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the bank reconciliation that this line belongs to.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    Editable = false;
                    ToolTip = 'Specifies the external document number for the posted journal line.';
                    Visible = false;
                }
                field("Account Type"; Rec."Account Type")
                {
                    Editable = false;
                    ToolTip = 'Specifies the Account Type field from the Bank Reconciliation Line table.';
                    Visible = false;
                }
                field("Account No."; Rec."Account No.")
                {
                    Editable = false;
                    ToolTip = 'Specifies the Account No. field from the Bank Reconciliation Line table.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a description of the transaction on the bank reconciliation line.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the item, such as a check, that was deposited.';
                }
                field(Cleared; Rec.Cleared)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the check on the line has been cleared, as indicated on the bank statement.';

                    trigger OnValidate()
                    begin
                        ClearedOnAfterValidate();
                    end;
                }
                field("Cleared Amount"; Rec."Cleared Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that was cleared by the bank, as indicated by the bank statement.';

                    trigger OnValidate()
                    begin
                        ClearedAmountOnAfterValidate();
                    end;
                }
                field("""Cleared Amount"" - Amount"; Rec."Cleared Amount" - Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Difference';
                    Editable = false;
                    ToolTip = 'Specifies the difference between the Amount field and the Cleared Amount field.';
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ToolTip = 'Specifies the code for the Balance Account Type that will be posted to the general ledger.';
                    Visible = false;
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ToolTip = 'Specifies the general ledger customer, vendor, or bank account number the line will be posted to.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    Editable = false;
                    ToolTip = 'Specifies the currency code for line amounts posted to the general ledger. This field is for adjustment type lines only.';
                    Visible = false;
                }
                field("Currency Factor"; Rec."Currency Factor")
                {
                    Editable = false;
                    ToolTip = 'Specifies a currency factor for the reconciliation sub-line entry. The value is calculated based on currency code, exchange rate, and the bank record header''s statement date.';
                    Visible = false;
                }
            }
            field(BankStatementCleared; BankRecHdr."Cleared Inc./Dpsts. Per Stmnt.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Statement';
                Editable = false;
                ToolTip = 'Specifies the bank reconciliation statement that this line applies to.';
            }
            field(TotalCleared; BankRecHdr."Total Cleared Deposits")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Total Cleared';
                Editable = false;
                ToolTip = 'Specifies the total amount of the lines that are marked as cleared.';
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        OnActivateForm();
    end;

    var
        BankRecHdr: Record "Posted Bank Rec. Header";

    procedure SetupTotals()
    begin
        if BankRecHdr.Get(Rec."Bank Account No.", Rec."Statement No.") then
            BankRecHdr.CalcFields("Total Cleared Deposits");
    end;

    procedure LookupLineDimensions()
    begin
        Rec.ShowDimensions();
    end;

    procedure GetTableID(): Integer
    var
        AllObj: Record AllObj;
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object Name", Rec.TableName);
        AllObj.FindFirst();
        exit(AllObj."Object ID");
    end;

    local procedure ClearedOnAfterValidate()
    begin
        CurrPage.Update();
        SetupTotals();
    end;

    local procedure ClearedAmountOnAfterValidate()
    begin
        CurrPage.Update();
        SetupTotals();
    end;

    local procedure OnActivateForm()
    begin
        SetupTotals();
    end;
}

