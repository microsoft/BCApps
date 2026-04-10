#pragma warning disable AA0247
table 12405 "VAT Ledger Line"
{
    Caption = 'VAT Ledger Line';
    Permissions = tabledata "VAT Ledger Line Tariff No." = d,
                  tabledata "VAT Ledger Line CD No." = d,
                  tabledata "VAT Ledger Connection" = d;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Purchase,Sales';
            OptionMembers = Purchase,Sales;
            TableRelation = "VAT Ledger".Type;
        }
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';
            TableRelation = "VAT Ledger".Code where(Type = field(Type));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "C/V No."; Code[20])
        {
            Caption = 'C/V No.';
            TableRelation = if ("C/V Type" = const(Vendor)) Vendor
            else
            if ("C/V Type" = const(Customer)) Customer;
        }
        field(5; "C/V Name"; Text[250])
        {
            Caption = 'C/V Name';
        }
        field(6; "C/V VAT Reg. No."; Code[20])
        {
            Caption = 'C/V VAT Reg. No.';
        }
        field(7; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(8; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(9; "Document No."; Code[30])
        {
            Caption = 'Document No.';
        }
        field(10; "Amount Including VAT"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount Including VAT';
        }
        field(11; Base20; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Base20';
        }
        field(12; Amount20; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount20';
        }
        field(13; Base10; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Base10';
        }
        field(14; Amount10; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount10';
        }
        field(15; Base0; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Base0';
        }
        field(16; "Base VAT Exempt"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Base VAT Exempt';
        }
        field(17; "Full VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Full VAT Amount';
        }
        field(18; "Excise Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Excise Amount';
        }
        field(19; "VAT Percent"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT Percent';
        }
        field(20; Method; Option)
        {
            Caption = 'Method';
            OptionCaption = 'Shipment,Payment';
            OptionMembers = Shipment,Payment;
        }
        field(22; "Transaction/Entry No."; Integer)
        {
            Caption = 'Transaction/Entry No.';
        }
        field(23; "Unreal. VAT Entry Date"; Date)
        {
            Caption = 'Unreal. VAT Entry Date';
        }
        field(24; "Real. VAT Entry Date"; Date)
        {
            Caption = 'Real. VAT Entry Date';
        }
        field(25; "C/V Posting Group"; Code[20])
        {
            Caption = 'C/V Posting Group';
        }
        field(26; "VAT Product Posting Group"; Code[20])
        {
            Caption = 'VAT Product Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(27; "VAT Business Posting Group"; Code[20])
        {
            Caption = 'VAT Business Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(28; "Origin. Document No."; Code[20])
        {
            Caption = 'Origin. Document No.';
        }
        field(29; Prepayment; Boolean)
        {
            Caption = 'Prepayment';
        }
        field(30; "Receipt Date"; Date)
        {
            Caption = 'Receipt Date';
        }
        field(31; "Country/Region of Origin Code"; Code[10])
        {
            Caption = 'Country/Region of Origin Code';
        }
        field(32; "CD No."; Code[50])
        {
            Caption = 'Package No.';
            Editable = false;

            trigger OnLookup()
            var
                VATLedgerLineCDNo: Record "VAT Ledger Line CD No.";
            begin
                VATLedgerLineCDNo.SetFilterVATLedgerLine(Rec);
                PAGE.Run(PAGE::"VAT Ledger Line CD No.", VATLedgerLineCDNo);
            end;
        }
        field(33; "Payment Doc. No."; Code[20])
        {
            Caption = 'Payment Doc. No.';
        }
        field(34; "Payment Date"; Date)
        {
            Caption = 'Payment Date';
        }
        field(35; "Amt. Diff. VAT"; Boolean)
        {
            Caption = 'Amt. Diff. VAT';
        }
        field(36; "Full Sales Tax Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Full Sales Tax Amount';
        }
        field(37; "Sales Tax Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Sales Tax Amount';
        }
        field(38; "Sales Tax Base"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Sales Tax Base';
        }
        field(39; "No. of Sales Ledger Lines"; Integer)
        {
            CalcFormula = count("VAT Ledger Connection" where("Connection Type" = const(Line),
                                                               "Purch. Ledger Code" = field(Code),
                                                               "Purch. Ledger Line No." = field("Line No.")));
            Caption = 'No. of Sales Ledger Lines';
            Editable = false;
            FieldClass = FlowField;
        }
        field(40; "No. of Purch. Ledger Lines"; Integer)
        {
            CalcFormula = count("VAT Ledger Connection" where("Connection Type" = const(Line),
                                                               "Sales Ledger Code" = field(Code),
                                                               "Sales Ledger Line No." = field("Line No.")));
            Caption = 'No. of Purch. Ledger Lines';
            Editable = false;
            FieldClass = FlowField;
        }
        field(41; "No. of VAT Sales Entries"; Integer)
        {
            CalcFormula = count("VAT Ledger Connection" where("Connection Type" = const(Sales),
                                                               "Sales Ledger Code" = field(Code),
                                                               "Sales Ledger Line No." = field("Line No.")));
            Caption = 'No. of VAT Sales Entries';
            Editable = false;
            FieldClass = FlowField;
        }
        field(42; "No. of VAT Purch. Entries"; Integer)
        {
            CalcFormula = count("VAT Ledger Connection" where("Connection Type" = const(Purchase),
                                                               "Purch. Ledger Code" = field(Code),
                                                               "Purch. Ledger Line No." = field("Line No.")));
            Caption = 'No. of VAT Purch. Entries';
            FieldClass = FlowField;
        }
        field(43; Base18; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Base18';
        }
        field(44; Amount18; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount18';
        }
        field(45; "Reg. Reason Code"; Code[10])
        {
            Caption = 'Reg. Reason Code';
        }
        field(50; "C/V Type"; Option)
        {
            Caption = 'C/V Type';
            OptionCaption = 'Vendor,Customer';
            OptionMembers = Vendor,Customer;
        }
        field(51; "Tariff No."; Code[20])
        {
            Caption = 'Tariff No.';
            Editable = false;

            trigger OnLookup()
            var
                VATLedgerLineTariffNo: Record "VAT Ledger Line Tariff No.";
            begin
                VATLedgerLineTariffNo.SetFilterVATLedgerLine(Rec);
                Page.Run(Page::"VAT Ledger Line Tariff No.", VATLedgerLineTariffNo);
            end;
        }
        field(12464; "VAT Correction"; Boolean)
        {
            Caption = 'VAT Correction';
        }
        field(12480; Partial; Boolean)
        {
            Caption = 'Partial';
        }
        field(12481; "Last Date"; Date)
        {
            Caption = 'Last Date';
        }
        field(12482; "Additional Sheet"; Boolean)
        {
            Caption = 'Additional Sheet';
        }
        field(12483; "Corr. VAT Entry Posting Date"; Date)
        {
            Caption = 'Corr. VAT Entry Posting Date';
        }
        field(12484; "Initial Document No."; Code[20])
        {
            Caption = 'Initial Document No.';
        }
        field(12485; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(12486; "Correction No."; Code[30])
        {
            Caption = 'Correction No.';
        }
        field(12487; "Correction Date"; Date)
        {
            Caption = 'Correction Date';
        }
        field(12488; "Revision No."; Code[30])
        {
            Caption = 'Revision No.';
        }
        field(12489; "Revision Date"; Date)
        {
            Caption = 'Revision Date';
        }
        field(12490; "Revision of Corr. No."; Code[20])
        {
            Caption = 'Revision of Corr. No.';
        }
        field(12491; "Revision of Corr. Date"; Date)
        {
            Caption = 'Revision of Corr. Date';
        }
        field(12492; "Print Revision"; Boolean)
        {
            Caption = 'Print Revision';
        }
        field(12493; "VAT Entry Type"; Code[15])
        {
            Caption = 'VAT Entry Type';
            TableRelation = "VAT Entry Type".Code;
            ValidateTableRelation = false;
        }
        field(12494; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        field(12495; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(12496; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount';
        }
    }

    keys
    {
        key(Key1; Type, "Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", "Document Date")
        {
        }
        key(Key3; "Document Date")
        {
        }
        key(Key4; "Real. VAT Entry Date")
        {
        }
        key(Key5; "Last Date")
        {
        }
        key(Key6; "C/V No.")
        {
        }
        key(Key7; "Corr. VAT Entry Posting Date")
        {
        }
        key(Key8; "Additional Sheet")
        {
            SumIndexFields = "Amount Including VAT", Base20, Amount20, Base10, Amount10, Base0, "Base VAT Exempt", Base18, Amount18;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        VATLedgerConnection: Record "VAT Ledger Connection";
        VATLedgerLineCDNo: Record "VAT Ledger Line CD No.";
        VATLedgerLineTariffNo: Record "VAT Ledger Line Tariff No.";
    begin
        if Type = Type::Purchase then begin
            VATLedgerConnection.SetRange("Purch. Ledger Code", Code);
            VATLedgerConnection.SetRange("Purch. Ledger Line No.", "Line No.");
            VATLedgerConnection.DeleteAll();
        end else begin
            VATLedgerConnection.SetRange("Sales Ledger Code", Code);
            VATLedgerConnection.SetRange("Sales Ledger Line No.", "Line No.");
            VATLedgerConnection.DeleteAll();
        end;

        VATLedgerLineCDNo.SetFilterVATLedgerLine(Rec);
        VATLedgerLineCDNo.DeleteAll();

        VATLedgerLineTariffNo.SetFilterVATLedgerLine(Rec);
        VATLedgerLineTariffNo.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure IsCorrection(): Boolean
    begin
        exit(("Correction No." <> '') or ("Revision No." <> '') or ("Revision of Corr. No." <> ''));
    end;

    [Scope('OnPrem')]
    procedure GetPmtVendorDtldLedgerLines(EndDate: Date; var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntryPayment: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedVendorLedgEntryPayment: Record "Detailed Vendor Ledg. Entry";
    begin
        VendorLedgerEntry.SetRange("Document No.", "Origin. Document No.");
        VendorLedgerEntry.FindFirst();

        DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
        DetailedVendorLedgEntry.SetRange(Unapplied, false);
        DetailedVendorLedgEntry.SetFilter("Posting Date", '..%1', EndDate);
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::Application);
        if DetailedVendorLedgEntry.FindSet() then
            repeat
                if DetailedVendorLedgEntry."Vendor Ledger Entry No." =
                   DetailedVendorLedgEntry."Applied Vend. Ledger Entry No."
                then begin
                    DetailedVendorLedgEntryPayment.SetRange(
                      "Applied Vend. Ledger Entry No.", DetailedVendorLedgEntry."Applied Vend. Ledger Entry No.");
                    DetailedVendorLedgEntryPayment.SetRange("Entry Type", DetailedVendorLedgEntryPayment."Entry Type"::Application);
                    DetailedVendorLedgEntryPayment.SetRange(Unapplied, false);
                    if DetailedVendorLedgEntryPayment.FindSet() then
                        repeat
                            if DetailedVendorLedgEntryPayment."Vendor Ledger Entry No." <>
                               DetailedVendorLedgEntryPayment."Applied Vend. Ledger Entry No."
                            then
                                if VendorLedgerEntryPayment.Get(DetailedVendorLedgEntryPayment."Vendor Ledger Entry No.") then begin
                                    TempVendorLedgerEntry := VendorLedgerEntryPayment;
                                    TempVendorLedgerEntry.Insert();
                                end;
                        until DetailedVendorLedgEntryPayment.Next() = 0;
                end else
                    if VendorLedgerEntryPayment.Get(DetailedVendorLedgEntry."Applied Vend. Ledger Entry No.") then begin
                        TempVendorLedgerEntry := VendorLedgerEntryPayment;
                        TempVendorLedgerEntry.Insert();
                    end;
            until DetailedVendorLedgEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetVATAgentVATAmountFCY(): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get("VAT Business Posting Group", "VAT Product Posting Group");
        exit(Round(Amount * VATPostingSetup."VAT %" / 100));
    end;

    [Scope('OnPrem')]
    procedure GetCDNoListString() Result: Text
    var
        VATLedgerLineCDNo: Record "VAT Ledger Line CD No.";
    begin
        VATLedgerLineCDNo.SetFilterVATLedgerLine(Rec);
        if VATLedgerLineCDNo.FindSet() then begin
            Result := VATLedgerLineCDNo."CD No.";
            while VATLedgerLineCDNo.Next() <> 0 do
                Result += ';' + VATLedgerLineCDNo."CD No.";
        end;
    end;
}

