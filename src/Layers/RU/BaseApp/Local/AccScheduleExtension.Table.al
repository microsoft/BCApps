#pragma warning disable AA0247
table 26584 "Acc. Schedule Extension"
{
    Caption = 'Acc. Schedule Extension';
    LookupPageID = "Acc. Schedule Extensions";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(10; "Source Table"; Option)
        {
            Caption = 'Source Table';
            OptionCaption = 'VAT Entry,Value Entry,Customer Entry,Vendor Entry';
            OptionMembers = "VAT Entry","Value Entry","Customer Entry","Vendor Entry";

            trigger OnValidate()
            begin
                if "Source Table" <> xRec."Source Table" then
                    CheckFieldsValues();
            end;
        }
        field(15; "Amount Sign"; Option)
        {
            Caption = 'Amount Sign';
            OptionCaption = ' ,Positive,Negative';
            OptionMembers = " ",Positive,Negative;

            trigger OnValidate()
            begin
                ValidateFieldValue(CurrFieldNo);
            end;
        }
        field(16; "VAT Entry Type"; Option)
        {
            Caption = 'VAT Entry Type';
            OptionCaption = ' ,Purchase,Sale';
            OptionMembers = " ",Purchase,Sale;

            trigger OnValidate()
            begin
                ValidateFieldValue(CurrFieldNo);
            end;
        }
        field(17; "Prepayment Filter"; Option)
        {
            Caption = 'Prepayment Filter';
            OptionCaption = ' ,Yes,No';
            OptionMembers = " ",Yes,No;

            trigger OnValidate()
            begin
                ValidateFieldValue(CurrFieldNo);
            end;
        }
        field(18; "Reverse Sign"; Boolean)
        {
            Caption = 'Reverse Sign';

            trigger OnValidate()
            begin
                ValidateFieldValue(CurrFieldNo);
            end;
        }
        field(20; "VAT Amount Type"; Option)
        {
            Caption = 'VAT Amount Type';
            OptionCaption = ' ,Base,Amount,Total';
            OptionMembers = " ",Base,Amount,Total;

            trigger OnValidate()
            begin
                ValidateFieldValue(CurrFieldNo);
            end;
        }
        field(21; "VAT Bus. Post. Group Filter"; Text[100])
        {
            Caption = 'VAT Bus. Post. Group Filter';
            TableRelation = "VAT Business Posting Group";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                ValidateFieldValue(CurrFieldNo);
            end;
        }
        field(22; "VAT Prod. Post. Group Filter"; Text[100])
        {
            Caption = 'VAT Prod. Post. Group Filter';
            TableRelation = "VAT Product Posting Group";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                ValidateFieldValue(CurrFieldNo);
            end;
        }
        field(23; "VAT Type"; Option)
        {
            Caption = 'VAT Type';
            OptionCaption = ' ,Realized,Unrealized,Remaining Unrealized';
            OptionMembers = " ",Realized,Unrealized,"Remaining Unrealized";

            trigger OnValidate()
            begin
                ValidateFieldValue(CurrFieldNo);
            end;
        }
        field(27; "Liability Type"; Option)
        {
            Caption = 'Liability Type';
            OptionCaption = ' ,Short Term,Long Term';
            OptionMembers = " ","Short Term","Long Term";

            trigger OnValidate()
            begin
                ValidateFieldValue(CurrFieldNo);
                if "Liability Type" <> "Liability Type"::" " then
                    TestField("Due Date Filter", '');
            end;
        }
        field(30; "Location Filter"; Text[100])
        {
            Caption = 'Location Filter';

            trigger OnLookup()
            begin
                if "Source Table" = "Source Table"::"Value Entry" then
                    if PAGE.RunModal(0, Location) = ACTION::LookupOK then
                        "Location Filter" += Location.Code;
            end;

            trigger OnValidate()
            begin
                ValidateFieldValue(CurrFieldNo);
            end;
        }
        field(31; "Bin Filter"; Text[100])
        {
            Caption = 'Bin Filter';

            trigger OnValidate()
            begin
                ValidateFieldValue(CurrFieldNo);
            end;
        }
        field(32; "Value Entry Type Filter"; Option)
        {
            Caption = 'Value Entry Type Filter';
            OptionCaption = ' ,Direct Cost,Revaluation,Rounding,Indirect Cost,Variance';
            OptionMembers = " ","Direct Cost",Revaluation,Rounding,"Indirect Cost",Variance;

            trigger OnValidate()
            begin
                ValidateFieldValue(CurrFieldNo);
            end;
        }
        field(33; "Inventory Posting Group Filter"; Code[100])
        {
            Caption = 'Inventory Posting Group Filter';
            TableRelation = "Inventory Posting Group";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                ValidateFieldValue(CurrFieldNo);
            end;
        }
        field(34; "Item Charge No. Filter"; Code[100])
        {
            Caption = 'Item Charge No. Filter';
            TableRelation = "Item Charge";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                ValidateFieldValue(CurrFieldNo);
            end;
        }
        field(35; "Value Entry Amount Type"; Option)
        {
            Caption = 'Value Entry Amount Type';
            OptionCaption = ' ,Cost Posted to G/L,Sales Amount (Expected),Sales Amount (Actual),Cost Amount (Expected),Cost Amount (Actual),Cost Amount (Non-Invtbl.),Purchase Amount (Actual),Purchase Amount (Expected)';
            OptionMembers = " ","Cost Posted to G/L","Sales Amount (Expected)","Sales Amount (Actual)","Cost Amount (Expected)","Cost Amount (Actual)","Cost Amount (Non-Invtbl.)","Purchase Amount (Actual)","Purchase Amount (Expected)";

            trigger OnValidate()
            begin
                ValidateFieldValue(CurrFieldNo);
            end;
        }
        field(56; "Posting Group Filter"; Code[250])
        {
            Caption = 'Posting Group Filter';
            TableRelation = if ("Source Table" = const("Customer Entry")) "Customer Posting Group"
            else
            if ("Source Table" = const("Vendor Entry")) "Vendor Posting Group";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                ValidateFieldValue(CurrFieldNo);
            end;
        }
        field(57; "Posting Date Filter"; Code[20])
        {
            Caption = 'Posting Date Filter';

            trigger OnValidate()
            begin
                ValidateFieldValue(CurrFieldNo);
                AccSchedExtensionManagement.CheckDateFilter("Posting Date Filter");
            end;
        }
        field(58; "Due Date Filter"; Code[20])
        {
            Caption = 'Due Date Filter';

            trigger OnValidate()
            begin
                ValidateFieldValue(CurrFieldNo);
                TestField("Liability Type", "Liability Type"::" ");
                AccSchedExtensionManagement.CheckDateFilter("Due Date Filter");
            end;
        }
        field(59; "Document Type Filter"; Text[100])
        {
            Caption = 'Document Type Filter';

            trigger OnValidate()
            begin
                ValidateFieldValue(CurrFieldNo);
                case "Source Table" of
                    "Source Table"::"Customer Entry":
                        begin
                            CustLedgerEntry.SetFilter("Document Type", "Document Type Filter");
                            "Document Type Filter" := CustLedgerEntry.GetFilter("Document Type");
                        end;
                    "Source Table"::"Vendor Entry":
                        begin
                            VendLedgerEntry.SetFilter("Document Type", "Document Type Filter");
                            "Document Type Filter" := VendLedgerEntry.GetFilter("Document Type");
                        end;
                end;
            end;
        }
        field(60; "Gen. Bus. Post. Group Filter"; Text[100])
        {
            Caption = 'Gen. Bus. Post. Group Filter';
            TableRelation = "Gen. Business Posting Group";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                ValidateFieldValue(CurrFieldNo);
            end;
        }
        field(61; "Gen. Prod. Post. Group Filter"; Text[100])
        {
            Caption = 'Gen. Prod. Post. Group Filter';
            TableRelation = "Gen. Product Posting Group";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                ValidateFieldValue(CurrFieldNo);
            end;
        }
        field(62; "Object Type Filter"; Option)
        {
            Caption = 'Object Type Filter';
            OptionCaption = ' ,G/L Account,Customer,Vendor,Bank Account,Fixed Asset';
            OptionMembers = " ","G/L Account",Customer,Vendor,"Bank Account","Fixed Asset";

            trigger OnValidate()
            begin
                ValidateFieldValue(CurrFieldNo);
                if "Object Type Filter" <> xRec."Object Type Filter" then
                    "Object No. Filter" := '';
            end;
        }
        field(63; "Object No. Filter"; Text[250])
        {
            Caption = 'Object No. Filter';
            TableRelation = if ("Object Type Filter" = const("G/L Account")) "G/L Account"
            else
            if ("Object Type Filter" = const(Customer)) Customer
            else
            if ("Object Type Filter" = const(Vendor)) Vendor
            else
            if ("Object Type Filter" = const("Bank Account")) "Bank Account"
            else
            if ("Object Type Filter" = const("Fixed Asset")) "Fixed Asset";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                ValidateFieldValue(CurrFieldNo);
            end;
        }
        field(64; "VAT Allocation Type Filter"; Option)
        {
            Caption = 'VAT Allocation Type Filter';
            OptionCaption = ' ,VAT,WriteOff,Charge';
            OptionMembers = " ",VAT,WriteOff,Charge;

            trigger OnValidate()
            begin
                ValidateFieldValue(CurrFieldNo);
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnRename()
    begin
        Error(Text001, TableCaption);
    end;

    var
        Location: Record Location;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendLedgerEntry: Record "Vendor Ledger Entry";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'You cannot rename an %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        AccSchedExtensionManagement: Codeunit AccSchedExtensionManagement;

    [Scope('OnPrem')]
    procedure ValidateFieldValue(FieldNumber: Integer)
    begin
        case "Source Table" of
            "Source Table"::"VAT Entry":
                if not (FieldNumber in [
                                        FieldNo("VAT Entry Type"),
                                        FieldNo("Reverse Sign"),
                                        FieldNo("VAT Amount Type"),
                                        FieldNo("VAT Bus. Post. Group Filter"),
                                        FieldNo("VAT Prod. Post. Group Filter"),
                                        FieldNo("VAT Type"),
                                        FieldNo("Gen. Bus. Post. Group Filter"),
                                        FieldNo("Gen. Prod. Post. Group Filter"),
                                        FieldNo("Object Type Filter"),
                                        FieldNo("Object No. Filter"),
                                        FieldNo("VAT Allocation Type Filter"),
                                        FieldNo("Prepayment Filter")
                                        ])
                then
                    FieldError("Source Table");
            "Source Table"::"Value Entry":
                if not (FieldNumber in [
                                        FieldNo("Location Filter"),
                                        FieldNo("Value Entry Type Filter"),
                                        FieldNo("Inventory Posting Group Filter"),
                                        FieldNo("Item Charge No. Filter"),
                                        FieldNo("Value Entry Amount Type"),
                                        FieldNo("Reverse Sign"),
                                        FieldNo("Amount Sign")
                                        ])
                then
                    FieldError("Source Table");
            "Source Table"::"Customer Entry",
          "Source Table"::"Vendor Entry":
                if not (FieldNumber in [
                                        FieldNo("Posting Group Filter"),
                                        FieldNo("Posting Date Filter"),
                                        FieldNo("Liability Type"),
                                        FieldNo("Due Date Filter"),
                                        FieldNo("Document Type Filter"),
                                        FieldNo("Prepayment Filter"),
                                        FieldNo("Amount Sign"),
                                        FieldNo("Reverse Sign")
                                        ])
                then
                    FieldError("Source Table");
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckFieldsValues()
    begin
        case "Source Table" of
            "Source Table"::"VAT Entry":
                begin
                    TestField("Location Filter", '');
                    TestField("Value Entry Type Filter", 0);
                    TestField("Inventory Posting Group Filter", '');
                    TestField("Item Charge No. Filter", '');
                    TestField("Value Entry Amount Type", 0);
                    TestField("Amount Sign", 0);
                    TestField("Posting Group Filter", '');
                    TestField("Posting Date Filter", '');
                    TestField("Liability Type", 0);
                    TestField("Due Date Filter", '');
                    TestField("Document Type Filter", '');
                    TestField("Prepayment Filter", 0);
                    TestField("Amount Sign", 0);
                end;
            "Source Table"::"Value Entry":
                begin
                    TestField("VAT Entry Type", 0);
                    TestField("VAT Amount Type", 0);
                    TestField("VAT Bus. Post. Group Filter", '');
                    TestField("VAT Prod. Post. Group Filter", '');
                    TestField("VAT Type", 0);
                    TestField("Gen. Bus. Post. Group Filter", '');
                    TestField("Gen. Prod. Post. Group Filter", '');
                    TestField("Object Type Filter", 0);
                    TestField("Object No. Filter", '');
                    TestField("VAT Allocation Type Filter", 0);
                    TestField("Prepayment Filter", 0);
                    TestField("Posting Group Filter", '');
                    TestField("Posting Date Filter", '');
                    TestField("Liability Type", 0);
                    TestField("Due Date Filter", '');
                    TestField("Document Type Filter", '');
                    TestField("Prepayment Filter", 0);
                end;
            "Source Table"::"Customer Entry",
            "Source Table"::"Vendor Entry":
                begin
                    TestField("VAT Entry Type", 0);
                    TestField("VAT Amount Type", 0);
                    TestField("VAT Bus. Post. Group Filter", '');
                    TestField("VAT Prod. Post. Group Filter", '');
                    TestField("VAT Type", 0);
                    TestField("Gen. Bus. Post. Group Filter", '');
                    TestField("Gen. Prod. Post. Group Filter", '');
                    TestField("Object Type Filter", 0);
                    TestField("Object No. Filter", '');
                    TestField("VAT Allocation Type Filter", 0);
                    TestField("Location Filter", '');
                    TestField("Value Entry Type Filter", 0);
                    TestField("Inventory Posting Group Filter", '');
                    TestField("Item Charge No. Filter", '');
                    TestField("Value Entry Amount Type", 0);
                end;
        end;
    end;
}

