#pragma warning disable AA0247
table 12404 "VAT Ledger"
{
    Caption = 'VAT Ledger';
    LookupPageID = "VAT Ledger List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Purchase,Sales';
            OptionMembers = Purchase,Sales;
        }
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';

            trigger OnValidate()
            var
                NoSeries: Codeunit "No. Series";
            begin
                if Code <> xRec.Code then begin
                    CheckVATLedgerStatus();
                    GLSetup.Get();
                    if Type = Type::Purchase then
                        NoSeries.TestManual(GLSetup."VAT Purch. Ledger No. Series")
                    else
                        NoSeries.TestManual(GLSetup."VAT Sales Ledger No. Series");
                    "No. Series" := '';
                end;
            end;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                CheckVATLedgerStatus();
            end;
        }
        field(4; "Start Date"; Date)
        {
            Caption = 'Start Date';

            trigger OnValidate()
            begin
                CheckVATLedgerStatus();
                ComposeDescription();
            end;
        }
        field(5; "End Date"; Date)
        {
            Caption = 'End Date';

            trigger OnValidate()
            begin
                CheckVATLedgerStatus();
                ComposeDescription();
            end;
        }
        field(6; "From No."; Integer)
        {
            CalcFormula = min("VAT Ledger Line"."Line No." where(Type = field(Type),
                                                                  Code = field(Code)));
            Caption = 'From No.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "To No."; Integer)
        {
            CalcFormula = max("VAT Ledger Line"."Line No." where(Type = field(Type),
                                                                  Code = field(Code)));
            Caption = 'To No.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "No. Series"; Code[10])
        {
            Caption = 'No. Series';
            Editable = false;

            trigger OnValidate()
            begin
                CheckVATLedgerStatus();
            end;
        }
        field(9; "Accounting Period"; Date)
        {
            Caption = 'Accounting Period';
            TableRelation = "Accounting Period";

            trigger OnValidate()
            begin
                CheckVATLedgerStatus();
                AccPeriod.Get("Accounting Period");
                Validate("Start Date", AccPeriod."Starting Date");
                if AccPeriod.Next() > 0 then
                    Validate("End Date", CalcDate('<-1D>', AccPeriod."Starting Date"))
                else
                    Error(Text12405);
            end;
        }
        field(10; "Start Page No."; Integer)
        {
            Caption = 'Start Page No.';

            trigger OnValidate()
            begin
                CheckVATLedgerStatus();
            end;
        }
        field(20; "C/V Filter"; Text[250])
        {
            Caption = 'C/V Filter';
            TableRelation = if (Type = const(Purchase)) Vendor
            else
            if (Type = const(Sales)) Customer;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                CheckVATLedgerStatus();
            end;
        }
        field(21; "VAT Product Group Filter"; Text[250])
        {
            Caption = 'VAT Product Group Filter';
            TableRelation = "VAT Product Posting Group";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                CheckVATLedgerStatus();
            end;
        }
        field(22; "VAT Business Group Filter"; Text[250])
        {
            Caption = 'VAT Business Group Filter';
            TableRelation = "VAT Business Posting Group";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                CheckVATLedgerStatus();
            end;
        }
        field(23; "Purchase Sorting"; Option)
        {
            Caption = 'Purchase Sorting';
            OptionCaption = ' ,Document Date,Document No.,Last Date';
            OptionMembers = " ","Document Date","Document No.","Last Date";

            trigger OnValidate()
            begin
                CheckVATLedgerStatus();
            end;
        }
        field(24; "Sales Sorting"; Option)
        {
            Caption = 'Sales Sorting';
            OptionCaption = ' ,Document Date,Document No.,Customer No.';
            OptionMembers = " ","Document Date","Document No.","Customer No.";

            trigger OnValidate()
            begin
                CheckVATLedgerStatus();
            end;
        }
        field(25; "Use External Doc. No."; Boolean)
        {
            Caption = 'Use External Doc. No.';

            trigger OnValidate()
            begin
                CheckVATLedgerStatus();
            end;
        }
        field(26; "Clear Lines"; Boolean)
        {
            Caption = 'Clear Lines';

            trigger OnValidate()
            begin
                CheckVATLedgerStatus();
            end;
        }
        field(27; "Start Numbering"; Integer)
        {
            Caption = 'Start Numbering';

            trigger OnValidate()
            begin
                CheckVATLedgerStatus();
            end;
        }
        field(28; "Other Rates"; Option)
        {
            Caption = 'Other Rates';
            OptionCaption = 'Do Not Show,Summarized,Detailed';
            OptionMembers = "Do Not Show",Summarized,Detailed;

            trigger OnValidate()
            begin
                CheckVATLedgerStatus();
            end;
        }
        field(29; "Show Realized VAT"; Boolean)
        {
            Caption = 'Show Realized VAT';

            trigger OnValidate()
            begin
                CheckVATLedgerStatus();
            end;
        }
        field(30; "Show Unrealized VAT"; Boolean)
        {
            Caption = 'Show Unrealized VAT';

            trigger OnValidate()
            begin
                CheckVATLedgerStatus();
            end;
        }
        field(31; "Show Amount Differences"; Boolean)
        {
            Caption = 'Show Amount Differences';

            trigger OnValidate()
            begin
                CheckVATLedgerStatus();
            end;
        }
        field(32; "Show Customer Prepayments"; Boolean)
        {
            Caption = 'Show Customer Prepayments';

            trigger OnValidate()
            begin
                CheckVATLedgerStatus();
            end;
        }
        field(33; "Show Vendor Prepayments"; Boolean)
        {
            Caption = 'Show Vendor Prepayments';

            trigger OnValidate()
            begin
                CheckVATLedgerStatus();
            end;
        }
        field(34; "Show VAT Reinstatement"; Boolean)
        {
            Caption = 'Show VAT Reinstatement';

            trigger OnValidate()
            begin
                CheckVATLedgerStatus();
            end;
        }
        field(35; "Total VAT Amt VAT Purch Ledger"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Total VAT Amt VAT Purch Ledger';
        }
        field(36; "Tot Base18 Amt VAT Sales Ledg"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Tot Base18 Amt VAT Sales Ledg';
        }
        field(37; "Tot Base 10 Amt VAT Sales Ledg"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Tot Base 10 Amt VAT Sales Ledg';
        }
        field(38; "Tot Base 0 Amt VAT Sales Ledg"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Tot Base 0 Amt VAT Sales Ledg';
        }
        field(39; "Total VAT18 Amt VAT Sales Ledg"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Total VAT18 Amt VAT Sales Ledg';
        }
        field(40; "Total VAT10 Amt VAT Sales Ledg"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Total VAT10 Amt VAT Sales Ledg';
        }
        field(41; "Total VATExempt Amt VAT S Ledg"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Total VATExempt Amt VAT S Ledg';
        }
        field(42; "Tot Base20 Amt VAT Sales Ledg"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Tot Base20 Amt VAT Sales Ledg';
        }
        field(43; "Total VAT20 Amt VAT Sales Ledg"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Total VAT20 Amt VAT Sales Ledg';
        }
    }

    keys
    {
        key(Key1; Type, "Code")
        {
            Clustered = true;
        }
        key(Key2; Type, "Start Date")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        VATLedgerLine.SetRange(Type, Type);
        VATLedgerLine.SetRange(Code, Code);
        VATLedgerLine.DeleteAll();

        case Type of
            Type::Purchase:
                begin
                    VATLedgerConnection.SetRange("Purch. Ledger Code", Code);
                    VATLedgerConnection.DeleteAll();
                end;
            Type::Sales:
                begin
                    VATLedgerConnection.SetRange("Sales Ledger Code", Code);
                    VATLedgerConnection.DeleteAll();
                end;
        end;
    end;

    trigger OnInsert()
    var
        NoSeries: Codeunit "No. Series";
    begin
        if Code = '' then begin
            GLSetup.Get();
            if Type = Type::Purchase then begin
                GLSetup.TestField("VAT Purch. Ledger No. Series");
                    "No. Series" := GLSetup."VAT Purch. Ledger No. Series";
                    if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                        "No. Series" := xRec."No. Series";
                    Code := NoSeries.GetNextNo("No. Series");
            end else begin
                GLSetup.TestField("VAT Sales Ledger No. Series");
                    "No. Series" := GLSetup."VAT Sales Ledger No. Series";
                    if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                        "No. Series" := xRec."No. Series";
                    Code := NoSeries.GetNextNo("No. Series");
            end;
        end;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerConnection: Record "VAT Ledger Connection";
        AccPeriod: Record "Accounting Period";
#pragma warning disable AA0074
        Text12404: Label 'You cannot change fields for already created ledger.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text12405: Label 'Please create next accounting period.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12406: Label 'VAT Purchase Ledger for period from %1 to %2';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12407: Label 'VAT Sales Ledger for period from %1 to %2';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure AssistEdit(OldVATLedger: Record "VAT Ledger"): Boolean
    var
        NoSeries: Codeunit "No. Series";
    begin
        VATLedger := Rec;
        GLSetup.Get();
        if VATLedger.Type = VATLedger.Type::Purchase then begin
            GLSetup.TestField("VAT Purch. Ledger No. Series");
            if NoSeries.LookupRelatedNoSeries(GLSetup."VAT Purch. Ledger No. Series", OldVATLedger."No. Series", VATLedger."No. Series") then begin
                VATLedger.Code := NoSeries.GetNextNo(VATLedger."No. Series");
                Rec := VATLedger;
                exit(true);
            end;
        end else begin
            GLSetup.TestField("VAT Sales Ledger No. Series");
            if NoSeries.LookupRelatedNoSeries(GLSetup."VAT Sales Ledger No. Series", OldVATLedger."No. Series", VATLedger."No. Series") then begin
                VATLedger.Code := NoSeries.GetNextNo(VATLedger."No. Series");
                Rec := VATLedger;
                exit(true);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure ComposeDescription()
    begin
        if Type = Type::Purchase then
            Description := StrSubstNo(Text12406, "Start Date", "End Date")
        else
            Description := StrSubstNo(Text12407, "Start Date", "End Date");
    end;

    [Scope('OnPrem')]
    procedure CheckVATLedgerStatus()
    begin
        CalcFields("To No.");
        if "To No." > 0 then
            Error(Text12404);
    end;

    [Scope('OnPrem')]
    procedure CreateVATLedger()
    var
        CreateVATPurchaseLedger: Report "Create VAT Purchase Ledger";
        CreateVATSalesLedger: Report "Create VAT Sales Ledger";
    begin
        VATLedger := Rec;
        VATLedger.SetRecFilter();
        case Type of
            Type::Sales:
                begin
                    CreateVATSalesLedger.SetParameters(
                      "C/V Filter",
                      "VAT Product Group Filter",
                      "VAT Business Group Filter",
                      "Sales Sorting",
                      "Clear Lines",
                      "Show Realized VAT",
                      "Show Unrealized VAT",
                      "Show Customer Prepayments",
                      "Show Amount Differences",
                      "Show Vendor Prepayments",
                      "Show VAT Reinstatement");
                    CreateVATSalesLedger.SetTableView(VATLedger);
                    CreateVATSalesLedger.RunModal();
                end;
            Type::Purchase:
                begin
                    CreateVATPurchaseLedger.SetParameters(
                      "C/V Filter",
                      "VAT Product Group Filter",
                      "VAT Business Group Filter",
                      "Purchase Sorting",
                      "Use External Doc. No.",
                      "Clear Lines",
                      "Start Numbering",
                      "Other Rates",
                      "Show Realized VAT",
                      "Show Unrealized VAT",
                      "Show Amount Differences",
                      "Show Customer Prepayments");
                    CreateVATPurchaseLedger.SetTableView(VATLedger);
                    CreateVATPurchaseLedger.RunModal();
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateAddSheet()
    var
        CreateVATPurchLedAdSh: Report "Create VAT Purch. Led. Ad. Sh.";
        CreateVATSalesLedAdSh: Report "Create VAT Sales Led. Ad. Sh.";
    begin
        VATLedger := Rec;
        VATLedger.SetRecFilter();
        case Type of
            Type::Sales:
                begin
                    CreateVATSalesLedAdSh.SetParameters(
                      "C/V Filter",
                      "VAT Product Group Filter",
                      "VAT Business Group Filter",
                      "Sales Sorting",
                      "Clear Lines",
                      "Show Realized VAT",
                      "Show Unrealized VAT",
                      "Show Customer Prepayments",
                      "Show Amount Differences",
                      "Show Vendor Prepayments");
                    CreateVATSalesLedAdSh.SetTableView(VATLedger);
                    CreateVATSalesLedAdSh.RunModal();
                end;
            Type::Purchase:
                begin
                    CreateVATPurchLedAdSh.SetParameters(
                      "C/V Filter",
                      "VAT Product Group Filter",
                      "VAT Business Group Filter",
                      "Purchase Sorting",
                      "Use External Doc. No.",
                      "Clear Lines",
                      "Start Numbering",
                      "Other Rates",
                      "Show Realized VAT",
                      "Show Unrealized VAT",
                      "Show Amount Differences",
                      "Show Customer Prepayments");
                    CreateVATPurchLedAdSh.SetTableView(VATLedger);
                    CreateVATPurchLedAdSh.RunModal();
                end;
        end;
    end;
}
