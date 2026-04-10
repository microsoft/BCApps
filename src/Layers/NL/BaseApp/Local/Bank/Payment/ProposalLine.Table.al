// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;

table 11000000 "Proposal Line"
{
    Caption = 'Proposal Line';
    DataCaptionFields = "Order", "Account Type", "Account No.";
    DrillDownPageID = "Telebank Proposal";
    LookupPageID = "Telebank Proposal";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(2; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = 'Customer,Vendor,Employee';
            OptionMembers = Customer,Vendor,Employee;

            trigger OnValidate()
            begin
                if "Account Type" <> xRec."Account Type" then begin
                    TestDetailAvailable(FieldCaption("Account Type"));
                    Validate("Account No.", '');
                end;
            end;
        }
        field(3; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            NotBlank = true;
            TableRelation = if ("Account Type" = const(Customer)) Customer."No."
            else
            if ("Account Type" = const(Vendor)) Vendor."No."
            else
            if ("Account Type" = const(Employee)) Employee."No.";

            trigger OnValidate()
            var
                Propline: Record "Proposal Line";
                Cust: Record Customer;
                Vend: Record Vendor;
                Empl: Record Employee;
            begin
                if "Account No." <> xRec."Account No." then begin
                    TestDetailAvailable(FieldCaption("Account No."));
                    Propline := Rec;
                    Init();
                    InitRecord();
                    "Account Type" := Propline."Account Type";
                    "Account No." := Propline."Account No.";
                    if "Account No." <> '' then
                        case "Account Type" of
                            "Account Type"::Customer:
                                begin
                                    Cust.Get("Account No.");
                                    if Cust."Preferred Bank Account Code" <> '' then
                                        Validate(Bank, Cust."Preferred Bank Account Code");
                                    if Cust."Transaction Mode Code" <> '' then
                                        Validate("Transaction Mode", Cust."Transaction Mode Code");
                                    "Account Name" := Cust.Name;
                                end;
                            "Account Type"::Vendor:
                                begin
                                    Vend.Get("Account No.");
                                    if Vend."Preferred Bank Account Code" <> '' then
                                        Validate(Bank, Vend."Preferred Bank Account Code");
                                    if Vend."Transaction Mode Code" <> '' then
                                        Validate("Transaction Mode", Vend."Transaction Mode Code");
                                    "Account Name" := Vend.Name;
                                end;
                            "Account Type"::Employee:
                                begin
                                    Empl.Get("Account No.");
                                    if Empl."Transaction Mode Code" <> '' then
                                        Validate("Transaction Mode", Empl."Transaction Mode Code");
                                    // We validate the bank here as we know that we want to use the employee's bank account.
                                    Validate(Bank, Empl."No.");
                                end;
                        end;
                end;

                ValidateDim();
            end;
        }
        field(4; "Transaction Date"; Date)
        {
            Caption = 'Transaction Date';
            NotBlank = true;

            trigger OnValidate()
            var
                DetailLine: Record "Detail Line";
            begin
                DetailLine.SetRange("Our Bank", "Our Bank No.");
                DetailLine.SetRange(Status, DetailLine.Status::Proposal);
                DetailLine.SetRange("Connect Lines", "Line No.");
                DetailLine.SetRange("Account Type", "Account Type");
                if DetailLine.FindSet() then
                    repeat
                        DetailLine.Date := "Transaction Date";
                        DetailLine.Modify();
                    until DetailLine.Next() = 0;
            end;
        }
        field(5; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            NotBlank = true;

            trigger OnValidate()
            begin
                TestField("Transaction Mode");
                "Amount (LCY)" := AmountLV();
            end;
        }
        field(7; Bank; Code[20])
        {
            Caption = 'Bank';
            TableRelation = if ("Account Type" = const(Customer)) "Customer Bank Account".Code where("Customer No." = field("Account No."))
            else
            if ("Account Type" = const(Vendor)) "Vendor Bank Account".Code where("Vendor No." = field("Account No."))
            else
            if ("Account Type" = const(Employee)) Employee."No." where("Employee No. Filter" = field("Account No."));

            trigger OnValidate()
            var
                "Detail line": Record "Detail Line";
                Custm: Record Customer;
                Vend: Record Vendor;
                Employee: Record Employee;
                CustmBank: Record "Customer Bank Account";
                VendBank: Record "Vendor Bank Account";
                GenJnlLine: Record "Gen. Journal Line";
                DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
            begin
                if Bank <> '' then begin
                    case "Account Type" of
                        "Account Type"::Customer:
                            begin
                                CustmBank.Get("Account No.", Bank);
                                "Bank Account No." := CustmBank."Bank Account No.";
                                "Account Holder Name" := CustmBank."Account Holder Name";
                                "Account Holder Address" := CustmBank."Account Holder Address";
                                "Account Holder Post Code" := CustmBank."Account Holder Post Code";
                                "Account Holder City" := CustmBank."Account Holder City";
                                "Acc. Hold. Country/Region Code" := CustmBank."Acc. Hold. Country/Region Code";
                                "National Bank Code" := CustmBank."National Bank Code";
                                "SWIFT Code" := CustmBank."SWIFT Code";
                                IBAN := CustmBank.IBAN;
                                "Direct Debit Mandate ID" := CustmBank."Direct Debit Mandate ID";
                                "Bank Name" := CustmBank.Name;
                                "Bank Address" := CustmBank.Address;
                                "Bank City" := CustmBank.City;
                                "Bank Country/Region Code" := CustmBank."Country/Region Code";
                                "Abbrev. National Bank Code" := CustmBank."Abbrev. National Bank Code";
                                if "Account Holder Name" + "Account Holder Address" + "Account Holder Post Code" + "Account Holder City" +
                                   "Acc. Hold. Country/Region Code" = ''
                                then begin
                                    Custm.Get("Account No.");
                                    "Account Holder Name" := Custm.Name;
                                    "Account Holder Address" := Custm.Address;
                                    "Account Holder Post Code" := Custm."Post Code";
                                    "Account Holder City" := Custm.City;
                                    "Acc. Hold. Country/Region Code" := Custm."Country/Region Code";
                                end;
                            end;
                        "Account Type"::Vendor:
                            begin
                                VendBank.Get("Account No.", Bank);
                                "Bank Account No." := VendBank."Bank Account No.";
                                "Account Holder Name" := VendBank."Account Holder Name";
                                "Account Holder Address" := VendBank."Account Holder Address";
                                "Account Holder Post Code" := VendBank."Account Holder Post Code";
                                "Account Holder City" := VendBank."Account Holder City";
                                "Acc. Hold. Country/Region Code" := VendBank."Acc. Hold. Country/Region Code";
                                "National Bank Code" := VendBank."National Bank Code";
                                "SWIFT Code" := VendBank."SWIFT Code";
                                IBAN := VendBank.IBAN;
                                "Bank Name" := VendBank.Name;
                                "Bank Address" := VendBank.Address;
                                "Bank City" := VendBank.City;
                                "Bank Country/Region Code" := VendBank."Country/Region Code";
                                "Abbrev. National Bank Code" := VendBank."Abbrev. National Bank Code";
                                if "Account Holder Name" + "Account Holder Address" + "Account Holder Post Code" + "Account Holder City" +
                                   "Acc. Hold. Country/Region Code" = ''
                                then begin
                                    Vend.Get("Account No.");
                                    "Account Holder Name" := Vend.Name;
                                    "Account Holder Address" := Vend.Address;
                                    "Account Holder Post Code" := Vend."Post Code";
                                    "Account Holder City" := Vend.City;
                                    "Acc. Hold. Country/Region Code" := Vend."Country/Region Code";
                                end;
                            end;
                        "Account Type"::Employee:
                            begin
                                if (not Employee.Get(Bank)) or (Bank <> "Account No.") then
                                    Error(BankShouldBeEmployeeNoErr);
                                // As we don't have Employee Bank Accounts we retrieve information directly from employee.
                                Validate("Account Name", CopyStr(Employee.FullName(), 1, MaxStrLen("Account Name")));
                                Validate("Account Holder Name", CopyStr(Employee.FullName(), 1, MaxStrLen("Account Holder Name")));
                                Validate("Acc. Hold. Country/Region Code", Employee."Country/Region Code");
                                Validate("Account Holder City", Employee.City);
                                Validate("Account Holder Address", Employee.Address);
                                Validate("Account Holder Post Code", Employee."Post Code");
                                Validate("Bank Country/Region Code", Employee."Country/Region Code");
                                Validate("Bank Account No.", Employee."Bank Account No.");
                                Validate("Bank Name", Employee."Bank Name");
                                Validate("Bank City", Employee."Bank City");
                                IBAN := Employee.IBAN;
                                "SWIFT Code" := Employee."SWIFT Code";
                                Bank := Employee."No.";
                                "Bank Address" := '';
                            end;
                    end;
                    DimManagement.AddDimSource(DefaultDimSource, DimManagement.TypeToTableID1(GenJnlLine."Account Type"::"Bank Account".AsInteger()), "Our Bank No.");
                    CreateDim(DefaultDimSource, true);
                end;
                DetailFilter("Detail line", Rec);
                "Detail line".ModifyAll(Bank, Bank);
            end;
        }
        field(8; "Our Bank No."; Code[20])
        {
            Caption = 'Our Bank No.';
            Editable = false;
            TableRelation = "Bank Account"."No.";
        }
        field(9; "Order"; Option)
        {
            Caption = 'Order';
            Editable = false;
            OptionCaption = ' ,Debit,Credit';
            OptionMembers = " ",Debit,Credit;
        }
        field(11; "Description 1"; Text[32])
        {
            Caption = 'Description 1';
        }
        field(12; "Description 2"; Text[32])
        {
            Caption = 'Description 2';
        }
        field(13; "Description 3"; Text[32])
        {
            Caption = 'Description 3';
        }
        field(14; "Description 4"; Text[32])
        {
            Caption = 'Description 4';
        }
        field(15; Identification; Code[20])
        {
            Caption = 'Identification';

            trigger OnValidate()
            var
                TrMode: Record "Transaction Mode";
                NoSeries: Codeunit "No. Series";

            begin
                TrMode.Get("Account Type", "Transaction Mode");
                TrMode.TestField("Identification No. Series");
                "Identification No. Series" := TrMode."Identification No. Series";
                if Identification = '' then
                    Identification := NoSeries.GetNextNo("Identification No. Series", "Transaction Date")
                else
                    NoSeries.TestManual("Identification No. Series");
            end;
        }
        field(16; "Bank Account No."; Text[30])
        {
            Caption = 'Bank Account No.';
            NotBlank = true;

            trigger OnValidate()
            var
                LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
            begin
                if not LocalFunctionalityMgt.CheckBankAccNo("Bank Account No.", "Bank Country/Region Code", "Bank Account No.") then
                    Message(Text1000000, "Bank Account No.");
            end;
        }
        field(17; "Our Bank Account No."; Text[30])
        {
            CalcFormula = lookup("Bank Account"."Bank Account No." where("No." = field("Our Bank No.")));
            Caption = 'Our Bank Account No.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Transaction Mode"; Code[20])
        {
            Caption = 'Transaction Mode';
            NotBlank = true;
            TableRelation = "Transaction Mode".Code where("Account Type" = field("Account Type"));

            trigger OnValidate()
            var
                TrMode: Record "Transaction Mode";
                NoSeries: Codeunit "No. Series";
            begin
                if "Transaction Mode" <> xRec."Transaction Mode" then
                    TestDetailAvailable(FieldCaption("Our Bank No."));

                TrMode.Get("Account Type", "Transaction Mode");
                Order := TrMode.Order;
                "Transfer Cost Domestic" := TrMode."Transfer Cost Domestic";
                "Transfer Cost Foreign" := TrMode."Transfer Cost Foreign";

                if "Our Bank No." = '' then
                    Validate("Our Bank No.", TrMode."Our Bank");

                if Identification = '' then begin
                    TrMode.TestField("Identification No. Series");
                    "Identification No. Series" := TrMode."Identification No. Series";
                    Identification := NoSeries.GetNextNo("Identification No. Series", "Transaction Date");
                end;
            end;
        }
        field(19; "Number of Detail Lines"; Integer)
        {
            CalcFormula = count("Detail Line" where("Our Bank" = field("Our Bank No."),
                                                     "Connect Lines" = field("Line No.")));
            Caption = 'Number of Detail Lines';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Error Message"; Text[125])
        {
            Caption = 'Error Message';
        }
        field(22; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency.Code;
        }
        field(23; "Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
            Editable = false;
        }
        field(24; Process; Boolean)
        {
            Caption = 'Process';
            InitValue = true;
        }
        field(25; Warning; Text[125])
        {
            Caption = 'Warning';
        }
        field(26; "Identification No. Series"; Code[20])
        {
            Caption = 'Identification No. Series';
        }
        field(27; Docket; Boolean)
        {
            Caption = 'Docket';
        }
        field(100; "Account Holder Name"; Text[100])
        {
            Caption = 'Account Holder Name';
        }
        field(101; "Account Holder Address"; Text[100])
        {
            Caption = 'Account Holder Address';

            trigger OnValidate()
            var
                Address2: Text[50];
                PhoneNo: Text[30];
                FaxNo: Text[30];
            begin
                PostCodeMgt.FindStreetName(
                    "Account Holder Address", Address2, "Account Holder Post Code", "Account Holder City",
                    "Acc. Hold. Country/Region Code", PhoneNo, FaxNo);
            end;
        }
        field(102; "Account Holder Post Code"; Code[20])
        {
            Caption = 'Account Holder Post Code';
        }
        field(103; "Account Holder City"; Text[30])
        {
            Caption = 'Account Holder City';
        }
        field(104; "Acc. Hold. Country/Region Code"; Code[10])
        {
            Caption = 'Acc. Hold. Country/Region Code';
            TableRelation = "Country/Region".Code;
        }
        field(105; "National Bank Code"; Code[10])
        {
            Caption = 'National Bank Code';
        }
        field(106; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
        }
        field(110; "Nature of the Payment"; Option)
        {
            Caption = 'Nature of the Payment';
            InitValue = Goods;
            OptionCaption = ' ,Goods,Transito Trade,Invisible- and Capital Transactions,Transfer to Own Account,Other Registrated BFI';
            OptionMembers = " ",Goods,"Transito Trade","Invisible- and Capital Transactions","Transfer to Own Account","Other Registrated BFI";
        }
        field(111; "Registration No. DNB"; Text[8])
        {
            Caption = 'Registration No. DNB';
        }
        field(112; "Description Payment"; Text[30])
        {
            Caption = 'Description Payment';
        }
        field(113; "Item No."; Text[2])
        {
            Caption = 'Item No.';
        }
        field(114; "Traders No."; Text[4])
        {
            Caption = 'Traders No.';
        }
        field(115; Urgent; Boolean)
        {
            Caption = 'Urgent';
        }
        field(120; "Bank Name"; Text[100])
        {
            Caption = 'Bank Name';
        }
        field(121; "Bank Address"; Text[100])
        {
            Caption = 'Bank Address';
        }
        field(122; "Bank City"; Text[30])
        {
            Caption = 'Bank City';
        }
        field(123; "Bank Country/Region Code"; Code[10])
        {
            Caption = 'Bank Country/Region Code';
            TableRelation = "Country/Region".Code;
        }
        field(130; "Transfer Cost Domestic"; Option)
        {
            Caption = 'Transfer Cost Domestic';
            OptionCaption = 'Principal,Balancing Account Holder';
            OptionMembers = Principal,"Balancing Account Holder";
        }
        field(131; "Transfer Cost Foreign"; Option)
        {
            Caption = 'Transfer Cost Foreign';
            OptionCaption = 'Principal,Balancing Account Holder';
            OptionMembers = Principal,"Balancing Account Holder";
        }
        field(132; "Abbrev. National Bank Code"; Code[3])
        {
            Caption = 'Abbrev. National Bank Code';
        }
        field(133; IBAN; Code[50])
        {
            Caption = 'IBAN';

            trigger OnValidate()
            var
                CompanyInfo: Record "Company Information";
            begin
                CompanyInfo.CheckIBAN(IBAN);
            end;
        }
        field(134; "Direct Debit Mandate ID"; Code[35])
        {
            Caption = 'Direct Debit Mandate ID';
            TableRelation = "SEPA Direct Debit Mandate".ID where("Customer No." = field("Account No."),
                                                                  "Customer Bank Account Code" = field(Bank));
        }
        field(135; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = "Salesperson/Purchaser";

            trigger OnValidate()
            begin
                ValidateDim();
            end;
        }
        field(200; "Account Name"; Text[100])
        {
            Caption = 'Account Name';
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
        field(481; "Header Dimension Set ID"; Integer)
        {
            Caption = 'Header Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowHeaderDimensions();
            end;
        }
        field(11400; "Foreign Currency"; Code[10])
        {
            Caption = 'Foreign Currency';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if "Foreign Currency" <> xRec."Foreign Currency" then
                    "Foreign Amount" := GetAmountInDocumentCurrency(Rec);
            end;
        }
        field(11401; "Foreign Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Foreign Currency";
            Caption = 'Foreign Amount';
        }
        field(11402; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(11403; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(Key1; "Our Bank No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Our Bank No.", Process, "Account Type", "Account No.", Bank, "Transaction Mode", "Currency Code", "Transaction Date")
        {
            SumIndexFields = Amount, "Amount (LCY)";
        }
        key(Key3; "Our Bank No.", Identification)
        {
        }
        key(Key4; "Our Bank No.", "Account Type", "Account Name")
        {
        }
        key(Key5; "Account No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        "Detail line": Record "Detail Line";
    begin
        DetailFilter("Detail line", Rec);
        "Detail line".DeleteAll(false);
    end;

    trigger OnInsert()
    begin
        InitRecord();
    end;

    trigger OnRename()
    var
        "Detail line": Record "Detail Line";
    begin
        DetailFilter("Detail line", xRec);
        while "Detail line".Find('-') do begin
            "Detail line"."Our Bank" := "Our Bank No.";
            "Detail line"."Connect Lines" := "Line No.";
            "Detail line".Modify();
        end;
    end;

    var
        Text1000000: Label 'Bank Account No. %1 is not entered correctly.';
        Text1000001: Label '%1 cannot be modified, related detail information is available.';
        BankAcc: Record "Bank Account";
        DimManagement: Codeunit DimensionManagement;
        PostCodeMgt: Codeunit "Post Code Management";
        BankShouldBeEmployeeNoErr: Label 'The value in the Bank field must be the same as in the Account No. field, which is the employee number.';

    procedure GetSourceName() Name: Text
    var
        Custm: Record Customer;
        Vend: Record Vendor;
        Empl: Record Employee;
    begin
        if "Account No." <> '' then
            case "Account Type" of
                "Account Type"::Customer:
                    begin
                        Custm.Get("Account No.");
                        exit(Custm.Name);
                    end;
                "Account Type"::Vendor:
                    begin
                        Vend.Get("Account No.");
                        exit(Vend.Name);
                    end;
                "Account Type"::Employee:
                    begin
                        Empl.Get("Account No.");
                        exit(Empl.FullName());
                    end;
            end
        else
            exit('');
    end;

    [Scope('OnPrem')]
    procedure TestDetailAvailable("Field": Text[250])
    var
        "Detail line": Record "Detail Line";
    begin
        DetailFilter("Detail line", Rec);
        if "Detail line".Find('-') then
            Error(Text1000001, Field);
    end;

    [Scope('OnPrem')]
    procedure AmountLV() AmountLCY: Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        if "Currency Code" = '' then
            exit(Amount);

        AmountLCY := Round(CurrencyExchangeRate.ExchangeAmtFCYToFCY("Transaction Date", "Currency Code", '', Amount));
    end;

    procedure DetailFilter(var "Detail line": Record "Detail Line"; ProposalFilterRecord: Record "Proposal Line")
    begin
        "Detail line".Reset();
        "Detail line".SetCurrentKey("Our Bank", Status, "Connect Batches", "Connect Lines");
        "Detail line".SetRange("Our Bank", ProposalFilterRecord."Our Bank No.");
        "Detail line".SetRange(Status, "Detail line".Status::Proposal);
        "Detail line".SetRange("Connect Batches", '');
        "Detail line".SetRange("Connect Lines", ProposalFilterRecord."Line No.");
    end;

    [Scope('OnPrem')]
    procedure InitRecord()
    var
        ProposalLine: Record "Proposal Line";
    begin
        TestField("Our Bank No.");
        BankAcc.Get("Our Bank No.");
        "Currency Code" := BankAcc."Currency Code";
        if "Transaction Date" = 0D then
            "Transaction Date" := WorkDate() + 1;

        if ProposalLine.FindFirst() then
            "Header Dimension Set ID" := ProposalLine."Header Dimension Set ID";
    end;

    [Scope('OnPrem')]
    procedure IdentificationAssistEdit(OldProp: Record "Proposal Line"): Boolean
    var
        Prop: Record "Proposal Line";
        TrMode: Record "Transaction Mode";
        NoSeries: Codeunit "No. Series";
    begin
        Prop := Rec;
        TrMode.Get(Prop."Account Type", Prop."Transaction Mode");
        TrMode.TestField("Identification No. Series");
        if NoSeries.LookupRelatedNoSeries(TrMode."Identification No. Series", OldProp."Identification No. Series", Prop."Identification No. Series") then begin
            Prop.Identification := NoSeries.GetNextNo(Prop."Identification No. Series");
            Rec := Prop;
            exit(true);
        end;
    end;

    local procedure ValidateDim()
    var
        GenJnlLine: Record "Gen. Journal Line";
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        case "Account Type" of
            "Account Type"::Customer:
                begin
                    DimManagement.AddDimSource(DefaultDimSource, DimManagement.TypeToTableID1(GenJnlLine."Account Type"::Customer.AsInteger()), "Account No.");
                    DimManagement.AddDimSource(DefaultDimSource, Database::"Salesperson/Purchaser", "Salespers./Purch. Code");
                    CreateDim(DefaultDimSource, false);
                end;
            "Account Type"::Vendor:
                begin
                    DimManagement.AddDimSource(DefaultDimSource, DimManagement.TypeToTableID1(GenJnlLine."Account Type"::Vendor.AsInteger()), "Account No.");
                    DimManagement.AddDimSource(DefaultDimSource, Database::"Salesperson/Purchaser", "Salespers./Purch. Code");
                    CreateDim(DefaultDimSource, false);
                end;
            "Account Type"::Employee:
                begin
                    DimManagement.AddDimSource(DefaultDimSource, DimManagement.TypeToTableID1(GenJnlLine."Account Type"::Employee.AsInteger()), "Account No.");
                    DimManagement.AddDimSource(DefaultDimSource, Database::"Salesperson/Purchaser", "Salespers./Purch. Code");
                    CreateDim(DefaultDimSource, false);
                end;
        end;
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; HeaderDimSetID: Boolean)
    var
        ShortcutDimension1Code: Code[20];
        ShortcutDimension2Code: Code[20];
    begin
        if not HeaderDimSetID then begin
            "Shortcut Dimension 1 Code" := '';
            "Shortcut Dimension 2 Code" := '';
            "Dimension Set ID" :=
              DimManagement.GetDefaultDimID(DefaultDimSource, '', "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
        end else
            "Header Dimension Set ID" :=
              DimManagement.GetDefaultDimID(DefaultDimSource, '', ShortcutDimension1Code, ShortcutDimension2Code, 0, 0);
    end;

    [Scope('OnPrem')]
    procedure ValidateShortcutDimCode(FieldNo: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNo, ShortcutDimCode);
        DimManagement.ValidateShortcutDimValues(FieldNo, ShortcutDimCode, "Dimension Set ID");
    end;

    /// <summary>
    /// Integration event raised before validating a shortcut dimension code for proposal line.
    /// Enables custom dimension validation logic or preprocessing before standard validation.
    /// </summary>
    /// <param name="ProposalLine">Proposal line record being validated</param>
    /// <param name="xProposalLine">Previous proposal line record state</param>
    /// <param name="FieldNo">Field number of the dimension being validated</param>
    /// <param name="ShortcutDimCode">Dimension code being validated</param>
    /// <remarks>
    /// Raised from ValidateShortcutDimCode procedure before standard dimension validation.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var ProposalLine: Record "Proposal Line"; var xProposalLine: Record "Proposal Line"; FieldNo: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [Scope('OnPrem')]
    procedure LookupShortcutDimCode(FieldNo: Integer; var ShortcutDimCode: Code[20])
    begin
        DimManagement.LookupDimValueCode(FieldNo, ShortcutDimCode);
        Rec.ValidateShortcutDimCode(FieldNo, ShortcutDimCode);
    end;

    [Scope('OnPrem')]
    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimManagement.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
    end;

    [Scope('OnPrem')]
    procedure SelectAll()
    begin
        if Find('-') then
            repeat
                Process := true;
                Modify();
            until Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure DeselectAll()
    begin
        if Find('-') then
            repeat
                Process := false;
                Modify();
            until Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimManagement.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2', "Our Bank No.", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    [Scope('OnPrem')]
    procedure ShowHeaderDimensions()
    var
        HeaderGlobalDim1: Code[20];
        HeaderGlobalDim2: Code[20];
    begin
        "Header Dimension Set ID" :=
          DimManagement.EditDimensionSet(
            Rec, "Header Dimension Set ID", StrSubstNo('%1 %2', "Our Bank No.", "Line No."),
            HeaderGlobalDim1, HeaderGlobalDim2);
    end;

    local procedure GetCurrencyAmountRoundingPrecision(FCYCode: Code[10]): Decimal
    var
        Currency: Record Currency;
    begin
        Currency.Initialize(FCYCode);
        exit(Currency."Amount Rounding Precision");
    end;

    local procedure GetAmountInDocumentCurrency(ProposalLine: Record "Proposal Line"): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        if ("Foreign Currency" = '') and ("Currency Code" = '') then
            exit(0);
        if ProposalLine."Foreign Currency" = ProposalLine."Currency Code" then
            exit(ProposalLine.Amount);

        exit(Round(
            CurrencyExchangeRate.ExchangeAmtFCYToFCY(
                ProposalLine."Transaction Date", ProposalLine."Currency Code", ProposalLine."Foreign Currency", ProposalLine.Amount),
                GetCurrencyAmountRoundingPrecision(ProposalLine."Foreign Currency")))
    end;
}
