#pragma warning disable AA0247
report 14901 "Purch. without Vend. VAT Inv."
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/PurchwithoutVendVATInv.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Purchases without Vendor VAT Invoice';
    EnableHyperlinks = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
        {
            CalcFields = "Original Amount";
            DataItemTableView = where("Document Type" = filter(Invoice | "Credit Memo"));
            RequestFilterFields = "Vendor No.", "Posting Date";
            column(USERID; UserId)
            {
            }
            column(RequestFilter; RequestFilter)
            {
            }
            column(CurrentDate; CurrentDate)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Vendor_Ledger_Entry__Posting_Date_; "Posting Date")
            {
            }
            column(Vendor_Ledger_Entry__Document_Type_; "Document Type")
            {
            }
            column(Vendor_Ledger_Entry__Document_No__; "Document No.")
            {
            }
            column(Vendor_Ledger_Entry__External_Document_No__; "External Document No.")
            {
            }
            column(Vendor_Ledger_Entry__Vendor_No__; "Vendor No.")
            {
            }
            column(Vendor_Ledger_Entry__Original_Amount_; "Original Amount")
            {
            }
            column(Vendor_Name; Vendor.Name)
            {
            }
            column(Vendor_Ledger_Entry__Currency_Code_; "Currency Code")
            {
            }
            column(VendorLE; Format(VendorLE.RecordId, 0, 10))
            {
            }
            column(Purchases_without_Vendor_VAT_InvoiceCaption; Purchases_without_Vendor_VAT_InvoiceCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__External_Document_No__Caption; FieldCaption("External Document No."))
            {
            }
            column(Vendor_Ledger_Entry__Posting_Date_Caption; FieldCaption("Posting Date"))
            {
            }
            column(Vendor_Ledger_Entry__Document_Type_Caption; FieldCaption("Document Type"))
            {
            }
            column(Vendor_Ledger_Entry__Document_No__Caption; FieldCaption("Document No."))
            {
            }
            column(Vendor_Ledger_Entry__Vendor_No__Caption; FieldCaption("Vendor No."))
            {
            }
            column(Vendor_Ledger_Entry__Original_Amount_Caption; FieldCaption("Original Amount"))
            {
            }
            column(Vendor_NameCaption; Vendor_NameCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Currency_Code_Caption; FieldCaption("Currency Code"))
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(Fixed_AssetsCaption; Fixed_AssetsCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry_Entry_No_; "Entry No.")
            {
            }

            trigger OnAfterGetRecord()
            begin
                if ("Vendor VAT Invoice No." <> '') and ("Vendor VAT Invoice Date" <> 0D) and
                   ("Vendor VAT Invoice Rcvd Date" <> 0D) then
                    CurrReport.Skip();

                Vendor.Get("Vendor No.");

                VendorLE.SetPosition("Vendor Ledger Entry".GetPosition());
            end;

            trigger OnPreDataItem()
            begin
                VendorLE.Open(DATABASE::"Vendor Ledger Entry");
            end;
        }
    }

    requestpage
    {

        layout
        {
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
        CurrentDate := LocMgt.Date2Text(Today()) + Format(Time(), 0, '(<Hours24>:<Minutes>)');
        RequestFilter := "Vendor Ledger Entry".GetFilters();
    end;

    var
        Vendor: Record Vendor;
        LocMgt: Codeunit "Localisation Management";
        VendorLE: RecordRef;
        CurrentDate: Text[30];
        RequestFilter: Text;
        Purchases_without_Vendor_VAT_InvoiceCaptionLbl: Label 'Purchases without Vendor VAT Invoice.';
        Vendor_NameCaptionLbl: Label 'Vendor Name';
        PageCaptionLbl: Label 'Page';
        Fixed_AssetsCaptionLbl: Label 'Purchase';
}

