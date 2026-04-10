#pragma warning disable AA0247
report 14907 "Change Vendor VAT Invoice"
{
    Caption = 'Change Vendor VAT Invoice';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(InvoiceNo; InvoiceNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor VAT Invoice No.';
                    }
                    field(InvoiceDate; InvoiceDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor VAT Invoice Date';
                    }
                    field(InvoiceRcvdDate; InvoiceRcvdDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor VAT Invoice Rcvd Date';
                    }
                    field(CreatePrepmtInvoice; CreatePrepmtInvoice)
                    {
                        ApplicationArea = Prepayments;
                        Caption = 'Create Prepmt. Invoice';
                    }
                    group(PrepaymentFrame)
                    {
                        Caption = 'Prepayment';
                        Visible = CreatePrepmtInvoice;
                        field(VATBus; VATBusPostingGrCode)
                        {
                            Caption = 'VAT Bus. Posting Group';
                            Editable = false;
                        }
                        field(VATProd; VATProdPostingGrCode)
                        {
                            Caption = 'VAT Prod. Posting Group';
                            ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                VATProdGroupLookup();
                            end;

                            trigger OnValidate()
                            begin
                                if CheckPostingGroup() then
                                    SetAmounts(0);
                            end;
                        }
                        field(VATBase; VATBase)
                        {
                            AutoFormatType = 1;
                            AutoFormatExpression = '';
                            Caption = 'VAT Base (LCY)';
                            Editable = false;
                        }
                        field(VATAmt; VATAmount)
                        {
                            AutoFormatType = 1;
                            AutoFormatExpression = '';
                            Caption = 'VAT Amount (LCY)';

                            trigger OnValidate()
                            begin
                                RecalcVATBase();
                            end;
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            UpdateRequestForm();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        VATPrepmtPost: Codeunit "VAT Prepayment-Post";
        VendEntryEdit: Codeunit "Vend. Entry-Edit";
    begin
        VendLedgEntry.Get(VendLedgEntry."Entry No.");
        VendLedgEntry.CalcFields("Remaining Amt. (LCY)");
        VendEntryEdit.UpdateVATInvoiceData(VendLedgEntry, InvoiceNo, InvoiceDate, InvoiceRcvdDate);
        if VendLedgEntry.Prepayment then begin
            VendLedgEntry.TestField("Vendor VAT Invoice No.");
            VendLedgEntry.TestField("Vendor VAT Invoice Date");
            VendLedgEntry.TestField("Vendor VAT Invoice Rcvd Date");
        end;

        if CreatePrepmtInvoice then begin
            CheckPostingGroup();
            VendLedgEntry.TestField(Prepayment, true);
            if (VATBase <= 0) or (VATAmount <= 0) then
                Error(Text001);
            VATPrepmtPost.PostVendVAT(VendLedgEntry, VATProdPostingGrCode, VATBase, VATAmount);

            Commit();
            if CurrReport.UseRequestPage then
                Message(Text002, VendLedgEntry."Document No.");
        end;
    end;

    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VATProdPostingGrCode: Code[20];
        VATBusPostingGrCode: Code[20];
        InvoiceDate: Date;
        InvoiceRcvdDate: Date;
        InvoiceNo: Code[30];
        CreatePrepmtInvoice: Boolean;
        VATAmount: Decimal;
#pragma warning disable AA0074
        Text001: Label 'VAT Base (LCY) and VAT Amount (LCY) must be positive.';
#pragma warning restore AA0074
        VATBase: Decimal;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'VAT for Prepayment %1 is successfully posted.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label 'You must specify %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure SetInvParameters(InvNo: Code[30]; InvDate: Date; InvRcvdDate: Date)
    begin
        InvoiceNo := InvNo;
        InvoiceDate := InvDate;
        InvoiceRcvdDate := InvRcvdDate;
        if InvoiceDate = 0D then begin
            InvoiceDate := WorkDate();
            InvoiceRcvdDate := InvoiceDate;
        end;
    end;

    local procedure UpdateRequestForm()
    begin
        if not CreatePrepmtInvoice then begin
            VATBase := 0;
            VATAmount := 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetVendLedgEntry(NewVendLedgEntry: Record "Vendor Ledger Entry")
    var
        Vendor: Record Vendor;
    begin
        VendLedgEntry := NewVendLedgEntry;
        Vendor.Get(VendLedgEntry."Vendor No.");
        VATBusPostingGrCode := Vendor."VAT Bus. Posting Group";
        SetInvParameters(VendLedgEntry."Vendor VAT Invoice No.", VendLedgEntry."Vendor VAT Invoice Date", VendLedgEntry."Vendor VAT Invoice Rcvd Date");
    end;

    local procedure VATProdGroupLookup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetupForm: Page "VAT Posting Setup";
    begin
        VATPostingSetup.FilterGroup(2);
        VATPostingSetup.SetRange("VAT Bus. Posting Group", VATBusPostingGrCode);
        VATPostingSetup.FilterGroup(0);
        VATPostingSetup.SetRange("VAT Calculation Type",
          VATPostingSetup."VAT Calculation Type"::"Full VAT");
        VATPostingSetup.SetRange("Unrealized VAT Type",
          VATPostingSetup."Unrealized VAT Type"::Percentage);
        if VATPostingSetup.Get(VATBusPostingGrCode, VATProdPostingGrCode) then;
        VATPostingSetupForm.SetTableView(VATPostingSetup);
        VATPostingSetupForm.LookupMode(true);
        if VATPostingSetupForm.RunModal() = ACTION::LookupOK then begin
            VATPostingSetupForm.GetRecord(VATPostingSetup);
            SetVATProdGroup(VATPostingSetup."VAT Prod. Posting Group");
        end;
    end;

    [Scope('OnPrem')]
    procedure SetVATProdGroup(NewVATProdPostingGrCode: Code[20])
    begin
        CreatePrepmtInvoice := true;
        VATProdPostingGrCode := NewVATProdPostingGrCode;
        if CheckPostingGroup() then
            SetAmounts(0);
    end;

    [Scope('OnPrem')]
    procedure SetAmounts(NewVATAmount: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if NewVATAmount = 0 then begin
            VATPostingSetup.Get(VATBusPostingGrCode, VATProdPostingGrCode);
            VendLedgEntry.CalcFields("Remaining Amt. (LCY)");
            VATAmount :=
              Round(VendLedgEntry."Remaining Amt. (LCY)" *
                VATPostingSetup."VAT %" /
                (100 + VATPostingSetup."VAT %"));
        end else
            VATAmount := NewVATAmount;
        RecalcVATBase();
    end;

    [Scope('OnPrem')]
    procedure CheckPostingGroup() Result: Boolean
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        Result := false;
        if VATProdPostingGrCode = '' then
            Error(Text003, VATPostingSetup.FieldCaption("VAT Prod. Posting Group"));
        VATPostingSetup.Get(VATBusPostingGrCode, VATProdPostingGrCode);
        VATPostingSetup.TestField("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Full VAT");
        VATPostingSetup.TestField("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        Result := true;
    end;

    [Scope('OnPrem')]
    procedure RecalcVATBase()
    begin
        VATBase := VendLedgEntry."Remaining Amt. (LCY)" - VATAmount;
    end;
}

