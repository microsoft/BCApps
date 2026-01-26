codeunit 160201 "Create Payment"
{

    trigger OnRun()
    begin
        //Payment Class
        // Suggestions :: None,Customer,Vendor
        // Unrealized VAT Reversal :: Application,Delayed
        InsertPaymentClass(XBor, Text0014, XBORE, true, XBor, 2, 0, 0);
        InsertPaymentClass(XLCR2, Text0015, XLCRE, true, XLCR, 1, 0, 0);
        InsertPaymentClass(XPRE, Text0016, XPRE, true, '', 1, 0, 2);
        InsertPaymentClass(XVIR, Text0017, XVIR, true, '', 2, 0, 1);

        //Payment Status
        InsertPaymentStatus(XBor, 0, Text0000, true, true, false, true, false, true, false, true, false);
        InsertPaymentStatus(XBor, 10000, Text0001, true, true, true, true, false, true, false, true, true);
        InsertPaymentStatus(XBor, 20000, Text0002, false, false, false, false, false, true, false, false, false);
        InsertPaymentStatus(XBor, 30000, Text0003, false, false, true, false, false, true, false, false, false);
        InsertPaymentStatus(XLCR2, 0, Text0004, true, true, false, true, false, false, true, true, false);
        InsertPaymentStatus(XLCR2, 10000, Text0005, true, true, true, true, false, false, true, true, true);
        InsertPaymentStatus(XLCR2, 20000, Text0006, true, true, true, true, false, false, true, true, true);
        InsertPaymentStatus(XLCR2, 30000, Text0007, true, true, true, true, false, false, true, true, true);
        InsertPaymentStatus(XLCR2, 40000, Text0008, false, false, true, false, false, false, true, false, false);
        InsertPaymentStatus(XPRE, 0, Text0009, true, true, false, false, false, false, true, true, false);
        InsertPaymentStatus(XPRE, 10000, Text0010, true, true, true, false, false, false, true, true, false);
        InsertPaymentStatus(XPRE, 20000, Text0011, false, false, true, false, false, false, true, false, false);
        InsertPaymentStatus(XVIR, 0, Text0012, true, true, false, false, false, true, false, true, false);
        InsertPaymentStatus(XVIR, 10000, Text0013, true, true, true, false, false, true, false, true, false);
        InsertPaymentStatus(XVIR, 20000, Text0014, false, false, true, false, false, true, false, false, false);

        // Payment Step
        // Action Type::None,Ledger,Report,File,Create New Document,Cancel File
        // Export Type::,,,Report,,,XMLport
        InsertPaymentStep(XBor, 10000, Text0018, 0, 0, 2, 10866, 0, 0, false, '', '', '', false, false, true, true, false);
        InsertPaymentStep(XBor, 20000, Text0019, 0, 10000, 1, 0, 0, 0, false, '', '', XEFFETS, false, false, true, true, false);
        InsertPaymentStep(XBor, 30000, Text0020, 20000, 30000, 1, 0, 0, 0, false, '', '', '', false, false, true, false, false);
        InsertPaymentStep(XBor, 40000, Text0021, 20000, 20000, 1, 0, 0, 0, false, '', '', XEFFETS, false, false, true, false, false);
        InsertPaymentStep(XBor, 50000, Text0022, 20000, 10000, 2, 10866, 0, 0, false, '', '', '', false, false, true, true, false);

        InsertPaymentStep(XLCR2, 10000, Text0023, 0, 0, 2, 10865, 0, 0, true, '', '', '', false, false, false, true, false);
        InsertPaymentStep(XLCR2, 20000, Text0024, 0, 10000, 1, 0, 0, 0, true, '', '', XEFFETS, false, false, false, true, false);
        InsertPaymentStep(XLCR2, 30000, Text0025, 10000, 20000, 1, 0, 0, 0, false, "XLCR-REM", '', '', false, false, false, false, false);
        InsertPaymentStep(XLCR2, 40000, Text0026, 10000, 0, 1, 0, 0, 0, false, '', '', XEFFETS, false, false, false, false, false);
        InsertPaymentStep(XLCR2, 50000, Text0027, 20000, 20000, 2, 10867, 0, 0, true, '', '', '', false, false, true, true, false);
        InsertPaymentStep(XLCR2, 60000, Text0028, 20000, 20000, 2, 10880, 3, 0, true, '', '', '', true, false, true, true, false);
        InsertPaymentStep(XLCR2, 70000, Text0025, 20000, 30000, 1, 0, 0, 0, false, '', '', XEFFETS, false, false, false, false, false);
        InsertPaymentStep(XLCR2, 80000, Text0030, 20000, 0, 1, 0, 0, 0, false, '', '', XEFFETS, false, false, false, false, false);
        InsertPaymentStep(XLCR2, 90000, Text0031, 30000, 40000, 1, 0, 0, 0, true, '', '', '', true, false, true, true, false);

        InsertPaymentStep(XPRE, 10000, Text0032, 0, 0, 2, 10870, 0, 0, true, '', '', '', false, false, true, true, false);
        InsertPaymentStep(XPRE, 20000, Text0033, 0, 0, 2, 10871, 0, 0, true, '', '', '', false, false, true, true, false);
        InsertPaymentStep(XPRE, 30000, Text0034, 0, 10000, 3, 0, 1010, 6, true, '', '', '', false, false, true, true, false);
        InsertPaymentStep(XPRE, 40000, Text0032, 10000, 10000, 2, 10870, 0, 0, true, '', '', '', false, false, true, true, false);
        InsertPaymentStep(XPRE, 50000, Text0033, 10000, 10000, 2, 10871, 0, 0, true, '', '', '', false, false, true, true, false);
        InsertPaymentStep(XPRE, 60000, Text0037, 10000, 20000, 0, 0, 0, 0, true, '', '', '', false, false, true, true, false);
        InsertPaymentStep(XPRE, 70000, Text0038, 10000, 0, 1, 0, 0, 0, false, '', '', '', false, false, false, false, false);
        InsertPaymentStep(XPRE, 80000, Text0039, 20000, 20000, 2, 10870, 0, 0, false, '', '', '', false, false, false, false, false);
        InsertPaymentStep(XPRE, 90000, Text0040, 20000, 20000, 2, 10871, 0, 0, false, '', '', '', false, false, false, false, false);

        InsertPaymentStep(XVIR, 10000, Text0032, 0, 0, 2, 10868, 0, 0, true, '', '', '', false, false, true, true, false);
        InsertPaymentStep(XVIR, 20000, Text0033, 0, 0, 2, 10869, 0, 0, true, '', '', '', false, false, true, true, false);
        InsertPaymentStep(XVIR, 30000, Text0034, 0, 10000, 3, 0, 1000, 6, true, '', '', '', false, false, true, true, false);
        InsertPaymentStep(XVIR, 40000, Text0032, 10000, 10000, 2, 10868, 0, 0, true, '', '', '', false, false, true, true, false);
        InsertPaymentStep(XVIR, 50000, Text0033, 10000, 10000, 2, 10869, 0, 0, true, '', '', '', false, false, true, true, false);
        InsertPaymentStep(XVIR, 60000, Text0037, 10000, 20000, 1, 0, 0, 0, true, '', '', '', false, false, true, true, false);
        InsertPaymentStep(XVIR, 70000, Text0038, 10000, 0, 5, 0, 0, 0, false, '', '', '', false, false, false, false, false);
        InsertPaymentStep(XVIR, 80000, Text0039, 20000, 20000, 2, 10868, 0, 0, false, '', '', '', false, false, false, false, false);
        InsertPaymentStep(XVIR, 90000, Text0040, 20000, 20000, 2, 10869, 0, 0, false, '', '', '', false, false, false, false, false);

        InsertPaymentStepLedger(XBor, 20000, 0, Text0050, 1, 0, '', '', '', '', 0, 0, false, 0, 1);
        InsertPaymentStepLedger(XBor, 20000, 1, Text0051, 1, 0, '', '', Text0062, '', 0, 0, false, 0, 1);
        InsertPaymentStepLedger(XBor, 30000, 0, Text0052, 0, 0, '', '', Text0062, '', 0, 1, false, 1, 1);
        InsertPaymentStepLedger(XBor, 30000, 1, Text0052, 6, 0, '', '', '', '', 0, 0, false, 1, 1);
        InsertPaymentStepLedger(XBor, 40000, 0, Text0053, 1, 0, '', '', Text0062, '', 0, 0, false, 0, 1);
        InsertPaymentStepLedger(XBor, 40000, 1, Text0053, 1, 0, '', '', '', '', 0, 0, false, 0, 1);

        InsertPaymentStepLedger(XLCR2, 20000, 0, Text0054, 1, 0, '', Text0062, '', '', 0, 0, false, 0, 1);
        InsertPaymentStepLedger(XLCR2, 20000, 1, Text0054, 1, 0, '', '', '', '', 0, 0, false, 0, 1);
        InsertPaymentStepLedger(XLCR2, 35000, 0, Text0055, 1, 0, '', '', '', '', 0, 0, false, 0, 1);
        InsertPaymentStepLedger(XLCR2, 35000, 1, Text0055, 1, 0, '', Text0062, '', '', 0, 0, false, 0, 1);
        InsertPaymentStepLedger(XLCR2, 160000, 0, Text0056, 1, 0, '', Text0063, '', '', 0, 0, false, 0, 1);
        InsertPaymentStepLedger(XLCR2, 160000, 1, Text0056, 1, 0, '', Text0062, '', '', 0, 0, false, 0, 1);
        InsertPaymentStepLedger(XLCR2, 165000, 0, Text0057, 1, 0, '', '', '', '', 0, 0, false, 0, 1);
        InsertPaymentStepLedger(XLCR2, 165000, 1, Text0057, 1, 0, '', Text0063, '', '', 0, 0, false, 0, 1);
        InsertPaymentStepLedger(XLCR2, 300000, 0, Text0058, 6, 0, '', '', '', '', 1, 0, false, 1, 0);
        InsertPaymentStepLedger(XLCR2, 300000, 1, Text0058, 0, 0, '', Text0063, '', '', 0, 1, false, 1, 0);

        InsertPaymentStepLedger(XPRE, 60000, 0, Text0059, 6, 0, '', '', '', '', 1, 0, false, 1, 0);
        InsertPaymentStepLedger(XPRE, 60000, 1, Text0060, 0, 0, '', '', '', '', 0, 1, false, 1, 0);

        InsertPaymentStepLedger(XVIR, 60000, 0, Text0061, 0, 0, '', '', '', '', 0, 1, false, 1, 0);
        InsertPaymentStepLedger(XVIR, 60000, 1, Text0059, 6, 0, '', '', '', '', 1, 0, false, 1, 0);
    end;

    var
        XBor: Label 'BOR', Locked = true;
        XLCR: Label 'LCR', Locked = true;
        XLCR2: Label 'LCR2', Locked = true;
        XPRE: Label 'PRE', Locked = true;
        XVIR: Label 'VIR', Locked = true;
        XBORE: Label 'BORE', Locked = true;
        XLCRE: Label 'LCRE', Locked = true;
        XEFFETS: Label 'EFFETS';
        "XLCR-REM": Label 'LCR-REM';
        Text0000: Label 'Promissory note - Entered';
        Text0001: Label 'Promissory Note - Posted';
        Text0002: Label 'Promissory Note - Cancelled';
        Text0003: Label 'Promissory Note - In bank';
        Text0004: Label 'Bill of Exchange - Enter';
        Text0005: Label 'Bill of Exchange - Remittance creation';
        Text0006: Label 'Bill of Exchange - Remittance posted';
        Text0007: Label 'Bill of Exchange - Cash receipt posted';
        Text0008: Label 'Customer Direct Debit - Enter';
        Text0009: Label 'Customer Direct Debit - File created';
        Text0010: Label 'Customer Direct Debit - In bank';
        Text0011: Label 'Vendor Credit Transfer - Enter';
        Text0012: Label 'Vendor Credit Transfer - File created';
        Text0013: Label 'Vendor Credit Transfer - In bank';
        Text0014: Label 'Promissory Note';
        Text0015: Label 'Bill of Exchange';
        Text0016: Label 'Customer Direct Debit';
        Text0017: Label 'Vendor Credit Transfer';
        Text0018: Label 'Print Notes';
        Text0019: Label 'Post Notes';
        Text0020: Label 'Pay Notes';
        Text0021: Label 'Cancel Notes';
        Text0022: Label 'Print Notes again';
        Text0023: Label 'Print Bill of Exchange';
        Text0024: Label 'Post Bill of Exchange';
        Text0025: Label 'Create Bill of Exchange remittance';
        Text0026: Label 'Cancel Bill of Exchange';
        Text0027: Label 'Print Bill of Exchange remittance';
        Text0028: Label 'Create ETEBAC file';
        Text0030: Label 'Post protested Bill of Exchange';
        Text0031: Label 'Post Cash receipt';
        Text0032: Label 'Print Notification';
        Text0033: Label 'Print transaction list';
        Text0034: Label 'Create payment file';
        Text0037: Label 'Post';
        Text0038: Label 'Cancel payment file';
        Text0039: Label 'Print notification again';
        Text0040: Label 'Print transaction list again';
        Text0050: Label 'Convert Invoice %2 into Note';
        Text0051: Label 'Note %2 Due date %1';
        Text0052: Label 'Note %2';
        Text0053: Label 'Cancel Note %2';
        Text0054: Label 'Bill of Exchange %1 %2';
        Text0055: Label 'Cancelled Bill of Exchange %2';
        Text0056: Label 'Bill of Exchange remittance %2';
        Text0057: Label 'Protested Bill of Exchange %2';
        Text0058: Label 'Cash Receipt %2';
        Text0059: Label 'Grouped payment';
        Text0060: Label 'Customer Direct Debit %2';
        Text0061: Label 'Vendor Credit Transfer %2';
        Text0062: Label 'FRANCE-EFF', Locked = true;
        Text0063: Label 'FRANCE-ENC', Locked = true;

    procedure InsertPaymentClass("Code": Code[10]; Name: Text[30]; HeaderNoSeries: Code[20]; Enable: Boolean; LineNoSeries: Code[20]; Suggestions: Integer; UnrealizedVATReversal: Integer; SEPATransferType: Option)
    var
        PaymentClass: Record "Payment Class";
    begin
        PaymentClass.Code := Code;
        PaymentClass.Name := Name;
        PaymentClass."Header No. Series" := HeaderNoSeries;
        PaymentClass.Enable := Enable;
        PaymentClass."Line No. Series" := LineNoSeries;
        PaymentClass.Suggestions := Suggestions;
        PaymentClass."Unrealized VAT Reversal" := UnrealizedVATReversal;
        PaymentClass."SEPA Transfer Type" := SEPATransferType;
        PaymentClass.Insert();
    end;

    procedure InsertPaymentStatus(PaymentClass: Code[10]; Line: Integer; Name: Text[50]; RIB: Boolean; Look: Boolean; RepoartMenu: Boolean; AccetationsCode: Boolean; Amount: Boolean; Debit: Boolean; Credit: Boolean; BasnkAccount: Boolean; "Payment in progress": Boolean)
    var
        PaymentStatus: Record "Payment Status";
    begin
        PaymentStatus."Payment Class" := PaymentClass;
        PaymentStatus.Line := Line;
        PaymentStatus.Name := Name;
        PaymentStatus.RIB := RIB;
        PaymentStatus.Look := Look;
        PaymentStatus.ReportMenu := RepoartMenu;
        PaymentStatus."Acceptation Code" := AccetationsCode;
        PaymentStatus.Amount := Amount;
        PaymentStatus.Debit := Debit;
        PaymentStatus.Credit := Credit;
        PaymentStatus."Bank Account" := BasnkAccount;
        PaymentStatus."Payment in Progress" := "Payment in progress";
        PaymentStatus."Archiving Authorized" := false;
        PaymentStatus.Insert();
    end;

    procedure InsertPaymentStep(PaymentClass: Text[30]; Line: Integer; Name: Text[50]; PreviousStatus: Integer; NextStatus: Integer; ActionType: Integer; ReportNo: Integer; ExportNo: Integer; ExportType: Integer; VerifyLinesRIB: Boolean; HeaderNoSeries: Code[20]; ReasonCode: Code[10]; SourceCode: Code[10]; AccetationCode: Boolean; Corrections: Boolean; VerifyHeaderRIB: Boolean; VerifyDueDate: Boolean; RealuzeVAT: Boolean)
    var
        PaymentStep: Record "Payment Step";
    begin
        PaymentStep."Payment Class" := PaymentClass;
        PaymentStep.Line := Line;
        PaymentStep.Name := Name;
        PaymentStep."Previous Status" := PreviousStatus;
        PaymentStep."Next Status" := NextStatus;
        PaymentStep."Action Type" := "Payment Step Action Type".FromInteger(ActionType);
        PaymentStep."Report No." := ReportNo;
        PaymentStep."Export No." := ExportNo;
        PaymentStep."Verify Lines RIB" := VerifyLinesRIB;
        PaymentStep."Header Nos. Series" := HeaderNoSeries;
        PaymentStep."Reason Code" := ReasonCode;
        PaymentStep."Source Code" := SourceCode;
        PaymentStep."Acceptation Code<>No" := AccetationCode;
        PaymentStep.Correction := Corrections;
        PaymentStep."Verify Header RIB" := VerifyHeaderRIB;
        PaymentStep."Verify Due Date" := VerifyDueDate;
        PaymentStep."Realize VAT" := RealuzeVAT;
        PaymentStep."Export Type" := ExportType;
        PaymentStep.Insert();

        // "BOR",10000,"Print Notes",0,0,"Report","10866","Dataport",0,false,'','','',false,false,true,true,false
    end;

    procedure InsertPaymentStepLedger(PaymentClass: Text[30]; Line: Integer; Sign: Integer; Description: Text[50]; AccountingType: Integer; AccountType: Integer; AccountNo: Code[20]; CustPostGroup: Code[10]; VendPostGroup: Code[10]; Root: Code[20]; DetailLevel: Integer; Application: Integer; MemorizeEntry: Boolean; DocumentType: Integer; DocumentNo: Integer)
    var
        PaymentStepLedger: Record "Payment Step Ledger";
    begin
        PaymentStepLedger."Payment Class" := PaymentClass;
        PaymentStepLedger.Line := Line;
        PaymentStepLedger.Sign := Sign;
        PaymentStepLedger.Description := Description;
        PaymentStepLedger."Accounting Type" := AccountingType;
        PaymentStepLedger."Account Type" := "Gen. Journal Account Type".FromInteger(AccountType);
        PaymentStepLedger."Account No." := AccountNo;
        PaymentStepLedger."Customer Posting Group" := CustPostGroup;
        PaymentStepLedger."Vendor Posting Group" := VendPostGroup;
        PaymentStepLedger.Root := Root;
        PaymentStepLedger."Detail Level" := DetailLevel;
        PaymentStepLedger.Application := Application;
        PaymentStepLedger."Memorize Entry" := MemorizeEntry;
        PaymentStepLedger."Document Type" := "Gen. Journal Document Type".FromInteger(DocumentType);
        PaymentStepLedger."Document No." := DocumentNo;
        PaymentStepLedger.Insert();
    end;
}

