#pragma warning disable AA0247
report 14928 "Unrealized VAT Analysis"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/UnrealizedVATAnalysis.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Unrealized VAT Analysis';
    EnableHyperlinks = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("VAT Entry"; "VAT Entry")
        {
            DataItemTableView = sorting(Type, "VAT Reporting Date", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Gen. Bus. Posting Group", "Gen. Prod. Posting Group", "Object Type", "Object No.", "VAT Allocation Type", Prepayment) where(Type = const(Purchase), Base = const(0), Amount = const(0));
            RequestFilterFields = "Bill-to/Pay-to No.", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Reporting Date";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(RequestFilter; RequestFilter)
            {
            }
            column(VATAccNoURL; Format(VATAccNoURL.RecordId, 0, 10))
            {
            }
            column(VendorURL; Format(VendorURL.RecordId, 0, 10))
            {
            }
            column(CustomerURL; Format(CustomerURL.RecordId, 0, 10))
            {
            }
            column(IsVendor; IsVendor)
            {
            }
            column(DocNoURL; Format(DocNoURL.RecordId, 0, 10))
            {
            }
            column(CollapseAll; CollapseAll)
            {
            }
            column(IsGLAccountView; IsGLAccountView)
            {
            }
            column(ViewByCaption; ViewByCaption)
            {
            }
            column(IsInvoice; IsInvoice)
            {
            }
            column(VAT_Entry__VAT_Reporting_Date_; "VAT Reporting Date")
            {
            }
            column(VAT_Entry__Document_Type_; "Document Type")
            {
            }
            column(VAT_Entry__Document_No__; "Document No.")
            {
            }
            column(VAT_Entry__Bill_to_Pay_to_No__; ContractorName)
            {
            }
            column(VAT_Entry__VAT_Bus__Posting_Group_; "VAT Bus. Posting Group")
            {
            }
            column(VAT_Entry__VAT_Prod__Posting_Group_; "VAT Prod. Posting Group")
            {
            }
            column(VAT_Entry__Unrealized_Base_; "Unrealized Base")
            {
            }
            column(VAT_Entry__Unrealized_Amount_; "Unrealized Amount")
            {
            }
            column(VATBase; VATBase)
            {
            }
            column(VATAmount; VATAmount)
            {
            }
            column(WriteoffVATBase; WriteoffVATBase)
            {
            }
            column(WriteoffVATAmount; WriteoffVATAmount)
            {
            }
            column(ChargeVATBase; ChargeVATBase)
            {
            }
            column(ChargeVATAmount; ChargeVATAmount)
            {
            }
            column(VATAccNo; VATAccNo)
            {
            }
            column(VAT_Entry__Remaining_Unrealized_Amount_; "Remaining Unrealized Amount")
            {
            }
            column(VAT_Entry__Remaining_Unrealized_Base_; "Remaining Unrealized Base")
            {
            }
            column(VendorVATInvoiceDate; VendorVATInvoiceDate)
            {
            }
            column(VATBase1; VATBase)
            {
            }
            column(VATAmount1; VATAmount)
            {
            }
            column(WriteoffVATBase1; WriteoffVATBase)
            {
            }
            column(WriteoffVATAmount1; WriteoffVATAmount)
            {
            }
            column(ChargeVATBase1; ChargeVATBase)
            {
            }
            column(ChargeVATAmount1; ChargeVATAmount)
            {
            }
            column(UnrealizedAmount_VATEntry; "Unrealized Amount")
            {
            }
            column(UnrealizedBase_VATEntry; "Unrealized Base")
            {
            }
            column(RemainingUnrealizedAmount_VATEntry; "Remaining Unrealized Amount")
            {
            }
            column(RemainingUnrealizedBase_VATEntry; "Remaining Unrealized Base")
            {
            }
            column(VAT_EntryCaption; VAT_EntryCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(VAT_Entry__VAT_Reporting_Date_Caption; FieldCaption("VAT Reporting Date"))
            {
            }
            column(VAT_Entry__Document_Type_Caption; FieldCaption("Document Type"))
            {
            }
            column(VAT_Entry__Document_No__Caption; FieldCaption("Document No."))
            {
            }
            column(VAT_Entry__Bill_to_Pay_to_No__Caption; VAT_Entry__Bill_to_Pay_to_No__CaptionLbl)
            {
            }
            column(VAT_Entry__VAT_Bus__Posting_Group_Caption; FieldCaption("VAT Bus. Posting Group"))
            {
            }
            column(VAT_Entry__VAT_Prod__Posting_Group_Caption; FieldCaption("VAT Prod. Posting Group"))
            {
            }
            column(VAT_Entry__Unrealized_Base_Caption; FieldCaption("Unrealized Base"))
            {
            }
            column(VAT_Entry__Unrealized_Amount_Caption; FieldCaption("Unrealized Amount"))
            {
            }
            column(VATBaseCaption; VATBaseCaptionLbl)
            {
            }
            column(VATAmountCaption; VATAmountCaptionLbl)
            {
            }
            column(WriteoffVATBaseCaption; WriteoffVATBaseCaptionLbl)
            {
            }
            column(WriteoffVATAmountCaption; WriteoffVATAmountCaptionLbl)
            {
            }
            column(ChargeVATBaseCaption; ChargeVATBaseCaptionLbl)
            {
            }
            column(ChargeVATAmountCaption; ChargeVATAmountCaptionLbl)
            {
            }
            column(VATAccNoCaption; VATAccNoCaptionLbl)
            {
            }
            column(VAT_Entry__Remaining_Unrealized_Amount_Caption; FieldCaption("Remaining Unrealized Amount"))
            {
            }
            column(VAT_Entry__Remaining_Unrealized_Base_Caption; FieldCaption("Remaining Unrealized Base"))
            {
            }
            column(VendorVATInvoiceDate_Caption; VendorVATInvoiceDate_CaptionLbl)
            {
            }
            column(VAT_Entry_Entry_No_; "Entry No.")
            {
            }

            trigger OnAfterGetRecord()
            var
                GLAccount: Record "G/L Account";
                PurchInvHeader: Record "Purch. Inv. Header";
                PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
            begin
                if not CheckVendorAgreement(VendorAgreementNo, "CV Ledg. Entry No.") then
                    CurrReport.Skip();

                VATAmount := 0;
                VATBase := 0;
                WriteoffVATAmount := 0;
                WriteoffVATBase := 0;
                ChargeVATAmount := 0;
                ChargeVATBase := 0;
                VATEntry.SetRange("Unrealized VAT Entry No.", "Entry No.");
                VATEntry.SetFilter("VAT Reporting Date", "VAT Entry".GetFilter("VAT Reporting Date"));
                if VATEntry.FindSet() then
                    repeat
                        case VATEntry."VAT Allocation Type" of
                            VATEntry."VAT Allocation Type"::VAT:
                                begin
                                    VATAmount += VATEntry.Amount;
                                    VATBase += VATEntry.Base;
                                end;
                            VATEntry."VAT Allocation Type"::WriteOff:
                                begin
                                    WriteoffVATAmount += VATEntry.Amount;
                                    WriteoffVATBase += VATEntry.Base;
                                end;
                            VATEntry."VAT Allocation Type"::Charge:
                                begin
                                    ChargeVATAmount += VATEntry.Amount;
                                    ChargeVATBase += VATEntry.Base;
                                end;
                        end;
                    until VATEntry.Next() = 0;

                VATAccNo := '';
                VATEntryLink.SetRange("VAT Entry No.", "Entry No.");
                if VATEntryLink.FindFirst() then begin
                    GLEntry.Get(VATEntryLink."G/L Entry No." + 1);
                    VATAccNo := GLEntry."G/L Account No.";
                    GLAccount.Get(VATAccNo);
                    VATAccNoURL.SetPosition(GLAccount.GetPosition());
                end;

                VendorVATInvoiceDate := GETVendorVATInvoiceDate("VAT Entry");
                InitializeCustVendInfo("VAT Entry");

                DocNoURL.Close();
                if "Document Type" = "Document Type"::Invoice then begin
                    IsInvoice := true;
                    DocNoURL.Open(DATABASE::"Purch. Inv. Header");
                    if PurchInvHeader.Get("Document No.") then
                        DocNoURL.SetPosition(PurchInvHeader.GetPosition());
                end else
                    if "Document Type" = "Document Type"::"Credit Memo" then begin
                        IsInvoice := false;
                        DocNoURL.Open(DATABASE::"Purch. Cr. Memo Hdr.");
                        if PurchCrMemoHdr.Get("Document No.") then
                            DocNoURL.SetPosition(PurchCrMemoHdr.GetPosition());
                    end;
            end;

            trigger OnPreDataItem()
            begin
                VATEntry.SetCurrentKey("Unrealized VAT Entry No.");

                VATAccNoURL.Open(DATABASE::"G/L Account");
                VendorURL.Open(DATABASE::Vendor);
                CustomerURL.Open(DATABASE::Customer);


                if ViewBy = ViewBy::"G/L Account" then begin
                    ViewByCaption := Text001;
                    IsGLAccountView := true;
                end else begin
                    ViewByCaption := Text002;
                    IsGLAccountView := false;
                end;
            end;
        }
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
                    field(VendorAgreementNo; VendorAgreementNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor Agreement No.';
                        TableRelation = "Vendor Agreement"."No.";
                    }
                    field(ViewBy; ViewBy)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'View by';
                        ToolTip = 'Specifies by which period amounts are displayed.';
                    }
                    field(CollapseAll; CollapseAll)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Collapse All';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        RequestFilter := "VAT Entry".GetFilters();
        if VendorAgreementNo <> '' then
            RequestFilter += Text010 + VendorAgreementNo;
    end;

    var
        GLEntry: Record "G/L Entry";
        VATEntryLink: Record "G/L Entry - VAT Entry Link";
        VATEntry: Record "VAT Entry";
        VATAmount: Decimal;
        VATBase: Decimal;
        WriteoffVATAmount: Decimal;
        WriteoffVATBase: Decimal;
        ChargeVATAmount: Decimal;
        ChargeVATBase: Decimal;
        VATAccNo: Code[20];
        VATAccNoURL: RecordRef;
        VendorVATInvoiceDate: Date;
        VendorURL: RecordRef;
        CustomerURL: RecordRef;
        DocNoURL: RecordRef;
        IsVendor: Boolean;
        ContractorName: Text[250];
        CollapseAll: Boolean;
        ViewBy: Option "G/L Account",Invoice;
        ViewByCaption: Text[250];
#pragma warning disable AA0074
        Text001: Label 'G/L Account View';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text002: Label 'Invoice View';
#pragma warning restore AA0074
        IsGLAccountView: Boolean;
        RequestFilter: Text;
        VendorAgreementNo: Code[20];
#pragma warning disable AA0074
        Text010: Label 'Agreement No.: ';
#pragma warning restore AA0074
        IsInvoice: Boolean;
        VAT_EntryCaptionLbl: Label 'Unrealized VAT Analysis';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        VAT_Entry__Bill_to_Pay_to_No__CaptionLbl: Label 'Contractor Name';
        VATBaseCaptionLbl: Label 'VAT Base';
        VATAmountCaptionLbl: Label 'VAT Amount';
        WriteoffVATBaseCaptionLbl: Label 'Written-off VAT Base';
        WriteoffVATAmountCaptionLbl: Label 'Written-off VAT Amount';
        ChargeVATBaseCaptionLbl: Label 'Alloc. on Cost VAT Base';
        ChargeVATAmountCaptionLbl: Label 'Alloc. on Cost VAT Amount';
        VATAccNoCaptionLbl: Label 'G/L Account No.';
        VendorVATInvoiceDate_CaptionLbl: Label 'Vendor VAT Invoice Date';

    [Scope('OnPrem')]
    procedure GETVendorVATInvoiceDate(VATEntry: Record "VAT Entry"): Date
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if VATEntry.Type = VATEntry.Type::Purchase then
            if VendorLedgerEntry.Get(VATEntry."CV Ledg. Entry No.") then
                exit(VendorLedgerEntry."Vendor VAT Invoice Date");
    end;

    [Scope('OnPrem')]
    procedure InitializeCustVendInfo(VATEntry: Record "VAT Entry")
    var
        LocRepMgt: Codeunit "Local Report Management";
        Vendor: Record Vendor;
        Customer: Record Customer;
    begin
        case VATEntry.Type of
            VATEntry.Type::Purchase:
                begin
                    IsVendor := true;
                    ContractorName := LocRepMgt.GetVendorName(VATEntry."Bill-to/Pay-to No.");
                    if Vendor.Get(VATEntry."Bill-to/Pay-to No.") then
                        VendorURL.SetPosition(Vendor.GetPosition());
                end;
            VATEntry.Type::Sale:
                begin
                    IsVendor := false;
                    ContractorName := LocRepMgt.GetCustName(VATEntry."Bill-to/Pay-to No.");
                    if Customer.Get(VATEntry."Bill-to/Pay-to No.") then
                        CustomerURL.SetPosition(Customer.GetPosition());
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckVendorAgreement(AgreementNo: Code[20]; CVLedgEntryNo: Integer): Boolean
    var
        VendorLedgEntry: Record "Vendor Ledger Entry";
    begin
        if AgreementNo = '' then
            exit(true);

        if VendorLedgEntry.Get(CVLedgEntryNo) then
            exit(VendorLedgEntry."Agreement No." = AgreementNo);

        exit(false);
    end;
}

