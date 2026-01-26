// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.History;

table 7000005 "Bill Group"
{
    Caption = 'Bill Group';
    DrillDownPageID = "Bill Groups List";
    LookupPageID = "Bill Groups List";
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
                NoSeries.TestManual(CarteraSetup."Bill Group Nos.");
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

                if BillGrIsEmpty() then begin
                    Validate("Currency Code", BankAcc."Currency Code");
                    exit;
                end;

                BankAcc.TestField("Currency Code", "Currency Code");

                CalcFields(Amount);
                if (Amount <> 0) and (Factoring = Factoring::" ") then
                    CarteraManagement.CheckDiscCreditLimit(Rec);

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
        field(6; "Dealing Type"; Enum "Cartera Dealing Type")
        {
            Caption = 'Dealing Type';

            trigger OnValidate()
            begin
                Validate("Currency Code");

                CalcFields(Amount);
                if (Factoring = Factoring::" ") and (Amount <> 0) then
                    CarteraManagement.CheckDiscCreditLimit(Rec);

                if "Dealing Type" <> xRec."Dealing Type" then begin
                    CheckPrinted();
                    ResetPrinted();
                end;
            end;
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
                                                                       Type = const(Receivable)));
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
                                                            Type = filter(Receivable)));
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

                if ("Currency Code" <> xRec."Currency Code") and not BillGrIsEmpty() then
                    FieldError("Currency Code",
                      StrSubstNo(Text1100003, TableCaption));

                if "Currency Code" <> '' then begin
                    Currency.Reset();
                    if "Dealing Type" = "Dealing Type"::Discount then
                        Currency.SetRange("Bill Groups - Discount", true)
                    else
                        Currency.SetRange("Bill Groups - Collection", true);
                    Currency.Code := "Currency Code";
                    if not Currency.Find() then
                        Error(
                          Text1100004,
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
                                                                           Type = const(Receivable)));
            Caption = 'Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(39; Factoring; Option)
        {
            Caption = 'Factoring';
            OptionCaption = ' ,Unrisked,Risked';
            OptionMembers = " ",Unrisked,Risked;

            trigger OnValidate()
            begin
                Doc.Reset();
                Doc.SetCurrentKey(Type, "Collection Agent", "Bill Gr./Pmt. Order No.", "Currency Code", Accepted, "Due Date", Place, "Document Type");
                Doc.SetRange(Type, Doc.Type::Receivable);
                Doc.SetRange("Collection Agent", Doc."Collection Agent"::Bank);
                Doc.SetRange("Bill Gr./Pmt. Order No.", "No.");
                if Factoring = Factoring::" " then begin
                    Doc.SetFilter("Document Type", '<>%1', Doc."Document Type"::Bill);
                    if Doc.FindFirst() then
                        Error(Text1100005);
                end else begin
                    Doc.SetFilter("Document Type", '%1', Doc."Document Type"::Bill);
                    if Doc.FindFirst() then
                        Error(Text1100006);
                end;
            end;
        }
        field(1200; "Partner Type"; Enum "Partner Type")
        {
            Caption = 'Partner Type';
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
        Doc.SetRange(Type, Doc.Type::Receivable);
        Doc.SetRange("Bill Gr./Pmt. Order No.", "No.");
        if Doc.FindFirst() then
            Error(Text1100002);

        BGPOCommentLine.SetRange("BG/PO No.", "No.");
        BGPOCommentLine.DeleteAll();
    end;

    trigger OnInsert()
    var
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            CarteraSetup.Get();
            CarteraSetup.TestField("Bill Group Nos.");
                "No. Series" := CarteraSetup."Bill Group Nos.";
                if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                    "No. Series" := xRec."No. Series";
                "No." := NoSeries.GetNextNo("No. Series");
        end;

        if GetFilter("Bank Account No.") <> '' then
            if GetRangeMin("Bank Account No.") = GetRangeMax("Bank Account No.") then begin
                Option := StrMenu(Text1100000);
                case Option of
                    0:
                        Error(Text1100001, TableCaption);
                    1:
                        "Dealing Type" := "Dealing Type"::Collection;
                    2:
                        "Dealing Type" := "Dealing Type"::Discount;
                end;
                BankAcc.Get(GetRangeMin("Bank Account No."));
                Validate("Currency Code", BankAcc."Currency Code");
                Validate("Bank Account No.", BankAcc."No.");
            end;

        CheckNoNotUsed();
        UpdateDescription();
        "Posting Date" := WorkDate();
    end;

    var
        Text1100000: Label '&Collection,&Discount';
        Text1100001: Label 'The creation of a new %1 was cancelled by the user';
        Text1100002: Label 'This Bill Group is not empty. Remove all its bills and try again.';
        Text1100003: Label 'can only be changed when the %1 is empty';
        Text1100004: Label 'The operation is not allowed for bill groups using %1. Check your currency setup.';
        Text1100005: Label 'Invoices should be removed.';
        Text1100006: Label 'Bills should be removed.';
        Text1100007: Label 'This bill group has already been printed. Proceed anyway?';
        Text1100008: Label 'The update has been interrupted by the user.';
        Text1100009: Label 'Bill Group';
        Text1100010: Label ' is currently in use in a Posted Bill Group.';
        Text1100011: Label ' is currently in use in a Closed Bill Group.';
        Text1100012: Label 'untitled';
        BillGr: Record "Bill Group";
        PostedBillGr: Record "Posted Bill Group";
        ClosedBillGr: Record "Closed Bill Group";
        Doc: Record "Cartera Doc.";
        CarteraSetup: Record "Cartera Setup";
        Currency: Record Currency;
        BankAcc: Record "Bank Account";
        BGPOCommentLine: Record "BG/PO Comment Line";
        Currencies: Page Currencies;
        CarteraManagement: Codeunit CarteraManagement;
        Option: Integer;
        SilentDirectDebitFormat: Option " ",Standard,N58;
        DirectDebitOptionTxt: Label 'Direct Debit';
        InvoiceDiscountingOptionTxt: Label 'Invoice Discounting';
        InstructionTxt: Label 'Select which format to use.';
        DirectDebitFormatSilentlySelected: Boolean;

    [Scope('OnPrem')]
    procedure AssistEdit(OldBillGr: Record "Bill Group"): Boolean
    var
        NoSeries: Codeunit "No. Series";
    begin
        BillGr := Rec;
        CarteraSetup.Get();
        CarteraSetup.TestField("Bill Group Nos.");
        if NoSeries.LookupRelatedNoSeries(CarteraSetup."Bill Group Nos.", OldBillGr."No. Series", BillGr."No. Series") then begin
            BillGr."No." := NoSeries.GetNextNo(BillGr."No. Series");
            Rec := BillGr;
            exit(true);
        end;
    end;

    local procedure CheckPrinted()
    begin
        if "No. Printed" <> 0 then
            if not Confirm(Text1100007) then
                Error(Text1100008);
    end;

    [Scope('OnPrem')]
    procedure ResetPrinted()
    begin
        "No. Printed" := 0;
    end;

    local procedure UpdateDescription()
    begin
        "Posting Description" := Text1100009 + ' ' + "No.";
    end;

    local procedure CheckNoNotUsed()
    begin
        if PostedBillGr.Get("No.") then
            FieldError("No.", PostedBillGr."No." + Text1100010);
        if ClosedBillGr.Get("No.") then
            FieldError("No.", ClosedBillGr."No." + Text1100011);
    end;

    [Scope('OnPrem')]
    procedure PrintRecords(ShowRequestForm: Boolean)
    var
        CarteraReportSelection: Record "Cartera Report Selections";
    begin
        BillGr.Copy(Rec);
        CarteraReportSelection.SetRange(Usage, CarteraReportSelection.Usage::"Bill Group");
        CarteraReportSelection.SetFilter("Report ID", '<>0');
        CarteraReportSelection.Find('-');
        repeat
            REPORT.RunModal(CarteraReportSelection."Report ID", ShowRequestForm, false, BillGr);
        until CarteraReportSelection.Next() = 0;
    end;

    local procedure BillGrIsEmpty(): Boolean
    begin
        Doc.SetCurrentKey(Type, "Bill Gr./Pmt. Order No.");
        Doc.SetRange(Type, Doc.Type::Receivable);
        Doc.SetRange("Bill Gr./Pmt. Order No.", "No.");
        exit(not Doc.FindFirst())
    end;

    procedure Caption(): Text
    begin
        if "No." = '' then
            exit(Text1100012);
        CalcFields("Bank Account Name");
        exit(StrSubstNo('%1 %2', "No.", "Bank Account Name"));
    end;

    [Scope('OnPrem')]
    procedure ExportToFile()
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        BankAccount: Record "Bank Account";
    begin
        DirectDebitCollection.CreateRecord("No.", "Bank Account No.", "Partner Type");
        DirectDebitCollection."Source Table ID" := DATABASE::"Bill Group";
        DirectDebitCollection.Modify();
        CheckSEPADirectDebitFormat(DirectDebitCollection);
        BankAccount.Get("Bank Account No.");
        Commit();
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");
        RunFileExportCodeunit(BankAccount.GetDDExportCodeunitID(), DirectDebitCollection."No.", DirectDebitCollectionEntry);
        DeleteDirectDebitCollection(DirectDebitCollection."No.");
    end;

    [Scope('OnPrem')]
    procedure RunFileExportCodeunit(CodeunitID: Integer; DirectDebitCollectionNo: Integer; var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    var
        LastError: Text;
    begin
        if not CODEUNIT.Run(CodeunitID, DirectDebitCollectionEntry) then begin
            LastError := GetLastErrorText;
            DeleteDirectDebitCollection(DirectDebitCollectionNo);
            Commit();
            Error(LastError);
        end;
    end;

    [Scope('OnPrem')]
    procedure DeleteDirectDebitCollection(DirectDebitCollectionNo: Integer)
    var
        DirectDebitCollection: Record "Direct Debit Collection";
    begin
        if DirectDebitCollection.Get(DirectDebitCollectionNo) then
            DirectDebitCollection.Delete(true);
    end;

    [Scope('OnPrem')]
    procedure SelectDirectDebitFormatSilently(NewDirectDebitFormat: Option)
    begin
        SilentDirectDebitFormat := NewDirectDebitFormat;
        DirectDebitFormatSilentlySelected := true;
    end;

    local procedure CheckSEPADirectDebitFormat(var DirectDebitCollection: Record "Direct Debit Collection")
    var
        BankAccount: Record "Bank Account";
        DirectDebitFormat: Option;
        Selection: Integer;
    begin
        BankAccount.Get("Bank Account No.");
        if BankAccount.GetDDExportCodeunitID() = CODEUNIT::"SEPA DD-Export File" then begin
            if not DirectDebitFormatSilentlySelected then begin
                Selection := StrMenu(StrSubstNo('%1,%2', DirectDebitOptionTxt, InvoiceDiscountingOptionTxt), 1, InstructionTxt);

                if Selection = 0 then
                    exit;

                case Selection of
                    1:
                        DirectDebitFormat := DirectDebitCollection."Direct Debit Format"::Standard;
                    2:
                        DirectDebitFormat := DirectDebitCollection."Direct Debit Format"::N58;
                end;
            end else
                DirectDebitFormat := SilentDirectDebitFormat;

            DirectDebitCollection."Direct Debit Format" := DirectDebitFormat;
            DirectDebitCollection.Modify();
        end;
    end;
}
