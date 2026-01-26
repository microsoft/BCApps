// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Statement;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Payment;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.IO;
using System.Reflection;

table 11401 "CBG Statement Line"
{
    Caption = 'CBG Statement Line';
    Permissions = TableData "Cust. Ledger Entry" = rm,
                  TableData "Vendor Ledger Entry" = rm,
                  TableData "Employee Ledger Entry" = rimd,
                  TableData "Data Exch. Field" = rimd;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Gen. Journal Template".Name;
        }
        field(2; "No."; Integer)
        {
            Caption = 'No.';
            NotBlank = true;
            TableRelation = "CBG Statement"."No." where("Journal Template Name" = field("Journal Template Name"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';

            trigger OnValidate()
            begin
                GenerateDocumentNo();
            end;
        }
        field(7; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
        }
        field(8; "Statement Type"; Option)
        {
            Caption = 'Statement Type';
            Editable = false;
            OptionCaption = 'G/L Account,Bank Account';
            OptionMembers = "G/L Account","Bank Account";
        }
        field(9; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            Editable = false;
            TableRelation = if ("Statement Type" = const("G/L Account")) "G/L Account"."No."
            else
            if ("Statement Type" = const("Bank Account")) "Bank Account"."No.";
        }
        field(10; Date; Date)
        {
            Caption = 'Date';

            trigger OnValidate()
            begin
                TestField(Date);
                if (Date <> xRec.Date) and (Amount <> 0) then
                    PaymentToleranceMgt.PmtTolCBGJnl(Rec);

                ValidateApplyRequirements(Rec);
            end;
        }
        field(12; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = 'G/L Account,Customer,Vendor,Bank Account,Employee';
            OptionMembers = "G/L Account",Customer,Vendor,"Bank Account",Employee;

            trigger OnValidate()
            begin
                case xRec."Account Type" of
                    "Account Type"::Customer, "Account Type"::Vendor, "Account Type"::Employee:
                        DeleteAppliesToID(xRec);
                end;
                Validate("Account No.", '');
            end;
        }
        field(13; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = if ("Account Type" = const("G/L Account")) "G/L Account"."No." where("Account Type" = const(Posting), Blocked = const(false), "Direct Posting" = const(true))
            else
            if ("Account Type" = const(Customer)) Customer."No."
            else
            if ("Account Type" = const(Vendor)) Vendor."No."
            else
            if ("Account Type" = const("Bank Account")) "Bank Account"."No."
            else
            if ("Account Type" = const(Employee)) Employee."No.";

            trigger OnValidate()
            var
                GLAccount: Record "G/L Account";
                OriginalDescription: Boolean;
                Cust: Record Customer;
                Vend: Record Vendor;
                Employee: Record Employee;
                BankAccount: Record "Bank Account";
                DocType: Enum "Gen. Journal Document Type";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeAccountNoOnValidate(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                "Applies-to Doc. Type" := "Applies-to Doc. Type"::" ";
                "Applies-to Doc. No." := '';
                "VAT Bus. Posting Group" := '';
                "VAT Prod. Posting Group" := '';
                "VAT %" := 0;
                "VAT Type" := "VAT Type"::" ";

                OriginalDescription := false;
                case xRec."Account Type" of
                    "Account Type"::"G/L Account":
                        if GLAccount.Get(xRec."Account No.") then
                            OriginalDescription := GLAccount.Name = Description;
                    "Account Type"::Customer:
                        begin
                            if Cust.Get(xRec."Account No.") then
                                OriginalDescription := Cust.Name = Description;
                            DeleteAppliesToID(xRec);
                        end;
                    "Account Type"::Vendor:
                        begin
                            if Vend.Get(xRec."Account No.") then
                                OriginalDescription := Vend.Name = Description;
                            DeleteAppliesToID(xRec);
                        end;
                    "Account Type"::Employee:
                        begin
                            if Employee.Get(xRec."Account No.") then
                                OriginalDescription := Employee.FullName() = Description;
                            DeleteAppliesToID(xRec);
                        end;
                    "Account Type"::"Bank Account":
                        if BankAccount.Get(xRec."Account No.") then
                            OriginalDescription := BankAccount.Name = Description;
                end;

                if "Account No." = '' then begin
                    if OriginalDescription then
                        Description := '';
                    CreateDimFromDefaultDim(FieldNo("Account No."));
                    exit;
                end;

                case "Account Type" of
                    "Account Type"::"G/L Account":
                        begin
                            GLAccount.Get("Account No.");
                            GLAccount.CheckGLAcc();
                            GLAccount.TestField("Direct Posting", true);
                            if (OriginalDescription or (Description = '')) and
                               (not GLAccount."Omit Default Descr. in Jnl.")
                            then
                                Description := GLAccount.Name
                            else
                                if GLAccount."Omit Default Descr. in Jnl." then
                                    Description := '';
                            GetCBGStatementHeader();
                            JrnlTemplate.Get("Journal Template Name");

                            if JrnlTemplate."Copy VAT Setup to Jnl. Lines" then begin
                                "VAT Bus. Posting Group" := GLAccount."VAT Bus. Posting Group";
                                "VAT Prod. Posting Group" := GLAccount."VAT Prod. Posting Group";
                                case GLAccount."Gen. Posting Type" of
                                    GLAccount."Gen. Posting Type"::" ":
                                        "VAT Type" := "VAT Type"::" ";
                                    GLAccount."Gen. Posting Type"::Purchase:
                                        "VAT Type" := "VAT Type"::Purchase;
                                    GLAccount."Gen. Posting Type"::Sale:
                                        "VAT Type" := "VAT Type"::Sale;
                                    else
                                        GLAccount.FieldError("Gen. Posting Type", Text1000000);
                                end;
                                Validate("VAT Prod. Posting Group");
                            end;
                        end;
                    "Account Type"::Customer:
                        begin
                            Cust.Get("Account No.");
                            Cust.CheckBlockedCustOnJnls(Cust, DocType::Payment, false);
                            if OriginalDescription or (Description = '') then
                                Description := Cust.Name;
                            "Salespers./Purch. Code" := Cust."Salesperson Code";
                        end;
                    "Account Type"::Vendor:
                        begin
                            Vend.Get("Account No.");
                            Vend.CheckBlockedVendOnJnls(Vend, DocType::Payment, false);
                            if OriginalDescription or (Description = '') then
                                Description := Vend.Name;
                            "Salespers./Purch. Code" := Vend."Purchaser Code";
                        end;
                    "Account Type"::Employee:
                        begin
                            Employee.Get("Account No.");
                            Employee.CheckBlockedEmployeeOnJnls(false);
                            if OriginalDescription or (Description = '') then
                                Description := CopyStr(Employee.FullName(), 1, MaxStrLen(Description));
                            "Salespers./Purch. Code" := Employee."Salespers./Purch. Code";
                        end;
                    "Account Type"::"Bank Account":
                        begin
                            BankAccount.Get("Account No.");
                            BankAccount.TestField(Blocked, false);
                            if OriginalDescription or (Description = '') then
                                Description := BankAccount.Name;
                        end;
                end;

                Validate(Amount);
                CreateDimFromDefaultDim(FieldNo("Account No."));
            end;
        }
        field(14; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(15; Debit; Decimal)
        {
            Caption = 'Debit';

            trigger OnValidate()
            begin
                Correction := Debit < 0;
                Validate(Amount, Debit);
            end;
        }
        field(16; Credit; Decimal)
        {
            Caption = 'Credit';

            trigger OnValidate()
            begin
                Correction := Credit < 0;
                Validate(Amount, -Credit);
            end;
        }
        field(17; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
        }
        field(18; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';

            trigger OnLookup()
            var
                GenJnlLine: Record "Gen. Journal Line" temporary;
                IsHandled: Boolean;
            begin
                isHandled := false;
                OnBeforeLookupAppliesToDocNo(Rec, IsHandled);
                if IsHandled then
                    exit;
                CreateGenJournalLine(GenJnlLine);
                LookupAppliesToDocNo(GenJnlLine);
                ReadGenJournalLine(GenJnlLine);
            end;

            trigger OnValidate()
            begin
                if not PaymentToleranceMgt.PmtTolCBGJnl(Rec) then
                    exit;
            end;
        }
        field(19; Correction; Boolean)
        {
            Caption = 'Correction';

            trigger OnValidate()
            begin
                Validate(Amount);
            end;
        }
        field(20; Amount; Decimal)
        {
            Caption = 'Amount';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                UpdateLineBalance();
                CalculateVAT();

                IsHandled := false;
                OnBeforePmtTolCBGJnl(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if (Amount <> xRec.Amount) and (Amount <> 0) then
                    PaymentToleranceMgt.PmtTolCBGJnl(Rec);
            end;
        }
        field(21; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';

            trigger OnValidate()
            var
                CBGStatementln: Record "CBG Statement Line";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeAppliesToIDOnValidate(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "Applies-to ID" <> '' then begin
                    CBGStatementln.SetCurrentKey("Journal Template Name", "No.", "Applies-to ID");
                    CBGStatementln.SetRange("Journal Template Name", "Journal Template Name");
                    CBGStatementln.SetRange("No.", "No.");
                    CBGStatementln.SetRange("Applies-to ID", "Applies-to ID");
                    CBGStatementln.SetFilter("Line No.", '<>%1', "Line No.");
                    if CBGStatementln.FindFirst() then
                        Error(Text1000001,
                          FieldCaption("Applies-to ID"),
                          "Applies-to ID",
                          CBGStatementln."Journal Template Name",
                          CBGStatementln."No.",
                          CBGStatementln."Line No.");
                end;
            end;
        }
        field(26; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = "Salesperson/Purchaser";

            trigger OnValidate()
            begin
                CreateDimFromDefaultDim(FieldNo("Salespers./Purch. Code"));
            end;
        }
        field(30; "Amount incl. VAT"; Boolean)
        {
            Caption = 'Amount incl. VAT';

            trigger OnValidate()
            begin
                Validate(Amount);
            end;
        }
        field(31; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                CalculateVAT();
            end;
        }
        field(32; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            begin
                CalculateVAT();
            end;
        }
        field(33; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            Editable = false;
        }
        field(35; "VAT Type"; Option)
        {
            BlankZero = true;
            Caption = 'VAT Type';
            OptionCaption = ' ,Purchase,Sale';
            OptionMembers = " ",Purchase,Sale;

            trigger OnValidate()
            begin
                CalculateVAT();
            end;
        }
        field(36; "Debit Incl. VAT"; Decimal)
        {
            Caption = 'Debit Incl. VAT';
            Editable = false;
        }
        field(37; "Credit Incl. VAT"; Decimal)
        {
            Caption = 'Credit Incl. VAT';
        }
        field(38; "Debit VAT"; Decimal)
        {
            Caption = 'Debit VAT';
        }
        field(39; "Credit VAT"; Decimal)
        {
            Caption = 'Credit VAT';
        }
        field(40; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(42; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            Editable = false;
            TableRelation = Job;

            trigger OnValidate()
            begin
                CreateDimFromDefaultDim(FieldNo("Job No."));
            end;
        }
        field(50; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;

            trigger OnValidate()
            var
                DimMgt: Codeunit DimensionManagement;
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(5050; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;

            trigger OnValidate()
            begin
                CreateDimFromDefaultDim(FieldNo("Campaign No."));
            end;
        }
        field(11400; "Amount Settled"; Decimal)
        {
            Caption = 'Amount Settled';
        }
        field(11401; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            Editable = false;
            TableRelation = "Data Exch.";
        }
        field(11402; "Data Exch. Line No."; Integer)
        {
            Caption = 'Data Exch. Line No.';
            Editable = false;
        }
        field(11000000; Identification; Code[80])
        {
            Caption = 'Identification';

            trigger OnLookup()
            begin
                IdentificationLookup();
            end;

            trigger OnValidate()
            var
                PaymentHistLine: Record "Payment History Line";
                CBGStatementLine: Record "CBG Statement Line";
                IsHandled: Boolean;
            begin
                if not (("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::Employee]) or ("Account No." = '')) then begin
                    Identification := '';
                    Message(Text1000002);
                end;

                IsHandled := false;
                OnValidateIdentificationOnBeforeCheck(Rec, IsHandled);
                if IsHandled then
                    exit;

                if Identification <> '' then begin
                    TestField("Statement Type", "Statement Type"::"Bank Account");
                    CBGStatementLine.SetCurrentKey("Statement Type", "Statement No.", Identification);
                    CBGStatementLine.SetRange("Statement Type", "Statement Type");
                    CBGStatementLine.SetRange("Statement No.", "Statement No.");
                    CBGStatementLine.SetRange(Identification, Identification);
                    if CBGStatementLine.Find('-') then
                        repeat
                            if (CBGStatementLine."Journal Template Name" <> "Journal Template Name") or
                               (CBGStatementLine."No." <> CBGStatementLine."No.") or
                               (CBGStatementLine."Line No." <> "Line No.")
                            then
                                Error(
                                  Text1000003 +
                                  Text1000004,
                                  CBGStatementLine.FieldCaption(Identification),
                                  CBGStatementLine.Identification,
                                  CBGStatementLine."Journal Template Name", CBGStatementLine."No.");
                        until CBGStatementLine.Next() = 0;

                    PaymentHistLine.SetCurrentKey("Our Bank", Identification);
                    PaymentHistLine.SetRange("Our Bank", "Statement No.");
                    PaymentHistLine.SetRange(Identification, Identification);
                    PaymentHistLine.FindFirst();

                    GetCBGStatementHeader();
                    CBGStatementLine := Rec;
                    Init();
                    InitRecord(CBGStatementLine);

                    if CBGStatementLine."Account No." = '' then
                        case PaymentHistLine."Account Type" of
                            PaymentHistLine."Account Type"::Customer:
                                Validate("Account Type", "Account Type"::Customer);
                            PaymentHistLine."Account Type"::Vendor:
                                Validate("Account Type", "Account Type"::Vendor);
                            PaymentHistLine."Account Type"::Employee:
                                Validate("Account Type", "Account Type"::Employee);
                        end
                    else begin
                        case CBGStatementLine."Account Type" of
                            "Account Type"::Customer:
                                PaymentHistLine.TestField("Account Type", PaymentHistLine."Account Type"::Customer);
                            "Account Type"::Vendor:
                                PaymentHistLine.TestField("Account Type", PaymentHistLine."Account Type"::Vendor);
                            "Account Type"::Employee:
                                PaymentHistLine.TestField("Account Type", PaymentHistLine."Account Type"::Employee);
                            else
                                Error(AccountTypeErr, CBGStatementLine."Account Type");
                        end;
                        PaymentHistLine.TestField("Account No.", CBGStatementLine."Account No.");
                    end;
                    Validate("Account No.", PaymentHistLine."Account No.");

                    if CBGStatementLine.Description = '' then
                        Validate(Description, PaymentHistLine."Description 1")
                    else
                        Validate(Description, CBGStatementLine.Description);

                    if CBGStatementLine.Date = 0D then
                        Validate(Date, PaymentHistLine.Date)
                    else
                        Validate(Date, CBGStatementLine.Date);

                    if CBGStatement.Currency <> PaymentHistLine."Currency Code" then
                        Error(Text1000006,
                          CBGStatement.Currency, PaymentHistLine."Currency Code");
                    "Amount Settled" := PaymentHistLine.Amount;
                    "Applies-to ID" := "New Applies-to ID"();
                    SetApplyCVLedgerEntries(PaymentHistLine);
                    if CBGStatementLine.Amount = 0 then
                        Validate(Amount, PaymentHistLine.Amount)
                    else begin
                        PaymentHistLine.TestField(Amount, CBGStatementLine.Amount);
                        Validate(Amount, CBGStatementLine.Amount)
                    end;
                    Identification := CBGStatementLine.Identification;
                    if CBGStatementLine."Shortcut Dimension 1 Code" <> '' then
                        Validate("Shortcut Dimension 1 Code", CBGStatementLine."Shortcut Dimension 1 Code");
                    if CBGStatementLine."Shortcut Dimension 2 Code" <> '' then
                        Validate("Shortcut Dimension 2 Code", CBGStatementLine."Shortcut Dimension 2 Code");
                    "Dimension Set ID" := PaymentHistLine."Dimension Set ID";
                end;
            end;
        }
        field(11000001; "Reconciliation Status"; Option)
        {
            Caption = 'Reconciliation Status';
            Editable = false;
            OptionCaption = 'Unknown,Changed,Applied';
            OptionMembers = Unknown,Changed,Applied;
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = Debit, Credit, "Debit Incl. VAT", "Credit Incl. VAT", "Debit VAT", "Credit VAT";
        }
        key(Key2; "Statement Type", "Statement No.", Identification)
        {
        }
        key(Key3; "Journal Template Name", "No.", "Applies-to ID")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        CBGStatementlineDescription: Record "CBG Statement Line Add. Info.";
    begin
        CBGStatementlineDescription.SetCurrentKey("Journal Template Name", "CBG Statement No.", "CBG Statement Line No.", "Line No.");
        CBGStatementlineDescription.SetRange("Journal Template Name", "Journal Template Name");
        CBGStatementlineDescription.SetRange("CBG Statement No.", "No.");
        CBGStatementlineDescription.SetRange("CBG Statement Line No.", "Line No.");
        CBGStatementlineDescription.DeleteAll(true);
        DeleteAppliesToID(Rec);
        ClearDataExchEntries();
    end;

    trigger OnInsert()
    var
        CBGStatementLine: Record "CBG Statement Line";
    begin
        GetCBGStatementHeader();

        if (CBGStatement.Type = CBGStatement.Type::Cash) and ("Document No." = '') then
            GenerateDocumentNo();

        JrnlTemplate.Get("Journal Template Name");

        CBGStatementLine.Reset();
        CBGStatementLine.SetRange("Journal Template Name", CBGStatement."Journal Template Name");
        CBGStatementLine.SetRange("No.", CBGStatement."No.");
        if (CBGStatement.Type = CBGStatement.Type::"Bank/Giro") and CBGStatementLine.IsEmpty() and (Date = 0D) then
            Date := CBGStatement.Date;
    end;

    var
        Text1000000: Label 'is not allowed in a Cash or Bank Journal';
        Text1000001: Label '%1 %2 is used before in %2 %4 line %5';
        Text1000002: Label 'The identification is only used with customers, vendors, and employees.';
        Text1000003: Label '%1 %2 is already used in:\';
        Text1000004: Label 'Bank Journal %3 (%4)\';
        Text1000007: Label 'D';
        Text1000008: Label 'DI';
        Text1000009: Label 'C';
        Text1000010: Label 'CI';
        Text1000011: Label 'NC';
        Text1000012: Label 'NCI';
        Text1000013: Label 'CBI';
        Text1000014: Label 'B';
        Text1000015: Label 'Account No.?';
        Text1000016: Label 'DEFAULT';
        Text1000017: Label 'The posting date is not filled in correctly on bank journal %1 line %2\';
        Text1000018: Label 'The document date is not filled in correctly on cash journal %1 line %2\';
        Text1000019: Label 'Use G/L Account for %1 when you use Full VAT';
        Text1000020: Label 'When %1 = %2  than %3 (%4) must be equal to %5 (%6) from the VAT Posting Setup table';
        Text1000021: Label 'is not supported in the Cash, Bank or Giro Journal';
        Text1000022: Label 'The combination %1-%2 and %3=%4 does not exist in the VAT setup!\';
        Text1000023: Label 'Therefore it is not possible to calculate %5.';
        Text1000024: Label 'To calculate the VAT it is necessary to fill in %1\\';
        Text1000025: Label 'Fill in the fields %2, %3 and %4 in G/L Account %5 and re-enter the line\\';
        Text1000026: Label 'or\\';
        Text1000027: Label 'Use Show Column to display the necessary fields in this form';
        Text1000028: Label 'You can only apply VAT when %1 = G/L Account';
        Currency: Record Currency;
        JrnlTemplate: Record "Gen. Journal Template";
        DimManagement: Codeunit DimensionManagement;
        GenJnlApply: Codeunit "Gen. Jnl.-Apply";
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
        TypeHelper: Codeunit "Type Helper";
        DateParseErr: Label 'Could not read a date from text ''%1'' using format %2.', Comment = '%1=a string representing a date like 081001,%2=a string representing a format like yyMMdd';
        FinancialInterfaceTelebank: Codeunit "Financial Interface Telebank";
        PostingDateEarlierErr: Label 'You cannot apply to an entry with a posting date before the posting date of the entry that you want to apply.';

    protected var
        CBGStatement: Record "CBG Statement";
        AccountTypeErr: Label '%1 must be customer, vendor, or employee.', Comment = '%1 - account type';
        Text1000006: Label 'The currency of the bank journal "%1" and the currency of the payment history line "%2" must be equal.';


    procedure InitRecord(LastRecord: Record "CBG Statement Line")
    begin
        OnBeforeInitRecord(Rec, LastRecord, CBGStatement);
        GetCBGStatementHeader();

        "Statement Type" := CBGStatement."Account Type";
        "Statement No." := CBGStatement."Account No.";
        "VAT Type" := "VAT Type"::" ";

        case CBGStatement.Type of
            CBGStatement.Type::Cash:
                if Date = 0D then
                    Date := WorkDate();
            CBGStatement.Type::"Bank/Giro":
                if Date = 0D then
                    if LastRecord.Date = 0D then
                        Date := CBGStatement.Date
                    else
                        Date := LastRecord.Date;
        end;

        "Account Type" := LastRecord."Account Type";
        "Applies-to Doc. Type" := LastRecord."Applies-to Doc. Type";
        "Amount incl. VAT" := LastRecord."Amount incl. VAT";
    end;

    procedure UpdateLineBalance()
    begin
        if ((Amount > 0) and (not Correction)) or
           ((Amount < 0) and Correction)
        then begin
            Debit := Amount;
            Credit := 0
        end else begin
            Debit := 0;
            Credit := -Amount;
        end;
    end;

    procedure TotalNetChange(DCNC: Code[10]) Tot: Decimal
    var
        CBGStatementLine: Record "CBG Statement Line";
    begin
        CBGStatementLine.SetRange("Journal Template Name", "Journal Template Name");
        CBGStatementLine.SetRange("No.", "No.");
        case DCNC of
            Text1000007: // Total debit
                begin
                    CBGStatementLine.CalcSums(Debit);
                    Tot := CBGStatementLine.Debit;
                end;
            Text1000008: // Total Debit Incl. VAT
                begin
                    CBGStatementLine.CalcSums("Debit Incl. VAT");
                    Tot := CBGStatementLine."Debit Incl. VAT";
                end;
            Text1000009: // Total Credit
                begin
                    CBGStatementLine.CalcSums(Credit);
                    Tot := CBGStatementLine.Credit;
                end;
            Text1000010: // Total Credit Incl. VAT
                begin
                    CBGStatementLine.CalcSums("Credit Incl. VAT");
                    Tot := CBGStatementLine."Credit Incl. VAT";
                end;
            Text1000011: // Total Net Change
                begin
                    CBGStatementLine.CalcSums(Debit, Credit);
                    Tot := CBGStatementLine.Debit - CBGStatementLine.Credit;
                end;
            Text1000012: // Total Net Change Incl. VAT
                begin
                    CBGStatementLine.CalcSums("Debit Incl. VAT", "Credit Incl. VAT");
                    Tot := CBGStatementLine."Debit Incl. VAT" - CBGStatementLine."Credit Incl. VAT";
                end;
            Text1000013: // Current Net Change Incl. VAT
                begin
                    if "Line No." <> 0 then
                        CBGStatementLine.SetFilter("Line No.", '..%1', "Line No.");
                    CBGStatementLine.CalcSums("Debit Incl. VAT", "Credit Incl. VAT");
                    Tot := CBGStatementLine."Debit Incl. VAT" - CBGStatementLine."Credit Incl. VAT";
                end;
            Text1000014: // Total VAT
                begin
                    CBGStatementLine.CalcSums("Debit VAT", "Credit VAT");
                    Tot := CBGStatementLine."Debit VAT" - CBGStatementLine."Credit VAT";
                end;
        end;
    end;

    procedure GetAccountName() Name: Text[100]
    var
        GLAccount: Record "G/L Account";
        Cust: Record Customer;
        Vend: Record Vendor;
        Employee: Record Employee;
        BankAccount: Record "Bank Account";
    begin
        case "Account Type" of
            "Account Type"::"G/L Account":
                case false of
                    GLAccount.Get("Account No."):
                        Name := Text1000015;
                    else
                        Name := GLAccount.Name;
                end;
            "Account Type"::"Bank Account":
                case false of
                    BankAccount.Get("Account No."):
                        Name := Text1000015;
                    else
                        Name := BankAccount.Name;
                end;
            "Account Type"::Customer:
                case false of
                    Cust.Get("Account No."):
                        Name := Text1000015;
                    else
                        Name := Cust.Name;
                end;
            "Account Type"::Vendor:
                case false of
                    Vend.Get("Account No."):
                        Name := Text1000015;
                    else
                        Name := Vend.Name;
                end;
            "Account Type"::Employee:
                case false of
                    Employee.Get("Account No."):
                        Name := Text1000015;
                    else
                        Name := Employee.FullName();
                end;
        end;
    end;

    procedure CreateGenJournalLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        CBGStatement: Record "CBG Statement";
    begin
        CheckAccountNo();
        GenJnlLine.Init();
        GenJnlLine."Journal Template Name" := "Journal Template Name";
        GenJnlLine."Journal Batch Name" := Text1000016;// STRSUBSTNO('%1',"No.");
        GenJnlLine."Line No." := 0;

        GenJnlLine.Validate("Posting Date", Date);
        SetAccountTypeAndDocumentType(GenJnlLine);

        GenJnlLine.Validate("Account No.", "Account No.");

        CBGStatement.Get("Journal Template Name", "No.");
        case CBGStatement.Type of
            CBGStatement.Type::"Bank/Giro":
                begin
                    if Date = 0D then
                        Error(Text1000017 +
                          '%3 %4 %5', "No.", "Line No.", GenJnlLine."Account Type", GenJnlLine."Account No.", GenJnlLine.Description);
                    GenJnlLine.Validate("Posting Date", Date);
                    GenJnlLine.Validate("Document Date", CBGStatement.Date);
                    GenJnlLine.Validate("Document No.", CBGStatement."Document No.");
                end;
            CBGStatement.Type::Cash:
                begin
                    if Date = 0D then
                        Error(Text1000018 +
                          '%3 %4 %5', "No.", "Line No.", GenJnlLine."Account Type", GenJnlLine."Account No.", GenJnlLine.Description);
                    GenJnlLine.Validate("Posting Date", Date);
                    GenJnlLine.Validate("Document Date", Date);
                    GenJnlLine.Validate("Document No.", "Document No.");
                end;
        end;

        if "Shortcut Dimension 1 Code" <> '' then
            GenJnlLine.Validate("Shortcut Dimension 1 Code", "Shortcut Dimension 1 Code");
        if "Shortcut Dimension 2 Code" <> '' then
            GenJnlLine.Validate("Shortcut Dimension 2 Code", "Shortcut Dimension 2 Code");
        if "Dimension Set ID" <> 0 then
            GenJnlLine.Validate("Dimension Set ID", "Dimension Set ID");

        GenJnlLine.Validate("Currency Code", CBGStatement.Currency);
        SetGenPostingTypeAndDocumentType(GenJnlLine);

        GenJnlLine."VAT Bus. Posting Group" := "VAT Bus. Posting Group";
        GenJnlLine.Validate("VAT Prod. Posting Group", "VAT Prod. Posting Group");

        if Rec.Correction then
            GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
        OnCreateGenJournalLineOnAfterSetDocumentTypeForCorrection(Rec, GenJnlLine);

        GenJnlLine.Description := Description;
        if "Applies-to Doc. No." <> '' then begin
            GenJnlLine.Validate("Applies-to Doc. Type", "Applies-to Doc. Type");
            GenJnlLine.Validate("Applies-to Doc. No.", "Applies-to Doc. No.");
        end else
            if "Applies-to ID" <> '' then
                GenJnlLine.Validate("Applies-to ID", "Applies-to ID");

        if "Debit Incl. VAT" <> 0 then begin
            GenJnlLine.Amount := "Debit Incl. VAT";
            GenJnlLine.Validate("Debit Amount", "Debit Incl. VAT")
        end else begin
            GenJnlLine.Amount := -"Credit Incl. VAT";
            GenJnlLine.Validate("Credit Amount", "Credit Incl. VAT");
        end;

        ValidateVATAmountOnLine(GenJnlLine);

        OnAfterCreateGenJournalLine(GenJnlLine, Rec);
    end;

    local procedure SetAccountTypeAndDocumentType(var GenJournalLine: Record "Gen. Journal Line")
    begin
        case Rec."Account Type" of
            Rec."Account Type"::"G/L Account":
                begin
                    GenJournalLine."Account Type" := GenJournalLine."Account Type"::"G/L Account";
                    case Rec."VAT Type" of
                        Rec."VAT Type"::Purchase:
                            if Rec.Credit = 0 then
                                GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment
                            else
                                GenJournalLine."Document Type" := GenJournalLine."Document Type"::" ";
                        Rec."VAT Type"::Sale:
                            if Rec.Debit = 0 then
                                GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment
                            else
                                GenJournalLine."Document Type" := GenJournalLine."Document Type"::" ";
                    end;
                end;
            Rec."Account Type"::Customer:
                begin
                    GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
                    if Rec.Debit = 0 then
                        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment
                    else
                        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Refund;
                end;
            Rec."Account Type"::Vendor:
                begin
                    GenJournalLine."Account Type" := GenJournalLine."Account Type"::Vendor;
                    if Rec.Credit = 0 then
                        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment
                    else
                        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Refund;
                end;
            Rec."Account Type"::Employee:
                begin
                    GenJournalLine."Account Type" := GenJournalLine."Account Type"::Employee;
                    GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment;
                end;
            Rec."Account Type"::"Bank Account":
                begin
                    GenJournalLine."Account Type" := GenJournalLine."Account Type"::"Bank Account";
                    GenJournalLine."Document Type" := GenJournalLine."Document Type"::" ";
                end;
        end;
        OnAfterSetAccountTypeAndDocumentType(Rec, GenJournalLine);
    end;

    local procedure SetGenPostingTypeAndDocumentType(var GenJournalLine: Record "Gen. Journal Line")
    begin
        case Rec."VAT Type" of
            Rec."VAT Type"::" ":
                GenJournalLine."Gen. Posting Type" := GenJournalLine."Gen. Posting Type"::" ";
            Rec."VAT Type"::Purchase:
                begin
                    GenJournalLine."Gen. Posting Type" := GenJournalLine."Gen. Posting Type"::Purchase;
                    GenJournalLine."Document Type" := GenJournalLine."Document Type"::Invoice;
                end;
            Rec."VAT Type"::Sale:
                begin
                    GenJournalLine."Gen. Posting Type" := GenJournalLine."Gen. Posting Type"::Sale;
                    GenJournalLine."Document Type" := GenJournalLine."Document Type"::Invoice;
                end;
        end;
        OnAfterSetGenPostingTypeAndDocumentType(Rec, GenJournalLine);
    end;

    local procedure ValidateVATAmountOnLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateVATAmountOnLine(Rec, GenJournalLine, IsHandled);
        if IsHandled then
            exit;

        if GenJournalLine."VAT Calculation Type" <> GenJournalLine."VAT Calculation Type"::"Full VAT" then
            if (Rec."Debit VAT" <> 0) and (Rec."Debit VAT" <> GenJournalLine."VAT Amount") then
                GenJournalLine.Validate("VAT Amount", Rec."Debit VAT")
            else
                if (Rec."Credit VAT" <> 0) and (-Rec."Credit VAT" <> GenJournalLine."VAT Amount") then
                    GenJournalLine.Validate("VAT Amount", -Rec."Credit VAT");
    end;

    procedure LookupAppliesToDocNo(var GenJnlLine: Record "Gen. Journal Line")
    var
        AccType: Enum "Gen. Journal Account Type";
        AccNo: Code[20];
    begin
        if GenJnlLine."Bal. Account Type" in
            ["Gen. Journal Account Type"::Customer, "Gen. Journal Account Type"::Vendor, "Gen. Journal Account Type"::Employee]
        then begin
            AccNo := GenJnlLine."Bal. Account No.";
            AccType := GenJnlLine."Bal. Account Type";
        end else begin
            AccNo := GenJnlLine."Account No.";
            AccType := GenJnlLine."Account Type";
        end;

        case AccType of
            AccType::Customer:
                LookupAppliesToDocNoForCustomer(GenJnlLine, AccNo);
            AccType::Vendor:
                LookupAppliesToDocNoForVendor(GenJnlLine, AccNo);
            AccType::Employee:
                LookupAppliesToDocNoForEmployee(GenJnlLine, AccNo);
        end;

        if not PaymentToleranceMgt.PmtTolGenJnl(GenJnlLine) then
            exit;
    end;

    local procedure LookupAppliesToDocNoForCustomer(var GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        ApplyCustEntries: Page "Apply Customer Entries";
    begin
        CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive, "Due Date");
        CustLedgEntry.SetRange("Customer No.", AccNo);
        CustLedgEntry.SetRange(Open, true);
        OnLookupAppliesToDocAnAfterSetCustLedgerEntryFilters(CustLedgEntry, GenJnlLine);
        if GenJnlLine."Applies-to Doc. No." <> '' then begin
            CustLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
            CustLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            if CustLedgEntry.Find('-') then;
            CustLedgEntry.SetRange("Document Type");
            CustLedgEntry.SetRange("Document No.");
        end else
            if GenJnlLine."Applies-to ID" <> '' then begin
                CustLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
                if CustLedgEntry.Find('-') then;
                CustLedgEntry.SetRange("Applies-to ID");
            end else
                if GenJnlLine."Applies-to Doc. Type" <> GenJnlLine."Applies-to Doc. Type"::" " then begin
                    CustLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
                    if CustLedgEntry.Find('-') then;
                    CustLedgEntry.SetRange("Document Type");
                end else
                    if GenJnlLine.Amount <> 0 then begin
                        CustLedgEntry.SetRange(Positive, GenJnlLine.Amount < 0);
                        if CustLedgEntry.Find('-') then;
                        CustLedgEntry.SetRange(Positive);
                    end;
        ApplyCustEntries.SetGenJnlLine(GenJnlLine, GenJnlLine.FieldNo("Applies-to Doc. No."));
        ApplyCustEntries.SetTableView(CustLedgEntry);
        ApplyCustEntries.SetRecord(CustLedgEntry);
        ApplyCustEntries.LookupMode(true);
        if ApplyCustEntries.RunModal() = ACTION::LookupOK then begin
            ApplyCustEntries.GetRecord(CustLedgEntry);
            CustLedgEntry.CalcFields("Remaining Amount");
            Clear(ApplyCustEntries);
            if GenJnlLine."Currency Code" <> CustLedgEntry."Currency Code" then
                if GenJnlLine.Amount = 0 then
                    GenJnlLine.Validate("Currency Code", CustLedgEntry."Currency Code")
                else
                    GenJnlApply.CheckAgainstApplnCurrency(
                        GenJnlLine."Currency Code", CustLedgEntry."Currency Code", GenJnlLine."Account Type"::Customer, true);
            if GenJnlLine.Amount = 0 then begin
                if (GenJnlLine."Document Type" = GenJnlLine."Document Type"::Payment) and
                    ((CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Invoice) or
                    (CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::"Credit Memo")) and
                    (GenJnlLine."Posting Date" <= CustLedgEntry."Pmt. Discount Date")
                then
                    GenJnlLine.Amount := -(CustLedgEntry."Remaining Amount" - CustLedgEntry."Original Pmt. Disc. Possible")
                else
                    GenJnlLine.Amount := -CustLedgEntry."Remaining Amount";
                if GenJnlLine."Bal. Account Type" in ["Gen. Journal Account Type"::Customer, "Gen. Journal Account Type"::Vendor] then
                    GenJnlLine.Amount := -GenJnlLine.Amount;
                GenJnlLine.Validate(Amount);
            end;
            GenJnlLine."Applies-to Doc. Type" := CustLedgEntry."Document Type";
            GenJnlLine."Applies-to Doc. No." := CustLedgEntry."Document No.";
            OnLookupAppliesToDocNoOnAfterSetCustAppliesToDocNo(CustLedgEntry, GenJnlLine);
            GenJnlLine."Applies-to ID" := '';
        end else
            Clear(ApplyCustEntries);
    end;

    local procedure LookupAppliesToDocNoForVendor(var GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        ApplyVendEntries: Page "Apply Vendor Entries";
    begin
        VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive, "Due Date");
        VendLedgEntry.SetRange("Vendor No.", AccNo);
        VendLedgEntry.SetRange(Open, true);
        OnLookupAppliesToDocAnAfterSetVendorLedgerEntryFilters(VendLedgEntry, GenJnlLine);
        if GenJnlLine."Applies-to Doc. No." <> '' then begin
            VendLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
            VendLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            if VendLedgEntry.Find('-') then;
            VendLedgEntry.SetRange("Document Type");
            VendLedgEntry.SetRange("Document No.");
        end else
            if GenJnlLine."Applies-to ID" <> '' then begin
                VendLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
                if VendLedgEntry.Find('-') then;
                VendLedgEntry.SetRange("Applies-to ID");
            end else
                if GenJnlLine."Applies-to Doc. Type" <> GenJnlLine."Applies-to Doc. Type"::" " then begin
                    VendLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
                    if VendLedgEntry.Find('-') then;
                    VendLedgEntry.SetRange("Document Type");
                end else
                    if GenJnlLine.Amount <> 0 then begin
                        VendLedgEntry.SetRange(Positive, GenJnlLine.Amount < 0);
                        if VendLedgEntry.Find('-') then;
                        VendLedgEntry.SetRange(Positive);
                    end;
        ApplyVendEntries.SetGenJnlLine(GenJnlLine, GenJnlLine.FieldNo("Applies-to Doc. No."));
        ApplyVendEntries.SetTableView(VendLedgEntry);
        ApplyVendEntries.SetRecord(VendLedgEntry);
        ApplyVendEntries.LookupMode(true);
        if ApplyVendEntries.RunModal() = ACTION::LookupOK then begin
            ApplyVendEntries.GetRecord(VendLedgEntry);
            VendLedgEntry.CalcFields("Remaining Amount");
            Clear(ApplyVendEntries);
            if GenJnlLine."Currency Code" <> VendLedgEntry."Currency Code" then
                if GenJnlLine.Amount = 0 then
                    GenJnlLine.Validate("Currency Code", VendLedgEntry."Currency Code")
                else
                    GenJnlApply.CheckAgainstApplnCurrency(
                        GenJnlLine."Currency Code", VendLedgEntry."Currency Code", GenJnlLine."Account Type"::Vendor, true);
            if GenJnlLine.Amount = 0 then begin
                if (GenJnlLine."Document Type" = GenJnlLine."Document Type"::Payment) and
                    ((VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::Invoice) or
                    (VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::"Credit Memo")) and
                    (GenJnlLine."Posting Date" <= VendLedgEntry."Pmt. Discount Date")
                then
                    GenJnlLine.Amount := -(VendLedgEntry."Remaining Amount" - VendLedgEntry."Original Pmt. Disc. Possible")
                else
                    GenJnlLine.Amount := -VendLedgEntry."Remaining Amount";
                if GenJnlLine."Bal. Account Type" in ["Gen. Journal Account Type"::Customer, "Gen. Journal Account Type"::Vendor] then
                    GenJnlLine.Amount := -GenJnlLine.Amount;
                GenJnlLine.Validate(Amount);
            end;
            GenJnlLine."Applies-to Doc. Type" := VendLedgEntry."Document Type";
            GenJnlLine."Applies-to Doc. No." := VendLedgEntry."Document No.";
            OnLookupAppliesToDocNoOnAfterSetVendorAppliesToDocNo(VendLedgEntry, GenJnlLine);
            GenJnlLine."Applies-to ID" := '';
        end else
            Clear(ApplyVendEntries);
    end;

    local procedure LookupAppliesToDocNoForEmployee(var GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20])
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        ApplyEmployeeEntries: Page "Apply Employee Entries";
    begin
        EmployeeLedgerEntry.SetCurrentKey("Employee No.", Open, Positive);
        EmployeeLedgerEntry.SetRange("Employee No.", AccNo);
        EmployeeLedgerEntry.SetRange(Open, true);
        if GenJnlLine."Applies-to Doc. No." <> '' then begin
            EmployeeLedgerEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
            EmployeeLedgerEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            if EmployeeLedgerEntry.Find('-') then;
            EmployeeLedgerEntry.SetRange("Document Type");
            EmployeeLedgerEntry.SetRange("Document No.");
        end else
            if GenJnlLine."Applies-to ID" <> '' then begin
                EmployeeLedgerEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
                if EmployeeLedgerEntry.Find('-') then;
                EmployeeLedgerEntry.SetRange("Applies-to ID");
            end else
                if GenJnlLine."Applies-to Doc. Type" <> GenJnlLine."Applies-to Doc. Type"::" " then begin
                    EmployeeLedgerEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
                    if EmployeeLedgerEntry.Find('-') then;
                    EmployeeLedgerEntry.SetRange("Document Type");
                end else
                    if GenJnlLine.Amount <> 0 then begin
                        EmployeeLedgerEntry.SetRange(Positive, GenJnlLine.Amount < 0);
                        if EmployeeLedgerEntry.Find('-') then;
                        EmployeeLedgerEntry.SetRange(Positive);
                    end;
        ApplyEmployeeEntries.SetGenJnlLine(GenJnlLine, GenJnlLine.FieldNo("Applies-to Doc. No."));
        ApplyEmployeeEntries.SetTableView(EmployeeLedgerEntry);
        ApplyEmployeeEntries.SetRecord(EmployeeLedgerEntry);
        ApplyEmployeeEntries.LookupMode(true);
        if ApplyEmployeeEntries.RunModal() = ACTION::LookupOK then begin
            ApplyEmployeeEntries.GetRecord(EmployeeLedgerEntry);
            EmployeeLedgerEntry.CalcFields("Remaining Amount");
            Clear(ApplyEmployeeEntries);
            if GenJnlLine."Currency Code" <> EmployeeLedgerEntry."Currency Code" then
                if GenJnlLine.Amount = 0 then
                    GenJnlLine.Validate("Currency Code", EmployeeLedgerEntry."Currency Code")
                else
                    GenJnlApply.CheckAgainstApplnCurrency(
                      GenJnlLine."Currency Code", EmployeeLedgerEntry."Currency Code", GenJnlLine."Account Type"::Employee, true);
            if GenJnlLine.Amount = 0 then begin
                GenJnlLine.Amount := -EmployeeLedgerEntry."Remaining Amount";
                if GenJnlLine."Bal. Account Type" = "Gen. Journal Account Type"::Employee then
                    GenJnlLine.Amount := -GenJnlLine.Amount;
                GenJnlLine.Validate(Amount);
            end;
            GenJnlLine."Applies-to Doc. Type" := EmployeeLedgerEntry."Document Type";
            GenJnlLine."Applies-to Doc. No." := EmployeeLedgerEntry."Document No.";
            GenJnlLine."Applies-to ID" := '';
        end else
            Clear(ApplyEmployeeEntries);
    end;

    local procedure CheckAccountNo()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAccountNo(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField("Account No.");
    end;

    procedure ReadGenJournalLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        UseCurrencyFactor: Decimal;
        IsHandled: Boolean;
        ShouldSetAmount: Boolean;
    begin
        IsHandled := false;
        OnBeforeReadGenJournalLine(Rec, GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        GetCBGStatementHeader();
        Correction := GenJnlLine.Correction;
        GetCurrency();

        ShouldSetAmount := GenJnlLine."Account Type" in [GenJnlLine."Account Type"::Customer, GenJnlLine."Account Type"::Vendor, GenJnlLine."Account Type"::Employee];
        OnReadGenJournalLineOnAfterCalcShouldSetAmount(Rec, GenJnlLine, ShouldSetAmount);
        if ShouldSetAmount then begin
            case true of
                CBGStatement.Currency = GenJnlLine."Currency Code":
                    Amount := GenJnlLine.Amount;
                (CBGStatement.Currency = '') and (GenJnlLine."Currency Code" <> ''):
                    begin
                        UseCurrencyFactor := CurrencyExchangeRate.ExchangeRate(Date, GenJnlLine."Currency Code");
                        Amount :=
                          Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(Date, GenJnlLine."Currency Code", GenJnlLine.Amount, UseCurrencyFactor),
                            Currency."Amount Rounding Precision");
                    end;
                (CBGStatement.Currency <> '') and (GenJnlLine."Currency Code" = ''):
                    begin
                        UseCurrencyFactor := CurrencyExchangeRate.ExchangeRate(Date, CBGStatement.Currency);
                        Amount :=
                          Round(CurrencyExchangeRate.ExchangeAmtLCYToFCY(Date, CBGStatement.Currency, GenJnlLine.Amount, UseCurrencyFactor),
                            Currency."Amount Rounding Precision");
                    end;
                (CBGStatement.Currency <> '') and (GenJnlLine."Currency Code" <> ''):
                    Amount :=
                      Round(CurrencyExchangeRate.ExchangeAmtFCYToFCY(Date, GenJnlLine."Currency Code", CBGStatement.Currency,
                        GenJnlLine.Amount), Currency."Amount Rounding Precision");
            end;
            "Amount Settled" := Amount;
            Validate(Amount);
        end;
        "Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type";
        "Applies-to Doc. No." := GenJnlLine."Applies-to Doc. No.";
        Validate("Applies-to ID", GenJnlLine."Applies-to ID");
        OnAfterReadGenJournalLine(Rec, GenJnlLine);
    end;

    procedure OpenAccountCard()
    var
        GLAcc: Record "G/L Account";
        Cust: Record Customer;
        Vend: Record Vendor;
        Employee: Record Employee;
        BankAcc: Record "Bank Account";
    begin
        TestField("Account No.");

        case "Account Type" of
            "Account Type"::"G/L Account":
                begin
                    GLAcc."No." := "Account No.";
                    PAGE.Run(PAGE::"G/L Account Card", GLAcc);
                end;
            "Account Type"::Customer:
                begin
                    Cust."No." := "Account No.";
                    PAGE.Run(PAGE::"Customer Card", Cust);
                end;
            "Account Type"::Vendor:
                begin
                    Vend."No." := "Account No.";
                    PAGE.Run(PAGE::"Vendor Card", Vend);
                end;
            "Account Type"::Employee:
                begin
                    Employee."No." := "Account No.";
                    PAGE.Run(PAGE::"Employee Card", Employee);
                end;
            "Account Type"::"Bank Account":
                begin
                    BankAcc."No." := "Account No.";
                    PAGE.Run(PAGE::"Bank Account Card", BankAcc);
                end;
        end;
    end;

    procedure OpenAccountEntries()
    var
        GLEntry: Record "G/L Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenAccountEntries(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField("Account No.");

        case "Account Type" of
            "Account Type"::"G/L Account":
                begin
                    GLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
                    GLEntry.SetRange("G/L Account No.", "Account No.");
                    if GLEntry.FindLast() then;
                    PAGE.Run(PAGE::"General Ledger Entries", GLEntry);
                end;
            "Account Type"::Customer:
                begin
                    CustLedgEntry.SetCurrentKey("Customer No.", "Posting Date");
                    CustLedgEntry.SetRange("Customer No.", "Account No.");
                    if CustLedgEntry.FindLast() then;
                    PAGE.Run(PAGE::"Customer Ledger Entries", CustLedgEntry);
                end;
            "Account Type"::Vendor:
                begin
                    VendLedgEntry.SetCurrentKey("Vendor No.", "Posting Date");
                    VendLedgEntry.SetRange("Vendor No.", "Account No.");
                    if VendLedgEntry.FindLast() then;
                    PAGE.Run(PAGE::"Vendor Ledger Entries", VendLedgEntry);
                end;
            "Account Type"::Employee:
                begin
                    EmployeeLedgerEntry.SetCurrentKey("Employee No.", "Posting Date");
                    EmployeeLedgerEntry.SetRange("Employee No.", "Account No.");
                    if EmployeeLedgerEntry.FindLast() then;
                    PAGE.Run(PAGE::"Employee Ledger Entries", EmployeeLedgerEntry);
                end;
            "Account Type"::"Bank Account":
                begin
                    BankAccLedgEntry.SetCurrentKey("Bank Account No.", "Posting Date");
                    BankAccLedgEntry.SetRange("Bank Account No.", "Account No.");
                    if BankAccLedgEntry.FindLast() then;
                    PAGE.Run(PAGE::"Bank Account Ledger Entries", BankAccLedgEntry);
                end;
        end;
    end;

    procedure AssistEdit(OldCBGStatementLine: Record "CBG Statement Line"): Boolean
    var
        CBGStatLine: Record "CBG Statement Line";
        JournalTemplate: Record "Gen. Journal Template";
        NoSeries: Codeunit "No. Series";
    begin
        CBGStatLine := Rec;
        JournalTemplate.Get(CBGStatLine."Journal Template Name");
        JournalTemplate.TestField("No. Series");
        if NoSeries.LookupRelatedNoSeries(JournalTemplate."No. Series", OldCBGStatementLine."No. Series", CBGStatLine."No. Series") then begin
            CBGStatLine."Document No." := NoSeries.GetNextNo(CBGStatLine."No. Series");
            Rec := CBGStatLine;
            exit(true);
        end;
    end;

    procedure GenerateDocumentNo()
    var
        JournalTemplate: Record "Gen. Journal Template";
        NoSeries: Codeunit "No. Series";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGenerateDocumentNo(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField("Journal Template Name");
        JournalTemplate.Get("Journal Template Name");
            "No. Series" := JournalTemplate."No. Series";
            if "Document No." = '' then begin
                if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                    "No. Series" := xRec."No. Series";
                "Document No." := NoSeries.GetNextNo("No. Series", Date);
            end else
                NoSeries.TestManual("No. Series");
    end;

    local procedure GetCurrency()
    begin
        GetCBGStatementHeader();
        if CBGStatement.Currency = '' then
            Currency.InitRoundingPrecision()
        else
            if CBGStatement.Currency <> Currency.Code then begin
                Currency.Get(CBGStatement.Currency);
                Currency.TestField("Amount Rounding Precision");
            end;
    end;

    procedure GetCBGStatementHeader()
    begin
        if (CBGStatement."Journal Template Name" <> "Journal Template Name") or
           (CBGStatement."No." <> "No.")
        then
            CBGStatement.Get("Journal Template Name", "No.");
    end;

    procedure IdentificationLookup()
    var
        PaymentHistLine: Record "Payment History Line";
        PaymentHistLnSurvey: Page "Payment History Line Overview";
    begin
        if ("Statement Type" = "Statement Type"::"Bank Account") and
           (("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::Employee]) or ("Account No." = ''))
        then begin
            PaymentHistLine.FilterGroup(10);
            PaymentHistLine.SetCurrentKey("Our Bank", Identification, Status);
            PaymentHistLine.SetRange("Our Bank", "Statement No.");
            PaymentHistLine.SetFilter(Status, '%1', PaymentHistLine.Status::Transmitted);
            if "Account No." <> '' then
                PaymentHistLine.SetRange("Account No.", "Account No.");
            PaymentHistLine.FilterGroup(0);
            PaymentHistLine."Our Bank" := "Statement No.";
            PaymentHistLine.Identification := Identification;
            PaymentHistLnSurvey.SetRecord(PaymentHistLine);
            PaymentHistLnSurvey.SetTableView(PaymentHistLine);
            PaymentHistLnSurvey.LookupMode(true);
            if PaymentHistLnSurvey.RunModal() = ACTION::LookupOK then begin
                PaymentHistLnSurvey.GetRecord(PaymentHistLine);
                Identification := PaymentHistLine.Identification;
                Validate(Identification);
            end;
        end;
    end;

    procedure CalculateVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        "VAT %" := 0;
        "Debit Incl. VAT" := Debit;
        "Debit VAT" := 0;
        "Credit Incl. VAT" := Credit;
        "Credit VAT" := 0;

        if "Account Type" = "Account Type"::"G/L Account" then begin
            GetCurrency();

            if "VAT Type" in ["VAT Type"::Purchase, "VAT Type"::Sale] then begin
                if GetVATPostingSetup(VATPostingSetup) then
                    case VATPostingSetup."VAT Calculation Type" of
                        VATPostingSetup."VAT Calculation Type"::"Normal VAT":
                            begin
                                "VAT %" := VATPostingSetup."VAT %";
                                if "Amount incl. VAT" then begin
                                    "Debit VAT" := Debit - Round(Debit / (1 + "VAT %" / 100), Currency."Amount Rounding Precision");
                                    "Debit Incl. VAT" := Debit;
                                    "Credit VAT" := Credit - Round(Credit / (1 + "VAT %" / 100), Currency."Amount Rounding Precision");
                                    "Credit Incl. VAT" := Credit;
                                end else begin
                                    "Debit VAT" := Round(Debit * "VAT %" / 100, Currency."Amount Rounding Precision");
                                    "Debit Incl. VAT" := Debit + "Debit VAT";
                                    "Credit VAT" := Round(Credit * "VAT %" / 100, Currency."Amount Rounding Precision");
                                    "Credit Incl. VAT" := Credit + "Credit VAT";
                                end;
                            end;
                        VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT":
                            begin
                                "VAT %" := 0;
                                "Debit VAT" := 0;
                                "Debit Incl. VAT" := Debit;
                                "Credit VAT" := 0;
                                "Credit Incl. VAT" := Credit;
                            end;
                        VATPostingSetup."VAT Calculation Type"::"Full VAT":
                            begin
                                "VAT %" := 100;
                                "Amount incl. VAT" := true;
                                "Debit Incl. VAT" := Debit;
                                "Debit VAT" := Debit;
                                "Credit Incl. VAT" := Credit;
                                "Credit VAT" := Credit;
                                if "Account Type" <> "Account Type"::"G/L Account" then
                                    Error(Text1000019, FieldCaption("Account Type"));
                                case "VAT Type" of
                                    "VAT Type"::Purchase:
                                        if "Account No." <> VATPostingSetup."Purchase VAT Account" then
                                            Error(
                                              Text1000020,
                                              FieldCaption("VAT Type"),
                                              "VAT Type",
                                              FieldCaption("Account No."),
                                              "Account No.",
                                              VATPostingSetup.FieldCaption("Purchase VAT Account"),
                                              VATPostingSetup."Purchase VAT Account");
                                    "VAT Type"::Sale:
                                        if "Account No." <> VATPostingSetup."Sales VAT Account" then
                                            Error(
                                              Text1000020,
                                              FieldCaption("VAT Type"),
                                              "VAT Type",
                                              FieldCaption("Account No."),
                                              "Account No.",
                                              VATPostingSetup.FieldCaption("Sales VAT Account"),
                                              VATPostingSetup."Sales VAT Account");
                                end;
                            end;
                        else
                            VATPostingSetup.FieldError("VAT Calculation Type",
                              Text1000021);
                    end
                else
                    if "VAT Prod. Posting Group" <> '' then
                        Message(
                          Text1000022 +
                          Text1000023,
                          FieldCaption("VAT Bus. Posting Group"), "VAT Bus. Posting Group",
                          FieldCaption("VAT Prod. Posting Group"), "VAT Prod. Posting Group",
                          FieldCaption("VAT %"));
            end else
                if "VAT Prod. Posting Group" <> '' then
                    Message(Text1000024 +
                      Text1000025 +
                      Text1000026 +
                      Text1000027,
                      FieldCaption("VAT Type"),
                      GLAccount.FieldCaption("Gen. Posting Type"),
                      GLAccount.FieldCaption("VAT Bus. Posting Group"),
                      GLAccount.FieldCaption("VAT Prod. Posting Group"),
                      "Account No.");
        end else
            if ("VAT Type" <> "VAT Type"::" ") or ("VAT Bus. Posting Group" <> '') or ("VAT Prod. Posting Group" <> '') then
                Error(
                  Text1000028,
                  FieldCaption("Account Type"));
    end;

    procedure "New Applies-to ID"() ID: Code[20]
    var
        CBGStatementln: Record "CBG Statement Line";
    begin
        GetCBGStatementHeader();
        case CBGStatement.Type of
            CBGStatement.Type::"Bank/Giro":
                begin
                    CBGStatementln.SetCurrentKey("Journal Template Name", "No.", "Applies-to ID");
                    CBGStatementln.SetRange("Journal Template Name", "Journal Template Name");
                    CBGStatementln.SetRange("No.", "No.");
                    CBGStatementln.SetFilter("Applies-to ID", '<>%1', '');
                    if CBGStatementln.FindLast() then
                        ID := IncStr(CBGStatementln."Applies-to ID")
                    else
                        if StrLen(CBGStatement."Document No.") > MaxStrLen(ID) - 10 then
                            ID := DelStr(CBGStatement."Document No.", 4, StrLen(CBGStatement."Document No.") - (MaxStrLen(ID) - 10)) + '-000000001'
                        else
                            ID := CBGStatement."Document No." + '-000000001';
                end;
            CBGStatement.Type::Cash:
                ID := "Document No.";
        end;
    end;

    local procedure GetVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup") Result: Boolean
    begin
        Result := VATPostingSetup.Get(Rec."VAT Bus. Posting Group", Rec."VAT Prod. Posting Group");
        OnAfterGetVATPostingSetup(VATPostingSetup, Rec, Result);
    end;

    protected procedure DeleteAppliesToID(var CBGStatementlineRec: Record "CBG Statement Line")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        if "Applies-to ID" <> '' then begin
            case CBGStatementlineRec."Account Type" of
                "Account Type"::Customer:
                    begin
                        CustLedgEntry.SetCurrentKey("Customer No.");
                        CustLedgEntry.SetRange("Customer No.", CBGStatementlineRec."Account No.");
                        CustLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
                        OnDeleteAppliesToIDOnAfterSetCustomerLedgerEntryFilters(CBGStatementlineRec, CustLedgEntry);
                        if CustLedgEntry.Find('-') then
                            repeat
                                ClearCustApplnEntryFields(CustLedgEntry);
                            until CustLedgEntry.Next() = 0;
                    end;
                "Account Type"::Vendor:
                    begin
                        VendLedgEntry.SetCurrentKey("Vendor No.");
                        VendLedgEntry.SetRange("Vendor No.", CBGStatementlineRec."Account No.");
                        VendLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
                        OnDeleteAppliesToIDOnAfterSetVendorLedgerEntryFilters(CBGStatementlineRec, VendLedgEntry);
                        if VendLedgEntry.Find('-') then
                            repeat
                                ClearVendApplnEntryFields(VendLedgEntry);
                            until VendLedgEntry.Next() = 0;
                    end;
                "Account Type"::Employee:
                    begin
                        EmployeeLedgerEntry.SetCurrentKey("Employee No.");
                        EmployeeLedgerEntry.SetRange("Employee No.", CBGStatementlineRec."Account No.");
                        EmployeeLedgerEntry.SetRange("Applies-to ID", "Applies-to ID");
                        OnDeleteAppliesToIDOnAfterSetEmployeeLedgerEntryFilters(CBGStatementlineRec, EmployeeLedgerEntry);
                        if EmployeeLedgerEntry.Find('-') then
                            repeat
                                ClearEmployeeApplnEntryFields(EmployeeLedgerEntry);
                            until EmployeeLedgerEntry.Next() = 0;
                    end;
            end;
            "Applies-to ID" := '';
        end;
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        GenJournalTemplate.Get("Journal Template Name");
        "Dimension Set ID" := DimManagement.GetDefaultDimID(
            DefaultDimSource, GenJournalTemplate."Source Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
    end;

    procedure ValidateShortcutDimCode(FieldNo: Integer; var ShortcutDimCode: Code[20])
    begin
        DimManagement.ValidateShortcutDimValues(FieldNo, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure LookupShortcutDimCode(FieldNo: Integer; var ShortcutDimCode: Code[20])
    begin
        DimManagement.LookupDimValueCode(FieldNo, ShortcutDimCode);
        Rec.ValidateShortcutDimCode(FieldNo, ShortcutDimCode);
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimManagement.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" := DimManagement.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2 %3', "Journal Template Name", "No.", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure GetDate(String: Text; Position: Integer; Length: Integer; ExpectedFormat: Text) Result: Date
    var
        DateString: Text;
        DateVar: Variant;
    begin
        DateVar := 0D;
        DateString := GetText(String, Position, Length);
        if not TypeHelper.Evaluate(DateVar, DateString, ExpectedFormat, '') then
            Error(DateParseErr, DateString, ExpectedFormat);
        Result := DateVar;
    end;

    procedure GetText(String: Text[1024]; Position: Integer; Length: Integer): Text[1024]
    begin
        exit(DelChr(CopyStr(String, Position, Length), '<>'));
    end;

    procedure GetDecimal(String: Text[1024]; Position: Integer; Length: Integer; DecimalSeparator: Code[1]) Result: Decimal
    var
        DecimalText: Text[30];
        DecimalTextBeforeComma: Text[30];
        DecimalTextAfterComma: Text[30];
        DecimalBeforeComma: Decimal;
        DecimalAfterComma: Decimal;
        CommaPosition: Integer;
    begin
        DecimalText := GetText(String, Position, Length);

        Position := 1;
        while DecimalText[Position] in ['0' .. '9', DecimalSeparator[1]] do
            Position := Position + 1;

        DecimalText := CopyStr(DecimalText, 1, Position - 1);
        CommaPosition := StrPos(DecimalText, DecimalSeparator);

        if CommaPosition > 0 then begin
            DecimalTextBeforeComma := CopyStr(DecimalText, 1, CommaPosition - 1);
            DecimalTextAfterComma := DelStr(DecimalText, 1, CommaPosition);
        end else begin
            DecimalTextBeforeComma := DecimalText;
            DecimalTextAfterComma := '0';
        end;

        if DecimalTextAfterComma = '' then
            DecimalTextAfterComma := '0';
        if DecimalTextBeforeComma = '' then
            DecimalTextBeforeComma := '0';

        Evaluate(DecimalBeforeComma, DecimalTextBeforeComma);
        Evaluate(DecimalAfterComma, DecimalTextAfterComma);

        exit(DecimalBeforeComma + Power(0.1, StrLen(DecimalTextAfterComma)) * DecimalAfterComma);
    end;

    local procedure ClearDataExchEntries()
    var
        DataExchField: Record "Data Exch. Field";
    begin
        DataExchField.SetRange("Data Exch. No.", "Data Exch. Entry No.");
        DataExchField.SetRange("Line No.", "Data Exch. Line No.");
        DataExchField.DeleteAll();
    end;

    local procedure ClearCustApplnEntryFields(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry."Accepted Pmt. Disc. Tolerance" := false;
        CustLedgerEntry."Accepted Payment Tolerance" := 0;
        CustLedgerEntry."Amount to Apply" := 0;
        CustLedgerEntry."Applies-to ID" := '';
        CustLedgerEntry.Modify();
    end;

    local procedure ClearVendApplnEntryFields(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry."Accepted Pmt. Disc. Tolerance" := false;
        VendorLedgerEntry."Accepted Payment Tolerance" := 0;
        VendorLedgerEntry."Amount to Apply" := 0;
        VendorLedgerEntry."Applies-to ID" := '';
        VendorLedgerEntry.Modify();
    end;

    local procedure ClearEmployeeApplnEntryFields(var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
        EmployeeLedgerEntry."Amount to Apply" := 0;
        EmployeeLedgerEntry."Applies-to ID" := '';
        EmployeeLedgerEntry.Modify();
    end;

    protected procedure SetApplyCVLedgerEntries(PaymentHistLine: Record "Payment History Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetApplyCVLedgerEntries(Rec, PaymentHistLine, IsHandled);
        if IsHandled then
            exit;

        FinancialInterfaceTelebank.SetApplyCVLedgerEntries(PaymentHistLine, "New Applies-to ID"(), false, false);
    end;

    procedure ValidateApplyRequirements(CBGStatementLine: Record "CBG Statement Line")
    begin
        case CBGStatementLine."Account Type" of
            CBGStatementLine."Account Type"::Customer:
                ValidateCustomerApplyRequirements(CBGStatementLine);
            CBGStatementLine."Account Type"::Vendor:
                ValidateVendorApplyRequirements(CBGStatementLine);
            CBGStatementLine."Account Type"::Employee:
                ValidateEmployeeApplyRequirements(CBGStatementLine);
        end;
    end;

    local procedure ValidateCustomerApplyRequirements(CBGStatementLine: Record "CBG Statement Line")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateCustomerApplyRequirements(CBGStatementLine, IsHandled);
        if IsHandled then
            exit;

        if (CBGStatementLine."Applies-to ID" = '') and (CBGStatementLine."Applies-to Doc. No." = '') then
            exit;

        case true of
            CBGStatementLine."Applies-to ID" <> '':
                CustLedgEntry.SetRange("Applies-to ID", CBGStatementLine."Applies-to ID");
            CBGStatementLine."Applies-to Doc. No." <> '':
                begin
                    CustLedgEntry.SetRange("Document No.", CBGStatementLine."Applies-to Doc. No.");
                    if CBGStatementLine."Applies-to Doc. Type" <> CBGStatementLine."Applies-to Doc. Type"::" " then
                        CustLedgEntry.SetRange("Document Type", CBGStatementLine."Applies-to Doc. Type");
                end;
        end;

        CustLedgEntry.SetRange("Customer No.", CBGStatementLine."Account No.");
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.SetFilter("Posting Date", '>%1', CBGStatementLine.Date);
        if not CustLedgEntry.IsEmpty() then
            Error(PostingDateEarlierErr);
    end;

    local procedure ValidateVendorApplyRequirements(CBGStatementLine: Record "CBG Statement Line")
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateVendorApplyRequirements(CBGStatementLine, IsHandled);
        if IsHandled then
            exit;

        if (CBGStatementLine."Applies-to ID" = '') and (CBGStatementLine."Applies-to Doc. No." = '') then
            exit;

        case true of
            CBGStatementLine."Applies-to ID" <> '':
                VendLedgEntry.SetRange("Applies-to ID", CBGStatementLine."Applies-to ID");
            CBGStatementLine."Applies-to Doc. No." <> '':
                begin
                    VendLedgEntry.SetRange("Document No.", CBGStatementLine."Applies-to Doc. No.");
                    if CBGStatementLine."Applies-to Doc. Type" <> CBGStatementLine."Applies-to Doc. Type"::" " then
                        VendLedgEntry.SetRange("Document Type", CBGStatementLine."Applies-to Doc. Type");
                end;
        end;

        VendLedgEntry.SetRange("Vendor No.", CBGStatementLine."Account No.");
        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.SetFilter("Posting Date", '>%1', CBGStatementLine.Date);
        if not VendLedgEntry.IsEmpty() then
            Error(PostingDateEarlierErr);
    end;

    local procedure ValidateEmployeeApplyRequirements(CBGStatementLine: Record "CBG Statement Line")
    var
        EmplLedgEntry: Record "Employee Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateEmployeeApplyRequirements(CBGStatementLine, IsHandled);
        if IsHandled then
            exit;

        if (CBGStatementLine."Applies-to ID" = '') and (CBGStatementLine."Applies-to Doc. No." = '') then
            exit;

        case true of
            CBGStatementLine."Applies-to ID" <> '':
                EmplLedgEntry.SetRange("Applies-to ID", CBGStatementLine."Applies-to ID");
            CBGStatementLine."Applies-to Doc. No." <> '':
                begin
                    EmplLedgEntry.SetRange("Document No.", CBGStatementLine."Applies-to Doc. No.");
                    if CBGStatementLine."Applies-to Doc. Type" <> EmplLedgEntry."Applies-to Doc. Type"::" " then
                        EmplLedgEntry.SetRange("Document Type", CBGStatementLine."Applies-to Doc. Type");
                end;
        end;

        EmplLedgEntry.SetRange("Employee No.", CBGStatementLine."Account No.");
        EmplLedgEntry.SetRange(Open, true);
        EmplLedgEntry.SetFilter("Posting Date", '>%1', CBGStatementLine.Date);
        if not EmplLedgEntry.IsEmpty() then
            Error(PostingDateEarlierErr);
    end;

    procedure CreateDimFromDefaultDim(FieldNo: Integer)
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource, FieldNo);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
        DimManagement.AddDimSource(DefaultDimSource, DimManagement.TypeToTableID1(Rec."Account Type"), Rec."Account No.", FieldNo = Rec.FieldNo("Account No."));
        DimManagement.AddDimSource(DefaultDimSource, Database::Job, Rec."Job No.", FieldNo = Rec.FieldNo("Job No."));
        DimManagement.AddDimSource(DefaultDimSource, Database::"Salesperson/Purchaser", Rec."Salespers./Purch. Code", FieldNo = Rec.FieldNo("Salespers./Purch. Code"));
        DimManagement.AddDimSource(DefaultDimSource, Database::Campaign, Rec."Campaign No.", FieldNo = Rec.FieldNo("Campaign No."));

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, FieldNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; CBGStatementLine: Record "CBG Statement Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var CBGStatementLine: Record "CBG Statement Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateGenJournalLine(var GenJnlLine: Record "Gen. Journal Line"; CBGStatementLine: Record "CBG Statement Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReadGenJournalLine(var CBGStatementLine: Record "CBG Statement Line"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAccountTypeAndDocumentType(var CBGStatementLine: Record "CBG Statement Line"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetGenPostingTypeAndDocumentType(CBGStatementLine: Record "CBG Statement Line"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAppliesToIDOnValidate(var CBGStatementLine: Record "CBG Statement Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAccountNo(var CBGStatementLine: Record "CBG Statement Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitRecord(var CBGStatementLine: Record "CBG Statement Line"; var CBGStatementLineLast: Record "CBG Statement Line"; CBGStatement: Record "CBG Statement")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupAppliesToDocNo(var CBGStatementLine: Record "CBG Statement Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenAccountEntries(var CBGStatementLine: Record "CBG Statement Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReadGenJournalLine(var CBGStatementLine: Record "CBG Statement Line"; var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetApplyCVLedgerEntries(var CBGStatementLine: Record "CBG Statement Line"; PaymentHistLine: Record "Payment History Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCustomerApplyRequirements(var CBGStatementLine: Record "CBG Statement Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateEmployeeApplyRequirements(var CBGStatementLine: Record "CBG Statement Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateVendorApplyRequirements(var CBGStatementLine: Record "CBG Statement Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateVATAmountOnLine(var CBGStatementLine: Record "CBG Statement Line"; var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateGenJournalLineOnAfterSetDocumentTypeForCorrection(CBGStatementLine: Record "CBG Statement Line"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteAppliesToIDOnAfterSetCustomerLedgerEntryFilters(var CBGStatementLine: Record "CBG Statement Line"; var CustLedgEntry: Record "Cust. Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteAppliesToIDOnAfterSetEmployeeLedgerEntryFilters(var CBGStatementLine: Record "CBG Statement Line"; var EmployeeLedgEntry: Record "Employee Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteAppliesToIDOnAfterSetVendorLedgerEntryFilters(var CBGStatementLine: Record "CBG Statement Line"; var VendorLedgEntry: Record "Vendor Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenerateDocumentNo(var CBGStatementLine: Record "CBG Statement Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePmtTolCBGJnl(var CBGStatementLine: Record "CBG Statement Line"; var xCBGStatementLine: Record "CBG Statement Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAccountNoOnValidate(var CBGStatementLine: Record "CBG Statement Line"; var xCBGStatementLine: Record "CBG Statement Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReadGenJournalLineOnAfterCalcShouldSetAmount(var CBGStatementLine: Record "CBG Statement Line"; GenJournalLine: Record "Gen. Journal Line"; var ShouldSetAmount: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateIdentificationOnBeforeCheck(var CBGStatementLine: Record "CBG Statement Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupAppliesToDocNoOnAfterSetCustAppliesToDocNo(var CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupAppliesToDocNoOnAfterSetVendorAppliesToDocNo(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupAppliesToDocAnAfterSetCustLedgerEntryFilters(var CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupAppliesToDocAnAfterSetVendorLedgerEntryFilters(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}
