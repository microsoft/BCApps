#pragma warning disable AA0247
report 14963 "Create VAT Sales Led. Ad. Sh."
{
    Caption = 'Create VAT Sales Led. Ad. Sh.';
    ProcessingOnly = true;
    Permissions = tabledata "VAT Ledger Line" = i,
                  tabledata "VAT Ledger Connection" = i;

    dataset
    {
        dataitem(VATLedgerName; "VAT Ledger")
        {
            DataItemTableView = sorting(Type, Code) where(Type = const(Sales));
            RequestFilterFields = "Code";
            dataitem(VATEntryAdd; "VAT Entry")
            {
                DataItemTableView = sorting("Posting Date", Type, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Tax Invoice Amount Type", Prepayment, Positive) where(Type = const(Sale), "Tax Invoice Amount Type" = const(VAT), "Additional VAT Ledger Sheet" = const(true), "VAT Allocation Type" = const(VAT));

                trigger OnAfterGetRecord()
                var
                begin
                    if Reversed then
                        if not ReversedByCorrection(VATEntryAdd) then
                            CurrReport.Skip();

                    if Prepayment then begin
                        if ("Unrealized VAT Entry No." <> 0) and not Reversed then
                            CurrReport.Skip();
                    end else
                        if "Unrealized VAT Entry No." = 0 then
                            if (Base = 0) and (Amount = 0) then
                                CurrReport.Skip();

                    if Prepayment and not ShowPrepayment then
                        CurrReport.Skip();
                    if not Prepayment then
                        if "Unrealized VAT Entry No." <> 0 then begin
                            if not ShowUnrealVAT then
                                CurrReport.Skip()
                        end else
                            if not ShowRealVAT then
                                CurrReport.Skip();

                    if not Reversed then
                        if "Posting Date" in [VATLedgerName."Start Date" .. VATLedgerName."End Date"] then
                            CurrReport.Skip();

                    DocumentDate := 0D;
                    RealVATEntryDate := 0D;
                    PaymentDate := 0D;

                    VATEntryNo := "Entry No.";
                    if "Unrealized VAT Entry No." <> 0 then
                        VATEntryNo := "Unrealized VAT Entry No.";
                    GetLineProperties(VATEntryNo);

                    if not Prepayment then begin
                        GetSalesPaymentDate("Transaction No.", PaymentDate);
                        if PaymentDate = 0D then
                            PaymentDate := "Posting Date";
                    end;

                    if "Unrealized VAT Entry No." = 0 then // by shipment
                        RealVATEntryDate := "Posting Date"
                    else // by payment
                        RealVATEntryDate := PaymentDate;

                    if Prepayment and ("Unrealized VAT Entry No." <> 0) then
                        InvertVATEntry(VATEntryAdd);

                    MakeSalesBook(VATEntryAdd, LedgerBuffer);
                end;

                trigger OnPreDataItem()
                var
                    VATLedgerLine: Record "VAT Ledger Line";
                begin
                    SetRange("Corrected Document Date", VATLedgerName."Start Date", VATLedgerName."End Date");
                    VATLedgMgt.SetCustVendFilter(VATEntryAdd, CustFilter);
                    VATLedgMgt.SetVATGroupsFilter(VATEntryAdd, VATProdGroupFilter, VATBusGroupFilter);

                    LedgerBuffer.Reset();
                    LedgerBuffer.SetCurrentKey("Document No.");

                    VATLedgerLine.SetRange(Code, VATLedgerName.Code);
                    VATLedgerLine.SetRange(Type, VATLedgerName.Type);
                    if VATLedgerLine.FindLast() then;
                    LineNo := VATLedgerLine."Line No.";
                end;
            }
            dataitem(PrepmtVATEntryAdd; "VAT Entry")
            {
                DataItemTableView = sorting("Posting Date", Type, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Tax Invoice Amount Type", Prepayment, Positive) where(Type = const(Purchase), "Tax Invoice Amount Type" = const(VAT), Prepayment = const(true), "Additional VAT Ledger Sheet" = const(true), "VAT Allocation Type" = const(VAT));

                trigger OnAfterGetRecord()
                var
                    ReversedVATEntry: Record "VAT Entry";
                begin
                    if "Unrealized VAT Entry No." = 0 then
                        CurrReport.Skip();

                    if not Reversed then
                        if "Posting Date" in [VATLedgerName."Start Date" .. VATLedgerName."End Date"] then
                            CurrReport.Skip();

                    if Reversed then begin
                        if not ReversedByCorrection(PrepmtVATEntryAdd) then
                            CurrReport.Skip();

                        // Returned Prepayment
                        if ReversedVATEntry.Get("Reversed Entry No.") then
                            if ReversedVATEntry."Unrealized VAT Entry No." = 0 then
                                CurrReport.Skip();
                    end;

                    DocumentDate := 0D;
                    GetLineProperties("Unrealized VAT Entry No.");
                    RealVATEntryDate := "Posting Date";

                    Base := -Base;
                    Amount := -Amount;
                    MakeSalesBook(PrepmtVATEntryAdd, LedgerBuffer);
                end;

                trigger OnPostDataItem()
                begin
                    SaveSalesLedger();
                end;

                trigger OnPreDataItem()
                var
                begin
                    if not ShowVendPrepmt then
                        CurrReport.Break();

                    SetRange("Corrected Document Date", VATLedgerName."Start Date", VATLedgerName."End Date");
                    VATLedgMgt.GetVendFilterByCustFilter(VendFilter, CustFilter);
                    VATLedgMgt.SetCustVendFilter(PrepmtVATEntryAdd, VendFilter);
                    VATLedgMgt.SetVATGroupsFilter(PrepmtVATEntryAdd, VATProdGroupFilter, VATBusGroupFilter);
                end;
            }
            dataitem(Ledger; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then begin
                        if not LedgerBuffer.FindSet() then
                            CurrReport.Break();
                    end else
                        if LedgerBuffer.Next(1) = 0 then
                            CurrReport.Break();
                    LedgerBuffer."Sales Tax Amount" := LedgerBuffer."Sales Tax Amount" + LedgerBuffer."Full Sales Tax Amount";

                    LedgerBuffer."Full VAT Amount" := 0;
                    LedgerBuffer."Full Sales Tax Amount" := 0;

                    if LedgerBuffer."Amount Including VAT" = 0 then
                        LedgerBuffer."Amount Including VAT" :=
                          Round(LedgerBuffer.Base20 + LedgerBuffer.Amount20 +
                            LedgerBuffer.Base18 + LedgerBuffer.Amount18 +
                            LedgerBuffer.Base10 + LedgerBuffer.Amount10 +
                            LedgerBuffer."Sales Tax Amount" + LedgerBuffer."Full Sales Tax Amount" + LedgerBuffer."Base VAT Exempt" +
                            LedgerBuffer.Base0,
                            0.01);

                    if LedgerBuffer."Amount Including VAT" = 0 then
                        CurrReport.Skip();

                    LedgerBuffer.Base20 := Round(LedgerBuffer.Base20, 0.01);
                    LedgerBuffer.Amount20 := Round(LedgerBuffer.Amount20, 0.01);
                    LedgerBuffer.Base18 := Round(LedgerBuffer.Base18, 0.01);
                    LedgerBuffer.Amount18 := Round(LedgerBuffer.Amount18, 0.01);
                    LedgerBuffer.Base10 := Round(LedgerBuffer.Base10, 0.01);
                    LedgerBuffer.Amount10 := Round(LedgerBuffer.Amount10, 0.01);
                    LedgerBuffer."Full VAT Amount" := Round(LedgerBuffer."Full VAT Amount", 0.01);
                    LedgerBuffer."Sales Tax Amount" := Round(LedgerBuffer."Sales Tax Amount", 0.01);
                    LedgerBuffer."Full Sales Tax Amount" := Round(LedgerBuffer."Full Sales Tax Amount", 0.01);
                    LedgerBuffer."Base VAT Exempt" := Round(LedgerBuffer."Base VAT Exempt", 0.01);
                    LedgerBuffer.Base0 := Round(LedgerBuffer.Base0, 0.01);

                    CheckMethod();

                    VATLedgMgt.InsertVATLedgerLineCDNoList(LedgerBuffer);
                    VATLedgMgt.InsertVATLedgerLineTariffNoList(LedgerBuffer);
                end;

                trigger OnPreDataItem()
                begin
                    if Details then
                        CurrReport.Break();

                    LedgerBuffer.Reset();

                    case Sorting of
                        Sorting::"Document Date":
                            LedgerBuffer.SetCurrentKey("Document Date");
                        Sorting::"Document No.":
                            LedgerBuffer.SetCurrentKey("Document No.");
                        Sorting::"Customer No.":
                            LedgerBuffer.SetCurrentKey("C/V No.");
                        else
                            LedgerBuffer.SetCurrentKey("Real. VAT Entry Date");
                    end;
                end;
            }
            dataitem(Analysis; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then begin
                        if not LedgerBuffer.FindSet() then
                            CurrReport.Break();
                    end else
                        if LedgerBuffer.Next() = 0 then
                            CurrReport.Break();

                    LedgerBuffer."Amount Including VAT" :=
                      Round(LedgerBuffer.Base20 + LedgerBuffer.Amount20 +
                        LedgerBuffer.Base18 + LedgerBuffer.Amount18 +
                        LedgerBuffer.Base10 + LedgerBuffer.Amount10 +
                        LedgerBuffer."Sales Tax Amount" + LedgerBuffer."Full Sales Tax Amount" + LedgerBuffer.Base0, 0.01);

                    CheckMethod();
                end;

                trigger OnPreDataItem()
                begin
                    if not Details then
                        CurrReport.Break();

                    LedgerBuffer.Reset();

                    case Sorting of
                        Sorting::"Document Date":
                            LedgerBuffer.SetCurrentKey("Document Date");
                        Sorting::"Document No.":
                            LedgerBuffer.SetCurrentKey("Document No.");
                        Sorting::"Customer No.":
                            LedgerBuffer.SetCurrentKey("C/V No.");
                        else
                            LedgerBuffer.SetCurrentKey("Real. VAT Entry Date");
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if ClearOperation then
                    VATLedgMgt.DeleteVATLedgerAddSheetLines(VATLedgerName);
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
                    field(CustFilter; CustFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Filter';
                        Editable = false;
                        TableRelation = Customer;
                    }
                    field(VATProdGroupFilter; VATProdGroupFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Product Group Filter';
                        Editable = false;
                        TableRelation = "VAT Product Posting Group";
                        ToolTip = 'Specifies a filter for data to be included. VAT product posting groups define the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    }
                    field(VATBusGroupFilter; VATBusGroupFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Business Group Filter';
                        Editable = false;
                        TableRelation = "VAT Business Posting Group";
                        ToolTip = 'Specifies a filter for data to be included. VAT business posting groups define the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    }
                    field(Sorting; Sorting)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sorting';
                        Editable = false;
                        OptionCaption = ' ,Document Date,Document No.,Customer No.';
                        ToolTip = 'Specifies how items are sorted on the resulting report.';
                    }
                    field(ClearOperation; ClearOperation)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Clear Lines by Code';
                        ToolTip = 'Specifies if you want to delete the stored lines that are created before the data in the VAT ledger is refreshed.';
                    }
                    field(TotalDetails; TotalDetails)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Aggregated Totals';
                        ToolTip = 'Specifies if you want to show the totals in groups.';
                    }
                    field(ShowRealVAT; ShowRealVAT)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Realized VAT';
                        Editable = false;
                        ToolTip = 'Specifies if you want to include realized VAT entries.';
                    }
                    field(ShowUnrealVAT; ShowUnrealVAT)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Unrealized VAT';
                        Editable = false;
                        ToolTip = 'Specifies if you want to include unrealized VAT entries.';
                    }
                    field(ShowPrepayment; ShowPrepayment)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Customer Prepayments';
                        Editable = false;
                        ToolTip = 'Specifies if you want to include customer prepayment information.';
                    }
                    field(ShowAmtDiff; ShowAmtDiff)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amount Differences';
                        Editable = false;
                        ToolTip = 'Specifies if you want to include exchange rate differences.';
                    }
                    field(Details; Details)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Details';
                        ToolTip = 'Specifies if the report displays all lines in detail.';
                    }
                    field(ShowVendPrepmt; ShowVendPrepmt)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Vendor Prepayments';
                        Editable = false;
                        ToolTip = 'Specifies if you want to include vendor prepayment information.';

                        trigger OnValidate()
                        begin
                            ShowVendPrepmtOnPush();
                        end;
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
        CompanyInfo.Get();
        if StartPageNo > 0 then
            StartPageNo := StartPageNo - 1
        else
            StartPageNo := 0;
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12400: Label 'cannot be %1 if Tax Invoice Amount Type is %2';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CompanyInfo: Record "Company Information";
        LedgerConnBuffer: Record "VAT Ledger Connection" temporary;
        LedgerBuffer: Record "VAT Ledger Line" temporary;
        ShipmentBuffer: Record "VAT Ledger Line" temporary;
        PrepaymBuffer: Record "VAT Ledger Line" temporary;
        PaymentBuffer: Record "VAT Ledger Line" temporary;
        AmtDiffBuffer: Record "VAT Ledger Line" temporary;
        AmountBuffer: Record "VAT Ledger Line" temporary;
        Details: Boolean;
        ShowRealVAT: Boolean;
        ShowUnrealVAT: Boolean;
        ShowPrepayment: Boolean;
        ShowAmtDiff: Boolean;
        Sorting: Option " ","Document Date","Document No.","Customer No.";
        LineNo: Integer;
        StartPageNo: Integer;
        LineLabel: Option " ","_By Pay","@ PrePay","$ Amt.Diff";
        CustNo: Code[20];
        DocumentNo: Code[30];
        DocumentDate: Date;
        VendFilter: Code[250];
        CustFilter: Code[250];
        VATProdGroupFilter: Code[250];
        VATBusGroupFilter: Code[250];
        ClearOperation: Boolean;
        TotalDetails: Boolean;
        RealVATEntryDate: Date;
        VATEntryNo: Integer;
        PaymentDate: Date;
        ShowVendPrepmt: Boolean;
        VATLedgMgt: Codeunit "VAT Ledger Management";
        CorrectionNo: Code[20];
        CorrectionDate: Date;
        RevisionNo: Code[20];
        RevisionDate: Date;
        RevisionOfCorrectionNo: Code[20];
        RevisionOfCorrectionDate: Date;
        PrintRevision: Boolean;

    [Scope('OnPrem')]
    procedure Check(VATEntry: Record "VAT Entry"): Boolean
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxDetail: Record "Tax Detail";
    begin
        Clear(AmountBuffer);

        VATEntry."Tax Invoice Amount Type" := VATEntry."Tax Invoice Amount Type"::VAT;
        case VATEntry."VAT Calculation Type" of
            VATEntry."VAT Calculation Type"::"Full VAT",
            VATEntry."VAT Calculation Type"::"Normal VAT":
                begin
                    VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
                    if VATPostingSetup."Not Include into VAT Ledger" in
                       [VATPostingSetup."Not Include into VAT Ledger"::Sales,
                        VATPostingSetup."Not Include into VAT Ledger"::"Purchases & Sales"]
                    then
                        exit(false);
                    VATEntry."Tax Invoice Amount Type" := VATPostingSetup."Tax Invoice Amount Type";
                end;
            VATEntry."VAT Calculation Type"::"Sales Tax":
                begin
                    TaxJurisdiction.Get(VATEntry."Tax Jurisdiction Code");
                    if TaxJurisdiction."Not Include into Ledger" in
                       [TaxJurisdiction."Not Include into Ledger"::Sales,
                        TaxJurisdiction."Not Include into Ledger"::"Purchase & Sales"]
                    then
                        exit(false);
                    VATEntry."Tax Invoice Amount Type" := TaxJurisdiction."Sales Tax Amount Type";
                    TaxDetail.SetRange("Tax Jurisdiction Code", VATEntry."Tax Jurisdiction Code");
                    TaxDetail.SetRange("Tax Group Code", VATEntry."Tax Group Used");
                    TaxDetail.SetRange("Tax Type", VATEntry."Tax Type");
                    TaxDetail.SetRange("Effective Date", 0D, VATEntry."Posting Date");
                    TaxDetail.Find('+');
                end;
        end;
        case VATEntry."Tax Invoice Amount Type" of
            VATEntry."Tax Invoice Amount Type"::Excise:
                case VATEntry."VAT Calculation Type" of
                    VATEntry."VAT Calculation Type"::"Full VAT",
                  VATEntry."VAT Calculation Type"::"Sales Tax":
                        AmountBuffer."Excise Amount" := VATEntry.Amount;
                    else
                        VATEntry.FieldError("VAT Calculation Type",
                          StrSubstNo(Text12400,
                            VATEntry."VAT Calculation Type", VATEntry."Tax Invoice Amount Type"));
                end;
            VATEntry."Tax Invoice Amount Type"::VAT:
                case VATEntry."VAT Calculation Type" of
                    VATEntry."VAT Calculation Type"::"Full VAT":
                        begin
                            AmountBuffer."Full VAT Amount" := VATEntry.Amount;
                            CheckVAT(VATEntry, VATPostingSetup."VAT %", VATPostingSetup."VAT Exempt");
                        end;
                    VATEntry."VAT Calculation Type"::"Normal VAT":
                        CheckVAT(VATEntry, VATPostingSetup."VAT %", VATPostingSetup."VAT Exempt");
                    VATEntry."VAT Calculation Type"::"Sales Tax":
                        CheckVAT(VATEntry, TaxDetail."Tax Below Maximum", VATPostingSetup."VAT Exempt");
                    else
                        VATEntry.FieldError("VAT Calculation Type",
                          StrSubstNo(Text12400,
                            VATEntry."VAT Calculation Type", VATEntry."Tax Invoice Amount Type"));
                end;
            VATEntry."Tax Invoice Amount Type"::"Sales Tax":
                case VATEntry."VAT Calculation Type" of
                    VATEntry."VAT Calculation Type"::"Full VAT":
                        AmountBuffer."Full Sales Tax Amount" := VATEntry.Amount;
                    VATEntry."VAT Calculation Type"::"Sales Tax":
                        begin
                            AmountBuffer."Sales Tax Amount" := VATEntry.Amount;
                            AmountBuffer."Sales Tax Base" := VATEntry.Base;
                        end;
                    else
                        VATEntry.FieldError("VAT Calculation Type",
                          StrSubstNo(Text12400,
                            VATEntry."VAT Calculation Type", VATEntry."Tax Invoice Amount Type"));
                end;
            else
                VATEntry.FieldError("Tax Invoice Amount Type",
                  StrSubstNo(Text12400,
                    VATEntry."Tax Invoice Amount Type", VATEntry.FieldCaption(Type), VATEntry.Type));
        end;
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure CheckVAT(VATEntry: Record "VAT Entry"; VATPercent: Decimal; VATExempt: Boolean)
    begin
        if VATPercent = 0 then
            if not VATExempt then
                AmountBuffer.Base0 := VATEntry.Base + VATEntry."Unrealized Base"
            else
                AmountBuffer."Base VAT Exempt" := VATEntry.Base + VATEntry."Unrealized Base"
        else
            case VATPercent of
                9.09, 10:
                    begin
                        AmountBuffer.Base10 := VATEntry.Base + VATEntry."Unrealized Base";
                        AmountBuffer.Amount10 := VATEntry.Amount + VATEntry."Unrealized Amount";
                    end;
                VATLedgMgt.GetVATPctRate2018():
                    begin
                        AmountBuffer.Base18 := VATEntry.Base + VATEntry."Unrealized Base";
                        AmountBuffer.Amount18 := VATEntry.Amount + VATEntry."Unrealized Amount";
                    end;
                16.67, 20:
                    begin
                        AmountBuffer.Base20 := VATEntry.Base + VATEntry."Unrealized Base";
                        AmountBuffer.Amount20 := VATEntry.Amount + VATEntry."Unrealized Amount";
                    end;
                else begin
                    AmountBuffer.Base18 := VATEntry.Base + VATEntry."Unrealized Base";
                    AmountBuffer.Amount18 := VATEntry.Amount + VATEntry."Unrealized Amount";
                    AmountBuffer."VAT Percent" := VATPercent;
                end;
            end;
    end;

    [Scope('OnPrem')]
    procedure MakeSalesBook(VATEntry: Record "VAT Entry"; var LedgerBuffer: Record "VAT Ledger Line" temporary)
    var
        Cust: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Vend: Record Vendor;
        CurrencyCode: Code[10];
        VATEntryType: Code[15];
        CVLedgEntryAmount: Decimal;
    begin
        if not Check(VATEntry) then
            exit;

        LedgerBuffer.SetRange("Document No.", DocumentNo);
        if VATEntry.Prepayment then
            LedgerBuffer.SetRange(Method)
        else
            if VATEntry."Unrealized VAT Entry No." = 0 then
                LedgerBuffer.SetRange(Method, LedgerBuffer.Method::Shipment)
            else
                LedgerBuffer.SetRange(Method, LedgerBuffer.Method::Payment);
        LedgerBuffer.SetRange(Prepayment, VATEntry.Prepayment);
        LedgerBuffer.SetRange("Amt. Diff. VAT", false);
        LedgerBuffer.SetRange("Document Type", VATEntry."Document Type");
        LedgerBuffer.SetRange("C/V No.", CustNo);

        if VATEntry."Corrective Doc. Type" <> VATEntry."Corrective Doc. Type"::" " then
            case VATEntry."Corrective Doc. Type" of
                VATEntry."Corrective Doc. Type"::Correction:
                    LedgerBuffer.SetRange("Correction No.", CorrectionNo);
                VATEntry."Corrective Doc. Type"::Revision:
                    begin
                        if RevisionNo <> '' then
                            LedgerBuffer.SetRange("Revision No.", RevisionNo);
                        if RevisionOfCorrectionNo <> '' then
                            LedgerBuffer.SetRange("Revision of Corr. No.", RevisionOfCorrectionNo);
                    end;
            end
        else begin
            LedgerBuffer.SetRange("Correction No.");
            LedgerBuffer.SetRange("Revision No.");
            LedgerBuffer.SetRange("Revision of Corr. No.");
        end;

        if LedgerBuffer.IsEmpty() then begin
            LedgerBuffer.Init();
            LineNo := LineNo + 1;
            LedgerBuffer.Type := VATLedgerName.Type;
            LedgerBuffer.Code := VATLedgerName.Code;
            LedgerBuffer."Line No." := LineNo;
            LedgerBuffer."Document No." := DocumentNo;
            LedgerBuffer."Origin. Document No." := CopyStr(DocumentNo, 1, MaxStrLen(LedgerBuffer."Origin. Document No."));
            LedgerBuffer."External Document No." := VATEntry."External Document No.";
            GetVATEntryValues(VATEntry, CVLedgEntryAmount, CurrencyCode, VATEntryType);
            LedgerBuffer.Amount := CVLedgEntryAmount;
            LedgerBuffer."Currency Code" := CurrencyCode;
            LedgerBuffer."VAT Entry Type" := VATEntryType;

            LedgerBuffer."Real. VAT Entry Date" := RealVATEntryDate;
            LedgerBuffer."Payment Date" := PaymentDate;
            LedgerBuffer."Transaction/Entry No." := VATEntry."Transaction No.";
            if VATEntry."Unrealized VAT Entry No." = 0 then
                LedgerBuffer.Method := LedgerBuffer.Method::Shipment
            else
                LedgerBuffer.Method := LedgerBuffer.Method::Payment;
            LedgerBuffer.Prepayment := VATEntry.Prepayment;
            LedgerBuffer."VAT Product Posting Group" := VATEntry."VAT Prod. Posting Group";
            LedgerBuffer."VAT Business Posting Group" := VATEntry."VAT Bus. Posting Group";
            LedgerBuffer."Document Type" := VATEntry."Document Type";
            LedgerBuffer."C/V No." := CustNo;
            LedgerBuffer."Document Date" := VATEntry."Posting Date";
            LedgerBuffer.Prepayment := VATEntry.Prepayment;

            case VATEntry.Type of
                VATEntry.Type::Purchase:
                    begin
                        LedgerBuffer."C/V Type" := LedgerBuffer."C/V Type"::Vendor;
                        if VATEntry.Prepayment or VATEntry."VAT Agent" then begin
                            LedgerBuffer."C/V Name" := CompanyInfo.Name + CompanyInfo."Name 2";
                            LedgerBuffer."C/V VAT Reg. No." := CompanyInfo."VAT Registration No.";
                            LedgerBuffer."Reg. Reason Code" := CompanyInfo."KPP Code";
                        end else
                            if Vend.Get(LedgerBuffer."C/V No.") then begin
                                LedgerBuffer."C/V Name" := Vend.Name + Vend."Name 2";
                                LedgerBuffer."C/V VAT Reg. No." := Vend."VAT Registration No.";
                                LedgerBuffer."Reg. Reason Code" := Vend."KPP Code";
                            end else
                                Vend.Init();
                    end;
                VATEntry.Type::Sale:
                    begin
                        LedgerBuffer."C/V Type" := LedgerBuffer."C/V Type"::Customer;
                        if Cust.Get(LedgerBuffer."C/V No.") then begin
                            LedgerBuffer."C/V Name" := Cust.Name + Cust."Name 2";
                            LedgerBuffer."C/V VAT Reg. No." := Cust."VAT Registration No.";
                            LedgerBuffer."Reg. Reason Code" := Cust."KPP Code";
                        end else
                            Cust.Init();
                    end;
            end;

            case VATEntry."Document Type" of
                VATEntry."Document Type"::Invoice:
                    if SalesInvoiceHeader.Get(VATEntry."Document No.") then
                        if SalesInvoiceHeader."KPP Code" <> '' then
                            LedgerBuffer."Reg. Reason Code" := SalesInvoiceHeader."KPP Code";
                VATEntry."Document Type"::"Credit Memo":
                    if SalesCrMemoHeader.Get(VATEntry."Document No.") then
                        if SalesCrMemoHeader."KPP Code" <> '' then
                            LedgerBuffer."Reg. Reason Code" := SalesCrMemoHeader."KPP Code";
            end;

            LedgerBuffer."Additional Sheet" := VATEntry."Additional VAT Ledger Sheet";
            if VATEntry."Additional VAT Ledger Sheet" then
                LedgerBuffer."Corr. VAT Entry Posting Date" := VATEntry."Posting Date";

            if VATEntry."Corrective Doc. Type" <> VATEntry."Corrective Doc. Type"::" " then begin
                LedgerBuffer."Document Date" := DocumentDate;
                LedgerBuffer."Correction No." := CorrectionNo;
                LedgerBuffer."Correction Date" := CorrectionDate;
                LedgerBuffer."Revision No." := RevisionNo;
                LedgerBuffer."Revision Date" := RevisionDate;
                LedgerBuffer."Revision of Corr. No." := RevisionOfCorrectionNo;
                LedgerBuffer."Revision of Corr. Date" := RevisionOfCorrectionDate;
                LedgerBuffer."Print Revision" := PrintRevision;
            end;

            LedgerBuffer.Insert();
            InsertLedgerConnBuffer(LedgerBuffer, VATEntry."Entry No.");
        end;

        UpdateLedgerBufferAmounts();
    end;

    [Scope('OnPrem')]
    procedure CheckMethod()
    begin
        if LedgerBuffer."Amt. Diff. VAT" then begin
            ShipmentBuffer.Init();
            PaymentBuffer.Init();
            PrepaymBuffer.Init();
            AmtDiffBuffer := LedgerBuffer;
            LineLabel := LineLabel::"$ Amt.Diff";
        end else
            if LedgerBuffer.Prepayment then begin
                ShipmentBuffer.Init();
                PaymentBuffer.Init();
                PrepaymBuffer := LedgerBuffer;
                AmtDiffBuffer.Init();
                LineLabel := LineLabel::"@ PrePay";
            end else
                if LedgerBuffer.Method = LedgerBuffer.Method::Shipment then begin
                    ShipmentBuffer := LedgerBuffer;
                    PaymentBuffer.Init();
                    PrepaymBuffer.Init();
                    AmtDiffBuffer.Init();
                    LineLabel := LineLabel::" ";
                end else begin
                    ShipmentBuffer.Init();
                    PaymentBuffer := LedgerBuffer;
                    PrepaymBuffer.Init();
                    AmtDiffBuffer.Init();
                    LineLabel := LineLabel::"_By Pay";
                end;
    end;

    [Scope('OnPrem')]
    procedure SaveSalesLedger()
    var
        LedgerLine: Record "VAT Ledger Line";
        LedgerConnection: Record "VAT Ledger Connection";
    begin
        LedgerBuffer.Reset();
        if LedgerBuffer.FindSet() then
            repeat
                LedgerBuffer."Amount Including VAT" :=
                  Round(LedgerBuffer.Base20 + LedgerBuffer.Amount20 +
                    LedgerBuffer.Base18 + LedgerBuffer.Amount18 +
                    LedgerBuffer.Base10 + LedgerBuffer.Amount10 +
                    LedgerBuffer."Sales Tax Amount" + LedgerBuffer."Full Sales Tax Amount" + LedgerBuffer."Base VAT Exempt" +
                    LedgerBuffer.Base0,
                    0.01);

                if LedgerBuffer."Amount Including VAT" <> 0 then begin
                    LedgerLine := LedgerBuffer;
                    LedgerLine.Correction := LedgerLine.IsCorrection();
                    LedgerLine.Insert();
                end else begin
                    LedgerConnBuffer.SetRange("Sales Ledger Code", LedgerBuffer.Code);
                    LedgerConnBuffer.SetRange("Sales Ledger Line No.", LedgerBuffer."Line No.");
                    LedgerConnBuffer.DeleteAll();
                end;
            until LedgerBuffer.Next() = 0;

        LedgerConnBuffer.Reset();
        if LedgerConnBuffer.FindSet() then
            repeat
                LedgerConnection := LedgerConnBuffer;
                LedgerConnection.Insert();
            until LedgerConnBuffer.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewCustFilter: Text[250])
    begin
        ShowRealVAT := true;
        ShowUnrealVAT := true;
        ShowPrepayment := true;
        ShowAmtDiff := true;
        CustFilter := NewCustFilter;
        ClearOperation := true;
    end;

    [Scope('OnPrem')]
    procedure GetLineProperties(VATEntryNo: Integer)
    var
        VATEntry: Record "VAT Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        if VATEntry.Get(VATEntryNo) then begin
            DocumentNo := VATEntry."Document No.";
            DocumentDate := VATEntry."Posting Date";
            CustNo := VATEntry."Bill-to/Pay-to No.";
            if VATEntry.Prepayment then
                case VATEntry.Type of
                    VATEntry.Type::Sale:
                        begin
                            CustLedgEntry.SetCurrentKey("Transaction No.");
                            CustLedgEntry.SetRange("Transaction No.", VATEntry."Transaction No.");
                            if CustLedgEntry.FindFirst() then begin
                                DocumentNo := CustLedgEntry."Prepayment Document No.";
                                PaymentDate := CustLedgEntry."Posting Date";
                            end;
                        end;
                    VATEntry.Type::Purchase:
                        if VendLedgEntry.Get(VATEntry."CV Ledg. Entry No.") then begin
                            DocumentNo := VendLedgEntry."Vendor VAT Invoice No.";
                            DocumentDate := VendLedgEntry."Vendor VAT Invoice Date";
                            PaymentDate := VendLedgEntry."Posting Date";
                        end;
                end;
            if VATEntry."Corrective Doc. Type" <> VATEntry."Corrective Doc. Type"::" " then
                VATLedgMgt.GetCorrDocProperties(
                  VATEntry, DocumentNo, DocumentDate, CorrectionNo, CorrectionDate,
                  RevisionNo, RevisionDate, RevisionOfCorrectionNo, RevisionOfCorrectionDate, PrintRevision);
        end;
    end;

    [Scope('OnPrem')]
    procedure InvertVATEntry(var VATEntry: Record "VAT Entry")
    begin
        VATEntry.Base := -VATEntry.Base;
        VATEntry."Unrealized Base" := -VATEntry."Unrealized Base";
        VATEntry.Amount := -VATEntry.Amount;
        VATEntry."Unrealized Amount" := -VATEntry."Unrealized Amount";
    end;

    [Scope('OnPrem')]
    procedure ReversedByCorrection(ReversedVATEntry: Record "VAT Entry"): Boolean
    var
        ReversedByVATEntry: Record "VAT Entry";
    begin
        if ReversedVATEntry.Reversed then begin
            if ReversedVATEntry."Additional VAT Ledger Sheet" then
                exit(true);

            if ReversedByVATEntry.Get(ReversedVATEntry."Reversed by Entry No.") then
                exit(ReversedByVATEntry."Corrected Document Date" <> 0D);
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure IsNotNullAmounts(VATLedgerLine: Record "VAT Ledger Line"): Boolean
    begin
        exit(not
              ((VATLedgerLine."Amount Including VAT" = 0) and
               (VATLedgerLine.Base20 = 0) and
               (VATLedgerLine.Amount20 = 0) and
               (VATLedgerLine.Base10 = 0) and
               (VATLedgerLine.Amount10 = 0) and
               (VATLedgerLine."Sales Tax Amount" = 0) and
               (VATLedgerLine."Sales Tax Base" = 0) and
               (VATLedgerLine.Base0 = 0) and
               (VATLedgerLine."Full VAT Amount" = 0) and
               (VATLedgerLine."Full Sales Tax Amount" = 0)));
    end;

    procedure SetParameters(NewCustFilter: Code[250]; NewVATProdGroupFilter: Code[250]; NewVATBusGroupFilter: Code[250]; NewSorting: Option " ","Document Date","Document No.","Customer No."; NewClearOperation: Boolean; NewShowRealVAT: Boolean; NewShowUnrealVAT: Boolean; NewShowCustPrepmt: Boolean; NewShowAmtDiff: Boolean; NewShowVendPrepmt: Boolean)
    begin
        CustFilter := NewCustFilter;
        VATProdGroupFilter := NewVATProdGroupFilter;
        VATBusGroupFilter := NewVATBusGroupFilter;
        Sorting := NewSorting;
        ClearOperation := NewClearOperation;
        ShowRealVAT := NewShowRealVAT;
        ShowUnrealVAT := NewShowUnrealVAT;
        ShowPrepayment := NewShowCustPrepmt;
        ShowAmtDiff := NewShowAmtDiff;
        ShowVendPrepmt := NewShowVendPrepmt;
    end;

    local procedure ShowVendPrepmtOnPush()
    begin
        if not ShowVendPrepmt then
            VendFilter := '';
    end;

    local procedure GetVATEntryValues(VATEntry: Record "VAT Entry"; var CVLedgEntryAmount: Decimal; var CurrencyCode: Code[10]; var VATEntryType: Code[15])
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if VATEntry.Type = VATEntry.Type::Sale then
            if CustLedgerEntry.Get(VATEntry."CV Ledg. Entry No.") then begin
                CustLedgerEntry.CalcFields(Amount);
                CVLedgEntryAmount := Abs(CustLedgerEntry.Amount);
                CurrencyCode := CustLedgerEntry."Currency Code";
                VATEntryType := CustLedgerEntry."VAT Entry Type";
            end;
        if VATEntry.Type = VATEntry.Type::Purchase then
            if VendLedgerEntry.Get(VATEntry."CV Ledg. Entry No.") then begin
                VendLedgerEntry.CalcFields(Amount);
                CVLedgEntryAmount := Abs(VendLedgerEntry.Amount);
                CurrencyCode := VendLedgerEntry."Currency Code";
                VATEntryType := VendLedgerEntry."VAT Entry Type";
            end;
    end;

    local procedure InsertLedgerConnBuffer(VATLedgerLine: Record "VAT Ledger Line"; VATEntryNo: Integer)
    begin
        LedgerConnBuffer.Init();
        LedgerConnBuffer."Connection Type" := LedgerConnBuffer."Connection Type"::Sales;
        LedgerConnBuffer."Sales Ledger Code" := VATLedgerLine.Code;
        LedgerConnBuffer."Sales Ledger Line No." := VATLedgerLine."Line No.";
        LedgerConnBuffer."Purch. Ledger Code" := '';
        LedgerConnBuffer."Purch. Ledger Line No." := 0;
        LedgerConnBuffer."VAT Entry No." := VATEntryNo;
        LedgerConnBuffer.Insert();
    end;

    local procedure UpdateLedgerBufferAmounts()
    begin
        LedgerBuffer.Base10 := LedgerBuffer.Base10 - AmountBuffer.Base10;
        LedgerBuffer.Amount10 := LedgerBuffer.Amount10 - AmountBuffer.Amount10;
        LedgerBuffer.Base20 := LedgerBuffer.Base20 - AmountBuffer.Base20;
        LedgerBuffer.Amount20 := LedgerBuffer.Amount20 - AmountBuffer.Amount20;
        LedgerBuffer.Base18 := LedgerBuffer.Base18 - AmountBuffer.Base18;
        LedgerBuffer.Amount18 := LedgerBuffer.Amount18 - AmountBuffer.Amount18;
        LedgerBuffer."Full VAT Amount" := LedgerBuffer."Full VAT Amount" - AmountBuffer."Full VAT Amount";
        LedgerBuffer."Sales Tax Amount" := LedgerBuffer."Sales Tax Amount" - AmountBuffer."Sales Tax Amount";
        LedgerBuffer."Sales Tax Base" := LedgerBuffer."Sales Tax Base" - AmountBuffer."Sales Tax Base";
        LedgerBuffer."Full Sales Tax Amount" := LedgerBuffer."Full Sales Tax Amount" - AmountBuffer."Full Sales Tax Amount";
        LedgerBuffer."Base VAT Exempt" := LedgerBuffer."Base VAT Exempt" - AmountBuffer."Base VAT Exempt";
        LedgerBuffer."Excise Amount" := LedgerBuffer."Excise Amount" - AmountBuffer."Excise Amount";
        LedgerBuffer.Base0 := LedgerBuffer.Base0 - AmountBuffer.Base0;
        if DocumentDate <> 0D then
            LedgerBuffer."Document Date" := DocumentDate;
        LedgerBuffer.Modify();
    end;
}

