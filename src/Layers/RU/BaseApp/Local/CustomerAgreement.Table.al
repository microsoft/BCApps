#pragma warning disable AA0247
table 14902 "Customer Agreement"
{
    Caption = 'Customer Agreement';
    DataCaptionFields = "Customer No.", "No.";
    DrillDownPageID = "Customer Agreements";
    LookupPageID = "Customer Agreements";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            var
                NoSeries: Codeunit "No. Series";
            begin
                if "No." <> xRec."No." then begin
                    Cust.Get("Customer No.");
                    NoSeries.TestManual(Cust."Agreement Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(4; "External Agreement No."; Text[30])
        {
            Caption = 'External Agreement No.';
        }
        field(5; "Agreement Date"; Date)
        {
            Caption = 'Agreement Date';
        }
        field(6; Active; Boolean)
        {
            Caption = 'Active';
        }
        field(7; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                CheckDates();
            end;
        }
        field(8; "Expire Date"; Date)
        {
            Caption = 'Expire Date';

            trigger OnValidate()
            begin
                CheckDates();
            end;
        }
        field(9; "Agreement Group"; Code[20])
        {
            Caption = 'Agreement Group';
            TableRelation = "Agreement Group".Code where(Type = const(Sales));
        }
        field(10; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Customer No."));
        }
        field(12; Comment; Boolean)
        {
            CalcFormula = exist("Sales Comment Line" where("Document Type" = const(Agreement),
                                                            "No." = field("No.")));
            Caption = 'Comment';
            FieldClass = FlowField;
        }
        field(14; Contact; Text[100])
        {
            Caption = 'Contact';
        }
        field(15; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
        }
        field(16; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(17; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(20; "Credit Limit (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            Caption = 'Credit Limit (LCY)';

            trigger OnValidate()
            begin
                Cust.Get("Customer No.");
                if "Credit Limit (LCY)" > Cust."Credit Limit (LCY)" then
                    Error(Text007);
            end;
        }
        field(21; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            TableRelation = "Customer Posting Group";

            trigger OnValidate()
            begin
                if "Customer Posting Group" <> xRec."Customer Posting Group" then begin
                    SalesSetup.Get();
                    if not SalesSetup."Allow Alter Posting Groups" then
                        Error(Text12401, FieldCaption("Customer Posting Group"),
                          SalesSetup.FieldCaption("Allow Alter Posting Groups"), SalesSetup.TableCaption());
                end;
            end;
        }
        field(22; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(23; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";
        }
        field(24; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(27; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(28; "Fin. Charge Terms Code"; Code[10])
        {
            Caption = 'Fin. Charge Terms Code';
            TableRelation = "Finance Charge Terms";
        }
        field(29; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(30; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";
        }
        field(31; "Shipping Agent Code"; Code[10])
        {
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";

            trigger OnValidate()
            begin
                if "Shipping Agent Code" <> xRec."Shipping Agent Code" then
                    Validate("Shipping Agent Service Code", '');
            end;
        }
        field(34; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";
        }
        field(35; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
        }
        field(39; Blocked; Enum "Customer Blocked")
        {
            Caption = 'Blocked';
        }
        field(47; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
        }
        field(55; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(56; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(57; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(58; Balance; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            CalcFormula = sum("Detailed Cust. Ledg. Entry".Amount where("Customer No." = field("Customer No."),
                                                                         "Agreement No." = field("No.")));
            Caption = 'Balance';
            Editable = false;
            FieldClass = FlowField;
        }
        field(59; "Balance (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("Detailed Cust. Ledg. Entry"."Amount (LCY)" where("Customer No." = field("Customer No."),
                                                                                 "Agreement No." = field("No.")));
            Caption = 'Balance (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(60; "Net Change"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Cust. Ledg. Entry".Amount where("Customer No." = field("Customer No."),
                                                                         "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                         "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                         "Posting Date" = field("Date Filter"),
                                                                         "Agreement No." = field("No.")));
            Caption = 'Net Change';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Net Change (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("Detailed Cust. Ledg. Entry"."Amount (LCY)" where("Customer No." = field("Customer No."),
                                                                                 "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                 "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                 "Posting Date" = field("Date Filter"),
                                                                                 "Agreement No." = field("No.")));
            Caption = 'Net Change (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(83; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(88; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            begin
                if xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Gen. Bus. Posting Group") then
                        Validate("VAT Bus. Posting Group", GenBusPostingGrp."Def. VAT Bus. Posting Group");
            end;
        }
        field(97; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Detailed Cust. Ledg. Entry"."Debit Amount" where("Customer No." = field("Customer No."),
                                                                                 "Entry Type" = filter(<> Application),
                                                                                 "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                 "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                 "Posting Date" = field("Date Filter"),
                                                                                 "Agreement No." = field("No.")));
            Caption = 'Debit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(98; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Detailed Cust. Ledg. Entry"."Credit Amount" where("Customer No." = field("Customer No."),
                                                                                  "Entry Type" = filter(<> Application),
                                                                                  "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                  "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                  "Posting Date" = field("Date Filter"),
                                                                                  "Agreement No." = field("No.")));
            Caption = 'Credit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(99; "Debit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            CalcFormula = sum("Detailed Cust. Ledg. Entry"."Debit Amount (LCY)" where("Customer No." = field("Customer No."),
                                                                                       "Entry Type" = filter(<> Application),
                                                                                       "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                       "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                       "Posting Date" = field("Date Filter"),
                                                                                       "Agreement No." = field("No.")));
            Caption = 'Debit Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(100; "Credit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            CalcFormula = sum("Detailed Cust. Ledg. Entry"."Credit Amount (LCY)" where("Customer No." = field("Customer No."),
                                                                                        "Entry Type" = filter(<> Application),
                                                                                        "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                        "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                        "Posting Date" = field("Date Filter"),
                                                                                        "Agreement No." = field("No.")));
            Caption = 'Credit Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(102; "E-Mail"; Text[80])
        {
            Caption = 'Email';
        }
        field(107; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(110; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
        }
        field(5750; "Shipping Advice"; Enum "Sales Header Shipping Advice")
        {
            Caption = 'Shipping Advice';
        }
        field(5790; "Shipping Time"; DateFormula)
        {
            Caption = 'Shipping Time';
        }
        field(5792; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));

            trigger OnValidate()
            begin
                if ("Shipping Agent Code" <> '') and
                   ("Shipping Agent Service Code" <> '')
                then
                    if ShippingAgentService.Get("Shipping Agent Code", "Shipping Agent Service Code") then
                        "Shipping Time" := ShippingAgentService."Shipping Time"
                    else
                        Evaluate("Shipping Time", '<>');
            end;
        }
        field(12400; "Default Bank Code"; Code[20])
        {
            Caption = 'Default Bank Code';
            TableRelation = "Customer Bank Account".Code where("Customer No." = field("Customer No."));
        }
        field(12422; "G/L Account Filter"; Code[20])
        {
            Caption = 'G/L Account Filter';
            FieldClass = FlowFilter;
            TableRelation = "G/L Account";
        }
        field(12423; "G/L Starting Date Filter"; Date)
        {
            Caption = 'G/L Starting Date Filter';
            FieldClass = FlowFilter;
        }
        field(12424; "G/L Starting Balance"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            CalcFormula = sum("G/L Entry".Amount where("Source Type" = const(Customer),
                                                        "Source No." = field("Customer No."),
                                                        "G/L Account No." = field("G/L Account Filter"),
                                                        "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                        "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                        "Agreement No." = field("No."),
                                                        "Posting Date" = field(upperlimit("G/L Starting Date Filter"))));
            Caption = 'G/L Starting Balance';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12425; "G/L Net Change"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            CalcFormula = sum("G/L Entry".Amount where("Source Type" = const(Customer),
                                                        "Source No." = field("Customer No."),
                                                        "G/L Account No." = field("G/L Account Filter"),
                                                        "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                        "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                        "Agreement No." = field("No."),
                                                        "Posting Date" = field("Date Filter")));
            Caption = 'G/L Net Change';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12426; "G/L Debit Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            CalcFormula = sum("G/L Entry"."Debit Amount" where("Source Type" = const(Customer),
                                                                "Source No." = field("Customer No."),
                                                                "G/L Account No." = field("G/L Account Filter"),
                                                                "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                "Agreement No." = field("No."),
                                                                "Posting Date" = field("Date Filter")));
            Caption = 'G/L Debit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12427; "G/L Credit Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            CalcFormula = sum("G/L Entry"."Credit Amount" where("Source Type" = const(Customer),
                                                                 "Source No." = field("Customer No."),
                                                                 "G/L Account No." = field("G/L Account Filter"),
                                                                 "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                 "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                 "Agreement No." = field("No."),
                                                                 "Posting Date" = field("Date Filter")));
            Caption = 'G/L Credit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12428; "G/L Balance to Date"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            CalcFormula = sum("G/L Entry".Amount where("Source Type" = const(Customer),
                                                        "Source No." = field("Customer No."),
                                                        "G/L Account No." = field("G/L Account Filter"),
                                                        "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                        "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                        "Agreement No." = field("No."),
                                                        "Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'G/L Balance to Date';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Customer No.", "No.")
        {
            Clustered = true;
        }
        key(Key2; "Agreement Group", "No.")
        {
        }
        key(Key3; "No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        CustLedgEntry.Reset();
        CustLedgEntry.SetRange("Customer No.", "Customer No.");
        CustLedgEntry.SetRange("Agreement No.", "No.");
        if CustLedgEntry.FindFirst() then
            Error(Text001);

        SalesSetup.Get();
        if DimValue.Get(SalesSetup."Customer Agreement Dim. Code", "No.") then
            DimValue.Delete();
    end;

    trigger OnInsert()
    var
        NoSeries: Codeunit "No. Series";
    begin
        Cust.Get("Customer No.");
        Cust.TestField("Agreement Posting", Cust."Agreement Posting"::Mandatory);
        if "No." = '' then begin
            Cust.TestField("Agreement Nos.");
                "No. Series" := Cust."Agreement Nos.";
                if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                    "No. Series" := xRec."No. Series";
                "No." := NoSeries.GetNextNo("No. Series");
            Description := StrSubstNo('%1 %2', Text12400, "No.");
        end;

        CustAgrmt.Reset();
        CustAgrmt.SetCurrentKey("No.");
        CustAgrmt.SetRange("No.", "No.");
        if CustAgrmt.FindSet() then
            repeat
                if CustAgrmt."Customer No." <> "Customer No." then
                    Error(Text12403, FieldCaption("No."), CustAgrmt."Customer No.");
            until CustAgrmt.Next() = 0;

        CustTransferFields();
        CustTransferDimensions();

        SalesSetup.Get();
        if SalesSetup."Synch. Agreement Dimension" then begin
            SalesSetup.TestField("Customer Agreement Dim. Code");

            DimValue.Init();
            DimValue."Dimension Code" := SalesSetup."Customer Agreement Dim. Code";
            DimValue.Code := "No.";
            DimValue.Name := CopyStr("No.", 1, MaxStrLen(DimValue.Name));
            if DimValue.Insert() then;

            DefaultDim2.Init();
            DefaultDim2."Table ID" := DATABASE::"Customer Agreement";
            DefaultDim2."No." := "No.";
            DefaultDim2."Dimension Code" := SalesSetup."Customer Agreement Dim. Code";
            DefaultDim2."Dimension Value Code" := "No.";
            DefaultDim2."Value Posting" := DefaultDim2."Value Posting"::"Same Code";
            if DefaultDim2.Insert() then;
        end;
    end;

    trigger OnModify()
    begin
        SalesSetup.Get();
        if DimValue.Get(SalesSetup."Customer Agreement Dim. Code", "No.") then begin
            DimValue.Name := CopyStr("No.", 1, MaxStrLen(DimValue.Name));
            if Blocked <> Blocked::" " then
                DimValue.Blocked := true
            else
                DimValue.Blocked := false;
            DimValue.Modify();
        end;
    end;

    trigger OnRename()
    begin
        Error(Text003, TableCaption);
    end;

    var
#pragma warning disable AA0074
        Text001: Label 'You cannot delete agreement if you already have ledger entries.';
#pragma warning restore AA0074
        SalesSetup: Record "Sales & Receivables Setup";
        Cust: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        DimValue: Record "Dimension Value";
        GenBusPostingGrp: Record "Gen. Business Posting Group";
        DefaultDim: Record "Default Dimension";
        DefaultDim2: Record "Default Dimension";
        CustAgrmt: Record "Customer Agreement";
        ShippingAgentService: Record "Shipping Agent Services";
        DimMgt: Codeunit DimensionManagement;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label 'You cannot rename %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text004: Label 'post';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text005: Label 'create';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text006: Label 'You cannot %1 this type of document when Customer %2 is blocked with type %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text007: Label 'Agreement credit limit should not exceed Customer credit limit.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text12400: Label 'Agreement';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12401: Label 'You cannot change %1 until you check %2 in %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12402: Label '%1 should be later than %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12403: Label 'This %1 already used for customer %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        PrivacyBlockedActionErr: Label 'You cannot %1 this type of document when Customer %2 is blocked for privacy.', Comment = '%1 = action (create or post), %2 = customer code.';

    [Scope('OnPrem')]
    procedure AssistEdit(OldCustAgreement: Record "Customer Agreement"): Boolean
    var
        NoSeries: Codeunit "No. Series";
    begin
        Cust.Get("Customer No.");
        Cust.TestField("Agreement Nos.");
        if NoSeries.LookupRelatedNoSeries(Cust."Agreement Nos.", OldCustAgreement."No. Series", "No. Series") then begin
            "No." := NoSeries.GetNextNo("No. Series");
            exit(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::"Customer Agreement", "No.", FieldNumber, ShortcutDimCode);
            Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then
            DimMgt.SaveDefaultDim(DATABASE::"Customer Agreement", "No.", FieldNumber, ShortcutDimCode);
    end;

    [Scope('OnPrem')]
    procedure CheckBlockedCustOnDocs(Cust2: Record Customer; DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; Shipment: Boolean; Transaction: Boolean)
    begin
        if Cust2."Privacy Blocked" then
            CustPrivacyBlockedErrorMessage(Cust2, Transaction);

        if ((Cust2.Blocked in [Cust2.Blocked::All]) or
            ((Cust2.Blocked = Cust2.Blocked::Invoice) and
             (DocType in [DocType::Quote, DocType::Order, DocType::Invoice, DocType::"Blanket Order"])) or
            ((Cust2.Blocked = Cust2.Blocked::Ship) and
             (DocType in [DocType::Quote, DocType::Order, DocType::"Blanket Order"]) and
             (not Transaction)) or
            ((Cust2.Blocked = Cust2.Blocked::Ship) and
             (DocType in [DocType::Quote, DocType::Order, DocType::Invoice, DocType::"Blanket Order"]) and
             Shipment and Transaction))
        then
            CustBlockedErrorMessage(Cust2, Transaction);
    end;

    [Scope('OnPrem')]
    procedure CheckBlockedCustOnJnls(Cust2: Record Customer; DocType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge",Reminder,Refund; Transaction: Boolean)
    begin
        if Cust2."Privacy Blocked" then
            CustPrivacyBlockedErrorMessage(Cust2, Transaction);

        if (Cust2.Blocked in [Cust2.Blocked::All]) or
           ((Cust2.Blocked = Cust2.Blocked::Invoice) and (DocType in [DocType::Invoice, DocType::" "]))
        then
            CustBlockedErrorMessage(Cust2, Transaction)
    end;

    [Scope('OnPrem')]
    procedure CustBlockedErrorMessage(Cust2: Record Customer; Transaction: Boolean)
    var
        "Action": Text[30];
    begin
        if Transaction then
            Action := Text004
        else
            Action := Text005;
        Error(Text006, Action, Cust2."No.", Cust2.Blocked);
    end;

    [Scope('OnPrem')]
    procedure CustPrivacyBlockedErrorMessage(Cust2: Record Customer; Transaction: Boolean)
    var
        "Action": Text[30];
    begin
        if Transaction then
            Action := Text004
        else
            Action := Text005;

        Error(PrivacyBlockedActionErr, Action, Cust2."No.");
    end;

    [Scope('OnPrem')]
    procedure CustTransferFields()
    begin
        Contact := Cust.Contact;
        "Phone No." := Cust."Phone No.";
        "E-Mail" := Cust."E-Mail";
        Blocked := Cust.Blocked;
        "Customer Posting Group" := Cust."Customer Posting Group";
        "Gen. Bus. Posting Group" := Cust."Gen. Bus. Posting Group";
        "VAT Bus. Posting Group" := Cust."VAT Bus. Posting Group";
        "Global Dimension 1 Code" := Cust."Global Dimension 1 Code";
        "Global Dimension 2 Code" := Cust."Global Dimension 2 Code";
        "Credit Limit (LCY)" := Cust."Credit Limit (LCY)";
        "Currency Code" := Cust."Currency Code";
        "Customer Price Group" := Cust."Customer Price Group";
        "Customer Disc. Group" := Cust."Customer Disc. Group";
        "Prices Including VAT" := Cust."Prices Including VAT";
        "Language Code" := Cust."Language Code";
        "Payment Terms Code" := Cust."Payment Terms Code";
        "Payment Method Code" := Cust."Payment Method Code";
        "Fin. Charge Terms Code" := Cust."Fin. Charge Terms Code";
        "Salesperson Code" := Cust."Salesperson Code";
        "Shipment Method Code" := Cust."Shipment Method Code";
        "Location Code" := Cust."Location Code";
        "Responsibility Center" := Cust."Responsibility Center";
        "Shipping Advice" := Cust."Shipping Advice";
        "Shipping Agent Code" := Cust."Shipping Agent Code";
        "Shipping Agent Service Code" := Cust."Shipping Agent Service Code";
        "Shipping Time" := Cust."Shipping Time";
        "Default Bank Code" := Cust."Default Bank Code";
    end;

    [Scope('OnPrem')]
    procedure CustTransferDimensions()
    begin
        DefaultDim.Reset();
        DefaultDim.SetRange("Table ID", DATABASE::Customer);
        DefaultDim.SetRange("No.", "Customer No.");
        if DefaultDim.FindSet() then
            repeat
                DefaultDim2.Init();
                DefaultDim2."Table ID" := DATABASE::"Customer Agreement";
                DefaultDim2."No." := "No.";
                DefaultDim2."Dimension Code" := DefaultDim."Dimension Code";
                DefaultDim2."Dimension Value Code" := DefaultDim."Dimension Value Code";
                DefaultDim2."Value Posting" := DefaultDim."Value Posting";
                DefaultDim2.Insert();
            until DefaultDim.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CheckDates()
    begin
        if ("Expire Date" <> 0D) and ("Starting Date" <> 0D) and ("Expire Date" < "Starting Date") then
            Error(Text12402, FieldCaption("Expire Date"), FieldCaption("Starting Date"));
    end;

    [Scope('OnPrem')]
    procedure GetDefaultDimSetID(DimSetID: Integer; var ShortcutDim1Code: Code[20]; var ShortcutDim2Code: Code[20]): Integer
    var
        AgrmtMgt: Codeunit "Agreement Management";
        DimSetIDArr: array[10] of Integer;
    begin
        DimSetIDArr[1] := DimSetID;
        DimSetIDArr[2] := AgrmtMgt.GetAgrmtDefaultDimSetID(DATABASE::"Customer Agreement", "No.");
        exit(
          DimMgt.GetCombinedDimensionSetID(
            DimSetIDArr, ShortcutDim1Code, ShortcutDim2Code));
    end;
}
