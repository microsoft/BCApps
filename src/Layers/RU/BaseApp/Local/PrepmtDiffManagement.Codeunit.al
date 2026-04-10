#pragma warning disable AA0247
codeunit 12412 PrepmtDiffManagement
{

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        AdvAdjmtEntryBuff: Record "Detailed CV Ledg. Entry Buffer" temporary;
        DimMgt: Codeunit DimensionManagement;
        InitialVATTransactionNo: Integer;

    [Scope('OnPrem')]
    procedure Init()
    begin
        GLSetup.Get();
        SalesSetup.Get();
        PurchSetup.Get();

        AdvAdjmtEntryBuff.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure UpdateCurrFactor(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
        OldCVLedgEntryBuf."Adjusted Currency Factor" := NewCVLedgEntryBuf."Adjusted Currency Factor";
        OldCVLedgEntryBuf."Original Currency Factor" := NewCVLedgEntryBuf."Original Currency Factor";
        NewCVLedgEntryBuf."Adjusted Currency Factor" := 1;
        NewCVLedgEntryBuf."Original Currency Factor" := 1;
    end;

    [Scope('OnPrem')]
    procedure LookupTaxDim(Type: Option Condition,Kind; var Value: Code[20])
    var
        TaxRegSetup: Record "Tax Register Setup";
        DimValue: Record "Dimension Value";
        DimCode: Code[20];
    begin
        DimCode := TaxRegSetup.GetDimCode(Type);
        DimValue.SetFilter("Dimension Code", DimCode);
        if DimValue.Get(DimCode, Value) then;
        if PAGE.RunModal(PAGE::"Dimension Value List", DimValue) = ACTION::LookupOK then begin
            DimValue.Get(DimCode, DimValue.Code);
            Value := DimValue.Code;
        end;
    end;

    [Scope('OnPrem')]
    procedure ValidateTaxDim(Type: Option Condition,Kind; Value: Code[20])
    var
        TaxRegSetup: Record "Tax Register Setup";
        DimValue: Record "Dimension Value";
    begin
        if Value <> '' then
            DimValue.Get(TaxRegSetup.GetDimCode(Type), Value);
    end;

    [Scope('OnPrem')]
    procedure UpdateCorrDocDimSetID(AccountType: Option Vendor,Customer; var DimSetID: Integer; CorrType: Option Loss,Gain; PrepAdjmt: Boolean)
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimType: Option Condition,Kind;
        DimCode: Code[20];
        DimValueCode: Code[20];
    begin
        DimMgt.GetDimensionSet(TempDimSetEntry, DimSetID);

        for DimType := 0 to 1 do begin
            GetTaxDimCodes(AccountType, CorrType, DimType, DimCode, DimValueCode, PrepAdjmt);
            UpdateDimSet(TempDimSetEntry, DimSetID, DimCode, DimValueCode);
        end;

        DimSetID := DimMgt.GetDimensionSetID(TempDimSetEntry);
    end;

    [Scope('OnPrem')]
    procedure GetTaxDimCodes(AccountType: Option Vendor,Customer; CorrType: Option Loss,Gain; DimType: Option Condition,Kind; var DimCode: Code[20]; var DimValueCode: Code[20]; PrepAdjmt: Boolean)
    var
        TaxRegSetup: Record "Tax Register Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        DimCode := TaxRegSetup.GetDimCode(DimType);
        case AccountType of
            AccountType::Customer:
                DimValueCode := SalesSetup.GetTaxDimValue(CorrType, DimType, PrepAdjmt);
            AccountType::Vendor:
                DimValueCode := PurchSetup.GetTaxDimValue(CorrType, DimType, PrepAdjmt);
        end;
    end;

    [Scope('OnPrem')]
    procedure InsertPrepmtDiffBufEntry(DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; PostingType: Option ,Purchase,Sale; InitialVATTransactionNo: Integer)
    begin
        AdvAdjmtEntryBuff.Init();
        AdvAdjmtEntryBuff := DtldCVLedgEntryBuf;
        AdvAdjmtEntryBuff."Gen. Posting Type" := "General Posting Type".FromInteger(PostingType);
        AdvAdjmtEntryBuff."Transaction No." := InitialVATTransactionNo;
        AdvAdjmtEntryBuff.Insert();
        AdvAdjmtEntryBuff.Reset();
    end;

    [Scope('OnPrem')]
    procedure PrepmtDiffProcessing(Unapply: Boolean; PreviewMode: Boolean)
    var
        SalesPost: Codeunit "Sales-Post";
        PurchPost: Codeunit "Purch.-Post";
    begin
        AdvAdjmtEntryBuff.Reset();
        if AdvAdjmtEntryBuff.FindSet() then
            repeat
                case AdvAdjmtEntryBuff."Gen. Posting Type" of
                    AdvAdjmtEntryBuff."Gen. Posting Type"::Purchase:
                        begin
                            PurchPost.SetPreviewMode(PreviewMode);
                            PurchPost.SetIndirectCall(true);
                            if Unapply then begin
                                AdvAdjmtEntryBuff."Transaction No." := InitialVATTransactionNo;
                                PurchPost.CreatePDDocForUnapply(AdvAdjmtEntryBuff);
                            end else
                                PurchPost.CreateCorrDoc(AdvAdjmtEntryBuff, true);
                        end;
                    AdvAdjmtEntryBuff."Gen. Posting Type"::Sale:
                        begin
                            PurchPost.SetPreviewMode(PreviewMode);
                            PurchPost.SetIndirectCall(true);
                            if Unapply then begin
                                AdvAdjmtEntryBuff."Transaction No." := InitialVATTransactionNo;
                                SalesPost.CreatePDDocForUnapply(AdvAdjmtEntryBuff);
                            end else
                                SalesPost.CreateCorrDoc(AdvAdjmtEntryBuff, true);
                        end;
                end;
            until AdvAdjmtEntryBuff.Next() = 0;
        AdvAdjmtEntryBuff.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure CheckCalcPrepDiff(NewCVLedgEntry: Record "CV Ledger Entry Buffer"; OldCVLedgEntry: Record "CV Ledger Entry Buffer"): Boolean
    var
        Currency: Record Currency;
    begin
        if not GLSetup."Enable Russian Accounting" then
            exit(false);

        if not GLSetup."Cancel Curr. Prepmt. Adjmt." then
            exit(false);

        if (not NewCVLedgEntry.Prepayment) and (not OldCVLedgEntry.Prepayment) then
            exit(false);

        if (NewCVLedgEntry."Currency Code" <> OldCVLedgEntry."Currency Code") and
           (NewCVLedgEntry."Currency Code" <> '') and (OldCVLedgEntry."Currency Code" <> '')
        then
            exit(false);

        if not CheckAllowedDocComb(NewCVLedgEntry, OldCVLedgEntry) then
            exit(false);

        if NewCVLedgEntry.Prepayment then begin
            Currency.Get(NewCVLedgEntry."Currency Code");
            exit((not Currency.Conventional) and (OldCVLedgEntry."Currency Code" <> ''));
        end;

        if OldCVLedgEntry.Prepayment then
            if OldCVLedgEntry."Currency Code" <> '' then begin
                Currency.Get(OldCVLedgEntry."Currency Code");
                exit(not Currency.Conventional);
            end else
                exit(true);

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure UpdatePDDocPostingNo(var PostingSeries: Code[20]; var PostingNo: Code[20]; PrepmtDiffEntryNo: Integer; AccountType: Option Cust,Vend; DocType: Option Invoice,"Credit Memo")
    begin
        case AccountType of
            AccountType::Cust:
                begin
                    SalesSetup.Get();
                    case SalesSetup."PD Doc. Nos. Type" of
                        SalesSetup."PD Doc. Nos. Type"::"Use No. Series":
                            begin
                                SalesSetup.TestField("Posted PD Doc. Nos.");
                                PostingSeries := SalesSetup."Posted PD Doc. Nos.";
                                PostingNo := '';
                            end;
                        SalesSetup."PD Doc. Nos. Type"::"Add Symbol":
                            begin
                                PostingSeries := '';
                                UpdatePDDocPostingNoAddSmbl(PostingNo, PrepmtDiffEntryNo, 0, DocType);
                            end;
                    end;
                end;
            AccountType::Vend:
                begin
                    PurchSetup.Get();
                    case PurchSetup."PD Doc. Nos. Type" of
                        PurchSetup."PD Doc. Nos. Type"::"Use No. Series":
                            begin
                                PurchSetup.TestField("Posted PD Doc. Nos.");
                                PostingSeries := PurchSetup."Posted PD Doc. Nos.";
                                PostingNo := '';
                            end;
                        PurchSetup."PD Doc. Nos. Type"::"Add Symbol":
                            begin
                                PostingSeries := '';
                                UpdatePDDocPostingNoAddSmbl(PostingNo, PrepmtDiffEntryNo, 1, DocType);
                            end;
                    end;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdatePDDocPostingNoAddSmbl(var PostingNo: Code[20]; PrepmtDiffEntryNo: Integer; AccountType: Option Cust,Vend; DocType: Option Invoice,"Credit Memo")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PDDocCount: Integer;
        SymbolForPDDoc: Code[10];
    begin
        case AccountType of
            AccountType::Cust:
                begin
                    SalesSetup.Get();
                    SalesSetup.TestField("Symbol for PD Doc.");
                    SymbolForPDDoc := SalesSetup."Symbol for PD Doc.";
                    PostingNo := CopyStr(PostingNo + SymbolForPDDoc, 1, MaxStrLen(PostingNo));
                    PDDocCount := 0;

                    case DocType of
                        DocType::Invoice:
                            begin
                                SalesInvHeader.Reset();
                                SalesInvHeader.SetFilter("No.", '%1', PostingNo + '*');
                                PDDocCount := SalesInvHeader.Count();
                            end;
                        DocType::"Credit Memo":
                            begin
                                SalesCrMemoHeader.Reset();
                                SalesCrMemoHeader.SetFilter("No.", '%1', PostingNo + '*');
                                PDDocCount := SalesCrMemoHeader.Count();
                            end;
                    end;
                end;
            AccountType::Vend:
                begin
                    PurchSetup.Get();
                    PurchSetup.TestField("Symbol for PD Doc.");
                    SymbolForPDDoc := PurchSetup."Symbol for PD Doc.";
                    PostingNo := CopyStr(PostingNo + SymbolForPDDoc, 1, MaxStrLen(PostingNo));
                    PDDocCount := 0;

                    case DocType of
                        DocType::Invoice:
                            begin
                                PurchInvHeader.Reset();
                                PurchInvHeader.SetFilter("No.", '%1', PostingNo + '*');
                                PDDocCount := PurchInvHeader.Count();
                            end;
                        DocType::"Credit Memo":
                            begin
                                PurchCrMemoHeader.Reset();
                                PurchCrMemoHeader.SetFilter("No.", '%1', PostingNo + '*');
                                PDDocCount := PurchCrMemoHeader.Count();
                            end;
                    end;
                end;
        end;

        if PDDocCount > 0 then
            PostingNo := CopyStr(PostingNo + Format(PDDocCount), 1, MaxStrLen(PostingNo));
    end;

    [Scope('OnPrem')]
    procedure CheckAllowedDocComb(NewCVLedgEntry: Record "CV Ledger Entry Buffer"; OldCVLedgEntry: Record "CV Ledger Entry Buffer"): Boolean
    begin
        if NewCVLedgEntry.Prepayment then
            exit(
              ((NewCVLedgEntry."Document Type" = NewCVLedgEntry."Document Type"::Payment) and
               (OldCVLedgEntry."Document Type" = OldCVLedgEntry."Document Type"::Invoice)) or
              ((NewCVLedgEntry."Document Type" = NewCVLedgEntry."Document Type"::Refund) and
               (OldCVLedgEntry."Document Type" = OldCVLedgEntry."Document Type"::"Credit Memo")));

        exit(
          ((NewCVLedgEntry."Document Type" = NewCVLedgEntry."Document Type"::Invoice) and
           (OldCVLedgEntry."Document Type" = OldCVLedgEntry."Document Type"::Payment)) or
          ((NewCVLedgEntry."Document Type" = NewCVLedgEntry."Document Type"::"Credit Memo") and
           (OldCVLedgEntry."Document Type" = OldCVLedgEntry."Document Type"::Refund)));
    end;

    [Scope('OnPrem')]
    procedure SetInitialVATTransactionNo(SavedInitialVATTransactionNo: Integer)
    begin
        InitialVATTransactionNo := SavedInitialVATTransactionNo;
    end;

    [Scope('OnPrem')]
    procedure IsDifferentTaxPeriod(InvDocPostingDate: Date; CorrDocPostingDate: Date): Boolean
    var
        TaxPeriod: array[2] of Integer;
    begin
        TaxPeriod[1] := Round(Date2DMY(InvDocPostingDate, 2) / 3, 1, '>');
        TaxPeriod[2] := Round(Date2DMY(CorrDocPostingDate, 2) / 3, 1, '>');
        if TaxPeriod[1] <> TaxPeriod[2] then
            exit(true);

        exit(false);
    end;

    local procedure UpdateDimSet(var TempDimSetEntry: Record "Dimension Set Entry" temporary; DimSetID: Integer; DimCode: Code[20]; DimValueCode: Code[20])
    var
        DimVal: Record "Dimension Value";
    begin
        if DimCode = '' then
            exit;
        if TempDimSetEntry.Get(DimSetID, DimCode) then
            TempDimSetEntry.Delete();
        if DimValueCode <> '' then begin
            DimVal.Get(DimCode, DimValueCode);
            TempDimSetEntry.Init();
            TempDimSetEntry."Dimension Set ID" := DimSetID;
            TempDimSetEntry."Dimension Code" := DimCode;
            TempDimSetEntry."Dimension Value Code" := DimValueCode;
            TempDimSetEntry."Dimension Value ID" := DimVal."Dimension Value ID";
            TempDimSetEntry.Insert();
        end;
    end;
}

