// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.CODA;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

table 2000041 "CODA Statement Line"
{
    Caption = 'CODA Statement Line';
    DrillDownPageID = "CODA Statement Info";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
        }
        field(2; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            TableRelation = "CODA Statement"."Statement No." where("Bank Account No." = field("Bank Account No."));
        }
        field(3; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
        }
        field(4; ID; Option)
        {
            Caption = 'ID';
            Editable = false;
            OptionCaption = ',,Movement,Information,Free Message';
            OptionMembers = ,,Movement,Information,"Free Message";
        }
        field(5; Type; Option)
        {
            Caption = 'Type';
            Editable = false;
            OptionCaption = 'Global,Detail';
            OptionMembers = Global,Detail;
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(9; "Bank Reference No."; Text[21])
        {
            Caption = 'Bank Reference No.';
            Editable = false;
        }
        field(10; "Ext. Reference No."; Text[8])
        {
            Caption = 'Ext. Reference No.';
            Editable = false;
        }
        field(11; "Statement Amount"; Decimal)
        {
            Caption = 'Statement Amount';
            Editable = false;
        }
        field(12; "Transaction Date"; Date)
        {
            Caption = 'Transaction Date';
            Editable = false;
        }
        field(13; "Transaction Type"; Integer)
        {
            Caption = 'Transaction Type';
            Editable = false;
        }
        field(14; "Transaction Family"; Integer)
        {
            Caption = 'Transaction Family';
            Editable = false;
        }
        field(15; Transaction; Integer)
        {
            Caption = 'Transaction';
            Editable = false;
        }
        field(16; "Transaction Category"; Integer)
        {
            Caption = 'Transaction Category';
            Editable = false;
        }
        field(17; "Message Type"; Option)
        {
            Caption = 'Message Type';
            Editable = false;
            OptionCaption = 'Non standard format,Standard format';
            OptionMembers = "Non standard format","Standard format";
        }
        field(18; "Type Standard Format Message"; Integer)
        {
            Caption = 'Type Standard Format Message';
            Editable = false;
        }
        field(19; "Statement Message"; Text[250])
        {
            Caption = 'Statement Message';
            Editable = false;
        }
        field(20; "Statement Message (cont.)"; Text[250])
        {
            Caption = 'Statement Message (cont.)';
            Editable = false;
        }
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        field(22; "Globalisation Code"; Integer)
        {
            Caption = 'Globalisation Code';
            Editable = false;
            MaxValue = 9;
            MinValue = 0;
        }
        field(23; "Customer Reference"; Text[35])
        {
            Caption = 'Customer Reference';
            Editable = false;
        }
        field(24; "Bank Account No. Other Party"; Text[34])
        {
            Caption = 'Bank Account No. Other Party';
            Editable = false;
        }
        field(25; "Internal Codes Other Party"; Text[10])
        {
            Caption = 'Internal Codes Other Party';
            Editable = false;
        }
        field(26; "Ext. Acc. No. Other Party"; Text[15])
        {
            Caption = 'Ext. Acc. No. Other Party';
            Editable = false;
        }
        field(27; "Name Other Party"; Text[35])
        {
            Caption = 'Name Other Party';
            Editable = false;
        }
        field(28; "Address Other Party"; Text[35])
        {
            Caption = 'Address Other Party';
            Editable = false;
        }
        field(29; "City Other Party"; Text[35])
        {
            Caption = 'City Other Party';
            Editable = false;
        }
        field(30; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            Editable = false;
        }
        field(31; Information; Integer)
        {
            BlankNumbers = BlankZero;
            BlankZero = true;
            CalcFormula = count("CODA Statement Line" where("Bank Account No." = field("Bank Account No."),
                                                             "Statement No." = field("Statement No."),
                                                             ID = const(Information),
                                                             "Attached to Line No." = field("Statement Line No.")));
            Caption = 'Information';
            Editable = false;
            FieldClass = FlowField;
        }
        field(37; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
        }
        field(38; "Application Information"; Text[80])
        {
            Caption = 'Application Information';
        }
        field(39; "Application Status"; Option)
        {
            Caption = 'Application Status';
            OptionCaption = ' ,Partly applied,Applied,Indirectly applied';
            OptionMembers = " ","Partly applied",Applied,"Indirectly applied";
        }
        field(40; "Account Type"; enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';

            trigger OnValidate()
            begin
                if "Account Type" <> xRec."Account Type" then
                    if xRec."Account No." <> '' then
                        Validate("Account No.", '')
            end;
        }
        field(41; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = if ("Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor
            else
            if ("Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Account Type" = const("Fixed Asset")) "Fixed Asset";

            trigger OnValidate()
            var
                CustLedgEntry: Record "Cust. Ledger Entry";
                VendLedgEntry: Record "Vendor Ledger Entry";
            begin
                if "Account No." <> xRec."Account No." then begin
                    Validate("Account Name", '');
                    UpdateStatus();
                    // clear Applies-to ID on ledger entries
                    case "Account Type" of
                        "Account Type"::Customer:
                            begin
                                CustLedgEntry.Reset();
                                CustLedgEntry.SetRange("Customer No.", xRec."Account No.");
                                CustLedgEntry.SetRange(Open, true);
                                CustLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
                                if CustLedgEntry.FindSet() then
                                    repeat
                                        CustLedgEntry.Validate("Applies-to ID", '');
                                        CustLedgEntry.Validate("Amount to Apply", 0);
                                        CustLedgEntry.Modify();
                                    until CustLedgEntry.Next() = 0;
                            end;
                        "Account Type"::Vendor:
                            begin
                                VendLedgEntry.Reset();
                                VendLedgEntry.SetRange("Vendor No.", xRec."Account No.");
                                VendLedgEntry.SetRange(Open, true);
                                VendLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
                                if VendLedgEntry.FindSet() then
                                    repeat
                                        VendLedgEntry.Validate("Applies-to ID", '');
                                        VendLedgEntry.Validate("Amount to Apply", 0);
                                        VendLedgEntry.Modify();
                                    until VendLedgEntry.Next() = 0;
                            end;
                    end;
                    "Applies-to ID" := '';
                    if "Account No." = '' then
                        exit;
                end;

                if ("System-Created Entry" and
                    ("Application Status" in ["Application Status"::Applied, "Application Status"::"Indirectly applied"])) or
                   (not "System-Created Entry" and ("Application Status" = "Application Status"::"Indirectly applied"))
                then
                    Error(Text001, "Application Status");

                "System-Created Entry" := false;

                case "Account Type" of
                    "Account Type"::"G/L Account":
                        begin
                            GLAcc.Get("Account No.");
                            Validate("Account Name", GLAcc.Name);
                        end;
                    "Account Type"::Customer:
                        begin
                            Cust.Get("Account No.");
                            Validate("Account Name", Cust.Name);
                        end;
                    "Account Type"::Vendor:
                        begin
                            Vend.Get("Account No.");
                            Validate("Account Name", Vend.Name);
                        end
                end;
                UpdateStatus();
            end;
        }
        field(42; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(43; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(44; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';

            trigger OnValidate()
            begin
                if "Currency Code" = '' then
                    "Amount (LCY)" := Amount
                else
                    "Amount (LCY)" := Round(Amount * "Currency Factor" / 100)
            end;
        }
        field(45; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(46; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            MinValue = 0;
        }
        field(47; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
            Editable = false;
        }
        field(48; "Unapplied Amount"; Decimal)
        {
            Caption = 'Unapplied Amount';
            Editable = false;

            trigger OnValidate()
            begin
                UpdateStatus();
            end;
        }
        field(49; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';
            trigger OnValidate()
            begin
                if ("Applies-to ID" <> xRec."Applies-to ID") and ("Applies-to ID" = '') then begin
                    Validate("Unapplied Amount", "Statement Amount");
                    Validate(Amount, 0);
                end;
            end;
        }
        field(50; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            Editable = false;
            TableRelation = "Gen. Journal Template";
        }
        field(51; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            Editable = false;
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        field(52; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(53; "Account Name"; Text[100])
        {
            Caption = 'Account Name';

            trigger OnValidate()
            begin
                if Description = '' then
                    Description := "Account Name"
                else
                    if Description = xRec."Account Name" then
                        Description := ''
            end;
        }
        field(60; "Original Transaction Currency"; Code[3])
        {
            Caption = 'Original Transaction Currency';
            Editable = false;
        }
        field(61; "Original Transaction Amount"; Decimal)
        {
            AutoFormatExpression = "Original Transaction Currency";
            AutoFormatType = 1;
            Caption = 'Original Transaction Amount';
            Editable = false;
        }
        field(62; "SWIFT Address"; Text[11])
        {
            Caption = 'SWIFT Address';
        }
    }

    keys
    {
        key(Key1; "Bank Account No.", "Statement No.", "Statement Line No.")
        {
            Clustered = true;
            SumIndexFields = "Statement Amount";
        }
        key(Key2; "Bank Account No.", "Statement No.", "Attached to Line No.")
        {
        }
        key(Key3; "Bank Account No.", "Statement No.", ID, "Attached to Line No.", Type)
        {
            SumIndexFields = "Statement Amount";
        }
        key(Key4; "Bank Account No.", "Statement No.", "Application Status")
        {
            SumIndexFields = "Unapplied Amount", Amount, "Amount (LCY)";
        }
    }

    fieldgroups
    {
    }

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        Text000: Label 'You cannot rename a %1.';
        Text001: Label 'The application status for the CODA statement line cannot be %1.';
        Text002: Label 'The application status for the CODA statement line %1 %2 cannot be %3.', Comment = 'First parameter - line type (Global or Detail), second - document number, third - application status ( ,Partly applied,Applied,Indirectly applied)';
        GLAcc: Record "G/L Account";
        Cust: Record Customer;
        Vend: Record Vendor;

    procedure UpdateStatus()
    var
        CODAStmtLine: Record "CODA Statement Line";
        CODAStmtLine2: Record "CODA Statement Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        StatusCount: array[4] of Integer;
        AmountToApply: Decimal;
    begin
        if "Account No." = '' then begin
            "Application Status" := "Application Status"::" ";
            Validate(Amount, 0);
            "Unapplied Amount" := "Statement Amount"
        end else
            // set Application status to Partly applied if no application ledger entry is selected
            if "Applies-to ID" = '' then begin
                "Application Status" := "Application Status"::"Partly applied";
                Validate(Amount, 0);
                "Unapplied Amount" := "Statement Amount";
            end else begin
                AmountToApply := "Statement Amount";
                case "Account Type" of
                    "Account Type"::Customer:
                        begin
                            CustLedgerEntry.SetRange("Customer No.", "Account No.");
                            CustLedgerEntry.SetRange("Applies-to ID", "Applies-to ID");
                            CustLedgerEntry.CalcSums("Amount to Apply");
                            AmountToApply := CustLedgerEntry."Amount to Apply";
                        end;
                    "Account Type"::Vendor:
                        begin
                            VendorLedgerEntry.SetRange("Vendor No.", "Account No.");
                            VendorLedgerEntry.SetRange("Applies-to ID", "Applies-to ID");
                            VendorLedgerEntry.CalcSums("Amount to Apply");
                            AmountToApply := VendorLedgerEntry."Amount to Apply";
                        end;
                end;
                if AmountToApply = "Statement Amount" then
                    "Application Status" := "Application Status"::Applied
                else
                    "Application Status" := "Application Status"::"Partly applied";
                Validate(Amount, AmountToApply);
                "Unapplied Amount" := "Statement Amount" - Amount;
            end;
        OnUpdateStatusOnAfterUpdateApplicationFields(Rec, xRec);

        // Lines with global info and details
        if Type = Type::Global then begin
            // Modify all details
            CODAStmtLine.Reset();
            CODAStmtLine.SetRange("Bank Account No.", "Bank Account No.");
            CODAStmtLine.SetRange("Statement No.", "Statement No.");
            CODAStmtLine.SetRange(ID, ID);
            CODAStmtLine.SetRange("Attached to Line No.", "Statement Line No.");
            if CODAStmtLine.FindSet() then
                repeat
                    // If partially applied, then first undo
                    if CODAStmtLine."System-Created Entry" and
                       (CODAStmtLine."Application Status" <> "Application Status"::" ")
                    then
                        Error(Text002,
                          CODAStmtLine.Type, CODAStmtLine."Document No.",
                          CODAStmtLine."Application Status");
                    if "Application Status" = "Application Status"::" " then begin
                        CODAStmtLine."Application Status" := "Application Status"::" ";
                        CODAStmtLine.Validate(Amount, 0);
                    end else
                        CODAStmtLine."Application Status" := "Application Status"::"Indirectly applied";
                    CODAStmtLine."Unapplied Amount" := CODAStmtLine."Statement Amount";
                    CODAStmtLine."System-Created Entry" := false;
                    CODAStmtLine.Modify();
                until CODAStmtLine.Next() = 0
        end else begin
            Modify();

            // Retrieve global info
            CODAStmtLine.Reset();
            CODAStmtLine.Get("Bank Account No.", "Statement No.", "Attached to Line No.");
            CODAStmtLine.Validate(Amount, 0);
            CODAStmtLine."Unapplied Amount" := CODAStmtLine."Statement Amount";

            // Run through details
            Clear(StatusCount);
            CODAStmtLine2.Reset();
            CODAStmtLine2.SetCurrentKey("Bank Account No.", "Statement No.", ID, "Attached to Line No.");
            CODAStmtLine2.SetRange("Bank Account No.", CODAStmtLine."Bank Account No.");
            CODAStmtLine2.SetRange("Statement No.", CODAStmtLine."Statement No.");
            CODAStmtLine2.SetRange(ID, CODAStmtLine.ID);
            CODAStmtLine2.SetRange("Attached to Line No.", CODAStmtLine."Statement Line No.");
            if CODAStmtLine2.FindSet() then
                repeat
                    if CODAStmtLine2."Application Status" = "Application Status"::Applied then
                        CODAStmtLine."Unapplied Amount" :=
                          CODAStmtLine."Unapplied Amount" - CODAStmtLine2.Amount;
                    StatusCount[CODAStmtLine2."Application Status" + 1] :=
                      StatusCount[CODAStmtLine2."Application Status" + 1] + 1
                until CODAStmtLine2.Next() = 0;

            // Update status of global info using detail status info
            if StatusCount["Application Status"::" " + 1] > 0 then begin
                if StatusCount["Application Status"::Applied + 1] = 0 then
                    CODAStmtLine."Application Status" := "Application Status"::" "
                else
                    CODAStmtLine."Application Status" := "Application Status"::"Partly applied"
            end else
                CODAStmtLine."Application Status" := "Application Status"::"Indirectly applied";
            CODAStmtLine.Modify();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateStatusOnAfterUpdateApplicationFields(var CODAStatementLine: Record "CODA Statement Line"; xCODAStatementLine: Record "CODA Statement Line")
    begin
    end;
}

