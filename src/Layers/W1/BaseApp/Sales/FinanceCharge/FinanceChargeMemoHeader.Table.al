// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;
using System.Globalization;
using System.IO;
using System.Security.User;
using System.Text;
using System.Utilities;

table 302 "Finance Charge Memo Header"
{
    Caption = 'Finance Charge Memo Header';
    DataCaptionFields = "No.", Name;
    DrillDownPageID = "Finance Charge Memo List";
    LookupPageID = "Finance Charge Memo List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    NoSeries.TestManual(GetNoSeriesCode());
                    "No. Series" := '';
                end;
                "Posting Description" := StrSubstNo(Text000, "No.");
            end;
        }
        field(2; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;

            trigger OnValidate()
            begin
                OnBeforeValidateCustomerNo(Rec);
                if CurrFieldNo = FieldNo("Customer No.") then
                    if Undo() then begin
                        "Customer No." := xRec."Customer No.";
                        exit;
                    end;
                if "Customer No." = '' then
                    exit;
                Cust.Get("Customer No.");
                Name := Cust.Name;
                "Name 2" := Cust."Name 2";
                Address := Cust.Address;
                "Address 2" := Cust."Address 2";
                "Post Code" := Cust."Post Code";
                City := Cust.City;
                County := Cust.County;
                Contact := Cust.Contact;
                "Country/Region Code" := Cust."Country/Region Code";
                "Language Code" := Cust."Language Code";
                "Format Region" := Cust."Format Region";
                "Currency Code" := Cust."Currency Code";
                "Shortcut Dimension 1 Code" := Cust."Global Dimension 1 Code";
                "Shortcut Dimension 2 Code" := Cust."Global Dimension 2 Code";
                "VAT Registration No." := Cust."VAT Registration No.";
                Cust.TestField("Customer Posting Group");
                "Customer Posting Group" := Cust."Customer Posting Group";
                "Gen. Bus. Posting Group" := Cust."Gen. Bus. Posting Group";
                "VAT Bus. Posting Group" := Cust."VAT Bus. Posting Group";
                "Tax Area Code" := Cust."Tax Area Code";
                "Tax Liable" := Cust."Tax Liable";
                Validate("Fin. Charge Terms Code", Cust."Fin. Charge Terms Code");
                OnValidateCustomerNoOnAfterAssignCustomerValues(Rec, Cust);

                CreateDimFromDefaultDim();
            end;
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(4; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(5; Address; Text[100])
        {
            Caption = 'Address';
        }
        field(6; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(7; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code"
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePostCode(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(8; City; Text[30])
        {
            Caption = 'City';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code".City
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCity(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(9; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(10; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
        }
        field(11; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(12; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo("Currency Code") then
                    if Undo() then begin
                        "Currency Code" := xRec."Currency Code";
                        exit;
                    end;
                SetCompanyBankAccount();
            end;
        }
        field(13; Contact; Text[100])
        {
            Caption = 'Contact';
        }
        field(14; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
        }
        field(15; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(16; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(17; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            TableRelation = "Customer Posting Group";

            trigger OnValidate()
            begin
                CheckCustomerPostingGroupChange();
            end;
        }
        field(18; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            Editable = false;
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            begin
                if xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Gen. Bus. Posting Group") then
                        Validate("VAT Bus. Posting Group", GenBusPostingGrp."Def. VAT Bus. Posting Group");
            end;
        }
        field(19; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(20; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            begin
                GLSetup.Get();
                GLSetup.UpdateVATDate("Posting Date", Enum::"VAT Reporting Date"::"Posting Date", "VAT Reporting Date");
                Validate("VAT Reporting Date");
            end;
        }
        field(22; "Document Date"; Date)
        {
            Caption = 'Document Date';

            trigger OnValidate()
            begin
                GLSetup.Get();
                GLSetup.UpdateVATDate("Document Date", Enum::"VAT Reporting Date"::"Document Date", "VAT Reporting Date");
                Validate("VAT Reporting Date");

                if CurrFieldNo = FieldNo("Document Date") then
                    if Undo() then begin
                        "Document Date" := xRec."Document Date";
                        exit;
                    end;
                Validate("Fin. Charge Terms Code");
            end;
        }
        field(23; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(25; "Fin. Charge Terms Code"; Code[10])
        {
            Caption = 'Fin. Charge Terms Code';
            TableRelation = "Finance Charge Terms";

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo("Fin. Charge Terms Code") then
                    if Undo() then begin
                        "Fin. Charge Terms Code" := xRec."Fin. Charge Terms Code";
                        exit;
                    end;
                if "Fin. Charge Terms Code" <> '' then begin
                    FinChrgTerms.Get("Fin. Charge Terms Code");
                    OnValidateFinChrgTermsCodeOnAfterFinChrgTermsGet(Rec, FinChrgTerms);
                    "Post Interest" := FinChrgTerms."Post Interest";
                    "Post Additional Fee" := FinChrgTerms."Post Additional Fee";
                    if "Document Date" <> 0D then
                        "Due Date" := CalcDate(FinChrgTerms."Due Date Calculation", "Document Date");
                end;
            end;
        }
        field(26; "Post Interest"; Boolean)
        {
            Caption = 'Post Interest';
        }
        field(27; "Post Additional Fee"; Boolean)
        {
            Caption = 'Post Additional Fee';
        }
        field(29; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        field(30; Comment; Boolean)
        {
            CalcFormula = exist("Fin. Charge Comment Line" where(Type = const("Finance Charge Memo"),
                                                                  "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Finance Charge Memo Line"."Remaining Amount" where("Finance Charge Memo No." = field("No."),
                                                                                   "Detailed Interest Rates Entry" = const(false)));
            Caption = 'Remaining Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(32; "Interest Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Finance Charge Memo Line".Amount where("Finance Charge Memo No." = field("No."),
                                                                       Type = const("Customer Ledger Entry"),
                                                                       "Detailed Interest Rates Entry" = const(false)));
            Caption = 'Interest Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(33; "Additional Fee"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Finance Charge Memo Line".Amount where("Finance Charge Memo No." = field("No."),
                                                                       Type = const("G/L Account")));
            Caption = 'Additional Fee';
            Editable = false;
            FieldClass = FlowField;
        }
        field(34; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Finance Charge Memo Line"."VAT Amount" where("Finance Charge Memo No." = field("No."),
                                                                             "Detailed Interest Rates Entry" = const(false)));
            Caption = 'VAT Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(37; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(38; "Issuing No. Series"; Code[20])
        {
            Caption = 'Issuing No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            begin
                FinChrgMemoHeader := Rec;
                FinChrgMemoHeader.TestNoSeries();
                if NoSeries.LookupRelatedNoSeries(GetIssuingNoSeriesCode(), FinChrgMemoHeader."Issuing No. Series") then
                    FinChrgMemoHeader.Validate("Issuing No. Series");
                Rec := FinChrgMemoHeader;
            end;

            trigger OnValidate()
            begin
                if "Issuing No. Series" <> '' then begin
                    TestNoSeries();
                    NoSeries.TestAreRelated(GetIssuingNoSeriesCode(), "Issuing No. Series");
                end;
                TestField("Issuing No.", '');
            end;
        }
        field(39; "Issuing No."; Code[20])
        {
            Caption = 'Issuing No.';
        }
        field(41; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(42; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        field(43; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(44; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';
            Editable = false;

            trigger OnValidate()
            begin
                if "VAT Reporting Date" = 0D then
                    InitVATDate();
            end;
        }
        field(54; "Format Region"; Text[80])
        {
            Caption = 'Format Region';
            TableRelation = "Language Selection"."Language Tag";
        }
        field(163; "Company Bank Account Code"; Code[20])
        {
            Caption = 'Company Bank Account Code';
            TableRelation = "Bank Account" where("Currency Code" = field("Currency Code"));
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDocDim();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(9000; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Customer No.", "Currency Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Customer No.", Name, "Due Date")
        {
        }
    }

    trigger OnDelete()
    begin
        FinChrgMemoIssue.DeleteHeader(Rec, IssuedFinChrgMemoHdr);

        FinChrgMemoLine.SetRange("Finance Charge Memo No.", "No.");
        FinChrgMemoLine.DeleteAll();

        FinChrgMemoCommentLine.SetRange(Type, FinChrgMemoCommentLine.Type::"Finance Charge Memo");
        FinChrgMemoCommentLine.SetRange("No.", "No.");
        FinChrgMemoCommentLine.DeleteAll();

        if IssuedFinChrgMemoHdr."No." <> '' then
            PrintConfirmation();
    end;

    trigger OnInsert()
    var
        IsHandled: Boolean;
    begin
        SalesSetup.GetRecordOnce();
        if "No." = '' then begin
            TestNoSeries();
            "No. Series" := GetNoSeriesCode();
                if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                    "No. Series" := xRec."No. Series";
                "No." := NoSeries.GetNextNo("No. Series", "Posting Date");

        end;
        "Posting Description" := StrSubstNo(Text000, "No.");

        IsHandled := false;
        OnInsertOnBeforeInitNoSeries(Rec, xRec, IsHandled);
        if not IsHandled then
            if ("No. Series" <> '') and
               (SalesSetup."Fin. Chrg. Memo Nos." = GetIssuingNoSeriesCode())
            then
                "Issuing No. Series" := "No. Series"
            else
            if NoSeries.IsAutomatic(GetIssuingNoSeriesCode()) then
                "Issuing No. Series" := GetIssuingNoSeriesCode();

        if "Posting Date" = 0D then
            "Posting Date" := WorkDate();
        "Document Date" := WorkDate();
        "Due Date" := WorkDate();

        InitVATDate();

        if GetFilter("Customer No.") <> '' then
            if GetRangeMin("Customer No.") = GetRangeMax("Customer No.") then
                Validate("Customer No.", GetRangeMin("Customer No."));
    end;

    var
        Currency: Record Currency;
        SalesSetup: Record "Sales & Receivables Setup";
        CustPostingGr: Record "Customer Posting Group";
        FinChrgTerms: Record "Finance Charge Terms";
        CurrForFinChrgTerms: Record "Currency for Fin. Charge Terms";
        FinChrgText: Record "Finance Charge Text";
        FinChrgMemoHeader: Record "Finance Charge Memo Header";
        FinChrgMemoLine: Record "Finance Charge Memo Line";
        FinChrgMemoCommentLine: Record "Fin. Charge Comment Line";
        Cust: Record Customer;
        PostCode: Record "Post Code";
        IssuedFinChrgMemoHdr: Record "Issued Fin. Charge Memo Header";
        GenBusPostingGrp: Record "Gen. Business Posting Group";
        CurrExchRate: Record "Currency Exchange Rate";
        GLSetup: Record "General Ledger Setup";
        AutoFormat: Codeunit "Auto Format";
        NoSeries: Codeunit "No. Series";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        FinChrgMemoIssue: Codeunit "FinChrgMemo-Issue";
        DimMgt: Codeunit DimensionManagement;
        NextLineNo: Integer;
        LineSpacing: Integer;
        FinChrgMemoTotal: Decimal;
        OK: Boolean;
        SelectNoSeriesAllowed: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Finance Charge Memo %1';
        Text001: Label 'Do you want to print finance charge memo %1?';
#pragma warning restore AA0470
        Text002: Label 'This change will cause the existing lines to be deleted for this finance charge memo.\\';
        Text003: Label 'Do you want to continue?';
        Text004: Label 'There is not enough space to insert the text.';
        Text005: Label 'Deleting this document will cause a gap in the number series for finance charge memos.';
#pragma warning disable AA0470
        Text006: Label 'An empty finance charge memo %1 will be created to fill this gap in the number series.\\';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure AssistEdit(OldFinChrgMemoHeader: Record "Finance Charge Memo Header"): Boolean
    begin
        FinChrgMemoHeader := Rec;
        FinChrgMemoHeader.TestNoSeries();
        if NoSeries.LookupRelatedNoSeries(SalesSetup."Fin. Chrg. Memo Nos.", OldFinChrgMemoHeader."No. Series", FinChrgMemoHeader."No. Series") then begin
            FinChrgMemoHeader."No." := NoSeries.GetNextNo(FinChrgMemoHeader."No. Series");
            Rec := FinChrgMemoHeader;
            exit(true);
        end;
    end;

    procedure TestNoSeries()
    var
        IsHandled: Boolean;
    begin
        SalesSetup.GetRecordOnce();
        IsHandled := false;
        OnBeforeTestNoSeries(Rec, IsHandled);
        if not IsHandled then begin
            SalesSetup.TestField("Fin. Chrg. Memo Nos.");
            SalesSetup.TestField("Issued Fin. Chrg. M. Nos.");
        end;

        OnAfterTestNoSeries(Rec);
    end;

    procedure GetNoSeriesCode() NoSeriesCode: Code[20]
    var
        IsHandled: Boolean;
    begin
        SalesSetup.GetRecordOnce();
        IsHandled := false;
        OnBeforeGetNoSeriesCode(Rec, SalesSetup, NoSeriesCode, IsHandled);
        if IsHandled then
            exit(NoSeriesCode);

        NoSeriesCode := SalesSetup."Fin. Chrg. Memo Nos.";

        OnAfterGetNoSeriesCode(Rec, SalesSetup, NoSeriesCode);
        if not SelectNoSeriesAllowed then
            exit(NoSeriesCode);

        if NoSeries.IsAutomatic(NoSeriesCode) then
            exit(NoSeriesCode);

        if NoSeries.HasRelatedSeries(NoSeriesCode) then
            if NoSeries.LookupRelatedNoSeries(NoSeriesCode, "No. Series") then
                exit("No. Series");

        exit(NoSeriesCode);
    end;

    local procedure InitVATDate()
    begin
        "VAT Reporting Date" := GLSetup.GetVATDate("Posting Date", "Document Date");
    end;

    local procedure GetIssuingNoSeriesCode() IssuingNos: Code[20]
    var
        IsHandled: Boolean;
    begin
        SalesSetup.GetRecordOnce();
        IsHandled := false;
        OnBeforeGetIssuingNoSeriesCode(Rec, SalesSetup, IssuingNos, IsHandled);
        if IsHandled then
            exit;

        IssuingNos := SalesSetup."Issued Fin. Chrg. M. Nos.";

        OnAfterGetIssuingNoSeriesCode(Rec, IssuingNos);
    end;

    local procedure SetCompanyBankAccount()
    var
        BankAccount: Record "Bank Account";
    begin
        Validate("Company Bank Account Code", BankAccount.GetDefaultBankAccountNoForCurrency("Currency Code"));
        OnAfterSetCompanyBankAccount(Rec, xRec);
    end;

    local procedure CheckCustomerPostingGroupChange()
    var
        Customer: Record Customer;
        PostingGroupChangeInterface: Interface "Posting Group Change Method";
        IsHandled: Boolean;
    begin
        OnBeforeCheckCustomerPostingGroupChange(Rec, xRec, IsHandled);
        if IsHandled then
            exit;
        if ("Customer Posting Group" <> xRec."Customer Posting Group") and (xRec."Customer Posting Group" <> '') then begin
            TestField("Customer No.");
            Customer.Get("Customer No.");
            SalesSetup.GetRecordOnce();
            if SalesSetup."Allow Multiple Posting Groups" then begin
                Customer.TestField("Allow Multiple Posting Groups");
                PostingGroupChangeInterface := SalesSetup."Check Multiple Posting Groups";
                PostingGroupChangeInterface.ChangePostingGroup("Customer Posting Group", xRec."Customer Posting Group", Rec);
            end;
        end;
    end;

    local procedure Undo(): Boolean
    begin
        FinChrgMemoLine.SetRange("Finance Charge Memo No.", "No.");
        if FinChrgMemoLine.Find('-') then begin
            Commit();
            if not
               Confirm(
                 Text002 +
                 Text003,
                 false)
            then
                exit(true);
            FinChrgMemoLine.DeleteAll();
            Modify();
        end;
    end;

    procedure InsertLines()
    var
        TranslationHelper: Codeunit "Translation Helper";
    begin
        TestField("Fin. Charge Terms Code");
        FinChrgTerms.Get("Fin. Charge Terms Code");
        OnInsertLinesOnAfterFinChrgTermsGet(Rec, FinChrgTerms);
        FinChrgMemoLine.Reset();
        FinChrgMemoLine.SetRange("Finance Charge Memo No.", "No.");
        FinChrgMemoLine."Finance Charge Memo No." := "No.";
        if FinChrgMemoLine.Find('+') then
            NextLineNo := FinChrgMemoLine."Line No."
        else
            NextLineNo := 0;
        if (FinChrgMemoLine.Type <> FinChrgMemoLine.Type::" ") or
           (FinChrgMemoLine.Description <> '')
        then begin
            LineSpacing := 10000;
            InsertBlankLine(FinChrgMemoLine."Line Type"::"Finance Charge Memo Line");
        end;
        if FinChrgTerms."Additional Fee (LCY)" <> 0 then begin
            NextLineNo := NextLineNo + 10000;
            FinChrgMemoLine.Init();
            FinChrgMemoLine."Line No." := NextLineNo;
            FinChrgMemoLine.Type := FinChrgMemoLine.Type::"G/L Account";
            TestField("Customer Posting Group");
            CustPostingGr.Get("Customer Posting Group");
            FinChrgMemoLine.Validate("No.", CustPostingGr.GetAdditionalFeeAccount());
            FinChrgMemoLine.Description :=
              CopyStr(
                TranslationHelper.GetTranslatedFieldCaption(
                  "Language Code", DATABASE::"Currency for Fin. Charge Terms",
                  CurrForFinChrgTerms.FieldNo("Additional Fee")), 1, 100);
            if "Currency Code" = '' then
                FinChrgMemoLine.Validate(Amount, FinChrgTerms."Additional Fee (LCY)")
            else begin
                if not CurrForFinChrgTerms.Get("Fin. Charge Terms Code", "Currency Code") then
                    CurrForFinChrgTerms."Additional Fee" :=
                      CurrExchRate.ExchangeAmtLCYToFCY(
                        "Posting Date", "Currency Code",
                        FinChrgTerms."Additional Fee (LCY)", CurrExchRate.ExchangeRate(
                          "Posting Date", "Currency Code"));
                FinChrgMemoLine.Validate(Amount, CurrForFinChrgTerms."Additional Fee");
            end;
            OnBeforeInsertFinChrgMemoLine(FinChrgMemoLine);
            FinChrgMemoLine.Insert();
            if TransferExtendedText.FinChrgMemoCheckIfAnyExtText(FinChrgMemoLine, false) then
                TransferExtendedText.InsertFinChrgMemoExtText(FinChrgMemoLine);
        end;
        FinChrgMemoLine."Line No." := FinChrgMemoLine."Line No." + 10000;
        FinanceChargeRounding(Rec);
        InsertBeginTexts(Rec);
        InsertEndTexts(Rec);
        Modify();
    end;

    procedure UpdateLines(FinChrgMemoHeader2: Record "Finance Charge Memo Header")
    begin
        FinChrgMemoLine.Reset();
        FinChrgMemoLine.SetRange("Finance Charge Memo No.", FinChrgMemoHeader2."No.");
        OK := FinChrgMemoLine.Find('-');
        while OK do begin
            OK :=
              (FinChrgMemoLine.Type = FinChrgMemoLine.Type::" ") and
              (FinChrgMemoLine."Attached to Line No." = 0);
            if OK then begin
                FinChrgMemoLine.Delete(true);
                OK := FinChrgMemoLine.Next() <> 0;
            end;
        end;
        OK := FinChrgMemoLine.Find('+');
        while OK do begin
            OK :=
              (FinChrgMemoLine.Type = FinChrgMemoLine.Type::" ") and
              (FinChrgMemoLine."Attached to Line No." = 0);
            if OK then begin
                FinChrgMemoLine.Delete(true);
                OK := FinChrgMemoLine.Next(-1) <> 0;
            end;
        end;
        FinChrgMemoLine.SetRange("Line Type", FinChrgMemoLine."Line Type"::Rounding);
        if FinChrgMemoLine.FindFirst() then
            FinChrgMemoLine.Delete(true);

        FinChrgMemoLine.SetRange("Line Type");
        FinChrgMemoLine.FindLast();
        FinChrgMemoLine."Line No." := FinChrgMemoLine."Line No." + 10000;
        FinanceChargeRounding(FinChrgMemoHeader2);

        InsertBeginTexts(FinChrgMemoHeader2);
        InsertEndTexts(FinChrgMemoHeader2);
    end;

    local procedure InsertBeginTexts(FinChrgMemoHeader2: Record "Finance Charge Memo Header")
    begin
        FinChrgText.Reset();
        FinChrgText.SetRange("Fin. Charge Terms Code", FinChrgMemoHeader2."Fin. Charge Terms Code");
        FinChrgText.SetRange(Position, FinChrgText.Position::Beginning);

        FinChrgMemoLine.Reset();
        FinChrgMemoLine.SetRange("Finance Charge Memo No.", FinChrgMemoHeader2."No.");
        FinChrgMemoLine."Finance Charge Memo No." := FinChrgMemoHeader2."No.";
        if FinChrgMemoLine.Find('-') then begin
            LineSpacing := FinChrgMemoLine."Line No." div (FinChrgText.Count + 2);
            if LineSpacing = 0 then
                Error(Text004);
        end else
            LineSpacing := 10000;
        NextLineNo := 0;
        InsertTextLines(FinChrgMemoHeader2);
    end;

    local procedure InsertEndTexts(FinChrgMemoHeader2: Record "Finance Charge Memo Header")
    begin
        FinChrgText.Reset();
        FinChrgText.SetRange("Fin. Charge Terms Code", FinChrgMemoHeader2."Fin. Charge Terms Code");
        FinChrgText.SetRange(Position, FinChrgText.Position::Ending);

        FinChrgMemoLine.Reset();
        FinChrgMemoLine.SetRange("Finance Charge Memo No.", FinChrgMemoHeader2."No.");
        FinChrgMemoLine."Finance Charge Memo No." := FinChrgMemoHeader2."No.";
        if FinChrgMemoLine.Find('+') then
            NextLineNo := FinChrgMemoLine."Line No."
        else begin
            FinChrgMemoLine.SetFilter("Line Type", '%1|%2',
              FinChrgMemoLine."Line Type"::"Finance Charge Memo Line",
              FinChrgMemoLine."Line Type"::Rounding);
            if FinChrgMemoLine.Find('+') then
                NextLineNo := FinChrgMemoLine."Line No."
            else
                NextLineNo := 0;
        end;
        FinChrgMemoLine.SetRange("Line Type");
        LineSpacing := 10000;
        InsertTextLines(FinChrgMemoHeader2);
    end;

    local procedure InsertTextLines(FinChrgMemoHeader2: Record "Finance Charge Memo Header")
    var
        AutoFormatType: Enum "Auto Format";
    begin
        if FinChrgText.Find('-') then begin
            if FinChrgText.Position = FinChrgText.Position::Ending then
                InsertBlankLine(FinChrgMemoLine."Line Type"::"Ending Text");
            if not FinChrgTerms.Get(FinChrgMemoHeader2."Fin. Charge Terms Code") then
                FinChrgTerms.Init();

            OnInsertTextLinesOnAfterFinChrgTermsGetOrInit(FinChrgMemoHeader2, FinChrgTerms);

            FinChrgMemoHeader2.CalcFields(
              "Remaining Amount", "Interest Amount", "Additional Fee", "VAT Amount");
            FinChrgMemoTotal :=
              FinChrgMemoHeader2."Remaining Amount" + FinChrgMemoHeader2."Interest Amount" +
              FinChrgMemoHeader2."Additional Fee" + FinChrgMemoHeader2."VAT Amount";

            repeat
                NextLineNo := NextLineNo + LineSpacing;
                FinChrgMemoLine.Init();
                FinChrgMemoLine."Line No." := NextLineNo;
                FinChrgMemoLine.Description :=
                  CopyStr(
                    StrSubstNo(
                      FinChrgText.Text,
                      FinChrgMemoHeader2."Document Date",
                      FinChrgMemoHeader2."Due Date",
                      FinChrgTerms."Interest Rate",
                      FinChrgMemoHeader2."Remaining Amount",
                      FinChrgMemoHeader2."Interest Amount",
                      FinChrgMemoHeader2."Additional Fee",
                      Format(FinChrgMemoTotal, 0, AutoFormat.ResolveAutoFormat(AutoFormatType::AmountFormat, FinChrgMemoHeader."Currency Code")),
                      FinChrgMemoHeader2."Currency Code",
                      FinChrgMemoHeader2."Posting Date"),
                    1, MaxStrLen(FinChrgMemoLine.Description));
                if FinChrgText.Position = FinChrgText.Position::Beginning then
                    FinChrgMemoLine."Line Type" := FinChrgMemoLine."Line Type"::"Beginning Text"
                else
                    FinChrgMemoLine."Line Type" := FinChrgMemoLine."Line Type"::"Ending Text";
                FinChrgMemoLine.Insert();
            until FinChrgText.Next() = 0;
            if FinChrgText.Position = FinChrgText.Position::Beginning then
                InsertBlankLine(FinChrgMemoLine."Line Type"::"Beginning Text");
        end;
    end;

    local procedure InsertBlankLine(LineType: Integer)
    begin
        NextLineNo := NextLineNo + LineSpacing;
        FinChrgMemoLine.Init();
        FinChrgMemoLine."Line No." := NextLineNo;
        FinChrgMemoLine."Line Type" := LineType;
        FinChrgMemoLine.Insert();
    end;

    procedure PrintRecords()
    var
        FinChrgMemoHeader: Record "Finance Charge Memo Header";
        ReportSelection: Record "Report Selections";
    begin
        FinChrgMemoHeader.Copy(Rec);
        ReportSelection.PrintForCust(ReportSelection.Usage::"F.C.Test", FinChrgMemoHeader, FinChrgMemoHeader.FieldNo("Customer No."));
    end;

    local procedure PrintConfirmation()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintConfirmation(Rec, IssuedFinChrgMemoHdr, IsHandled);
        if IsHandled then
            exit;

        Commit();
        if ConfirmManagement.GetResponse(
                StrSubstNo(Text001, IssuedFinChrgMemoHdr."No."), true)
        then begin
            IssuedFinChrgMemoHdr.SetRecFilter();
            IssuedFinChrgMemoHdr.PrintRecords(true, false, false)
        end;
    end;

    procedure ConfirmDeletion(): Boolean
    begin
        FinChrgMemoIssue.TestDeleteHeader(Rec, IssuedFinChrgMemoHdr);
        if IssuedFinChrgMemoHdr."No." <> '' then
            if not Confirm(
                 Text005 +
                 Text006 +
                 Text003, true,
                 IssuedFinChrgMemoHdr."No.")
            then
                exit;
        exit(true);
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
        IsHandled: Boolean;
    begin
        SourceCodeSetup.Get();

        IsHandled := false;
        OnBeforeCreateDim(Rec, CurrFieldNo, DefaultDimSource, IsHandled);
        if IsHandled then
            exit;

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, SourceCodeSetup."Finance Charge Memo",
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterCreateDimProcedure(Rec, CurrFieldNo, DefaultDimSource);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure GetInvoiceRoundingAmount(): Decimal
    var
        TotalAmountInclVAT: Decimal;
    begin
        GetCurrency(Rec);
        if Currency."Invoice Rounding Precision" = 0 then
            exit(0);

        CalcFields(
            "Interest Amount", "Additional Fee", "VAT Amount");
        TotalAmountInclVAT :=
            "Interest Amount" + "Additional Fee" + "VAT Amount";

        exit(
            -Round(
                TotalAmountInclVAT -
                Round(
                    TotalAmountInclVAT,
                    Currency."Invoice Rounding Precision",
                    Currency.InvoiceRoundingDirection()),
              Currency."Amount Rounding Precision"));
    end;

    local procedure FinanceChargeRounding(FinanceChargeHeader: Record "Finance Charge Memo Header")
    var
        FinanceChargeRoundingAmount: Decimal;
    begin
        FinanceChargeRoundingAmount := FinanceChargeHeader.GetInvoiceRoundingAmount();

        if FinanceChargeRoundingAmount <> 0 then begin
            CustPostingGr.Get(FinanceChargeHeader."Customer Posting Group");
            FinChrgMemoLine.Init();
            FinChrgMemoLine.Validate(Type, FinChrgMemoLine.Type::"G/L Account");
            FinChrgMemoLine."System-Created Entry" := true;
            FinChrgMemoLine.Validate("No.", CustPostingGr.GetInvRoundingAccount());
            FinChrgMemoLine.Validate(
              Amount,
              Round(
                FinanceChargeRoundingAmount / (1 + (FinChrgMemoLine."VAT %" / 100)),
                Currency."Amount Rounding Precision"));
            FinChrgMemoLine."VAT Amount" := FinanceChargeRoundingAmount - FinChrgMemoLine.Amount;
            FinChrgMemoLine."Line Type" := FinChrgMemoLine."Line Type"::Rounding;
            OnFinanceChargeRoundingOnBeforeInsertFinanceMemoHeader(FinanceChargeHeader, FinChrgMemoLine);
            FinChrgMemoLine.Insert();
        end;
    end;

    local procedure GetCurrency(FinanceChargeHeader: Record "Finance Charge Memo Header")
    begin
        if FinanceChargeHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else begin
            Currency.Get(FinanceChargeHeader."Currency Code");
            Currency.TestField("Amount Rounding Precision");
        end;
    end;

    procedure UpdateFinanceChargeRounding(FinanceChargeHeader: Record "Finance Charge Memo Header")
    var
        OldLineNo: Integer;
    begin
        FinChrgMemoLine.Reset();
        FinChrgMemoLine.SetRange("Finance Charge Memo No.", FinanceChargeHeader."No.");
        FinChrgMemoLine.SetRange("Line Type", FinChrgMemoLine."Line Type"::Rounding);
        if FinChrgMemoLine.FindFirst() then
            FinChrgMemoLine.Delete(true);

        FinChrgMemoLine.SetRange("Line Type");
        FinChrgMemoLine.SetFilter(Type, '<>%1', FinChrgMemoLine.Type::" ");
        if FinChrgMemoLine.FindLast() then begin
            OldLineNo := FinChrgMemoLine."Line No.";
            FinChrgMemoLine.SetRange(Type);
            if FinChrgMemoLine.Next() <> 0 then
                FinChrgMemoLine."Line No." := OldLineNo + ((FinChrgMemoLine."Line No." - OldLineNo) / 2)
            else
                FinChrgMemoLine."Line No." := FinChrgMemoLine."Line No." + 10000;
        end else
            FinChrgMemoLine."Line No." := 10000;

        FinanceChargeRounding(FinanceChargeHeader);
        OnAfterFinanceChargeRounding(FinanceChargeHeader);
    end;

    procedure SetAllowSelectNoSeries()
    begin
        SelectNoSeriesAllowed := true;
    end;

    procedure ShowDocDim()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterShowDocDim(Rec);
    end;

    local procedure GetFilterCustNo(): Code[20]
    begin
        if GetFilter("Customer No.") <> '' then
            if GetRangeMin("Customer No.") = GetRangeMax("Customer No.") then
                exit(GetRangeMax("Customer No."));
    end;

    procedure SetCustomerFromFilter()
    begin
        if GetFilterCustNo() <> '' then
            Validate("Customer No.", GetFilterCustNo());
    end;

    procedure CreateDimFromDefaultDim()
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::Customer, Rec."Customer No.");

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimProcedure(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; CurrFieldNo: Integer; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetNoSeriesCode(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; SalesSetup: Record "Sales & Receivables Setup"; var NoSeriesCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetIssuingNoSeriesCode(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var IssuingNos: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDocDim(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestNoSeries(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCompanyBankAccount(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; xFinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var xFinanceChargeMemoHeader: Record "Finance Charge Memo Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNoSeriesCode(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; SalesSetup: Record "Sales & Receivables Setup"; var NoSeriesCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetIssuingNoSeriesCode(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; SalesSetup: Record "Sales & Receivables Setup"; var IssuingNos: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertFinChrgMemoLine(var FinChrgMemoLine: Record "Finance Charge Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCustomerNo(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoSeries(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var xFinanceChargeMemoHeader: Record "Finance Charge Memo Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinanceChargeRounding(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCustomerNoOnAfterAssignCustomerValues(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; Customer: Record "Customer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCity(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostCode(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintConfirmation(var FinChargeMemoHeader: Record "Finance Charge Memo Header"; var IssuedFinChrgMemoHdr: Record "Issued Fin. Charge Memo Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCustomerPostingGroupChange(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var xFinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; CallingFieldNo: Integer; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinanceChargeRoundingOnBeforeInsertFinanceMemoHeader(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var FinanceChargeMemoLine: Record "Finance Charge Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTextLinesOnAfterFinChrgTermsGetOrInit(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var FinanceChargeTerms: Record "Finance Charge Terms")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateFinChrgTermsCodeOnAfterFinChrgTermsGet(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var FinanceChargeTerms: Record "Finance Charge Terms")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertLinesOnAfterFinChrgTermsGet(var FinChargeMemoHeader: Record "Finance Charge Memo Header"; var FinChrgTerms: Record "Finance Charge Terms")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInsertOnBeforeInitNoSeries(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var xFinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var IsHandled: Boolean)
    begin
    end;
}
