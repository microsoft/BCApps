// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Contact;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Setup;
using System.Globalization;
using System.IO;
using System.Security.User;
using System.Text;

/// <summary>
/// Stores the header information for a reminder document including customer, posting, and reminder level details.
/// </summary>
table 295 "Reminder Header"
{
    Caption = 'Reminder Header';
    DataCaptionFields = "No.", Name;
    DrillDownPageID = "Reminder List";
    LookupPageID = "Reminder List";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the unique identifier for the reminder document.
        /// </summary>
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    NoSeries.TestManual(GetNoSeriesCode());
                    "No. Series" := '';
                end;
                "Posting Description" := StrSubstNo(ReminderNoLbl, "No.");
            end;
        }
        /// <summary>
        /// Specifies the customer to whom this reminder will be sent.
        /// </summary>
        field(2; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            ToolTip = 'Specifies the number of the customer you want to post a reminder for.';
            TableRelation = Customer;

            trigger OnValidate()
            var
                Cont: Record Contact;
            begin
                if CurrFieldNo = FieldNo("Customer No.") then
                    if Undo() then begin
                        "Customer No." := xRec."Customer No.";
                        CreateDimFromDefaultDim();
                        exit;
                    end;
                if "Customer No." = '' then begin
                    CreateDimFromDefaultDim();
                    exit;
                end;
                Cust.Get("Customer No.");
                if Cust."Privacy Blocked" then
                    Cust.CustPrivacyBlockedErrorMessage(Cust, false);
                CheckCustomerBlockedAll(Cust);

                if Cont.Get(Cust."Primary Contact No.") then
                    Cont.CheckIfPrivacyBlockedGeneric();

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
                Validate("Currency Code", Cust."Currency Code");
                "Shortcut Dimension 1 Code" := Cust."Global Dimension 1 Code";
                "Shortcut Dimension 2 Code" := Cust."Global Dimension 2 Code";
                "VAT Registration No." := Cust."VAT Registration No.";
                Cust.TestField("Customer Posting Group");
                "Customer Posting Group" := Cust."Customer Posting Group";
                "Gen. Bus. Posting Group" := Cust."Gen. Bus. Posting Group";
                "VAT Bus. Posting Group" := Cust."VAT Bus. Posting Group";
                "Tax Area Code" := Cust."Tax Area Code";
                "Tax Liable" := Cust."Tax Liable";
                "Reminder Terms Code" := Cust."Reminder Terms Code";
                "Fin. Charge Terms Code" := Cust."Fin. Charge Terms Code";
                OnValidateCustomerNoOnAfterAssignCustomerValues(Rec, Cust);
                Validate("Reminder Terms Code");

                CreateDimFromDefaultDim();
            end;
        }
        /// <summary>
        /// Specifies the name of the customer receiving the reminder.
        /// </summary>
        field(3; Name; Text[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the customer the reminder is for.';
        }
        /// <summary>
        /// Specifies additional name information for the customer.
        /// </summary>
        field(4; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        /// <summary>
        /// Specifies the street address of the customer.
        /// </summary>
        field(5; Address; Text[100])
        {
            Caption = 'Address';
            ToolTip = 'Specifies the address of the customer the reminder is for.';
        }
        /// <summary>
        /// Specifies additional address information for the customer.
        /// </summary>
        field(6; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
            ToolTip = 'Specifies additional address information.';
        }
        /// <summary>
        /// Specifies the postal code of the customer's address.
        /// </summary>
        field(7; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            ToolTip = 'Specifies the postal code.';
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
        /// <summary>
        /// Specifies the city of the customer's address.
        /// </summary>
        field(8; City; Text[30])
        {
            Caption = 'City';
            ToolTip = 'Specifies the city name of the customer the reminder is for.';
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
        /// <summary>
        /// Specifies the county or state of the customer's address.
        /// </summary>
        field(9; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        /// <summary>
        /// Specifies the country or region code of the customer's address.
        /// </summary>
        field(10; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
        }
        /// <summary>
        /// Specifies the language code used for translating reminder texts.
        /// </summary>
        field(11; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        /// <summary>
        /// Specifies the currency in which amounts on the reminder are calculated and displayed.
        /// </summary>
        field(12; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency code of the reminder.';
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
        /// <summary>
        /// Specifies the name of the contact person at the customer.
        /// </summary>
        field(13; Contact; Text[100])
        {
            Caption = 'Contact';
            ToolTip = 'Specifies the name of the person you regularly contact when you communicate with the customer the reminder is for.';
        }
        /// <summary>
        /// Specifies the customer's reference number or code for this document.
        /// </summary>
        field(14; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
            ToolTip = 'Specifies the customer''s reference. The content will be printed on the related document.';
        }
        /// <summary>
        /// Specifies the first shortcut dimension code used for analysis and reporting.
        /// </summary>
        field(15; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        /// <summary>
        /// Specifies the second shortcut dimension code used for analysis and reporting.
        /// </summary>
        field(16; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        /// <summary>
        /// Specifies the customer posting group that determines G/L accounts for posting.
        /// </summary>
        field(17; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            Editable = false;
            TableRelation = "Customer Posting Group";
        }
        /// <summary>
        /// Specifies the general business posting group for VAT and cost allocation.
        /// </summary>
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
        /// <summary>
        /// Specifies the customer's VAT registration number for tax reporting.
        /// </summary>
        field(19; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        /// <summary>
        /// Specifies the reason code that explains the purpose of the reminder entry.
        /// </summary>
        field(20; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        /// <summary>
        /// Specifies the date when the reminder will be posted to the general ledger.
        /// </summary>
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the date when the reminder should be issued.';

            trigger OnValidate()
            begin
                GLSetup.Get();
                GLSetup.UpdateVATDate("Posting Date", Enum::"VAT Reporting Date"::"Posting Date", "VAT Reporting Date");
                Validate("VAT Reporting Date");
            end;
        }
        /// <summary>
        /// Specifies the date when the reminder document was created.
        /// </summary>
        field(22; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ToolTip = 'Specifies the date when the related document was created.';

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
                Validate("Reminder Level");
            end;
        }
        /// <summary>
        /// Specifies the date by which the customer must pay the outstanding amount.
        /// </summary>
        field(23; "Due Date"; Date)
        {
            Caption = 'Due Date';
            ToolTip = 'Specifies when payment of the amount on the reminder is due.';
        }
        /// <summary>
        /// Specifies the reminder terms code that controls fees, interest, and escalation levels.
        /// </summary>
        field(24; "Reminder Terms Code"; Code[10])
        {
            Caption = 'Reminder Terms Code';
            ToolTip = 'Specifies how reminders about late payments are handled for this customer.';
            TableRelation = "Reminder Terms";

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo("Reminder Terms Code") then
                    if Undo() then begin
                        "Reminder Terms Code" := xRec."Reminder Terms Code";
                        exit;
                    end;
                if "Reminder Terms Code" <> '' then begin
                    ReminderTerms.Get("Reminder Terms Code");
                    "Post Interest" := ReminderTerms."Post Interest";
                    "Post Additional Fee" := ReminderTerms."Post Additional Fee";
                    "Post Add. Fee per Line" := ReminderTerms."Post Add. Fee per Line";
                    Validate("Reminder Level");
                    Validate("Post Interest");
                end;
            end;
        }
        /// <summary>
        /// Specifies the finance charge terms used for calculating interest on overdue amounts.
        /// </summary>
        field(25; "Fin. Charge Terms Code"; Code[10])
        {
            Caption = 'Fin. Charge Terms Code';
            ToolTip = 'Specifies the code for the involved finance charges in case of late payment.';
            TableRelation = "Finance Charge Terms";

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo("Fin. Charge Terms Code") then
                    if Undo() then begin
                        "Fin. Charge Terms Code" := xRec."Fin. Charge Terms Code";
                        exit;
                    end;
            end;
        }
        /// <summary>
        /// Indicates whether interest charges will be posted when the reminder is issued.
        /// </summary>
        field(26; "Post Interest"; Boolean)
        {
            Caption = 'Post Interest';
        }
        /// <summary>
        /// Indicates whether additional fees will be posted when the reminder is issued.
        /// </summary>
        field(27; "Post Additional Fee"; Boolean)
        {
            Caption = 'Post Additional Fee';
        }
        /// <summary>
        /// Specifies the escalation level of this reminder based on the number of overdue notices sent.
        /// </summary>
        field(28; "Reminder Level"; Integer)
        {
            Caption = 'Reminder Level';
            ToolTip = 'Specifies the reminder''s level.';
            TableRelation = "Reminder Level"."No." where("Reminder Terms Code" = field("Reminder Terms Code"));

            trigger OnValidate()
            begin
                if ("Reminder Level" <> 0) and ("Reminder Terms Code" <> '') then begin
                    ReminderTerms.Get("Reminder Terms Code");
                    ReminderLevel.SetRange("Reminder Terms Code", "Reminder Terms Code");
                    ReminderLevel.SetRange("No.", 1, "Reminder Level");
                    if ReminderLevel.FindLast() and ("Document Date" <> 0D) then
                        "Due Date" := CalcDate(ReminderLevel."Due Date Calculation", "Document Date");

                    OnAfterValidateReminderLevel(Rec, ReminderLevel);
                end;
            end;
        }
        /// <summary>
        /// Specifies a description that will appear on ledger entries when the reminder is posted.
        /// </summary>
        field(29; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        /// <summary>
        /// Indicates whether comments are attached to this reminder document.
        /// </summary>
        field(30; Comment; Boolean)
        {
            CalcFormula = exist("Reminder Comment Line" where(Type = const(Reminder),
                                                               "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Contains the total remaining amount that the customer owes on the entries included in this reminder.
        /// </summary>
        field(31; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Reminder Line"."Remaining Amount" where("Reminder No." = field("No."),
                                                                        "Line Type" = const("Reminder Line"),
                                                                        "Detailed Interest Rates Entry" = const(false)));
            Caption = 'Remaining Amount';
            ToolTip = 'Specifies the total of the remaining amounts on the reminder lines.';
            DecimalPlaces = 2 : 2;
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Contains the total calculated interest amount on overdue entries in this reminder.
        /// </summary>
        field(32; "Interest Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Reminder Line".Amount where("Reminder No." = field("No."),
                                                            Type = const("Customer Ledger Entry"),
                                                            "Detailed Interest Rates Entry" = const(false),
                                                            "Line Type" = filter(<> "Not Due")));
            Caption = 'Interest Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Contains the total additional fee amount charged on this reminder.
        /// </summary>
        field(33; "Additional Fee"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Reminder Line".Amount where("Reminder No." = field("No."),
                                                            Type = const("G/L Account"),
                                                            "Line Type" = filter(<> "Not Due")));
            Caption = 'Additional Fee';
            ToolTip = 'Specifies the total of the additional fee amounts on the reminder lines.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Contains the total VAT amount calculated on fees and interest for this reminder.
        /// </summary>
        field(34; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Reminder Line"."VAT Amount" where("Reminder No." = field("No."),
                                                                  "Detailed Interest Rates Entry" = const(false),
                                                                  "Line Type" = filter(<> "Not Due")));
            Caption = 'VAT Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Specifies the number series used to assign document numbers to reminders.
        /// </summary>
        field(37; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Specifies the number series used to assign document numbers when reminders are issued.
        /// </summary>
        field(38; "Issuing No. Series"; Code[20])
        {
            Caption = 'Issuing No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            begin
                ReminderHeader := Rec;
                ReminderHeader.TestNoSeries();
                if NoSeries.LookupRelatedNoSeries(GetIssuingNoSeriesCode(), ReminderHeader."Issuing No. Series") then
                    ReminderHeader.Validate("Issuing No. Series");
                Rec := ReminderHeader;
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
        /// <summary>
        /// Specifies the document number that will be assigned when this reminder is issued.
        /// </summary>
        field(39; "Issuing No."; Code[20])
        {
            Caption = 'Issuing No.';
        }
        /// <summary>
        /// Specifies the tax area code for sales tax calculation in North America.
        /// </summary>
        field(41; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        /// <summary>
        /// Indicates whether the customer is liable for sales tax.
        /// </summary>
        field(42; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        /// <summary>
        /// Specifies the VAT business posting group for determining VAT rates and accounts.
        /// </summary>
        field(43; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>
        /// Indicates whether the reminder level from the header should apply to all lines.
        /// </summary>
        field(44; "Use Header Level"; Boolean)
        {
            Caption = 'Use Header Level';
            ToolTip = 'Specifies that the condition of the level for the Reminder Level field is applied to all suggested reminder lines.';
        }
        /// <summary>
        /// Contains the total line fee amount charged per document on this reminder.
        /// </summary>
        field(45; "Add. Fee per Line"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = Rec."Currency Code";
            CalcFormula = sum("Reminder Line".Amount where("Reminder No." = field("No."),
                                                            Type = const("Line Fee"),
                                                            "Line Type" = filter(<> "Not Due")));
            Caption = 'Add. Fee per Line';
            ToolTip = 'Specifies that the fee is distributed on individual reminder lines.';
            FieldClass = FlowField;
        }
        /// <summary>
        /// Indicates whether line fees will be posted when the reminder is issued.
        /// </summary>
        field(46; "Post Add. Fee per Line"; Boolean)
        {
            Caption = 'Post Add. Fee per Line';
        }
        /// <summary>
        /// Specifies the date used for VAT reporting purposes.
        /// </summary>
        field(47; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';
            ToolTip = 'Specifies the date used to include entries on VAT reports in a VAT period. This is either the date that the document was created or posted, depending on your setting on the General Ledger Setup page.';
            Editable = false;

            trigger OnValidate()
            begin
                if "VAT Reporting Date" = 0D then
                    InitVATDate();
            end;
        }
        /// <summary>
        /// Specifies the regional format for dates, numbers, and currency display.
        /// </summary>
        field(54; "Format Region"; Text[80])
        {
            Caption = 'Format Region';
            TableRelation = "Language Selection"."Language Tag";
        }
        /// <summary>
        /// Contains the email body text content for reminder communications.
        /// </summary>
        field(55; "Email Text"; Blob)
        {
            Caption = 'Email Text';
        }
        /// <summary>
        /// Specifies the company bank account for receiving payments referenced on this reminder.
        /// </summary>
        field(163; "Company Bank Account Code"; Code[20])
        {
            Caption = 'Company Bank Account Code';
            ToolTip = 'Specifies the bank account to use for bank information when the document is printed.';
            TableRelation = "Bank Account" where("Currency Code" = field("Currency Code"));
        }
        /// <summary>
        /// Specifies the combination of dimension values applied to this reminder for analysis.
        /// </summary>
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
        /// <summary>
        /// Specifies the reminder automation group code used to create this reminder automatically.
        /// </summary>
        field(500; "Reminder Automation Code"; Code[50])
        {
            DataClassification = CustomerContent;
            TableRelation = "Reminder Action Group"."Code";
        }
        /// <summary>
        /// Specifies the user who is assigned responsibility for this reminder.
        /// </summary>
        field(9000; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            ToolTip = 'Specifies the ID of the user who is responsible for the document.';
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
        ReminderIssue.DeleteHeader(Rec, IssuedReminderHeader);

        ReminderLine.SetRange("Reminder No.", "No.");
        ReminderLine.DeleteAll();

        ReminderCommentLine.SetRange(Type, ReminderCommentLine.Type::Reminder);
        ReminderCommentLine.SetRange("No.", "No.");
        ReminderCommentLine.DeleteAll();

        PrintIssuedReminders();
    end;

    trigger OnInsert()
    var
        IsHandled: Boolean;
    begin
        SalesSetup.Get();
        SetReminderNo();
        "Posting Description" := StrSubstNo(ReminderNoLbl, "No.");

        OnInsertOnBeforeInitNoSeries(Rec, xRec, IsHandled);
        if not IsHandled then
            if ("No. Series" <> '') and
                (SalesSetup."Reminder Nos." = GetIssuingNoSeriesCode())
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
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
        ReminderText: Record "Reminder Text";
        FinChrgTerms: Record "Finance Charge Terms";
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        ReminderCommentLine: Record "Reminder Comment Line";
        Cust: Record Customer;
        PostCode: Record "Post Code";
        IssuedReminderHeader: Record "Issued Reminder Header";
        GenBusPostingGrp: Record "Gen. Business Posting Group";
        GLSetup: Record "General Ledger Setup";
        AutoFormat: Codeunit "Auto Format";
        NoSeries: Codeunit "No. Series";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        ReminderIssue: Codeunit "Reminder-Issue";
        DimMgt: Codeunit DimensionManagement;
        NextLineNo: Integer;
        LineSpacing: Integer;
        ReminderTotal: Decimal;
        SelectNoSeriesAllowed: Boolean;
        ReminderNoLbl: Label 'Reminder %1', Comment = '%1 = Reminder No.';
        PrintReminderQst: Label 'Do you want to print reminder %1?', Comment = '%1 = Reminder No.';
        DeleteExistingLinesTxt: Label 'This change will cause the existing lines to be deleted for this reminder.\\';
        ContinueTxt: Label 'Do you want to continue?';
        NotEnoughSpaceForTextErr: Label 'There is not enough space to insert the text.';
        GapInNumberSeriesIfDeleteTxt: Label 'Deleting this document will cause a gap in the number series for reminders. ';
        CreateEmptyReminderTxt: Label 'An empty reminder %1 will be created to fill this gap in the number series.\\', Comment = '%1 = Reminder No.';
        UnexpectedLineTypeErr: Label 'Unexpected line type %1 in reminder %2', Comment = '%1 = Line Type, %2 = Reminder No.';

    /// <summary>
    /// Opens a dialog to assist with selecting a number from related number series.
    /// </summary>
    /// <param name="OldReminderHeader">The previous reminder header record for reference.</param>
    /// <returns>True if a new number was selected; otherwise, false.</returns>
    procedure AssistEdit(OldReminderHeader: Record "Reminder Header"): Boolean
    begin
        ReminderHeader := Rec;
        ReminderHeader.TestNoSeries();
        if NoSeries.LookupRelatedNoSeries(SalesSetup."Reminder Nos.", OldReminderHeader."No. Series", ReminderHeader."No. Series") then begin
            ReminderHeader."No." := NoSeries.GetNextNo(ReminderHeader."No. Series");
            Rec := ReminderHeader;
            exit(true);
        end;
    end;

    /// <summary>
    /// Tests that the required number series are set up in Sales and Receivables Setup.
    /// </summary>
    procedure TestNoSeries()
    var
        IsHandled: Boolean;
    begin
        SalesSetup.Get();
        IsHandled := false;
        OnBeforeTestNoSeries(Rec, IsHandled);
        if not IsHandled then begin
            SalesSetup.TestField("Reminder Nos.");
            SalesSetup.TestField("Issued Reminder Nos.");
        end;

        OnAfterTestNoSeries(Rec);
    end;

    /// <summary>
    /// Gets the number series code for reminder documents.
    /// </summary>
    /// <returns>The number series code to use for reminders.</returns>
    procedure GetNoSeriesCode(): Code[20]
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
    begin
        SalesSetup.Get();
        IsHandled := false;
        OnBeforeGetNoSeriesCode(Rec, SalesSetup, NoSeriesCode, IsHandled);
        if IsHandled then
            exit(NoSeriesCode);

        NoSeriesCode := SalesSetup."Reminder Nos.";

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
        SalesSetup.Get();
        IsHandled := false;
        OnBeforeGetIssuingNoSeriesCode(Rec, SalesSetup, IssuingNos, IsHandled);
        if IsHandled then
            exit;

        IssuingNos := SalesSetup."Issued Reminder Nos.";

        OnAfterGetIssuingNoSeriesCode(Rec, IssuingNos);
    end;

    local procedure SetCompanyBankAccount()
    var
        BankAccount: Record "Bank Account";
    begin
        Validate("Company Bank Account Code", BankAccount.GetDefaultBankAccountNoForCurrency("Currency Code"));
        OnAfterSetCompanyBankAccount(Rec, xRec);
    end;

    /// <summary>
    /// Prompts the user to confirm deletion of existing reminder lines and deletes them if confirmed.
    /// </summary>
    /// <returns>True if the user cancels the operation; otherwise, false.</returns>
    procedure Undo(): Boolean
    begin
        ReminderLine.SetRange("Reminder No.", "No.");
        if ReminderLine.Find('-') then begin
            Commit();
            if not
               Confirm(
                 DeleteExistingLinesTxt +
                 ContinueTxt,
                 false)
            then
                exit(true);
            ReminderLine.DeleteAll();
            Modify();
        end;
    end;

    /// <summary>
    /// Inserts reminder lines including additional fees, beginning and ending texts based on the reminder level.
    /// </summary>
    procedure InsertLines()
    var
        ReminderLine2: Record "Reminder Line";
        CurrencyForReminderLevel: Record "Currency for Reminder Level";
        TranslationHelper: Codeunit "Translation Helper";
        AdditionalFee: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertLines(Rec, IsHandled);
        if not IsHandled then begin
            CurrencyForReminderLevel.Init();
            ReminderLevel.SetRange("Reminder Terms Code", "Reminder Terms Code");
            ReminderLevel.SetRange("No.", 1, "Reminder Level");
            OnInsertLinesOnAfterReminderLevelSetFilters(Rec, ReminderLevel);
            if ReminderLevel.FindLast() then begin
                CalcFields("Remaining Amount");
                AdditionalFee := ReminderLevel.GetAdditionalFee("Remaining Amount", "Currency Code", false, "Posting Date");
                OnInsertLinesOnAfterCalcAdditionalFee(Rec, ReminderLevel, AdditionalFee);

                if AdditionalFee > 0 then begin
                    ReminderLine.Reset();
                    ReminderLine.SetRange("Reminder No.", "No.");
                    ReminderLine.SetRange("Line Type", ReminderLine."Line Type"::"Reminder Line");
                    ReminderLine."Reminder No." := "No.";
                    if ReminderLine.Find('+') then
                        NextLineNo := ReminderLine."Line No."
                    else
                        NextLineNo := 0;
                    ReminderLine.SetRange("Line Type");
                    ReminderLine2 := ReminderLine;
                    ReminderLine2.CopyFilters(ReminderLine);
                    ReminderLine2.SetFilter("Line Type", '<>%1', ReminderLine2."Line Type"::"Line Fee");
                    if ReminderLine2.Next() <> 0 then
                        LineSpacing := (ReminderLine2."Line No." - ReminderLine."Line No.") div 3
                    else
                        LineSpacing := 10000;
                    InsertBlankLine(ReminderLine."Line Type"::"Additional Fee");

                    NextLineNo := NextLineNo + LineSpacing;
                    ReminderLine.Init();
                    ReminderLine."Line No." := NextLineNo;
                    ReminderLine.Type := ReminderLine.Type::"G/L Account";
                    TestField("Customer Posting Group");
                    CustPostingGr.Get("Customer Posting Group");
                    ReminderLine.Validate("No.", CustPostingGr.GetAdditionalFeeAccount());
                    ReminderLine.Description :=
                      CopyStr(
                        TranslationHelper.GetTranslatedFieldCaption(
                          "Language Code", DATABASE::"Currency for Reminder Level",
                          CurrencyForReminderLevel.FieldNo("Additional Fee")), 1, 100);

                    IsHandled := false;
                    OnInsertLinesOnBeforeValidateAmount(Rec, ReminderLine, IsHandled);
                    if not IsHandled then
                        ReminderLine.Validate(Amount, AdditionalFee);
                    ReminderLine."Line Type" := ReminderLine."Line Type"::"Additional Fee";
                    IsHandled := false;
                    OnInsertLinesOnBeforeReminderLineInsert(Rec, ReminderLine, IsHandled);
                    if not IsHandled then
                        ReminderLine.Insert();
                    if TransferExtendedText.ReminderCheckIfAnyExtText(ReminderLine, false) then
                        TransferExtendedText.InsertReminderExtText(ReminderLine);
                end;
            end;
            ReminderLine."Line No." := ReminderLine."Line No." + 10000;
            ReminderRounding(Rec);
            InsertBeginTexts(Rec);
            InsertEndTexts(Rec);
            Modify();
        end;

        OnAfterInsertLines(Rec);
    end;

    /// <summary>
    /// Updates reminder lines by refreshing text lines and optionally recalculating additional fees.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="UpdateAdditionalFee">Indicates whether to recalculate the additional fee.</param>
    procedure UpdateLines(ReminderHeader: Record "Reminder Header"; UpdateAdditionalFee: Boolean)
    begin
        ReminderLine.Reset();
        ReminderLine.SetRange("Reminder No.", ReminderHeader."No.");
        ReminderLine.SetRange(
          "Line Type",
          ReminderLine."Line Type"::"Beginning Text",
          ReminderLine."Line Type"::"Ending Text");
        ReminderLine.SetRange(Type, ReminderLine.Type::" ");
        ReminderLine.SetRange("Attached to Line No.", 0);
        ReminderLine.DeleteAll(true);

        if UpdateAdditionalFee then begin
            ReminderLine.Reset();
            ReminderLine.SetRange("Reminder No.", ReminderHeader."No.");
            ReminderLine.SetRange("Line Type", ReminderLine."Line Type"::"Additional Fee");
            ReminderLine.DeleteAll();
            InsertLines();
        end else begin
            InsertBeginTexts(ReminderHeader);
            InsertEndTexts(ReminderHeader);
        end;

        OnAfterUpdateLines(Rec, UpdateAdditionalFee);
    end;

    local procedure InsertBeginTexts(var ReminderHeader: Record "Reminder Header")
    var
        ReminderCommunication: Codeunit "Reminder Communication";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertBeginTexts(ReminderHeader, IsHandled);
        if IsHandled then
            exit;

        ReminderLevel.SetRange("Reminder Terms Code", ReminderHeader."Reminder Terms Code");
        ReminderLevel.SetRange("No.", 1, ReminderHeader."Reminder Level");
        OnInsertBeginTextsOnAfterReminderLevelSetFilters(ReminderLevel, ReminderHeader);
        if ReminderLevel.FindLast() then
            if ReminderCommunication.NewReminderCommunicationEnabled() then
                ReminderCommunication.InsertBeginningText(ReminderHeader, ReminderLevel, ReminderLine)
            else begin
                ReminderText.Reset();
                ReminderText.SetRange("Reminder Terms Code", ReminderHeader."Reminder Terms Code");
                ReminderText.SetRange("Reminder Level", ReminderLevel."No.");
                ReminderText.SetRange(Position, ReminderText.Position::Beginning);
                OnInsertBeginTextsOnAfterReminderTextSetFilters(ReminderText, ReminderHeader);

                ReminderLine.Reset();
                ReminderLine.SetRange("Reminder No.", ReminderHeader."No.");
                ReminderLine."Reminder No." := ReminderHeader."No.";
                if ReminderLine.Find('-') then begin
                    LineSpacing := ReminderLine."Line No." div (ReminderText.Count + 2);
                    if LineSpacing = 0 then
                        Error(NotEnoughSpaceForTextErr);
                end else
                    LineSpacing := 10000;
                NextLineNo := 0;
                InsertTextLines(ReminderHeader);
            end;
    end;

    local procedure InsertEndTexts(var ReminderHeader: Record "Reminder Header")
    var
        ReminderCommunication: Codeunit "Reminder Communication";
        ReminderLine2: Record "Reminder Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertEndTexts(ReminderHeader, IsHandled);
        if IsHandled then
            exit;

        ReminderLevel.SetRange("Reminder Terms Code", ReminderHeader."Reminder Terms Code");
        ReminderLevel.SetRange("No.", 1, ReminderHeader."Reminder Level");
        OnInsertEndTextsOnAfterReminderLevelSetFilters(ReminderLevel, ReminderHeader);
        if ReminderLevel.FindLast() then
            if ReminderCommunication.NewReminderCommunicationEnabled() then
                ReminderCommunication.InsertEndingText(ReminderHeader, ReminderLevel, ReminderLine)
            else begin
                ReminderText.SetRange(
                  "Reminder Terms Code", ReminderHeader."Reminder Terms Code");
                ReminderText.SetRange("Reminder Level", ReminderLevel."No.");
                ReminderText.SetRange(Position, ReminderText.Position::Ending);
                OnInsertEndTextsOnAfterReminderTextSetFilters(ReminderText, ReminderHeader);

                ReminderLine.Reset();
                ReminderLine.SetRange("Reminder No.", ReminderHeader."No.");
                ReminderLine.SetFilter(
                  "Line Type", '%1|%2|%3',
                  ReminderLine."Line Type"::"Reminder Line",
                  ReminderLine."Line Type"::"Additional Fee",
                  ReminderLine."Line Type"::Rounding);
                OnInsertEndTextsOnAfterReminderLineSetFilters(ReminderLine, ReminderHeader);
                if ReminderLine.FindLast() then
                    NextLineNo := ReminderLine."Line No."
                else
                    NextLineNo := 0;
                ReminderLine.SetRange("Line Type");
                ReminderLine2 := ReminderLine;
                ReminderLine2.CopyFilters(ReminderLine);
                ReminderLine2.SetFilter("Line Type", '<>%1', ReminderLine2."Line Type"::"Line Fee");
                if ReminderLine2.Next() <> 0 then begin
                    LineSpacing :=
                      (ReminderLine2."Line No." - ReminderLine."Line No.") div
                      (ReminderText.Count + 2);
                    if LineSpacing = 0 then
                        Error(NotEnoughSpaceForTextErr);
                end else
                    LineSpacing := 10000;
                InsertTextLines(ReminderHeader);
            end;
    end;

    local procedure InsertTextLines(var ReminderHeader: Record "Reminder Header")
    begin
        InsertTextLines(ReminderHeader, ReminderText, NextLineNo, LineSpacing);
    end;

    /// <summary>
    /// Inserts text lines from reminder text records into the reminder document.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="ReminderText">The reminder text records to insert.</param>
    /// <param name="NextLineNo">The next line number to use, updated after insertion.</param>
    /// <param name="LineSpacing">The spacing between lines.</param>
    procedure InsertTextLines(var ReminderHeader: Record "Reminder Header"; var ReminderText: Record "Reminder Text"; var NextLineNo: Integer; LineSpacing: Integer)
    var
        CompanyInfo: Record "Company Information";
        AutoFormatType: Enum "Auto Format";
    begin
        if ReminderText.Find('-') then begin
            if ReminderText.Position = ReminderText.Position::Ending then
                InsertBlankLine(ReminderLine."Line Type"::"Ending Text");
            if ReminderHeader."Fin. Charge Terms Code" <> '' then
                FinChrgTerms.Get(ReminderHeader."Fin. Charge Terms Code");
            OnInsertTextLinesOnAfterGetFinChrgTerms(ReminderHeader, FinChrgTerms);
            if not ReminderLevel."Calculate Interest" then
                FinChrgTerms."Interest Rate" := 0;
            ReminderHeader.CalcFields(
              "Remaining Amount", "Interest Amount", "Additional Fee", "VAT Amount", "Add. Fee per Line");
            ReminderTotal :=
              ReminderHeader."Remaining Amount" + ReminderHeader."Interest Amount" +
              ReminderHeader."Additional Fee" + ReminderHeader."VAT Amount" +
              ReminderHeader."Add. Fee per Line";
            CompanyInfo.Get();

            repeat
                NextLineNo := NextLineNo + LineSpacing;
                ReminderLine.Init();
                ReminderLine."Line No." := NextLineNo;
                ReminderLine.Type := ReminderLine.Type::" ";
                ReminderLine.Description :=
                  CopyStr(
                    StrSubstNo(
                      ReminderText.Text,
                      ReminderHeader."Document Date",
                      ReminderHeader."Due Date",
                      FinChrgTerms."Interest Rate",
                      Format(ReminderHeader."Remaining Amount", 0,
                        AutoFormat.ResolveAutoFormat(AutoFormatType::AmountFormat, ReminderHeader."Currency Code")),
                      ReminderHeader."Interest Amount",
                      ReminderHeader."Additional Fee",
                      Format(ReminderTotal, 0, AutoFormat.ResolveAutoFormat(AutoFormatType::AmountFormat, ReminderHeader."Currency Code")),
                      ReminderHeader."Reminder Level",
                      ReminderHeader."Currency Code",
                      ReminderHeader."Posting Date",
                      CompanyInfo.Name,
                      ReminderHeader."Add. Fee per Line"),
                    1,
                    MaxStrLen(ReminderLine.Description));
                if ReminderText.Position = ReminderText.Position::Beginning then
                    ReminderLine."Line Type" := ReminderLine."Line Type"::"Beginning Text"
                else
                    ReminderLine."Line Type" := ReminderLine."Line Type"::"Ending Text";
                OnInsertTextLinesOnBeforeReminderLineInsert(ReminderLine, ReminderText, ReminderHeader);
                ReminderLine.Insert();
            until ReminderText.Next() = 0;
            if ReminderText.Position = ReminderText.Position::Beginning then
                InsertBlankLine(ReminderLine."Line Type"::"Beginning Text");
        end;
    end;

    /// <summary>
    /// Inserts text lines from reminder attachment text records into the reminder document.
    /// </summary>
    /// <param name="LocalReminderHeader">The reminder header record.</param>
    /// <param name="ReminderAttachmentText">The reminder attachment text records to insert.</param>
    /// <param name="LineType">The type of line (Beginning Text or Ending Text).</param>
    /// <param name="NextLineNumber">The next line number to use, updated after insertion.</param>
    /// <param name="LineSpace">The spacing between lines.</param>
    procedure InsertTextLines(var LocalReminderHeader: Record "Reminder Header"; var ReminderAttachmentText: Record "Reminder Attachment Text"; LineType: Enum "Reminder Line Type"; var NextLineNumber: Integer; LineSpace: Integer)
    var
        ReminderAttachmentTextLine: Record "Reminder Attachment Text Line";
        ReminderCommunication: Codeunit "Reminder Communication";
    begin
        if not ReminderAttachmentText.IsEmpty() then begin
            NextLineNo := NextLineNumber;
            LineSpacing := LineSpace;

            if LineType = Enum::"Reminder Line Type"::"Ending Text" then
                InsertBlankLine(ReminderLine."Line Type"::"Ending Text");

            if LocalReminderHeader."Fin. Charge Terms Code" <> '' then
                FinChrgTerms.Get(LocalReminderHeader."Fin. Charge Terms Code");

            OnInsertTextLinesOnAfterGetFinChrgTerms(LocalReminderHeader, FinChrgTerms);

            if not ReminderLevel."Calculate Interest" then
                FinChrgTerms."Interest Rate" := 0;
            LocalReminderHeader.CalcFields("Remaining Amount", "Interest Amount", "Additional Fee", "VAT Amount", "Add. Fee per Line");
            ReminderTotal := LocalReminderHeader."Remaining Amount"
                            + LocalReminderHeader."Interest Amount"
                            + LocalReminderHeader."Additional Fee"
                            + LocalReminderHeader."VAT Amount"
                            + LocalReminderHeader."Add. Fee per Line";

            ReminderAttachmentTextLine.SetRange(Id, ReminderAttachmentText."Id");
            ReminderAttachmentTextLine.SetRange("Language Code", ReminderAttachmentText."Language Code");
            case LineType of
                Enum::"Reminder Line Type"::"Beginning Text":
                    ReminderAttachmentTextLine.SetRange(Position, ReminderAttachmentTextLine.Position::"Beginning Line");
                Enum::"Reminder Line Type"::"Ending Text":
                    ReminderAttachmentTextLine.SetRange(Position, ReminderAttachmentTextLine.Position::"Ending Line");
                else
                    Error(UnexpectedLineTypeErr, LineType, LocalReminderHeader."No.");
            end;
            if ReminderAttachmentTextLine.IsEmpty() then
                exit;

            ReminderAttachmentTextLine.FindSet();
            repeat
                NextLineNo := NextLineNo + LineSpacing;
                ReminderLine.Init();
                ReminderLine.Type := ReminderLine.Type::" ";
                case LineType of
                    Enum::"Reminder Line Type"::"Beginning Text":
                        ReminderLine."Line Type" := ReminderLine."Line Type"::"Beginning Text";
                    Enum::"Reminder Line Type"::"Ending Text":
                        ReminderLine."Line Type" := ReminderLine."Line Type"::"Ending Text";
                end;
                ReminderLine."Reminder No." := LocalReminderHeader."No.";
                ReminderLine."Line No." := NextLineNo;
                ReminderLine.Description := ReminderCommunication.SubstituteBeginningOrEndingDescription(ReminderAttachmentTextLine.Text, ReminderTotal, MaxStrLen(ReminderLine.Description), LocalReminderHeader, FinChrgTerms);
                OnInsertTextLinesOnBeforeRemLineInsert(LocalReminderHeader, ReminderLine, ReminderAttachmentText, ReminderAttachmentTextLine);
                ReminderLine.Insert();
            until ReminderAttachmentTextLine.Next() = 0;

            if LineType = Enum::"Reminder Line Type"::"Beginning Text" then
                InsertBlankLine(ReminderLine."Line Type"::"Beginning Text");
        end;
    end;

    local procedure InsertBlankLine(LineType: Enum "Reminder Line Type")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertBlankLine(Rec, LineType, NextLineNo, LineSpacing, IsHandled);
        if IsHandled then
            exit;

        NextLineNo := NextLineNo + LineSpacing;
        ReminderLine.Init();
        ReminderLine."Line No." := NextLineNo;
        ReminderLine."Line Type" := LineType;
        OnInsertBlankLineOnBeforeReminderLineInsert(ReminderLine);
        ReminderLine.Insert();
    end;

    /// <summary>
    /// Prints the reminder test report for the current record.
    /// </summary>
    procedure PrintRecords()
    var
        ReminderHeader: Record "Reminder Header";
        ReportSelection: Record "Report Selections";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintRecords(Rec, IsHandled);
        if IsHandled then
            exit;

        ReminderHeader.Copy(Rec);
        ReminderHeader.FindFirst();
        ReminderHeader.SetRecFilter();
        ReportSelection.PrintForCust(ReportSelection.Usage::"Rem.Test", ReminderHeader, ReminderHeader.FieldNo("Customer No."));
    end;

    /// <summary>
    /// Prompts the user to confirm deletion of the reminder and warns about number series gaps.
    /// </summary>
    /// <returns>True if deletion is confirmed; otherwise, false.</returns>
    procedure ConfirmDeletion() Confirmed: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmDeletion(Rec, IssuedReminderHeader, Confirmed, IsHandled);
        if IsHandled then
            exit(Confirmed);

        ReminderIssue.TestDeleteHeader(Rec, IssuedReminderHeader);
        if IssuedReminderHeader."No." <> '' then
            if not Confirm(
                 GapInNumberSeriesIfDeleteTxt +
                 CreateEmptyReminderTxt +
                 ContinueTxt, true,
                 IssuedReminderHeader."No.")
            then
                exit;
        exit(true);
    end;

    /// <summary>
    /// Creates dimensions for the reminder header based on the provided dimension sources.
    /// </summary>
    /// <param name="DefaultDimSource">The list of default dimension sources.</param>
    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDimProcedure(Rec, CurrFieldNo, DefaultDimSource, IsHandled);
        if not IsHandled then begin
            SourceCodeSetup.Get();
            "Shortcut Dimension 1 Code" := '';
            "Shortcut Dimension 2 Code" := '';
            "Dimension Set ID" :=
              DimMgt.GetRecDefaultDimID(
                Rec, CurrFieldNo, DefaultDimSource, SourceCodeSetup.Reminder, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
        end;

        OnAfterCreateDimProcedure(Rec, CurrFieldNo, DefaultDimSource);
    end;

    /// <summary>
    /// Validates and updates a shortcut dimension code on the reminder header.
    /// </summary>
    /// <param name="FieldNumber">The field number of the shortcut dimension.</param>
    /// <param name="ShortcutDimCode">The shortcut dimension code value.</param>
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, IsHandled);
        if not IsHandled then
            DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    /// <summary>
    /// Calculates the invoice rounding amount for the reminder based on currency settings.
    /// </summary>
    /// <returns>The invoice rounding amount.</returns>
    procedure GetInvoiceRoundingAmount(): Decimal
    var
        TotalAmountInclVAT: Decimal;
    begin
        GetCurrency();
        if Currency."Invoice Rounding Precision" = 0 then
            exit(0);

        CalcFields(
            "Remaining Amount", "Interest Amount", "Additional Fee", "VAT Amount", "Add. Fee per Line");
        TotalAmountInclVAT :=
            "Remaining Amount" + "Interest Amount" + "Additional Fee" +
            "Add. Fee per Line" + "VAT Amount";

        exit(
            -Round(
                TotalAmountInclVAT -
                Round(
                    TotalAmountInclVAT,
                    Currency."Invoice Rounding Precision",
                    Currency.InvoiceRoundingDirection()),
                Currency."Amount Rounding Precision"));
    end;

    local procedure ReminderRounding(var ReminderHeader: Record "Reminder Header")
    var
        ReminderRoundingAmount: Decimal;
        Handled: Boolean;
    begin
        OnBeforeReminderRounding(ReminderHeader, Handled);
        if Handled then
            exit;

        ReminderRoundingAmount := ReminderHeader.GetInvoiceRoundingAmount();

        if ReminderRoundingAmount <> 0 then begin
            CustPostingGr.Get(ReminderHeader."Customer Posting Group");
            ReminderLine.Init();
            ReminderLine.Validate("Line No.", GetNextLineNo(ReminderHeader."No."));
            ReminderLine.Validate("Reminder No.", ReminderHeader."No.");
            ReminderLine.Validate(Type, ReminderLine.Type::"G/L Account");
            ReminderLine."System-Created Entry" := true;
            ReminderLine.Validate("No.", CustPostingGr.GetInvRoundingAccount());
            ReminderLine.Validate(
              Amount,
              Round(
                ReminderRoundingAmount / (1 + (ReminderLine."VAT %" / 100)),
                Currency."Amount Rounding Precision"));
            ReminderLine."VAT Amount" := ReminderRoundingAmount - ReminderLine.Amount;
            ReminderLine."Line Type" := ReminderLine."Line Type"::Rounding;
            ReminderLine.Insert();
        end;
    end;

    local procedure GetCurrency()
    begin
        if "Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else begin
            Currency.Get("Currency Code");
            Currency.TestField("Amount Rounding Precision");
        end;
    end;

    /// <summary>
    /// Updates the invoice rounding line for the reminder by recalculating the rounding amount.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    procedure UpdateReminderRounding(ReminderHeader: Record "Reminder Header")
    var
        OldLineNo: Integer;
    begin
        ReminderLine.Reset();
        ReminderLine.SetRange("Reminder No.", ReminderHeader."No.");
        ReminderLine.SetRange("Line Type", ReminderLine."Line Type"::Rounding);
        if ReminderLine.FindFirst() then
            ReminderLine.Delete(true);

        ReminderLine.SetRange("Line Type");
        ReminderLine.SetFilter(Type, '<>%1', ReminderLine.Type::" ");
        if ReminderLine.FindLast() then begin
            OldLineNo := ReminderLine."Line No.";
            ReminderLine.SetRange(Type);
            if ReminderLine.Next() <> 0 then
                ReminderLine."Line No." := OldLineNo + ((ReminderLine."Line No." - OldLineNo) div 2)
            else
                ReminderLine."Line No." := OldLineNo + 10000;
        end else
            ReminderLine."Line No." := 10000;

        ReminderRounding(ReminderHeader);
    end;

    /// <summary>
    /// Opens a dialog to view and edit the document dimensions for the reminder.
    /// </summary>
    procedure ShowDocDim()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterShowDocDim(Rec);
    end;

    /// <summary>
    /// Calculates the total VAT amount for line fee type reminder lines.
    /// </summary>
    /// <returns>The sum of VAT amounts for line fee lines.</returns>
    procedure CalculateLineFeeVATAmount(): Decimal
    var
        ReminderLine: Record "Reminder Line";
    begin
        ReminderLine.SetCurrentKey("Reminder No.", Type, "Line Type");
        ReminderLine.SetRange("Reminder No.", "No.");
        ReminderLine.SetRange(Type, ReminderLine.Type::"Line Fee");
        ReminderLine.CalcSums("VAT Amount");
        exit(ReminderLine."VAT Amount");
    end;

    local procedure GetNextLineNo(ReminderNo: Code[20]): Integer
    var
        ReminderLine: Record "Reminder Line";
    begin
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        if ReminderLine.FindLast() then
            exit(ReminderLine."Line No." + 10000);
        exit(10000);
    end;

    local procedure GetFilterCustNo(): Code[20]
    begin
        if GetFilter("Customer No.") <> '' then
            if GetRangeMin("Customer No.") = GetRangeMax("Customer No.") then
                exit(GetRangeMax("Customer No."));
    end;

    /// <summary>
    /// Enables the option to select from related number series when creating a reminder.
    /// </summary>
    procedure SetAllowSelectNoSeries()
    begin
        SelectNoSeriesAllowed := true;
    end;

    /// <summary>
    /// Sets the customer number from the current filter if a single customer is filtered.
    /// </summary>
    procedure SetCustomerFromFilter()
    begin
        if GetFilterCustNo() <> '' then
            Validate("Customer No.", GetFilterCustNo());
    end;

    /// <summary>
    /// Assigns the next reminder number from the number series if no number is set.
    /// </summary>
    [Scope('OnPrem')]
    procedure SetReminderNo()
    begin
        if "No." = '' then begin
            TestNoSeries();
            "No. Series" := GetNoSeriesCode();
            if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                "No. Series" := xRec."No. Series";
            "No." := NoSeries.GetNextNo("No. Series", "Posting Date");
        end;
    end;

    local procedure CheckCustomerBlockedAll(Cust: Record Customer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCustomerBlockedAll(Rec, Cust, IsHandled);
        if IsHandled then
            exit;

        if Cust.Blocked = Cust.Blocked::All then
            Cust.CustBlockedErrorMessage(Cust, false);
    end;

    local procedure PrintIssuedReminders()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintIssuedReminders(Rec, IsHandled);
        if IsHandled then
            exit;

        if IssuedReminderHeader."No." <> '' then begin
            Commit();
            if Confirm(PrintReminderQst, true, IssuedReminderHeader."No.") then begin
                IssuedReminderHeader.SetRecFilter();
                IssuedReminderHeader.PrintRecords(true, false, false)
            end;
        end;
    end;

    /// <summary>
    /// Creates dimensions for the reminder header using the default dimension sources.
    /// </summary>
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

    /// <summary>
    /// Raised after initializing default dimension sources for the reminder header.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="DefaultDimSource">The list of default dimension sources.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var ReminderHeader: Record "Reminder Header"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    /// <summary>
    /// Raised before creating dimensions for the reminder header.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="CurrFieldNo">The current field number triggering the dimension creation.</param>
    /// <param name="DefaultDimSource">The list of default dimension sources.</param>
    /// <param name="IsHandled">Set to true to skip default dimension creation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDimProcedure(var ReminderHeader: Record "Reminder Header"; CurrFieldNo: Integer; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before confirming deletion of the reminder header.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header to delete.</param>
    /// <param name="IssuedReminderHeader">The related issued reminder header.</param>
    /// <param name="Confirmed">Returns the confirmation result.</param>
    /// <param name="IsHandled">Set to true to skip default confirmation dialog.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmDeletion(ReminderHeader: Record "Reminder Header"; IssuedReminderHeader: Record "Issued Reminder Header"; var Confirmed: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after creating dimensions for the reminder header.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="CurrFieldNo">The current field number that triggered dimension creation.</param>
    /// <param name="DefaultDimSource">The list of default dimension sources.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimProcedure(var ReminderHeader: Record "Reminder Header"; CurrFieldNo: Integer; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    /// <summary>
    /// Raised after retrieving the number series code for reminders.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="SalesSetup">The sales and receivables setup record.</param>
    /// <param name="NoSeriesCode">The number series code retrieved.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetNoSeriesCode(var ReminderHeader: Record "Reminder Header"; SalesSetup: Record "Sales & Receivables Setup"; var NoSeriesCode: Code[20])
    begin
    end;

    /// <summary>
    /// Raised after retrieving the issuing number series code for reminders.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="IssuingNos">The issuing number series code retrieved.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetIssuingNoSeriesCode(var ReminderHeader: Record "Reminder Header"; var IssuingNos: Code[20])
    begin
    end;

    /// <summary>
    /// Raised after inserting reminder lines for the header.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertLines(var ReminderHeader: Record "Reminder Header")
    begin
    end;

    /// <summary>
    /// Raised after testing the number series for the reminder header.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterTestNoSeries(var ReminderHeader: Record "Reminder Header")
    begin
    end;

    /// <summary>
    /// Raised after setting the company bank account on the reminder header.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="xReminderHeader">The previous reminder header values.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCompanyBankAccount(var ReminderHeader: Record "Reminder Header"; xReminderHeader: Record "Reminder Header")
    begin
    end;

    /// <summary>
    /// Raised after validating a shortcut dimension code on the reminder header.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="xReminderHeader">The previous reminder header values.</param>
    /// <param name="FieldNumber">The field number of the shortcut dimension.</param>
    /// <param name="ShortcutDimCode">The shortcut dimension code value.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var ReminderHeader: Record "Reminder Header"; var xReminderHeader: Record "Reminder Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    /// <summary>
    /// Raised after updating reminder lines for the header.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="UpdateAdditionalFee">Indicates whether to update the additional fee.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateLines(var ReminderHeader: Record "Reminder Header"; UpdateAdditionalFee: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after showing the document dimensions for the reminder header.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDocDim(var ReminderHeader: Record "Reminder Header")
    begin
    end;

    /// <summary>
    /// Raised before retrieving the number series code for reminders.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="SalesSetup">The sales and receivables setup record.</param>
    /// <param name="NoSeriesCode">The number series code to retrieve.</param>
    /// <param name="IsHandled">Set to true to skip default number series retrieval.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNoSeriesCode(var ReminderHeader: Record "Reminder Header"; SalesSetup: Record "Sales & Receivables Setup"; var NoSeriesCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before retrieving the issuing number series code for reminders.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="SalesSetup">The sales and receivables setup record.</param>
    /// <param name="IssuingNos">The issuing number series code to retrieve.</param>
    /// <param name="IsHandled">Set to true to skip default number series retrieval.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetIssuingNoSeriesCode(var ReminderHeader: Record "Reminder Header"; SalesSetup: Record "Sales & Receivables Setup"; var IssuingNos: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before inserting a reminder line during InsertLines processing.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="ReminderLine">The reminder line to insert.</param>
    /// <param name="IsHandled">Set to true to skip default line insertion.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertLinesOnBeforeReminderLineInsert(var ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before inserting a blank reminder line.
    /// </summary>
    /// <param name="ReminderLine">The blank reminder line to insert.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertBlankLineOnBeforeReminderLineInsert(var ReminderLine: Record "Reminder Line")
    begin
    end;

    /// <summary>
    /// Raised before inserting a text line during InsertTextLines processing.
    /// </summary>
    /// <param name="ReminderLine">The reminder line to insert.</param>
    /// <param name="ReminderText">The source reminder text record.</param>
    /// <param name="ReminderHeader">The reminder header record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertTextLinesOnBeforeReminderLineInsert(var ReminderLine: Record "Reminder Line"; var ReminderText: Record "Reminder Text"; var ReminderHeader: Record "Reminder Header")
    begin
    end;

    /// <summary>
    /// Raised after setting filters on reminder lines during InsertEndTexts processing.
    /// </summary>
    /// <param name="ReminderLine">The reminder line record with filters.</param>
    /// <param name="ReminderHeader">The reminder header record.</param>
    [IntegrationEvent(false, false)]
    internal procedure OnInsertEndTextsOnAfterReminderLineSetFilters(var ReminderLine: Record "Reminder Line"; ReminderHeader: Record "Reminder Header")
    begin
    end;

    /// <summary>
    /// Raised after setting filters on reminder level during InsertEndTexts processing.
    /// </summary>
    /// <param name="ReminderLevel">The reminder level record with filters.</param>
    /// <param name="ReminderHeader">The reminder header record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertEndTextsOnAfterReminderLevelSetFilters(var ReminderLevel: Record "Reminder Level"; ReminderHeader: Record "Reminder Header");
    begin
    end;

    /// <summary>
    /// Raised after setting filters on reminder level during InsertBeginTexts processing.
    /// </summary>
    /// <param name="ReminderLevel">The reminder level record with filters.</param>
    /// <param name="ReminderHeader">The reminder header record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertBeginTextsOnAfterReminderLevelSetFilters(var ReminderLevel: Record "Reminder Level"; var ReminderHeader: Record "Reminder Header")
    begin
    end;

    /// <summary>
    /// Raised after setting filters on reminder level during InsertLines processing.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="ReminderLevel">The reminder level record with filters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertLinesOnAfterReminderLevelSetFilters(var ReminderHeader: Record "Reminder Header"; var ReminderLevel: Record "Reminder Level")
    begin
    end;

    /// <summary>
    /// Raised before initializing the number series during record insertion.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record being inserted.</param>
    /// <param name="xReminderHeader">The previous reminder header values.</param>
    /// <param name="IsHandled">Set to true to skip default number series initialization.</param>
    [IntegrationEvent(true, false)]
    local procedure OnInsertOnBeforeInitNoSeries(var ReminderHeader: Record "Reminder Header"; var xReminderHeader: Record "Reminder Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before applying invoice rounding to the reminder.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="Handled">Set to true to skip default rounding logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeReminderRounding(var ReminderHeader: Record "Reminder Header"; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before inserting beginning text lines for the reminder.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="IsHandled">Set to true to skip default begin text insertion.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertBeginTexts(var ReminderHeader: Record "Reminder Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before inserting a blank line in the reminder.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="LineType">The type of reminder line.</param>
    /// <param name="NextLineNo">The next line number to use.</param>
    /// <param name="LineSpacing">The spacing between lines.</param>
    /// <param name="IsHandled">Set to true to skip default blank line insertion.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertBlankLine(var ReminderHeader: Record "Reminder Header"; LineType: Enum "Reminder Line Type"; NextLineNo: Integer; LineSpacing: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before inserting ending text lines for the reminder.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="IsHandled">Set to true to skip default end text insertion.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertEndTexts(var ReminderHeader: Record "Reminder Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before testing the number series for the reminder header.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="IsHandled">Set to true to skip default number series testing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoSeries(var ReminderHeader: Record "Reminder Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after validating the reminder level on the header.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="ReminderLevel">The validated reminder level record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateReminderLevel(var ReminderHeader: Record "Reminder Header"; ReminderLevel: Record "Reminder Level")
    begin
    end;

    /// <summary>
    /// Raised before validating a shortcut dimension code on the reminder header.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="xReminderHeader">The previous reminder header values.</param>
    /// <param name="FieldNumber">The field number of the shortcut dimension.</param>
    /// <param name="ShortcutDimCode">The shortcut dimension code value.</param>
    /// <param name="IsHandled">Set to true to skip default validation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var ReminderHeader: Record "Reminder Header"; var xReminderHeader: Record "Reminder Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before checking if the customer is blocked for all transactions.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="Cust">The customer record to check.</param>
    /// <param name="IsHandled">Set to true to skip default blocking check.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCustomerBlockedAll(var ReminderHeader: Record "Reminder Header"; Cust: Record Customer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before printing issued reminders.
    /// </summary>
    /// <param name="Rec">The reminder header record.</param>
    /// <param name="IsHandled">Set to true to skip default printing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintIssuedReminders(var Rec: Record "Reminder Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after setting filters on reminder text during InsertBeginTexts processing.
    /// </summary>
    /// <param name="ReminderText">The reminder text record with filters.</param>
    /// <param name="ReminderHeader">The reminder header record.</param>
    [IntegrationEvent(false, false)]
    internal procedure OnInsertBeginTextsOnAfterReminderTextSetFilters(var ReminderText: Record "Reminder Text"; ReminderHeader: Record "Reminder Header")
    begin
    end;

    /// <summary>
    /// Raised after setting filters on reminder text during InsertEndTexts processing.
    /// </summary>
    /// <param name="ReminderText">The reminder text record with filters.</param>
    /// <param name="ReminderHeader">The reminder header record.</param>
    [IntegrationEvent(false, false)]
    internal procedure OnInsertEndTextsOnAfterReminderTextSetFilters(var ReminderText: Record "Reminder Text"; ReminderHeader: Record "Reminder Header")
    begin
    end;

    /// <summary>
    /// Raised after calculating the additional fee during InsertLines processing.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="ReminderLevel">The reminder level record.</param>
    /// <param name="AdditionalFee">The calculated additional fee amount.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertLinesOnAfterCalcAdditionalFee(var ReminderHeader: Record "Reminder Header"; ReminderLevel: Record "Reminder Level"; var AdditionalFee: Decimal)
    begin
    end;

    /// <summary>
    /// Raised after assigning customer values during Customer No. validation.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="Customer">The customer record with assigned values.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateCustomerNoOnAfterAssignCustomerValues(var ReminderHeader: Record "Reminder Header"; Customer: Record Customer)
    begin
    end;

    /// <summary>
    /// Raised before validating the city field on the reminder header.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="PostCode">The post code record for validation.</param>
    /// <param name="CurrentFieldNo">The current field number being validated.</param>
    /// <param name="IsHandled">Set to true to skip default city validation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCity(var ReminderHeader: Record "Reminder Header"; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before validating the post code field on the reminder header.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="PostCode">The post code record for validation.</param>
    /// <param name="CurrentFieldNo">The current field number being validated.</param>
    /// <param name="IsHandled">Set to true to skip default post code validation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostCode(var ReminderHeader: Record "Reminder Header"; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after retrieving finance charge terms during InsertTextLines processing.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="FinanceChargeTerms">The finance charge terms record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertTextLinesOnAfterGetFinChrgTerms(var ReminderHeader: Record "Reminder Header"; var FinanceChargeTerms: Record "Finance Charge Terms")
    begin
    end;

    /// <summary>
    /// Raised before validating the amount on a reminder line during InsertLines processing.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="ReminderLine">The reminder line record.</param>
    /// <param name="IsHandled">Set to true to skip default amount validation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertLinesOnBeforeValidateAmount(var ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before printing reminder records.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="IsHandled">Set to true to skip default printing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(var ReminderHeader: Record "Reminder Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before inserting lines for the reminder header.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="IsHandled">Set to true to skip default line insertion.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertLines(var ReminderHeader: Record "Reminder Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before inserting a reminder line from attachment text during InsertTextLines processing.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header record.</param>
    /// <param name="ReminderLine">The reminder line to insert.</param>
    /// <param name="ReminderAttachmentText">The reminder attachment text record.</param>
    /// <param name="ReminderAttachmentTextLine">The reminder attachment text line record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertTextLinesOnBeforeRemLineInsert(var ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line"; var ReminderAttachmentText: Record "Reminder Attachment Text"; var ReminderAttachmentTextLine: Record "Reminder Attachment Text Line")
    begin
    end;
}
