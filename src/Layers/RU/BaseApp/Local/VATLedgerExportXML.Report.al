#pragma warning disable AA0247
report 12461 "VAT Ledger Export XML"
{
    Caption = 'VAT Ledger Export XML';
    ProcessingOnly = true;

    dataset
    {
        dataitem(VATLedger; "VAT Ledger")
        {
            DataItemTableView = sorting(Type, Code);
            dataitem(SalesVATLedgerLine; "VAT Ledger Line")
            {
                DataItemLink = Type = field(Type), Code = field(Code);
                DataItemLinkReference = VATLedger;
                DataItemTableView = sorting(Type, Code, "Line No.") where(Type = const(Sales), "Additional Sheet" = const(false));

                trigger OnAfterGetRecord()
                begin
                    CheckVATRegistrationNo("C/V Type", "C/V No.");
                    CreateSalesLedgerLineElement(SalesVATLedgerLine);
                end;

                trigger OnPreDataItem()
                begin
                    if AddSheet or (VATLedgerType = VATLedger.Type::Purchase) then
                        CurrReport.Break();
                    SetRange(Type, VATLedgerType);
                    SetRange(Code, VATLedgerCode);
                    SetRange("Additional Sheet", AddSheet);
                end;
            }
            dataitem(PurchVATLedgerLine; "VAT Ledger Line")
            {
                DataItemLink = Type = field(Type), Code = field(Code);
                DataItemLinkReference = VATLedger;
                DataItemTableView = sorting(Type, Code, "Line No.") where(Type = const(Purchase), "Additional Sheet" = const(false));

                trigger OnAfterGetRecord()
                begin
                    CheckVATRegistrationNo("C/V Type", "C/V No.");
                    CreatePurchaseLedgerLineElement(PurchVATLedgerLine);
                end;

                trigger OnPreDataItem()
                begin
                    if AddSheet or (VATLedgerType = VATLedger.Type::Sales) then
                        CurrReport.Break();
                    SetRange(Type, VATLedgerType);
                    SetRange(Code, VATLedgerCode);
                    SetRange("Additional Sheet", AddSheet);
                end;
            }
            dataitem(SalesVATLedgerLineAddSheet; "VAT Ledger Line")
            {
                DataItemLink = Type = field(Type), Code = field(Code);
                DataItemLinkReference = VATLedger;
                DataItemTableView = sorting(Type, Code, "Line No.") where(Type = const(Sales), "Additional Sheet" = const(true));

                trigger OnAfterGetRecord()
                var
                    SalesInvHeader: Record "Sales Invoice Header";
                    SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                    CorrDocAddSheet: Boolean;
                begin
                    CheckVATRegistrationNo("C/V Type", "C/V No.");

                    if SalesInvHeader.Get("Document No.") then
                        CorrDocAddSheet := SalesInvHeader."Additional VAT Ledger Sheet";
                    if SalesCrMemoHeader.Get("Document No.") then
                        CorrDocAddSheet := SalesCrMemoHeader."Additional VAT Ledger Sheet";

                    if CorrDocAddSheet then
                        "Document Date" := "Corr. VAT Entry Posting Date";

                    CreateSalesLedgerLineElement(SalesVATLedgerLineAddSheet);
                end;

                trigger OnPreDataItem()
                begin
                    if (not AddSheet) or (VATLedgerType = VATLedger.Type::Purchase) then
                        CurrReport.Break();
                    SetRange(Type, VATLedgerType);
                    SetRange(Code, VATLedgerCode);
                    SetRange("Additional Sheet", AddSheet);
                end;
            }
            dataitem(PurchVATLedgerLineAddSheet; "VAT Ledger Line")
            {
                DataItemLink = Type = field(Type), Code = field(Code);
                DataItemLinkReference = VATLedger;
                DataItemTableView = sorting(Type, Code, "Line No.") where(Type = const(Purchase), "Additional Sheet" = const(true));

                trigger OnAfterGetRecord()
                begin
                    CheckVATRegistrationNo("C/V Type", "C/V No.");
                    CreatePurchaseLedgerLineElement(PurchVATLedgerLineAddSheet);
                end;

                trigger OnPreDataItem()
                begin
                    if (not AddSheet) or (VATLedgerType = VATLedger.Type::Sales) then
                        CurrReport.Break();

                    SetRange(Type, VATLedgerType);
                    SetRange(Code, VATLedgerCode);
                    SetRange("Additional Sheet", AddSheet);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CreateXMLDoc(XmlDoc, XMLCurrNode);
                CreateFileElement(FileId);
                CreateDocumentElement(VATLedgerType, CorrectionNo);
                if ActCriteria then
                    CurrReport.Skip();
                if VATLedgerType = Type::Sales then
                    CreateSalesLedgerElement(VATLedger)
                else
                    CreatePurchaseLedgerElement(VATLedger);
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Type, VATLedgerType);
                SetRange(Code, VATLedgerCode);
                LineNo := 1;
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
                    field(CorrectiveSubmission; CorrectiveSubmission)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Corrective Entry';
                        Editable = true;
                        Enabled = true;

                        trigger OnValidate()
                        begin
                            if not CorrectiveSubmission then begin
                                CorrectionNo := 0;
                                ActCriteria := false;
                            end else
                                CorrectionNo := 1;
                        end;
                    }
                    field(CorrectionNo; CorrectionNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Correction Number';
                        Enabled = CorrectiveSubmission;
                        MaxValue = 999;
                        MinValue = 1;
                    }
                    field(ActCriteria; ActCriteria)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Previously Sent Data Still Current';
                        Enabled = CorrectiveSubmission;
                    }
                    field(FileName; FileId)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'File Name';
                        ToolTip = 'Specifies the name of the file.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            GetFileName();
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if not TempErrorMessage.HasErrors(false) then
            if SaveXMLFile(XmlDoc) then
                Message(CompletedMsg);

        TempErrorMessage.ShowErrorMessages(false);
    end;

    trigger OnPreReport()
    begin
        TempErrorMessage.ClearLog();
        CompanyInfo.Get();
        CompanyInfo.TestField("VAT Registration No.");
    end;

    var
        CompanyInfo: Record "Company Information";
        TempErrorMessage: Record "Error Message" temporary;
        FileManagement: Codeunit "File Management";
        LocalReportMgt: Codeunit "Local Report Management";
        XMLNewChild: DotNet XmlNode;
        XMLCurrNode: DotNet XmlNode;
        XmlDoc: DotNet XmlDocument;
        VATLedgerType: Option;
        VATLedgerCode: Code[20];
        AddSheet: Boolean;
        FileId: Text[100];
        CorrectionNo: Integer;
        CorrectiveSubmission: Boolean;
        ActCriteria: Boolean;
        CVVATRegistrationNo: Text[20];
        CVKPPCode: Text[10];
        CompletedMsg: Label 'The data was exported successfully.';
        LineNo: Integer;
        DocumentTxt: Label 'Document', Comment = 'Should be translated as ´Š¢´Š¢´Š¢Ò¼Ñ´Š¢´Š¢';
        IndexTxt: Label 'Index', Comment = 'Should be translated as ´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢';
        PriznSvedTxt: Label 'PriznSved', Comment = 'Should be translated as ´Š¢Ó¿º´Š¢´Š¢´Š¢´Š¢´Š¢';
        NomCorrTxt: Label 'NomCorr', Comment = 'Should be translated as ´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢';
        FileTxt: Label 'File', Comment = 'Should be translated as ´Š¢´Š¢´Š¢´Š¢';
        FileIDTxt: Label 'FileID', Comment = 'Should be translated as ´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢';
        VersProgTxt: Label 'VersProg', Comment = 'Should be translated as ´Š¢´Š¢´Š¢´Š¢Ó«ú';
        VersFormTxt: Label 'VersForm', Comment = 'Should be translated as ´Š¢´Š¢´Š¢ßö«´Š¢';
        SvProdTxt: Label 'SvProd', Comment = 'Should be translated as ´Š¢´Š¢´Š¢Ó«ñ';
        SvPokupTxt: Label 'SvPokup', Comment = 'Should be translated as ´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢';
        SvedULTxt: Label 'SvedUL', Comment = 'Should be translated as ´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢';
        SvedIPTxt: Label 'SvedIP', Comment = 'Should be translated as ´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢';
        INNULTxt: Label 'INNUL', Comment = 'Should be translated as ´Š¢´Š¢´Š¢´Š¢´Š¢';
        INNFLTxt: Label 'INNFL', Comment = 'Should be translated as ´Š¢´Š¢´Š¢´Š¢´Š¢';
        KPPTxt: Label 'KPP', Comment = 'Should be translated as ´Š¢´Š¢´Š¢';
        KnigaProdTxt: Label 'KnigaProd', Comment = 'Should be translated as ´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢Ó«ñ';
        KnigaProdDLTxt: Label 'KnigaProdDL', Comment = 'Should be translated as ´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢Ó«ñ´Š¢´Š¢';
        KnProdDLStrTxt: Label 'KnProdDLStr', Comment = 'Should be translated as ´Š¢´Š¢´Š¢Ó«ñ´Š¢´Š¢´Š¢´Š¢´Š¢';
        KnProdStrTxt: Label 'KnProdStr', Comment = 'Should be translated as ´Š¢´Š¢´Š¢Ó«ñ´Š¢´Š¢´Š¢';
        KnigaPokupTxt: Label 'KnigaPokup', Comment = 'Should be translated as ´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢';
        KnigaPokupDLTxt: Label 'KnigaPokupDL', Comment = 'Should be translated as ´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢Ò»ä´Š¢';
        KnPokDLStrTxt: Label 'KnPokDLStr', Comment = 'Should be translated as ´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢';
        KnPokStrTxt: Label 'KnPokStr', Comment = 'Should be translated as ´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢';
        SumNDSTxt: Label 'SumNDS', Comment = 'Should be translated as ´Š¢Ò¼ì´Š¢´Š¢';
        SumNDSVicTxt: Label 'SumNDSVic', Comment = 'Should be translated as ´Š¢Ò¼ì´Š¢´Š¢´Š¢´Š¢´Š¢';
        SumNDSItKPkTxt: Label 'SumNDSItKPk', Comment = 'Should be translated as ´Š¢Ò¼ì´Š¢´Š¢´Š¢ÔèÅ´Š¢';
        SumNDSItP1R8Txt: Label 'SumNDSItP1R8', Comment = 'Should be translated as ´Š¢Ò¼ì´Š¢´Š¢´Š¢´Š¢1´Š¢8';
        SumNDSVsKPkTxt: Label 'SumNDSVsKPk', Comment = 'Should be translated as ´Š¢Ò¼ì´Š¢´Š¢´Š¢ßèÅ´Š¢';
        ItStProdKPrTxt: Label 'ItStProdKPr', Comment = 'Should be translated as ´Š¢´Š¢´Š¢Ó«ñ´Š¢´Š¢´Š¢';
        SumNDSItKPrTxt: Label 'SumNDSItKPr', Comment = 'Should be translated as ´Š¢Ò¼ì´Š¢´Š¢´Š¢ÔèÅ´Š¢';
        ItStProdOsvKPrTxt: Label 'ItStProdOsvKPr', Comment = 'Should be translated as ´Š¢´Š¢´Š¢Ó«ñ´Š¢ßóè´Š¢´Š¢';
        StProdVsP1R9Txt: Label 'StProdVsP1R9', Comment = 'Should be translated as ´Š¢´Š¢Ó«ñ´Š¢´Š¢1´Š¢9';
        SumNDSVsP1R9Txt: Label 'SumNDSVsP1R9', Comment = 'Should be translated as ´Š¢Ò¼ì´Š¢´Š¢´Š¢´Š¢1´Š¢9';
        StProdOsvP1R9VsTxt: Label 'StProdOsvP1R9Vs', Comment = 'Should be translated as ´Š¢´Š¢Ó«ñ´Š¢ßóÅ1´Š¢9´Š¢´Š¢';
        StProdBezNDSTxt: Label 'StProdBezNDS', Comment = 'Should be translated as ´Š¢´Š¢Ó«ñ´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢';
        SumNDSVsKPrTxt: Label 'SumNDSVsKPr', Comment = 'Should be translated as ´Š¢Ò¼ì´Š¢´Š¢´Š¢ßèÅ´Š¢';
        StProdOsvVsKPrTxt: Label 'StProdOsvVsKPr', Comment = 'Should be translated as ´Š¢´Š¢Ó«ñ´Š¢ßóéßèÅ´Š¢';
        NomerPorTxt: Label 'NomerPor', Comment = 'Should be translated as ´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢';
        NomScFProdTxt: Label 'NomScFProd', Comment = 'Should be translated as ´Š¢´Š¢´Š¢´Š¢þöÅÓ«ñ';
        DataScFProdTxt: Label 'DataScFProd', Comment = 'Should be translated as ´Š¢´Š¢ÔáæþöÅÓ«ñ';
        NomIsprScFTxt: Label 'NomIsprScF', Comment = 'Should be translated as ´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢';
        DataIsprScFTxt: Label 'DataIsprScF', Comment = 'Should be translated as ´Š¢´Š¢Ôáê´Š¢´Š¢´Š¢´Š¢';
        NomKScFProdTxt: Label 'NomKScFProd', Comment = 'Should be translated as ´Š¢´Š¢´Š¢´Š¢´Š¢þöÅÓ«ñ';
        DataKScFProdTxt: Label 'DataKScFProd', Comment = 'Should be translated as ´Š¢´Š¢Ôáè´Š¢þöÅÓ«ñ';
        NomIsprKScFTxt: Label 'NomIsprKScF', Comment = 'Should be translated as ´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢';
        DataIsprKScFTxt: Label 'DataIsprKScF', Comment = 'Should be translated as ´Š¢´Š¢Ôáê´Š¢´Š¢´Š¢´Š¢´Š¢';
        OKVTxt: Label 'OKV', Comment = 'Should be translated as ´Š¢´Š¢´Š¢';
        StoimProdSFVTxt: Label 'StoimProdSFV', Comment = 'Should be translated as ´Š¢Ô«¿´Š¢´Š¢Ó«ñ´Š¢´Š¢´Š¢';
        StoimProdSFTxt: Label 'StoimProdSF', Comment = 'Should be translated as ´Š¢Ô«¿´Š¢´Š¢Ó«ñ´Š¢´Š¢';
        StoimPokupVTxt: Label 'StoimPokupV', Comment = 'Should be translated as ´Š¢Ô«¿´Š¢´Š¢´Š¢´Š¢Ò»é';
        SumNDSSFTxt: Label 'SumNDSSF', Comment = 'Should be translated as ´Š¢Ò¼ì´Š¢´Š¢´Š¢´Š¢';
        StoimProdOsvTxt: Label 'StoimProdOsv', Comment = 'Should be translated as ´Š¢Ô«¿´Š¢´Š¢Ó«ñ´Š¢´Š¢';
        KodVidOperTxt: Label 'KodVidOper', Comment = 'Should be translated as ´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢';
        DocPdtvOplTxt: Label 'DocPdtvOpl', Comment = 'Should be translated as ´Š¢´Š¢´Š¢´Š¢´Š¢ÔóÄ´Š¢´Š¢';
        NomDocPdtvOplTxt: Label 'NomDocPdtvOpl', Comment = 'Should be translated as ´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢ÔóÄ´Š¢´Š¢';
        DataDocPdtvOplTxt: Label 'DataDocPdtvOpl', Comment = 'Should be translated as ´Š¢´Š¢ÔáÅ´Š¢ÔóÄ´Š¢´Š¢';
        DocPdtvUplTxt: Label 'DocPdtvUpl', Comment = 'Should be translated as ´Š¢´Š¢´Š¢´Š¢´Š¢Ôóô´Š¢´Š¢';
        NomDocPdtvUplTxt: Label 'NomDocPdtvUpl', Comment = 'Should be translated as ´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢´Š¢Ôóô´Š¢´Š¢';
        DataDocPdtvUplTxt: Label 'DataDocPdtvUpl', Comment = 'Should be translated as ´Š¢´Š¢ÔáÅ´Š¢Ôóô´Š¢´Š¢';
        DataUcTovTxt: Label 'DataUcTov', Comment = 'Should be translated as ´Š¢´Š¢ÔáôþÆ«´Š¢';
        KodVidTovarTxt: Label 'KodVidTovar';
        SvRegNomTxt: Label 'SvRegNom', Comment = 'Should be translated as СвРегНом';
        RegNomProslTxt: Label 'RegNomProsl', Comment = 'Should be translated as РегНомПросл';

    [Scope('OnPrem')]
    procedure InitializeReport(NewVATLedgerType: Option; NewVATLedgerCode: Code[20]; NewAddSheet: Boolean)
    begin
        VATLedgerType := NewVATLedgerType;
        VATLedgerCode := NewVATLedgerCode;
        AddSheet := NewAddSheet;
    end;

    local procedure CheckVATRegistrationNo(CVType: Option Vendor,Customer; CVNo: Code[20])
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        CVVATRegistrationNo := '';
        CVKPPCode := '';
        if CVType = CVType::Customer then begin
            if VATLedgerType = VATLedger.Type::Sales then begin
                if Customer.Get(CVNo) then;
                if StrLen(Customer."VAT Registration No.") = 10 then
                    TempErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("KPP Code"), TempErrorMessage."Message Type"::Error);
                if TempErrorMessage.HasErrors(false) then
                    CurrReport.Skip();
                CVVATRegistrationNo := Customer."VAT Registration No.";
                CVKPPCode := Customer."KPP Code";
            end else
                CheckCompanyVATRegNoKPP();
        end else begin
            if Vendor.Get(CVNo) then;
            if VATLedgerType = VATLedger.Type::Purchase then begin
                if not Vendor."VAT Agent" or (Vendor."VAT Agent Type" <> Vendor."VAT Agent Type"::"Non-resident") then begin
                    TempErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo("VAT Registration No."), TempErrorMessage."Message Type"::Error);
                    if StrLen(Vendor."VAT Registration No.") = 10 then
                        TempErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo("KPP Code"), TempErrorMessage."Message Type"::Error);
                    if TempErrorMessage.HasErrors(false) then
                        CurrReport.Skip();
                end;
                CVVATRegistrationNo := Vendor."VAT Registration No.";
                CVKPPCode := Vendor."KPP Code";
            end else
                CheckCompanyVATRegNoKPP();
        end
    end;

    local procedure CheckCompanyVATRegNoKPP()
    begin
        TempErrorMessage.LogIfEmpty(
          CompanyInfo, CompanyInfo.FieldNo("VAT Registration No."), TempErrorMessage."Message Type"::Error);
        if StrLen(CompanyInfo."VAT Registration No.") = 10 then
            TempErrorMessage.LogIfEmpty(
              CompanyInfo, CompanyInfo.FieldNo("KPP Code"), TempErrorMessage."Message Type"::Error);
        if TempErrorMessage.HasErrors(false) then
            CurrReport.Skip();
        CVVATRegistrationNo := CompanyInfo."VAT Registration No.";
        CVKPPCode := CompanyInfo."KPP Code";
    end;

    local procedure CreateDocumentElement(VATLedgerType: Option; CorrectionNo: Integer)
    var
        ActCriteriaAttributeName: Text[250];
    begin
        XMLAddComplexElement(DocumentTxt);

        if VATLedgerType = VATLedger.Type::Sales then
            if AddSheet then begin
                XMLAddAttribute(XMLCurrNode, IndexTxt, '0000091');
                ActCriteriaAttributeName := PriznSvedTxt + '91';
            end else begin
                XMLAddAttribute(XMLCurrNode, IndexTxt, '0000090');
                ActCriteriaAttributeName := PriznSvedTxt + '9';
            end
        else
            if AddSheet then begin
                XMLAddAttribute(XMLCurrNode, IndexTxt, '0000081');
                ActCriteriaAttributeName := PriznSvedTxt + '81';
            end else begin
                XMLAddAttribute(XMLCurrNode, IndexTxt, '0000080');
                ActCriteriaAttributeName := PriznSvedTxt + '8';
            end;

        XMLAddAttribute(XMLCurrNode, NomCorrTxt, Format(CorrectionNo));
        if CorrectionNo > 0 then
            XMLAddAttribute(XMLCurrNode, ActCriteriaAttributeName, GetActCriteria());
    end;

    local procedure CreateFileElement(FileID: Text[100])
    begin
        XMLAddComplexElement(FileTxt);
        XMLAddAttribute(XMLCurrNode, FileIDTxt, FileID);
        XMLAddAttribute(XMLCurrNode, VersProgTxt, '1.0');
        XMLAddAttribute(XMLCurrNode, VersFormTxt, LocalReportMgt.GetVATLedgerFormatVersion());
        XMLCurrNode := XMLNewChild;
    end;

    local procedure CreatePurchaseCVInfoElement()
    begin
        XMLAddComplexElement(SvProdTxt);
        if StrLen(CVVATRegistrationNo) = 10 then begin
            XMLAddComplexElement(SvedULTxt);
            XMLAddAttribute(XMLCurrNode, INNULTxt, CVVATRegistrationNo);
            XMLAddAttribute(XMLCurrNode, KPPTxt, CVKPPCode);
        end else begin
            XMLAddComplexElement(SvedIPTxt);
            XMLAddAttribute(XMLCurrNode, INNFLTxt, CVVATRegistrationNo);
        end;
        XMLCurrNode := XMLCurrNode.ParentNode;
    end;

    local procedure CreatePurchaseLedgerElement(VATLedger: Record "VAT Ledger")
    var
        VATLedgerLine: Record "VAT Ledger Line";
        TotalVATLCY: Decimal;
    begin
        if AddSheet then
            XMLAddComplexElement(KnigaPokupDLTxt)
        else
            XMLAddComplexElement(KnigaPokupTxt);

        VATLedgerLine.SetRange(Type, VATLedger.Type);
        VATLedgerLine.SetRange(Code, VATLedger.Code);
        VATLedgerLine.SetRange("Additional Sheet", AddSheet);
        if VATLedgerLine.FindSet() then
            repeat
                TotalVATLCY += VATLedgerLine.Amount10 + VATLedgerLine.Amount18 + VATLedgerLine.Amount20;
            until VATLedgerLine.Next() = 0;

        if AddSheet then begin
            XMLAddAttribute(XMLCurrNode, SumNDSItKPkTxt, VATLedger."Total VAT Amt VAT Purch Ledger");
            XMLAddAttribute(XMLCurrNode, SumNDSItP1R8Txt, TotalVATLCY + VATLedger."Total VAT Amt VAT Purch Ledger");
        end else
            XMLAddAttribute(XMLCurrNode, SumNDSVsKPkTxt, TotalVATLCY);
    end;

    local procedure CreatePurchaseLedgerLineElement(VATLedgerLine: Record "VAT Ledger Line")
    var
        ItemRealizeDate: Date;
    begin
        if AddSheet then
            XMLAddComplexElement(KnPokDLStrTxt)
        else
            XMLAddComplexElement(KnPokStrTxt);
        // purchase line
        XMLAddAttribute(XMLCurrNode, NomerPorTxt, Format(LineNo));
        XMLAddAttribute(XMLCurrNode, NomScFProdTxt, Format(VATLedgerLine."Document No."));
        XMLAddOptionalAttribute(XMLCurrNode, DataScFProdTxt, GetFormattedDate(VATLedgerLine."Document Date"));
        XMLAddOptionalAttribute(XMLCurrNode, NomIsprScFTxt, Format(VATLedgerLine."Revision No."));
        XMLAddOptionalAttribute(XMLCurrNode, DataIsprScFTxt, GetFormattedDate(VATLedgerLine."Revision Date"));
        XMLAddOptionalAttribute(XMLCurrNode, NomKScFProdTxt, Format(VATLedgerLine."Correction No."));
        XMLAddOptionalAttribute(XMLCurrNode, DataKScFProdTxt, GetFormattedDate(VATLedgerLine."Correction Date"));
        XMLAddOptionalAttribute(XMLCurrNode, NomIsprKScFTxt, Format(VATLedgerLine."Revision of Corr. No."));
        XMLAddOptionalAttribute(XMLCurrNode, DataIsprKScFTxt, GetFormattedDate(VATLedgerLine."Revision of Corr. Date"));

        case true of
            LocalReportMgt.IsForeignCurrency(VATLedgerLine."Currency Code") and
            not LocalReportMgt.IsConventionalCurrency(VATLedgerLine."Currency Code") and
            not LocalReportMgt.HasRelationalCurrCode(VATLedgerLine."Currency Code", VATLedgerLine."Document Date"):
                begin
                    XMLAddOptionalAttribute(XMLCurrNode, OKVTxt, Format(GetCurrencyInfo(VATLedgerLine."Currency Code")));
                    XMLAddAttribute(XMLCurrNode, StoimPokupVTxt, LocalReportMgt.FormatAmount(VATLedgerLine.Amount));
                end;
            LocalReportMgt.IsCustomerPrepayment(VATLedgerLine):
                XMLAddAttribute(XMLCurrNode, StoimPokupVTxt, LocalReportMgt.FormatAmount(VATLedgerLine.Amount));
            else
                XMLAddAttribute(XMLCurrNode, StoimPokupVTxt, LocalReportMgt.GetVATLedgerAmounInclVATFCY(VATLedgerLine));
        end;

        if AddSheet then
            XMLAddAttribute(XMLCurrNode, SumNDSTxt, VATLedgerLine.Amount10 + VATLedgerLine.Amount18 + VATLedgerLine.Amount20)
        else
            XMLAddAttribute(XMLCurrNode, SumNDSVicTxt, VATLedgerLine.Amount10 + VATLedgerLine.Amount18 + VATLedgerLine.Amount20);
        XMLAddSimpleElement(KodVidOperTxt, VATLedgerLine."VAT Entry Type");

        CreateCDNoList(VATLedgerLine);
        if VATLedgerLine."Tariff No." <> '' then
            XMLAddSimpleElement(KodVidTovarTxt, VATLedgerLine."Tariff No.");
        // payment document
        CreatePurchPaymentDocElement(VATLedgerLine);
        ItemRealizeDate := LocalReportMgt.GetVATLedgerItemRealizeDate(VATLedgerLine);
        if ItemRealizeDate <> 0D then
            XMLAddSimpleElement(DataUcTovTxt, GetFormattedDate(ItemRealizeDate));
        // C/V info element
        if not (VATLedgerLine."VAT Entry Type" in ['19', '20', '27', '28']) then begin
            CreatePurchaseCVInfoElement();
            XMLCurrNode := XMLCurrNode.ParentNode();
        end;
        XMLCurrNode := XMLCurrNode.ParentNode;
        LineNo += 1;
    end;

    local procedure CreatePurchPaymentDocElement(VATLedgerLine: Record "VAT Ledger Line")
    var
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
    begin
        case true of
            VATLedgerLine."Full VAT Amount" <> 0:
                begin
                    VATLedgerLine.GetPmtVendorDtldLedgerLines(VATLedger."End Date", TempVendorLedgerEntry);
                    if TempVendorLedgerEntry.FindSet() then
                        repeat
                            XMLAddComplexElement(DocPdtvUplTxt);
                            XMLAddAttribute(XMLCurrNode, NomDocPdtvUplTxt, TempVendorLedgerEntry."External Document No.");
                            XMLAddAttribute(XMLCurrNode, DataDocPdtvUplTxt, GetFormattedDate(TempVendorLedgerEntry."Posting Date"));
                            XMLCurrNode := XMLCurrNode.ParentNode;
                        until TempVendorLedgerEntry.Next() = 0;
                    exit;
                end;
            VATLedgerLine.Prepayment,
            LocalReportMgt.IsVATAgentVendor(VATLedgerLine."C/V No.", VATLedgerLine."C/V Type"):
                begin
                    XMLAddComplexElement(DocPdtvUplTxt);
                    XMLAddAttribute(XMLCurrNode, NomDocPdtvUplTxt, VATLedgerLine."External Document No.");
                    XMLAddAttribute(XMLCurrNode, DataDocPdtvUplTxt, GetFormattedDate(VATLedgerLine."Payment Date"));
                    XMLCurrNode := XMLCurrNode.ParentNode;
                end;
        end;
    end;

    local procedure CreateSalesCVInfoElement()
    begin
        if CVVATRegistrationNo = '' then
            exit;
        XMLAddComplexElement(SvPokupTxt);
        if StrLen(CVVATRegistrationNo) = 10 then begin
            XMLAddComplexElement(SvedULTxt);
            XMLAddAttribute(XMLCurrNode, INNULTxt, CVVATRegistrationNo);
            XMLAddAttribute(XMLCurrNode, KPPTxt, CVKPPCode);
        end else begin
            XMLAddComplexElement(SvedIPTxt);
            XMLAddAttribute(XMLCurrNode, INNFLTxt, CVVATRegistrationNo);
        end;
        XMLCurrNode := XMLCurrNode.ParentNode;
    end;

    local procedure CreateSalesLedgerElement(VATLedger: Record "VAT Ledger")
    var
        VATLedgerLine: Record "VAT Ledger Line";
        TotalBase20: Decimal;
        TotalBase18: Decimal;
        TotalBase10: Decimal;
        TotalBase0: Decimal;
        TotalAmount20: Decimal;
        TotalAmount18: Decimal;
        TotalAmount10: Decimal;
        TotalAmount0: Decimal;
    begin
        if AddSheet then
            XMLAddComplexElement(KnigaProdDLTxt)
        else
            XMLAddComplexElement(KnigaProdTxt);

        Commit();
        VATLedgerLine.SetRange(Type, VATLedger.Type);
        VATLedgerLine.SetRange(Code, VATLedger.Code);
        VATLedgerLine.SetRange("Additional Sheet", AddSheet);
        if VATLedgerLine.FindSet() then
            repeat
                if not VATLedgerLine.Prepayment then begin
                    TotalBase20 += VATLedgerLine.Base20;
                    TotalBase18 += VATLedgerLine.Base18;
                    TotalBase10 += VATLedgerLine.Base10;
                    TotalBase0 += VATLedgerLine.Base0;
                end;
                TotalAmount0 += VATLedgerLine."Base VAT Exempt";
                TotalAmount20 += VATLedgerLine.Amount20;
                TotalAmount18 += VATLedgerLine.Amount18;
                TotalAmount10 += VATLedgerLine.Amount10;
            until VATLedgerLine.Next() = 0;

        if AddSheet then begin
            XMLAddOptionalAttribute(XMLCurrNode, ItStProdKPrTxt + '20', VATLedger."Tot Base20 Amt VAT Sales Ledg");
            XMLAddOptionalAttribute(XMLCurrNode, ItStProdKPrTxt + '18', VATLedger."Tot Base18 Amt VAT Sales Ledg");
            XMLAddOptionalAttribute(XMLCurrNode, ItStProdKPrTxt + '10', VATLedger."Tot Base 10 Amt VAT Sales Ledg");
            XMLAddOptionalAttribute(XMLCurrNode, ItStProdKPrTxt + '0', VATLedger."Tot Base 0 Amt VAT Sales Ledg");
            XMLAddOptionalAttribute(XMLCurrNode, SumNDSItKPrTxt + '20', VATLedger."Total VAT20 Amt VAT Sales Ledg");
            XMLAddOptionalAttribute(XMLCurrNode, SumNDSItKPrTxt + '18', VATLedger."Total VAT18 Amt VAT Sales Ledg");
            XMLAddOptionalAttribute(XMLCurrNode, SumNDSItKPrTxt + '10', VATLedger."Total VAT10 Amt VAT Sales Ledg");
            XMLAddOptionalAttribute(XMLCurrNode, ItStProdOsvKPrTxt, VATLedger."Total VATExempt Amt VAT S Ledg");
            XMLAddOptionalAttribute(XMLCurrNode, StProdVsP1R9Txt + '_20', VATLedger."Tot Base20 Amt VAT Sales Ledg" + TotalBase20);
            XMLAddOptionalAttribute(XMLCurrNode, StProdVsP1R9Txt + '_18', VATLedger."Tot Base18 Amt VAT Sales Ledg" + TotalBase18);
            XMLAddOptionalAttribute(XMLCurrNode, StProdVsP1R9Txt + '_10', VATLedger."Tot Base 10 Amt VAT Sales Ledg" + TotalBase10);
            XMLAddOptionalAttribute(XMLCurrNode, StProdVsP1R9Txt + '_0', VATLedger."Tot Base 0 Amt VAT Sales Ledg" + TotalBase0);
            XMLAddOptionalAttribute(XMLCurrNode, SumNDSVsP1R9Txt + '_20', VATLedger."Total VAT20 Amt VAT Sales Ledg" + TotalAmount20);
            XMLAddOptionalAttribute(XMLCurrNode, SumNDSVsP1R9Txt + '_18', VATLedger."Total VAT18 Amt VAT Sales Ledg" + TotalAmount18);
            XMLAddOptionalAttribute(XMLCurrNode, SumNDSVsP1R9Txt + '_10', VATLedger."Total VAT10 Amt VAT Sales Ledg" + TotalAmount10);
            XMLAddOptionalAttribute(XMLCurrNode, StProdOsvP1R9VsTxt, VATLedger."Total VATExempt Amt VAT S Ledg" + TotalAmount0);
        end else begin
            XMLAddOptionalAttribute(XMLCurrNode, StProdBezNDSTxt + '20', TotalBase20);
            XMLAddOptionalAttribute(XMLCurrNode, StProdBezNDSTxt + '18', TotalBase18);
            XMLAddOptionalAttribute(XMLCurrNode, StProdBezNDSTxt + '10', TotalBase10);
            XMLAddOptionalAttribute(XMLCurrNode, StProdBezNDSTxt + '0', TotalBase0);
            XMLAddOptionalAttribute(XMLCurrNode, SumNDSVsKPrTxt + '20', TotalAmount20);
            XMLAddOptionalAttribute(XMLCurrNode, SumNDSVsKPrTxt + '18', TotalAmount18);
            XMLAddOptionalAttribute(XMLCurrNode, SumNDSVsKPrTxt + '10', TotalAmount10);
            XMLAddOptionalAttribute(XMLCurrNode, StProdOsvVsKPrTxt, TotalAmount0);
        end;
    end;

    local procedure CreateSalesLedgerLineElement(VATLedgerLineLocal: Record "VAT Ledger Line")
    begin
        if AddSheet then
            XMLAddComplexElement(KnProdDLStrTxt)
        else
            XMLAddComplexElement(KnProdStrTxt);

        XMLAddAttribute(XMLCurrNode, NomerPorTxt, Format(LineNo));
        XMLAddAttribute(XMLCurrNode, NomScFProdTxt, Format(VATLedgerLineLocal."Document No."));
        XMLAddAttribute(XMLCurrNode, DataScFProdTxt, GetFormattedDate(VATLedgerLineLocal."Document Date"));
        XMLAddOptionalAttribute(XMLCurrNode, NomIsprScFTxt, Format(VATLedgerLineLocal."Revision No."));
        XMLAddOptionalAttribute(XMLCurrNode, DataIsprScFTxt, GetFormattedDate(VATLedgerLineLocal."Revision Date"));
        XMLAddOptionalAttribute(XMLCurrNode, NomKScFProdTxt, Format(VATLedgerLineLocal."Correction No."));
        XMLAddOptionalAttribute(XMLCurrNode, DataKScFProdTxt, GetFormattedDate(VATLedgerLineLocal."Correction Date"));
        XMLAddOptionalAttribute(XMLCurrNode, NomIsprKScFTxt, Format(VATLedgerLineLocal."Revision of Corr. No."));
        XMLAddOptionalAttribute(XMLCurrNode, DataIsprKScFTxt, GetFormattedDate(VATLedgerLineLocal."Revision of Corr. Date"));

        if LocalReportMgt.IsForeignCurrency(VATLedgerLineLocal."Currency Code") and
           not LocalReportMgt.IsConventionalCurrency(VATLedgerLineLocal."Currency Code") and
           not LocalReportMgt.HasRelationalCurrCode(VATLedgerLineLocal."Currency Code", VATLedgerLineLocal."Document Date")
        then begin
            XMLAddOptionalAttribute(XMLCurrNode, OKVTxt, Format(GetCurrencyInfo(VATLedgerLineLocal."Currency Code")));
            XMLAddOptionalAttribute(XMLCurrNode, StoimProdSFVTxt, LocalReportMgt.FormatAmount(Abs(VATLedgerLineLocal.Amount)));
        end;

        XMLAddOptionalAttribute(XMLCurrNode, StoimProdSFTxt, LocalReportMgt.GetVATLedgerAmounInclVATFCY(VATLedgerLineLocal));
        XMLAddOptionalAttribute(XMLCurrNode, StoimProdSFTxt + '20', GetBaseValue(VATLedgerLineLocal.Base20, VATLedgerLineLocal.Prepayment));
        XMLAddOptionalAttribute(XMLCurrNode, StoimProdSFTxt + '18', GetBaseValue(VATLedgerLineLocal.Base18, VATLedgerLineLocal.Prepayment));
        XMLAddOptionalAttribute(XMLCurrNode, StoimProdSFTxt + '10', GetBaseValue(VATLedgerLineLocal.Base10, VATLedgerLineLocal.Prepayment));
        XMLAddOptionalAttribute(XMLCurrNode, StoimProdSFTxt + '0', GetBaseValue(VATLedgerLineLocal.Base0, VATLedgerLineLocal.Prepayment));

        if VATLedgerLineLocal.Base20 <> 0 then
            XMLAddOptionalAttribute(XMLCurrNode, SumNDSSFTxt + '20', VATLedgerLineLocal.Amount20);

        if VATLedgerLineLocal.Base18 <> 0 then
            XMLAddOptionalAttribute(XMLCurrNode, SumNDSSFTxt + '18', VATLedgerLineLocal.Amount18);

        if VATLedgerLineLocal.Base10 <> 0 then
            XMLAddOptionalAttribute(XMLCurrNode, SumNDSSFTxt + '10', VATLedgerLineLocal.Amount10);

        XMLAddOptionalAttribute(XMLCurrNode, StoimProdOsvTxt, VATLedgerLineLocal."Base VAT Exempt");
        XMLAddSimpleElement(KodVidOperTxt, VATLedgerLineLocal."VAT Entry Type");

        CreateCDNoList(VATLedgerLineLocal);
        if VATLedgerLineLocal."Tariff No." <> '' then
            XMLAddSimpleElement(KodVidTovarTxt, VATLedgerLineLocal."Tariff No.");
        // payment document
        CreateSalesPaymentDocElement(VATLedgerLineLocal);
        // C/V info element
        CreateSalesCVInfoElement();

        XMLCurrNode := XMLCurrNode.ParentNode;
        XMLCurrNode := XMLCurrNode.ParentNode;
        LineNo += 1;
    end;

    local procedure CreateSalesPaymentDocElement(VATLedgerLine: Record "VAT Ledger Line")
    begin
        if VATLedgerLine.Prepayment or LocalReportMgt.IsVATAgentVendor(VATLedgerLine."C/V No.", VATLedgerLine."C/V Type") then begin
            XMLAddComplexElement(DocPdtvOplTxt);
            XMLAddAttribute(XMLCurrNode, NomDocPdtvOplTxt, VATLedgerLine."External Document No.");
            XMLAddAttribute(XMLCurrNode, DataDocPdtvOplTxt, GetFormattedDate(VATLedgerLine."Payment Date"));
            XMLCurrNode := XMLCurrNode.ParentNode;
        end;
    end;

    local procedure CreateCDNoList(VATLedgerLine: Record "VAT Ledger Line")
    var
        VATLedgerLineCDNo: Record "VAT Ledger Line CD No.";
    begin
        VATLedgerLineCDNo.SetFilterVATLedgerLine(VATLedgerLine);
        if VATLedgerLineCDNo.FindSet() then
            repeat
                XMLAddComplexElement(SvRegNomTxt);
                XMLAddAttribute(XMLCurrNode, RegNomProslTxt, Format(VATLedgerLineCDNo."CD No."));
                XMLCurrNode := XMLCurrNode.ParentNode;
            until VATLedgerLineCDNo.Next() = 0;
    end;

    local procedure CreateXMLDoc(var XmlDoc: DotNet XmlDocument; var ProcInstr: DotNet XmlProcessingInstruction)
    var
        XMLDeclaration: DotNet XmlDeclaration;
    begin
        XmlDoc := XmlDoc.XmlDocument();
        XMLDeclaration := XmlDoc.CreateXmlDeclaration('1.0', 'windows-1251', '');
        ProcInstr := XmlDoc.CreateProcessingInstruction('xml', 'version="1.0" encoding="windows-1251"');
        XmlDoc.AppendChild(ProcInstr);
    end;

    local procedure EvaluateNodeValue(NodeValue: Variant; var NodeValueText: Text): Boolean
    var
        NodeValueDecimal: Decimal;
    begin
        if NodeValue.IsInteger or NodeValue.IsDecimal then begin
            NodeValueText := LocalReportMgt.FormatAmount(NodeValue);
            NodeValueDecimal := NodeValue;
            if NodeValueDecimal = 0 then
                exit(true);
        end else
            NodeValueText := Format(NodeValue);
        exit(false);
    end;

    local procedure GetBaseValue(VATBase: Decimal; Prepayment: Boolean): Decimal
    begin
        if VATBase <> 0 then
            if Prepayment then
                exit(0);
        exit(VATBase);
    end;

    local procedure GetActCriteria(): Text[1]
    begin
        if ActCriteria then
            exit('1');
        exit('0')
    end;

    local procedure GetCurrencyInfo(CurrencyCode: Code[10]): Text[260]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Currency: Record Currency;
    begin
        if CurrencyCode = '' then
            exit('');

        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."LCY Code" = CurrencyCode then
            exit('');

        if LocalReportMgt.IsConventionalCurrency(CurrencyCode) then
            exit('');

        if Currency.Get(CurrencyCode) then begin
            if Currency."RU Bank Digital Code" <> '' then
                exit(Currency."RU Bank Digital Code");
            exit(Currency.Code);
        end;
    end;

    local procedure GetFileName()
    begin
        FileId := CopyStr(LocalReportMgt.GetVATLedgerXMLFileName(VATLedgerType, AddSheet), 1, MaxStrLen(FileId));
    end;

    local procedure GetFormattedDate(InputDate: Date): Text[250]
    begin
        if InputDate <> 0D then
            exit(Format(InputDate, 10, '<Day,2>.<Month,2>.<Year4>'));
        exit('')
    end;

    local procedure SaveXMLFile(var XmlDoc: DotNet XmlDocument): Boolean
    var
        dotNetFile: DotNet File;
        Encoding: DotNet Encoding;
        ServerFileNameUTF8: Text;
        ServerFileNameWindows1251: Text;
    begin
        ServerFileNameUTF8 := FileManagement.ServerTempFileName('xml');
        ServerFileNameWindows1251 := FileManagement.ServerTempFileName('xml');
        XmlDoc.Save(ServerFileNameUTF8);
        dotNetFile.WriteAllText(ServerFileNameWindows1251,
          dotNetFile.ReadAllText(ServerFileNameUTF8, Encoding.GetEncoding('utf-8')),
          Encoding.GetEncoding('windows-1251'));

        FileId += '.xml';
        Download(ServerFileNameWindows1251, '', '', '(*.xml)|*.xml', FileId);

        FileManagement.DeleteServerFile(ServerFileNameUTF8);
        FileManagement.DeleteServerFile(ServerFileNameWindows1251);
        exit(true);
    end;

    local procedure XMLAddElement(var XMLNode: DotNet XmlNode; NodeName: Text[250]; NodeText: Text[250]; NameSpace: Text[250]; var CreatedXMLNode: DotNet XmlNode)
    var
        NewChildNode: DotNet XmlNode;
        XmlNodeType: DotNet XmlNodeType;
    begin
        NewChildNode := XMLNode.OwnerDocument.CreateNode(XmlNodeType.Element, NodeName, NameSpace);

        if NodeText <> '' then
            NewChildNode.InnerText := NodeText;

        if XMLNode.NodeType.Equals(XmlNodeType.ProcessingInstruction) then
            CreatedXMLNode := XMLNode.OwnerDocument.AppendChild(NewChildNode)
        else begin
            XMLNode.AppendChild(NewChildNode);
            CreatedXMLNode := NewChildNode;
        end;
    end;

    local procedure XMLAddAttribute(var XMLNode: DotNet XmlNode; Name: Text[260]; NodeValue: Variant)
    var
        XMLNewAttributeNode: DotNet XmlNode;
        NodeValueText: Text;
    begin
        XMLNewAttributeNode := XMLNode.OwnerDocument.CreateAttribute(Name);
        EvaluateNodeValue(NodeValue, NodeValueText);

        if NodeValueText <> '' then
            XMLNewAttributeNode.Value := NodeValueText;

        XMLNode.Attributes.SetNamedItem(XMLNewAttributeNode);
    end;

    local procedure XMLAddOptionalAttribute(var XMLNode: DotNet XmlNode; Name: Text; NodeValue: Variant)
    var
        XMLNewAttributeNode: DotNet XmlNode;
        NodeValueText: Text;
        IsZero: Boolean;
    begin
        XMLNewAttributeNode := XMLNode.OwnerDocument.CreateAttribute(Name);
        IsZero := EvaluateNodeValue(NodeValue, NodeValueText);

        if (NodeValueText = '') or IsZero then
            exit;

        XMLNewAttributeNode.Value := NodeValueText;
        XMLNode.Attributes.SetNamedItem(XMLNewAttributeNode);
    end;

    local procedure XMLAddSimpleElement(NodeName: Text[250]; NodeText: Text[250])
    begin
        XMLAddElement(XMLCurrNode, NodeName, UpperCase(NodeText), '', XMLNewChild);
    end;

    local procedure XMLAddComplexElement(NodeName: Text[250])
    begin
        XMLAddElement(XMLCurrNode, NodeName, '', '', XMLNewChild);
        XMLCurrNode := XMLNewChild;
    end;
}

