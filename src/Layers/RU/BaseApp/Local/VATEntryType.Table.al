#pragma warning disable AA0247
table 14949 "VAT Entry Type"
{
    Caption = 'VAT Entry Type';
    Permissions = TableData "Sales Invoice Header" = rm,
                  TableData "Sales Cr.Memo Header" = rm,
                  TableData "Purch. Inv. Header" = rm,
                  TableData "Purch. Cr. Memo Hdr." = rm;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[2])
        {
            Caption = 'Code';
            NotBlank = true;
            Numeric = true;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(3; Comment; Text[250])
        {
            Caption = 'Comment';
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

    var
#pragma warning disable AA0074
        Text001: Label 'Length of VAT Entry Type Code cannot be greater than 2.';
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure LookupSetOfVATEntryCodes(var SetOfVATEntryTypes: Code[20]): Boolean
    var
        VATEntryTypes: Page "VAT Entry Types";
    begin
        VATEntryTypes.LookupMode := true;
        VATEntryTypes.Editable := false;
        if VATEntryTypes.RunModal() = ACTION::LookupOK then begin
            SetOfVATEntryTypes := VATEntryTypes.GetSelection();
            exit(true)
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure ValidateSetOfVATEntryCodes(SetOfVATEntryTypes: Code[15])
    var
        VATEntryType: Record "VAT Entry Type";
        VATEntryTypeCode: Code[15];
        i: Integer;
    begin
        if SetOfVATEntryTypes = '' then
            exit;

        repeat
            i := StrPos(SetOfVATEntryTypes, ';');
            if i = 0 then
                VATEntryTypeCode := SetOfVATEntryTypes
            else
                VATEntryTypeCode := CopyStr(SetOfVATEntryTypes, 1, i - 1);
            if StrLen(VATEntryTypeCode) > 2 then
                Error(Text001);
            VATEntryType.Get(VATEntryTypeCode);
            SetOfVATEntryTypes := CopyStr(SetOfVATEntryTypes, i + 1);
        until i = 0;
    end;

    [Scope('OnPrem')]
    procedure UpdateSalesVATEntryType(CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        ValidateSetOfVATEntryCodes(CustLedgerEntry."VAT Entry Type");

        if SalesInvoiceHeader.Get(CustLedgerEntry."Document No.") and
           (CustLedgerEntry."VAT Entry Type" <> SalesInvoiceHeader."VAT Entry Type")
        then begin
            SalesInvoiceHeader."VAT Entry Type" := CustLedgerEntry."VAT Entry Type";
            SalesInvoiceHeader.Modify();
        end;

        if SalesCrMemoHeader.Get(CustLedgerEntry."Document No.") and
           (CustLedgerEntry."VAT Entry Type" <> SalesCrMemoHeader."VAT Entry Type")
        then begin
            SalesCrMemoHeader."VAT Entry Type" := CustLedgerEntry."VAT Entry Type";
            SalesCrMemoHeader.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdatePurchVATEntryType(VendLedgerEntry: Record "Vendor Ledger Entry")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        ValidateSetOfVATEntryCodes(VendLedgerEntry."VAT Entry Type");

        if PurchInvHeader.Get(VendLedgerEntry."Document No.") and
           (VendLedgerEntry."VAT Entry Type" <> PurchInvHeader."VAT Entry Type")
        then begin
            PurchInvHeader."VAT Entry Type" := VendLedgerEntry."VAT Entry Type";
            PurchInvHeader.Modify();
        end;

        if PurchCrMemoHdr.Get(VendLedgerEntry."Document No.") and
           (VendLedgerEntry."VAT Entry Type" <> PurchCrMemoHdr."VAT Entry Type")
        then begin
            PurchCrMemoHdr."VAT Entry Type" := VendLedgerEntry."VAT Entry Type";
            PurchCrMemoHdr.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure GetValue() SetOfVATEntryType: Code[20]
    var
        Delimiter: Text[1];
    begin
        if FindSet() then
            repeat
                SetOfVATEntryType += Delimiter + Code;
                Delimiter := ';';
            until Next() = 0;
    end;
}

