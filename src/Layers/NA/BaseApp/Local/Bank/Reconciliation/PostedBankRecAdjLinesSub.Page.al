// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Reflection;

page 10128 "Posted Bank Rec. Adj Lines Sub"
{
    AutoSplitKey = true;
    Caption = 'Posted Bank Rec. Adj Lines Sub';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "Posted Bank Rec. Line";
    SourceTableView = sorting("Bank Account No.", "Statement No.", "Record Type", "Line No.")
                      where("Record Type" = const(Adjustment));

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
                    ToolTip = 'Specifies the Posting Date field from the Bank Rec. Line table.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document from the Bank Reconciliation Line table.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank reconciliation that this line belongs to.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ToolTip = 'Specifies the external document number for the posted journal line.';
                    Visible = false;
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Account Type field from the Bank Reconciliation Line table.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Account No. field from the Bank Reconciliation Line table.';

                    trigger OnValidate()
                    begin
                        AccountNoOnAfterValidate();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the transaction on the bank reconciliation line.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the item, such as a check, that was deposited.';

                    trigger OnValidate()
                    begin
                        AmountOnAfterValidate();
                    end;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ToolTip = 'Specifies the currency code for line amounts posted to the general ledger. This field is for adjustment type lines only.';
                    Visible = false;
                }
                field("Currency Factor"; Rec."Currency Factor")
                {
                    ToolTip = 'Specifies a currency factor for the reconciliation sub-line entry. The value is calculated based on currency code, exchange rate, and the bank record header''s statement date.';
                    Visible = false;
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the Balance Account Type that will be posted to the general ledger.';
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger customer, vendor, or bank account number the line will be posted to.';

                    trigger OnValidate()
                    begin
                        BalAccountNoOnAfterValidate();
                    end;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the dimension value code that is linked to the journal line.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the dimension value code that the journal line is linked to.';
                    Visible = false;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
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
                field("Adj. Source Record ID"; Rec."Adj. Source Record ID")
                {
                    ToolTip = 'Specifies the adjustment source record type for the Posted Bank Rec. Line.';
                    Visible = false;
                }
                field("Adj. Source Document No."; Rec."Adj. Source Document No.")
                {
                    ToolTip = 'Specifies the adjustment source document number for the Posted Bank Reconciliation Line.';
                    Visible = false;
                }
            }
            field(AccName; AccName)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Account Name';
                Editable = false;
                ToolTip = 'Specifies the name of the bank account.';
            }
            field(BalAccName; BalAccName)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bal. Account Name';
                Editable = false;
                ToolTip = 'Specifies the name of the balancing account.';
            }
            field(TotalAdjustments; BankRecHdr."Total Adjustments" - BankRecHdr."Total Balanced Adjustments")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Total Adjustments';
                Editable = false;
                ToolTip = 'Specifies the total amount of the lines that are adjustments.';
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
        AfterGetCurrentRecord();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        AfterGetCurrentRecord();
    end;

    trigger OnOpenPage()
    begin
        OnActivateForm();
    end;

    var
        AccName: Text[100];
        BalAccName: Text[100];
        BankRecHdr: Record "Posted Bank Rec. Header";
        LastBankRecLine: Record "Posted Bank Rec. Line";

    protected var
        ShortcutDimCode: array[8] of Code[20];

    procedure SetupTotals()
    begin
        if BankRecHdr.Get(Rec."Bank Account No.", Rec."Statement No.") then
            BankRecHdr.CalcFields("Total Adjustments", "Total Balanced Adjustments");
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

    procedure GetAccounts(var BankRecLine: Record "Posted Bank Rec. Line"; var AccName: Text[100]; var BalAccName: Text[100])
    var
        GLAcc: Record "G/L Account";
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
        FA: Record "Fixed Asset";
    begin
        if (BankRecLine."Account Type" <> LastBankRecLine."Account Type") or
           (BankRecLine."Account No." <> LastBankRecLine."Account No.")
        then begin
            AccName := '';
            if BankRecLine."Account No." <> '' then
                case BankRecLine."Account Type" of
                    BankRecLine."Account Type"::"G/L Account":
                        if GLAcc.Get(BankRecLine."Account No.") then
                            AccName := GLAcc.Name;
                    BankRecLine."Account Type"::Customer:
                        if Cust.Get(BankRecLine."Account No.") then
                            AccName := Cust.Name;
                    BankRecLine."Account Type"::Vendor:
                        if Vend.Get(BankRecLine."Account No.") then
                            AccName := Vend.Name;
                    BankRecLine."Account Type"::"Bank Account":
                        if BankAcc.Get(BankRecLine."Account No.") then
                            AccName := BankAcc.Name;
                    BankRecLine."Account Type"::"Fixed Asset":
                        if FA.Get(BankRecLine."Account No.") then
                            AccName := FA.Description;
                end;
        end;

        if (BankRecLine."Bal. Account Type" <> LastBankRecLine."Bal. Account Type") or
           (BankRecLine."Bal. Account No." <> LastBankRecLine."Bal. Account No.")
        then begin
            BalAccName := '';
            if BankRecLine."Bal. Account No." <> '' then
                case BankRecLine."Bal. Account Type" of
                    BankRecLine."Bal. Account Type"::"G/L Account":
                        if GLAcc.Get(BankRecLine."Bal. Account No.") then
                            BalAccName := GLAcc.Name;
                    BankRecLine."Bal. Account Type"::Customer:
                        if Cust.Get(BankRecLine."Bal. Account No.") then
                            BalAccName := Cust.Name;
                    BankRecLine."Bal. Account Type"::Vendor:
                        if Vend.Get(BankRecLine."Bal. Account No.") then
                            BalAccName := Vend.Name;
                    BankRecLine."Bal. Account Type"::"Bank Account":
                        if BankAcc.Get(BankRecLine."Bal. Account No.") then
                            BalAccName := BankAcc.Name;
                    BankRecLine."Bal. Account Type"::"Fixed Asset":
                        if FA.Get(BankRecLine."Bal. Account No.") then
                            BalAccName := FA.Description;
                end;
        end;

        LastBankRecLine := BankRecLine;
    end;

    local procedure AccountNoOnAfterValidate()
    begin
        GetAccounts(Rec, AccName, BalAccName);
    end;

    local procedure AmountOnAfterValidate()
    begin
        CurrPage.Update(true);
        SetupTotals();
    end;

    local procedure BalAccountNoOnAfterValidate()
    begin
        GetAccounts(Rec, AccName, BalAccName);
    end;

    local procedure AfterGetCurrentRecord()
    begin
        xRec := Rec;
        GetAccounts(Rec, AccName, BalAccName);
    end;

    local procedure OnActivateForm()
    begin
        SetupTotals();
    end;
}

