// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.History;

table 7000020 "Payment Order"
{
    Caption = 'Payment Order';
    DrillDownPageID = "Payment Orders List";
    LookupPageID = "Payment Orders List";
    Permissions = TableData "Cartera Doc." = m;
    DataClassification = CustomerContent;

    fields
    {
        field(2; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            var
                NoSeries: Codeunit "No. Series";
            begin
                if "No." = xRec."No." then
                    exit;

                CheckPrinted();
                ResetPrinted();

                CarteraSetup.Get();
                NoSeries.TestManual(CarteraSetup."Payment Order Nos.");
                "No. Series" := '';

                UpdateDescription();
                CheckNoNotUsed();
            end;
        }
        field(3; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";

            trigger OnValidate()
            begin
                CalcFields("Bank Account Name");

                if "Bank Account No." = '' then
                    exit;

                BankAcc.Get("Bank Account No.");
                BankAcc.TestField(Blocked, false);

                if PmtOrdIsEmpty() then begin
                    Validate("Currency Code", BankAcc."Currency Code");
                    exit;
                end;

                BankAcc.TestField("Currency Code", "Currency Code");

                CalcFields(Amount);

                if "Bank Account No." <> xRec."Bank Account No." then begin
                    CheckPrinted();
                    ResetPrinted();
                end;
            end;
        }
        field(4; "Bank Account Name"; Text[100])
        {
            CalcFormula = lookup("Bank Account".Name where("No." = field("Bank Account No.")));
            Caption = 'Bank Account Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        field(7; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Cartera Doc."."Remaining Amount" where("Bill Gr./Pmt. Order No." = field("No."),
                                                                       "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                       "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                       "Category Code" = field("Category Filter"),
                                                                       "Due Date" = field("Due Date Filter"),
                                                                       Type = const(Payable)));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(9; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
        }
        field(10; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            begin
                if "Posting Date" <> xRec."Posting Date" then begin
                    CheckPrinted();
                    ResetPrinted();
                end;
            end;
        }
        field(11; Comment; Boolean)
        {
            CalcFormula = exist("BG/PO Comment Line" where("BG/PO No." = field("No."),
                                                            Type = filter(Payable)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Category Filter"; Code[10])
        {
            Caption = 'Category Filter';
            FieldClass = FlowFilter;
            TableRelation = "Category Code";
            ValidateTableRelation = false;
        }
        field(13; "Due Date Filter"; Date)
        {
            Caption = 'Due Date Filter';
            FieldClass = FlowFilter;
        }
        field(14; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(15; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(16; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(33; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnLookup()
            begin
                Currency.Reset();

                if Currency.Get("Currency Code") then;
                Currencies.SetRecord(Currency);
                Currencies.LookupMode(true);
                if ACTION::LookupOK = Currencies.RunModal() then begin
                    Currencies.GetRecord(Currency);
                    Clear(Currencies);
                    Validate("Currency Code", Currency.Code);
                end else
                    Clear(Currencies);
            end;

            trigger OnValidate()
            begin
                if BankAcc.Get("Bank Account No.") and ("Currency Code" <> BankAcc."Currency Code")
                then
                    TestField("Currency Code", BankAcc."Currency Code");

                if ("Currency Code" <> xRec."Currency Code") and not PmtOrdIsEmpty() then
                    FieldError("Currency Code",
                      StrSubstNo(Text1100001, TableCaption));

                if "Currency Code" <> '' then begin
                    Currency.Reset();
                    Currency.SetRange("Payment Orders", true);
                    Currency.Code := "Currency Code";
                    if not Currency.Find() then
                        Error(
                          Text1100002,
                          "Currency Code");
                end;

                if "Currency Code" <> xRec."Currency Code" then begin
                    CheckPrinted();
                    ResetPrinted();
                end;
            end;
        }
        field(34; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Cartera Doc."."Remaining Amt. (LCY)" where("Bill Gr./Pmt. Order No." = field("No."),
                                                                           "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                           "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                           "Category Code" = field("Category Filter"),
                                                                           "Due Date" = field("Due Date Filter"),
                                                                           Type = const(Payable)));
            Caption = 'Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(35; "Elect. Pmts Exported"; Boolean)
        {
            Caption = 'Elect. Pmts Exported';

            trigger OnValidate()
            var
                CarteraDoc: Record "Cartera Doc.";
            begin
                CarteraDoc.SetRange(Type, CarteraDoc.Type::Payable);
                CarteraDoc.SetRange("Bill Gr./Pmt. Order No.", "No.");
                CarteraDoc.ModifyAll("Elect. Pmts Exported", true);
            end;
        }
        field(36; "Export Electronic Payment"; Boolean)
        {
            Caption = 'Export Electronic Payment';

            trigger OnValidate()
            begin
                TestField("Elect. Pmts Exported", false);
            end;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Bank Account No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        Doc.SetCurrentKey(Type, "Bill Gr./Pmt. Order No.");
        Doc.SetRange(Type, Doc.Type::Payable);
        Doc.SetRange("Bill Gr./Pmt. Order No.", "No.");
        if Doc.FindFirst() then
            Error(Text1100000);

        BGPOCommentLine.SetRange("BG/PO No.", "No.");
        BGPOCommentLine.DeleteAll();
    end;

    trigger OnInsert()
    var
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            CarteraSetup.Get();
            CarteraSetup.TestField("Payment Order Nos.");
                "No. Series" := CarteraSetup."Payment Order Nos.";
                if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                    "No. Series" := xRec."No. Series";
                "No." := NoSeries.GetNextNo("No. Series");
        end;

        if GetFilter("Bank Account No.") <> '' then
            if GetRangeMin("Bank Account No.") = GetRangeMax("Bank Account No.") then begin
                BankAcc.Get(GetRangeMin("Bank Account No."));
                Validate("Currency Code", BankAcc."Currency Code");
                Validate("Bank Account No.", BankAcc."No.");
            end;

        CheckNoNotUsed();
        UpdateDescription();
        "Posting Date" := WorkDate();
    end;

    var
        Text1100000: Label 'This Payment Order is not empty. Remove all its bills and invoices and try again.';
        Text1100001: Label 'can only be changed when the %1 is empty';
        Text1100002: Label 'The operation is not allowed for payment order using %1. Check your currency setup.';
        Text1100003: Label 'This payment order has already been printed. Proceed anyway?';
        Text1100004: Label 'The update has been interrupted by the user.';
        Text1100005: Label 'Payment Order';
        Text1100006: Label ' is currently in use in a Posted Payment Order.';
        Text1100007: Label ' is currently in use in a Closed Payment Order.';
        Text1100008: Label 'untitled';
        PmtOrd: Record "Payment Order";
        PostedPmtOrd: Record "Posted Payment Order";
        ClosedPmtOrd: Record "Closed Payment Order";
        Doc: Record "Cartera Doc.";
        CarteraSetup: Record "Cartera Setup";
        Currency: Record Currency;
        BankAcc: Record "Bank Account";
        BGPOCommentLine: Record "BG/PO Comment Line";
        Currencies: Page Currencies;
        ExportAgainQst: Label 'The selected payment order has already been exported. Do you want to export again?';

    [Scope('OnPrem')]
    procedure AssistEdit(OldPmtOrd: Record "Payment Order"): Boolean
    var
        NoSeries: Codeunit "No. Series";
    begin
        PmtOrd := Rec;
        CarteraSetup.Get();
        CarteraSetup.TestField("Payment Order Nos.");
        if NoSeries.LookupRelatedNoSeries(CarteraSetup."Payment Order Nos.", OldPmtOrd."No. Series", PmtOrd."No. Series") then begin
            PmtOrd."No." := NoSeries.GetNextNo(PmtOrd."No. Series");
            Rec := PmtOrd;
            exit(true);
        end;
    end;

    local procedure CheckPrinted()
    begin
        if "No. Printed" <> 0 then
            if not Confirm(Text1100003) then
                Error(Text1100004);
    end;

    [Scope('OnPrem')]
    procedure ResetPrinted()
    begin
        "No. Printed" := 0;
    end;

    local procedure UpdateDescription()
    begin
        "Posting Description" := Text1100005 + ' ' + "No.";
    end;

    local procedure CheckNoNotUsed()
    begin
        if PostedPmtOrd.Get("No.") then
            FieldError("No.", PostedPmtOrd."No." + Text1100006);
        if ClosedPmtOrd.Get("No.") then
            FieldError("No.", ClosedPmtOrd."No." + Text1100007);
    end;

    [Scope('OnPrem')]
    procedure PrintRecords(ShowRequestForm: Boolean)
    var
        CarteraReportSelection: Record "Cartera Report Selections";
    begin
        PmtOrd.Copy(Rec);
        CarteraReportSelection.SetRange(Usage, CarteraReportSelection.Usage::"Payment Order");
        CarteraReportSelection.SetFilter("Report ID", '<>0');
        CarteraReportSelection.Find('-');
        repeat
            REPORT.RunModal(CarteraReportSelection."Report ID", ShowRequestForm, false, PmtOrd);
        until CarteraReportSelection.Next() = 0;
    end;

    local procedure PmtOrdIsEmpty(): Boolean
    begin
        Doc.SetCurrentKey(Type, "Bill Gr./Pmt. Order No.");
        Doc.SetRange(Type, Doc.Type::Payable);
        Doc.SetRange("Bill Gr./Pmt. Order No.", "No.");
        exit(not Doc.FindFirst())
    end;

    procedure Caption(): Text
    begin
        if "No." = '' then
            exit(Text1100008);
        CalcFields("Bank Account Name");
        exit(StrSubstNo('%1 %2', "No.", "Bank Account Name"));
    end;

    [Scope('OnPrem')]
    procedure FilterSourceForExport(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine.SetRange("Journal Template Name", '');
        GenJnlLine.SetRange("Journal Batch Name", '');
        GenJnlLine.SetRange("Document No.", "No.");
        GenJnlLine."Bal. Account No." := "Bank Account No.";
    end;

    [Scope('OnPrem')]
    procedure ExportToFile()
    var
        GenJnlLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
    begin
        SetRecFilter();
        TestField("Export Electronic Payment", true);

        if "Elect. Pmts Exported" then
            if not Confirm(ExportAgainQst) then
                exit;

        BankAccount.Get("Bank Account No.");
        FilterSourceForExport(GenJnlLine);
        CODEUNIT.Run(BankAccount.GetPaymentExportCodeunitID(), GenJnlLine);
        Find();
        Validate("Elect. Pmts Exported", true);
        Modify();
    end;
}
