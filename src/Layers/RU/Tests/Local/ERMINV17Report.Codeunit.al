codeunit 144704 "ERM INV-17 Report"
{
    TestPermissions = NonRestrictive;
    Subtype = Test;
    Permissions = tabledata "Cust. Ledger Entry" = i,
                  tabledata "Detailed Cust. Ledg. Entry" = i,
                  tabledata "Vendor Ledger Entry" = i,
                  tabledata "Detailed Vendor Ledg. Entry" = i;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LocMgt: Codeunit "Localisation Management";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure InventActHeader()
    var
        InvtActHeader: Record "Invent. Act Header";
    begin
        Initialize();
        MockInvActHeader(InvtActHeader);
        RunINV17Report(InvtActHeader);
        VerifyReportHeader(
          InvtActHeader."Reason Document No.", InvtActHeader."Reason Document Date",
          InvtActHeader."No.", InvtActHeader."Act Date", InvtActHeader."Inventory Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultilineInventAct()
    var
        InvtActHeader: Record "Invent. Act Header";
        TempInvtActLine: Record "Invent. Act Line" temporary;
    begin
        Initialize();
        MockInvActHeader(InvtActHeader);
        InitCustBuffer(TempInvtActLine, InvtActHeader."No.");
        InitVendBuffer(TempInvtActLine, InvtActHeader."No.");
        RunINV17Report(InvtActHeader);
        VerifyReportLineValuesFromBuffer(TempInvtActLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplementInvAct()
    var
        InvtActHeader: Record "Invent. Act Header";
        InvtActLine: Record "Invent. Act Line";
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        TempVendLedgEntry: Record "Vendor Ledger Entry" temporary;
        CategoryType: Option;
        Counter: Integer;
    begin
        Initialize();
        MockInvActHeader(InvtActHeader);
        MockCustomerWithLedgEntries(TempCustLedgEntry, InvtActHeader."Inventory Date");
        MockVendorWithLedgEntries(TempVendLedgEntry, InvtActHeader."Inventory Date");
        for CategoryType := InvtActLine.Category::Debts to InvtActLine.Category::Liabilities do begin
            MockInvActLine(
              InvtActLine, InvtActHeader."No.", InvtActLine."Contractor Type"::Customer, TempCustLedgEntry."Customer No."
              , '', TempCustLedgEntry."Customer Posting Group", CategoryType);
            MockInvActLine(
              InvtActLine, InvtActHeader."No.", InvtActLine."Contractor Type"::Vendor, TempVendLedgEntry."Vendor No."
              , '', TempVendLedgEntry."Vendor Posting Group", CategoryType);
        end;
        RunINV17SupplementReport(InvtActHeader);
        VerifySupplementLineValuesFromCustBuffer(TempCustLedgEntry, Counter);
        VerifySupplementLineValuesFromVendBuffer(TempVendLedgEntry, Counter);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        Clear(LibraryReportValidation);

        if isInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
    end;

    local procedure MockInvActHeader(var InvtActHeader: Record "Invent. Act Header")
    begin
        InvtActHeader.Init();
        InvtActHeader.Insert(true);
        InvtActHeader.Validate("Inventory Date", WorkDate());
        InvtActHeader.Validate("Reason Document No.", LibraryUtility.GenerateGUID());
        InvtActHeader.Validate("Reason Document Date", CalcDate('<1D>', InvtActHeader."Inventory Date"));
        InvtActHeader.Validate("Act Date", CalcDate('<1D>', InvtActHeader."Reason Document Date"));
        InvtActHeader.Modify(true);
    end;

    local procedure InitCustBuffer(var TempInvtActLine: Record "Invent. Act Line" temporary; ActNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        i: Integer;
        j: Integer;
    begin
        LibraryERM.FindGLAccount(GLAccount);
        Customer.SetFilter(Name, '<>%1', '');
        Customer.FindSet();
        for i := 1 to 2 do begin
            CustomerPostingGroup.FindSet();
            for j := 1 to 2 do begin
                MockGroupInvtActLine(
                  TempInvtActLine, ActNo, TempInvtActLine."Contractor Type"::Customer, Customer."No.", GLAccount."No.",
                  CustomerPostingGroup.Code);
                CustomerPostingGroup.Next();
            end;
            Customer.Next();
        end;
    end;

    local procedure InitVendBuffer(var TempInvtActLine: Record "Invent. Act Line" temporary; ActNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        i: Integer;
        j: Integer;
    begin
        LibraryERM.FindGLAccount(GLAccount);
        Vendor.SetFilter(Name, '<>%1', '');
        Vendor.FindSet();
        for i := 1 to 2 do begin
            VendorPostingGroup.FindSet();
            for j := 1 to 2 do begin
                MockGroupInvtActLine(
                  TempInvtActLine, ActNo, TempInvtActLine."Contractor Type"::Vendor, Vendor."No.", GLAccount."No.",
                  VendorPostingGroup.Code);
                VendorPostingGroup.Next();
            end;
            Vendor.Next();
        end;
    end;

    local procedure MockGroupInvtActLine(var TempInvtActLine: Record "Invent. Act Line" temporary; ActNo: Code[20]; ContractorType: Option; ContractorNo: Code[20]; GLAccNo: Code[20]; PostingGroupCode: Code[20])
    var
        InvtActLine: Record "Invent. Act Line";
        CategoryType: Option;
    begin
        TempInvtActLine.SetRange("Contractor No.", ContractorNo);
        TempInvtActLine.SetRange("Contractor Type", ContractorType);

        for CategoryType := InvtActLine.Category::Debts to InvtActLine.Category::Liabilities do begin
            MockInvActLine(
              InvtActLine, ActNo, ContractorType, ContractorNo, GLAccNo, PostingGroupCode,
              CategoryType);
            TempInvtActLine.SetRange(Category, CategoryType);
            if TempInvtActLine.FindFirst() then
                SummarizeAmounts(TempInvtActLine, InvtActLine)
            else begin
                TempInvtActLine := InvtActLine;
                TempInvtActLine.Insert();
            end;
        end;
    end;

    local procedure MockInvActLine(var InvtActLine: Record "Invent. Act Line"; ActNo: Code[20]; ContractorType: Option; ContractorNo: Code[20]; GLAccNo: Code[20]; PostingGroup: Code[20]; CategoryType: Option)
    begin
        InvtActLine.Init();
        InvtActLine.Validate("Act No.", ActNo);
        InvtActLine.Validate("Contractor Type", ContractorType);
        InvtActLine.Validate("Contractor No.", ContractorNo);
        InvtActLine.Validate("Posting Group", PostingGroup);
        InvtActLine.Validate(Category, CategoryType);
        InvtActLine.Validate("Contractor Name", GetContractorName(ContractorType, ContractorNo));
        InvtActLine.Validate("G/L Account No.", GLAccNo);
        InvtActLine.Validate("Total Amount", LibraryRandom.RandDec(100, 2));
        InvtActLine.Validate("Confirmed Amount", LibraryRandom.RandDec(100, 2));
        InvtActLine.Validate("Not Confirmed Amount", LibraryRandom.RandDec(100, 2));
        InvtActLine.Validate("Overdue Amount", LibraryRandom.RandDec(100, 2));
        InvtActLine.Insert(true);
    end;

    local procedure MockCustomerWithLedgEntries(var CustLedgEntry: Record "Cust. Ledger Entry"; InvDate: Date)
    var
        Customer: Record Customer;
        CustAgreement: Record "Customer Agreement";
        CustPostingGroup: Record "Customer Posting Group";
        EntryAmount: Decimal;
    begin
        CustPostingGroup.FindFirst();
        Customer.Init();
        Customer."Customer Posting Group" := CustPostingGroup.Code;
        Customer.Name := LibraryUtility.GenerateGUID();
        Customer."Name 2" := LibraryUtility.GenerateGUID();
        Customer.Address := LibraryUtility.GenerateGUID();
        Customer."Address 2" := LibraryUtility.GenerateGUID();
        Customer."Phone No." := LibraryUtility.GenerateGUID();
        Customer."Agreement Posting" := Customer."Agreement Posting"::Mandatory;
        Customer.Insert(true);

        CustAgreement.Init();
        CustAgreement."Customer No." := Customer."No.";
        CustAgreement.Description := LibraryUtility.GenerateGUID();
        CustAgreement.Insert(true);

        EntryAmount := LibraryRandom.RandDec(100, 2);
        // Ledger entry outside of date range
        MockCustLedgEntryWithDtldEntry(
          CustLedgEntry, Customer, CalcDate('<1M>', InvDate), InvDate, CustAgreement."No.", EntryAmount, false);
        // Dtld. Ledger Entry outside of date range
        MockCustLedgEntryWithDtldEntry(
          CustLedgEntry, Customer, InvDate, CalcDate('<1M>', InvDate), CustAgreement."No.", EntryAmount, false);
        // Ledger Entries that should be print in report
        MockCustLedgEntryWithDtldEntry(
          CustLedgEntry, Customer, InvDate, InvDate, CustAgreement."No.", EntryAmount, true);
        MockCustLedgEntryWithDtldEntry(
          CustLedgEntry, Customer, InvDate, InvDate, CustAgreement."No.", -EntryAmount, true);
    end;

    local procedure MockVendorWithLedgEntries(var VendLedgEntry: Record "Vendor Ledger Entry"; InvDate: Date)
    var
        Vendor: Record Vendor;
        VendAgreement: Record "Vendor Agreement";
        VendPostingGroup: Record "Vendor Posting Group";
        EntryAmount: Decimal;
    begin
        VendPostingGroup.FindFirst();
        Vendor.Init();
        Vendor."Vendor Posting Group" := VendPostingGroup.Code;
        Vendor.Name := LibraryUtility.GenerateGUID();
        Vendor."Name 2" := LibraryUtility.GenerateGUID();
        Vendor.Address := LibraryUtility.GenerateGUID();
        Vendor."Address 2" := LibraryUtility.GenerateGUID();
        Vendor."Phone No." := LibraryUtility.GenerateGUID();
        Vendor."Agreement Posting" := Vendor."Agreement Posting"::Mandatory;
        Vendor.Insert(true);

        VendAgreement.Init();
        VendAgreement."Vendor No." := Vendor."No.";
        VendAgreement.Description := LibraryUtility.GenerateGUID();
        VendAgreement.Insert(true);

        EntryAmount := LibraryRandom.RandDec(100, 2);
        // Ledger entry outside of date range
        MockVendLedgEntryWithDtldEntry(
          VendLedgEntry, Vendor, CalcDate('<1M>', InvDate), InvDate, VendAgreement."No.", EntryAmount, false);
        // Dtld. Ledger Entry outside of date range
        MockVendLedgEntryWithDtldEntry(
          VendLedgEntry, Vendor, InvDate, CalcDate('<1M>', InvDate), VendAgreement."No.", EntryAmount, false);
        // Ledger Entries that should be print in report
        MockVendLedgEntryWithDtldEntry(
          VendLedgEntry, Vendor, InvDate, InvDate, VendAgreement."No.", EntryAmount, true);
        MockVendLedgEntryWithDtldEntry(
          VendLedgEntry, Vendor, InvDate, InvDate, VendAgreement."No.", -EntryAmount, true);
    end;

    local procedure MockCustLedgEntryWithDtldEntry(var CustLedgEntryBuffer: Record "Cust. Ledger Entry"; Customer: Record Customer; PostingDate: Date; DtldEntryPostingDate: Date; AgreementNo: Code[20]; EntryAmount: Decimal; InsertInBuffer: Boolean)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        EntryNo: Integer;
    begin
        if CustLedgEntry.FindLast() then
            EntryNo := CustLedgEntry."Entry No."
        else
            EntryNo := 0;
        EntryNo += 1;
        MockCustLedgEntry(CustLedgEntry, EntryNo, Customer."No.", Customer."Customer Posting Group", PostingDate, AgreementNo);

        if DtldCustLedgEntry.FindLast() then
            EntryNo := DtldCustLedgEntry."Entry No."
        else
            EntryNo := 0;
        EntryNo += 1;
        MockDtldCustLedgEntry(DtldCustLedgEntry, EntryNo, CustLedgEntry."Entry No.", DtldEntryPostingDate, EntryAmount);

        if InsertInBuffer then begin
            CustLedgEntryBuffer := CustLedgEntry;
            CustLedgEntryBuffer.Insert();
        end;
    end;

    local procedure MockCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; EntryNo: Integer; CustNo: Code[20]; CustPostGroupCode: Code[20]; PostingDate: Date; AgreementNo: Code[20])
    begin
        CustLedgEntry.Init();
        CustLedgEntry."Entry No." := EntryNo;
        CustLedgEntry."Customer No." := CustNo;
        CustLedgEntry."Customer Posting Group" := CustPostGroupCode;
        CustLedgEntry."Posting Date" := PostingDate;
        CustLedgEntry."Document Type" := CustLedgEntry."Document Type"::Invoice;
        CustLedgEntry."Document No." := LibraryUtility.GenerateGUID();
        CustLedgEntry."Agreement No." := AgreementNo;
        CustLedgEntry.Insert();
    end;

    local procedure MockDtldCustLedgEntry(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; EntryNo: Integer; CustLedgEntryNo: Integer; DtldEntryPostingDate: Date; EntryAmount: Decimal)
    begin
        DtldCustLedgEntry.Init();
        DtldCustLedgEntry."Entry No." := EntryNo;
        DtldCustLedgEntry."Cust. Ledger Entry No." := CustLedgEntryNo;
        DtldCustLedgEntry."Entry Type" := DtldCustLedgEntry."Entry Type"::"Initial Entry";
        DtldCustLedgEntry."Posting Date" := DtldEntryPostingDate;
        DtldCustLedgEntry."Amount (LCY)" := EntryAmount;
        DtldCustLedgEntry.Insert();
    end;

    local procedure MockVendLedgEntryWithDtldEntry(var VendLedgEntryBuffer: Record "Vendor Ledger Entry"; Vendor: Record Vendor; PostingDate: Date; DtldEntryPostingDate: Date; AgreementNo: Code[20]; EntryAmount: Decimal; InsertInBuffer: Boolean)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        EntryNo: Integer;
    begin
        if VendLedgEntry.FindLast() then
            EntryNo := VendLedgEntry."Entry No."
        else
            EntryNo := 0;
        EntryNo += 1;
        MockVendLedgEntry(VendLedgEntry, EntryNo, Vendor."No.", Vendor."Vendor Posting Group", PostingDate, AgreementNo);

        if DtldVendLedgEntry.FindLast() then
            EntryNo := DtldVendLedgEntry."Entry No."
        else
            EntryNo := 0;
        EntryNo += 1;
        MockDtldVendLedgEntry(DtldVendLedgEntry, EntryNo, VendLedgEntry."Entry No.", DtldEntryPostingDate, EntryAmount);

        if InsertInBuffer then begin
            VendLedgEntryBuffer := VendLedgEntry;
            VendLedgEntryBuffer.Insert();
        end;
    end;

    local procedure MockVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry"; EntryNo: Integer; VendNo: Code[20]; VendPostGroupCode: Code[20]; PostingDate: Date; AgreementNo: Code[20])
    begin
        VendLedgEntry.Init();
        VendLedgEntry."Entry No." := EntryNo;
        VendLedgEntry."Vendor No." := VendNo;
        VendLedgEntry."Vendor Posting Group" := VendPostGroupCode;
        VendLedgEntry."Posting Date" := PostingDate;
        VendLedgEntry."Document Type" := VendLedgEntry."Document Type"::Invoice;
        VendLedgEntry."Document No." := LibraryUtility.GenerateGUID();
        VendLedgEntry."Agreement No." := AgreementNo;
        VendLedgEntry.Insert();
    end;

    local procedure MockDtldVendLedgEntry(var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; EntryNo: Integer; VendLedgEntryNo: Integer; DtldEntryPostingDate: Date; EntryAmount: Decimal)
    begin
        DtldVendLedgEntry.Init();
        DtldVendLedgEntry."Entry No." := EntryNo;
        DtldVendLedgEntry."Vendor Ledger Entry No." := VendLedgEntryNo;
        DtldVendLedgEntry."Entry Type" := DtldVendLedgEntry."Entry Type"::"Initial Entry";
        DtldVendLedgEntry."Posting Date" := DtldEntryPostingDate;
        DtldVendLedgEntry."Amount (LCY)" := EntryAmount;
        DtldVendLedgEntry.Insert();
    end;

    local procedure GetContractorName(ContractorType: Option; ContractorNo: Code[20]): Text[250]
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        InvtActLine: Record "Invent. Act Line";
    begin
        case ContractorType of
            InvtActLine."Contractor Type"::Customer:
                begin
                    Customer.Get(ContractorNo);
                    exit(Customer.Name);
                end;
            InvtActLine."Contractor Type"::Vendor:
                begin
                    Vendor.Get(ContractorNo);
                    exit(Vendor.Name);
                end;
        end;
    end;

    local procedure GetCustFullNameAndContacts(CustNo: Code[20]): Text
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustNo);
        exit(
          Customer.Name + Customer."Name 2" + ', ' + Customer.Address +
          Customer."Address 2" + ', ' + Customer."Phone No.");
    end;

    local procedure GetCustAgrDescription(CustLedgEntry: Record "Cust. Ledger Entry"): Text
    var
        CustAgreement: Record "Customer Agreement";
    begin
        CustAgreement.Get(CustLedgEntry."Customer No.", CustLedgEntry."Agreement No.");
        exit(CustLedgEntry.Description + ' ' + CustAgreement.Description);
    end;

    local procedure GetVendFullNameAndContacts(VendNo: Code[20]): Text
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendNo);
        exit(
          Vendor.Name + Vendor."Name 2" + ', ' + Vendor.Address +
          Vendor."Address 2" + ', ' + Vendor."Phone No.");
    end;

    local procedure GetVendAgrDescription(VendLedgEntry: Record "Vendor Ledger Entry"): Text
    var
        VendAgreement: Record "Vendor Agreement";
    begin
        VendAgreement.Get(VendLedgEntry."Vendor No.", VendLedgEntry."Agreement No.");
        exit(VendLedgEntry.Description + ' ' + VendAgreement.Description);
    end;

    local procedure CalcDebtLiabilitiesAmount(var DebtsAmount: Decimal; var LiabilitiesAmount: Decimal; Amount: Decimal)
    begin
        DebtsAmount := 0;
        LiabilitiesAmount := 0;
        if Amount > 0 then
            DebtsAmount := Amount
        else
            LiabilitiesAmount := -Amount;
    end;

    local procedure SummarizeAmounts(var ToInvActLine: Record "Invent. Act Line"; FromInvActLine: Record "Invent. Act Line")
    begin
        ToInvActLine."Total Amount" += FromInvActLine."Total Amount";
        ToInvActLine."Confirmed Amount" += FromInvActLine."Confirmed Amount";
        ToInvActLine."Not Confirmed Amount" += FromInvActLine."Not Confirmed Amount";
        ToInvActLine."Overdue Amount" += FromInvActLine."Overdue Amount";
        ToInvActLine.Modify();
    end;

    local procedure RunINV17Report(InvtActHeader: Record "Invent. Act Header")
    var
        InvActRep: Report "Invent. Act INV-17";
    begin
        LibraryReportValidation.SetFileName(InvtActHeader."No.");
        InvtActHeader.SetRecFilter();
        InvActRep.SetFileNameSilent(LibraryReportValidation.GetFileName());
        InvActRep.SetTableView(InvtActHeader);
        InvActRep.UseRequestPage(false);
        InvActRep.Run();
    end;

    local procedure RunINV17SupplementReport(InvtActHeader: Record "Invent. Act Header")
    var
        SupplementInvActRep: Report "Supplement to INV-17";
    begin
        LibraryReportValidation.SetFileName(InvtActHeader."No.");
        InvtActHeader.SetRecFilter();
        SupplementInvActRep.SetFileNameSilent(LibraryReportValidation.GetFileName());
        SupplementInvActRep.SetTableView(InvtActHeader);
        SupplementInvActRep.UseRequestPage(false);
        SupplementInvActRep.Run();
    end;

    local procedure VerifyReportHeader(ReasonDocNo: Code[20]; ReasonDocDate: Date; DocNo: Code[20]; DocDate: Date; InvDate: Date)
    var
        CompanyInfo: Record "Company Information";
        StdRepMgt: Codeunit "Local Report Management";
    begin
        CompanyInfo.Get();
        LibraryReportValidation.VerifyCellValue(7, 1, StdRepMgt.GetCompanyName());
        LibraryReportValidation.VerifyCellValue(7, 22, CompanyInfo."OKPO Code");
        LibraryReportValidation.VerifyCellValue(12, 22, ReasonDocNo);
        LibraryReportValidation.VerifyCellValue(13, 22, Format(ReasonDocDate));
        LibraryReportValidation.VerifyCellValue(18, 11, DocNo);
        LibraryReportValidation.VerifyCellValue(18, 14, Format(DocDate));
        LibraryReportValidation.VerifyCellValue(21, 6, Format(Date2DMY(InvDate, 1)));
        LibraryReportValidation.VerifyCellValue(21, 8, LocMgt.Month2Text(InvDate));
        LibraryReportValidation.VerifyCellValue(21, 15, Format(Date2DMY(InvDate, 1)));
    end;

    local procedure VerifyReportLineValuesFromBuffer(var TempInvtActLine: Record "Invent. Act Line")
    var
        CategoryType: Integer;
        RowShift: Integer;
    begin
        RowShift := 0;
        TempInvtActLine.Reset();
        for CategoryType := TempInvtActLine.Category::Debts to TempInvtActLine.Category::Liabilities do begin
            TempInvtActLine.SetRange(Category, CategoryType);
            TempInvtActLine.FindSet();
            repeat
                VerifyLineValue(
                  RowShift,
                  TempInvtActLine."Contractor Name",
                  TempInvtActLine."G/L Account No.",
                  TempInvtActLine."Total Amount",
                  TempInvtActLine."Confirmed Amount",
                  TempInvtActLine."Not Confirmed Amount",
                  TempInvtActLine."Overdue Amount");
                RowShift += 1;
            until TempInvtActLine.Next() = 0;
            RowShift += 6; // Printing of page header
        end;
    end;

    local procedure VerifyLineValue(RowShift: Integer; ContractorName: Text; AccountNo: Code[20]; TotalAmount: Decimal; ConfirmedAmount: Decimal; NotConfirmedAmount: Decimal; OverdueAmount: Decimal)
    var
        LineRowId: Integer;
    begin
        LineRowId := 29 + RowShift;
        LibraryReportValidation.VerifyCellValue(LineRowId, 1, ContractorName);
        LibraryReportValidation.VerifyCellValue(LineRowId, 5, AccountNo);
        VerifyAmounts(RowShift, TotalAmount, ConfirmedAmount, NotConfirmedAmount, OverdueAmount);
    end;

    local procedure VerifyAmounts(RowShift: Integer; TotalAmount: Decimal; ConfirmedAmount: Decimal; NotConfirmedAmount: Decimal; OverdueAmount: Decimal)
    var
        LineRowId: Integer;
    begin
        LineRowId := 29 + RowShift;
        LibraryReportValidation.VerifyCellValue(LineRowId, 10, Format(TotalAmount));
        LibraryReportValidation.VerifyCellValue(LineRowId, 12, Format(ConfirmedAmount));
        LibraryReportValidation.VerifyCellValue(LineRowId, 18, Format(NotConfirmedAmount));
        LibraryReportValidation.VerifyCellValue(LineRowId, 23, Format(OverdueAmount));
    end;

    local procedure VerifySupplementLineValuesFromCustBuffer(var CustLedgEntry: Record "Cust. Ledger Entry" temporary; var Counter: Integer)
    var
        DebtsAmount: Decimal;
        LiabilitiesAmount: Decimal;
    begin
        CustLedgEntry.FindSet();
        repeat
            CustLedgEntry.CalcFields("Remaining Amt. (LCY)");
            CustLedgEntry.TestField("Remaining Amt. (LCY)");
            CalcDebtLiabilitiesAmount(DebtsAmount, LiabilitiesAmount, CustLedgEntry."Remaining Amt. (LCY)");
            VerifySupplementLineValue(
              Counter, GetCustFullNameAndContacts(CustLedgEntry."Customer No."),
              GetCustAgrDescription(CustLedgEntry), Format(CustLedgEntry."Posting Date"),
              Format(DebtsAmount), Format(LiabilitiesAmount),
              Format(CustLedgEntry."Document Type"), CustLedgEntry."Document No.", Format(CustLedgEntry."Posting Date"));
            Counter += 1;
        until CustLedgEntry.Next() = 0;
    end;

    local procedure VerifySupplementLineValuesFromVendBuffer(var VendLedgEntry: Record "Vendor Ledger Entry" temporary; var Counter: Integer)
    var
        DebtsAmount: Decimal;
        LiabilitiesAmount: Decimal;
    begin
        VendLedgEntry.FindSet();
        repeat
            VendLedgEntry.CalcFields("Remaining Amt. (LCY)");
            VendLedgEntry.TestField("Remaining Amt. (LCY)");
            CalcDebtLiabilitiesAmount(DebtsAmount, LiabilitiesAmount, VendLedgEntry."Remaining Amt. (LCY)");
            VerifySupplementLineValue(
              Counter, GetVendFullNameAndContacts(VendLedgEntry."Vendor No."),
              GetVendAgrDescription(VendLedgEntry), Format(VendLedgEntry."Posting Date"),
              Format(DebtsAmount), Format(LiabilitiesAmount),
              Format(VendLedgEntry."Document Type"), VendLedgEntry."Document No.", Format(VendLedgEntry."Posting Date"));
            Counter += 1;
        until VendLedgEntry.Next() = 0;
    end;

    local procedure VerifySupplementLineValue(Counter: Integer; Name: Text; AgreementDescription: Text; DocDate: Text; DebtsAmount: Text; LiabilitiesAmount: Text; DocType: Text; DocNo: Text; PostingDate: Text)
    var
        LineRowId: Integer;
    begin
        LineRowId := 19 + Counter;
        LibraryReportValidation.VerifyCellValue(LineRowId, 1, Format(Counter + 1));
        LibraryReportValidation.VerifyCellValue(LineRowId, 2, Name);
        LibraryReportValidation.VerifyCellValue(LineRowId, 4, AgreementDescription);
        LibraryReportValidation.VerifyCellValue(LineRowId, 7, DocDate);
        LibraryReportValidation.VerifyCellValue(LineRowId, 12, DebtsAmount);
        LibraryReportValidation.VerifyCellValue(LineRowId, 14, LiabilitiesAmount);
        LibraryReportValidation.VerifyCellValue(LineRowId, 19, DocType);
        LibraryReportValidation.VerifyCellValue(LineRowId, 20, DocNo);
        LibraryReportValidation.VerifyCellValue(LineRowId, 21, PostingDate);
    end;
}

