codeunit 131921 "Library - CAMT File Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        NamespaceTxt: Label 'urn:iso:std:iso:20022:tech:xsd:camt.053.001.02';

    procedure WriteCAMTHeader(var OutStream: OutStream)
    begin
        WriteLine(OutStream, '<?xml version="1.0" encoding="UTF-8"?>');
        WriteLine(OutStream,
          '<Document xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="' + NamespaceTxt + '">');
        WriteLine(OutStream, '  <BkToCstmrStmt>');
        WriteLine(OutStream, '    <GrpHdr>');
        WriteLine(OutStream, '      <MsgId>FP-STAT001</MsgId>');
        WriteLine(OutStream, '    </GrpHdr>');
    end;

    procedure WriteCAMTStmtHeader(var OutStream: OutStream; CurrTxt: Text; BankAccNo: Text)
    begin
        WriteLine(OutStream, '    <Stmt>');
        WriteLine(OutStream, '      <Id>FP-STAT001</Id>');
        WriteLine(OutStream, '      <CreDtTm>2017-05-05T17:00:00+01:00</CreDtTm>');
        WriteCAMTStmtHeaderBankAccIBAN(OutStream, BankAccNo);
        WriteCAMTStmtHeaderBal(OutStream, 'OPBD', CurrTxt, '500000', '2010-10-15');
        WriteCAMTStmtHeaderBal(OutStream, 'CLBD', CurrTxt, '435678.50', '2017-05-05');
    end;

    procedure WriteCAMTStmtHeaderWithBankID(var OutStream: OutStream; StmtID: Text; CreDtTm: Text; CurrTxt: Text; BankAccID: Text; OPBDAmount: Text; OPBDDate: Text; CLBDAmount: Text; CLBDDate: Text)
    begin
        WriteLine(OutStream, '    <Stmt>');
        WriteLine(OutStream, '      <Id>' + StmtID + '</Id>');
        WriteLine(OutStream, '      <CreDtTm>' + CreDtTm + '</CreDtTm>');
        WriteCAMTStmtHeaderBankAccID(OutStream, BankAccID);
        WriteCAMTStmtHeaderBal(OutStream, 'OPBD', CurrTxt, OPBDAmount, OPBDDate);
        WriteCAMTStmtHeaderBal(OutStream, 'CLBD', CurrTxt, CLBDAmount, CLBDDate);
    end;

    procedure WriteCAMTStmtHeaderBal(var OutStream: OutStream; CdTxt: Text; CurrTxt: Text; AmountTxt: Text; DateTxt: Text)
    begin
        WriteLine(OutStream, '      <Bal>');
        WriteCAMTStmtHeaderBalCdOrPrtry(OutStream, CdTxt);
        WriteLine(OutStream, '      <Amt Ccy="' + CurrTxt + '">' + AmountTxt + '</Amt>');
        WriteCAMTStmtHeaderBalCdtDbtDt(OutStream, DateTxt);
        WriteLine(OutStream, '      </Bal>');
    end;

    procedure WriteCAMTStmtHeaderBalCdOrPrtry(var OutStream: OutStream; CdTxt: Text)
    begin
        WriteLine(OutStream, '        <Tp>');
        WriteLine(OutStream, '          <CdOrPrtry>');
        WriteLine(OutStream, '            <Cd>' + CdTxt + '</Cd>');
        WriteLine(OutStream, '          </CdOrPrtry>');
        WriteLine(OutStream, '        </Tp>');
    end;

    procedure WriteCAMTStmtHeaderBalCdtDbtDt(var OutStream: OutStream; DateTxt: Text)
    begin
        WriteLine(OutStream, '      <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '      <Dt>');
        WriteLine(OutStream, '        <Dt>' + DateTxt + '</Dt>');
        WriteLine(OutStream, '      </Dt>');
    end;

    procedure WriteCAMTStmtHeaderBankAccIBAN(var OutStream: OutStream; IBAN: Text)
    begin
        WriteLine(OutStream, '      <Acct>');
        WriteLine(OutStream, '        <Id>');
        WriteLine(OutStream, '          <IBAN>' + IBAN + '</IBAN>');
        WriteLine(OutStream, '        </Id>');
        WriteLine(OutStream, '      </Acct>');
    end;

    procedure WriteCAMTStmtHeaderBankAccID(var OutStream: OutStream; BankID: Text)
    begin
        WriteLine(OutStream, '      <Acct>');
        WriteLine(OutStream, '        <Id>');
        WriteLine(OutStream, '          <Othr>');
        WriteLine(OutStream, '            <Id>' + BankID + '</Id>');
        WriteLine(OutStream, '          </Othr>');
        WriteLine(OutStream, '        </Id>');
        WriteLine(OutStream, '      </Acct>');
    end;

    procedure WriteCAMTStmtLine(var OutStream: OutStream; StmtDate: Date; StmtText: Text; StmtAmt: Decimal; StmtCurr: Text; StmtRelatedParty: Text)
    begin
        WriteCAMTStmtLineWithInstdAmt(OutStream, StmtDate, StmtText, StmtAmt, StmtCurr, StmtRelatedParty, 0, '');
    end;

    procedure WriteCAMTStmtLineWithInstdAmt(var OutStream: OutStream; StmtDate: Date; StmtText: Text; StmtAmt: Decimal; StmtCurr: Text; StmtRelatedParty: Text; InstdAmt: Decimal; InstdAmtCurr: Text)
    var
        StmtAmtTxt: Text;
    begin
        StmtAmtTxt := Format(StmtAmt, 0, 9);
        WriteLine(OutStream, '      <Ntry>');
        WriteLine(OutStream, '        <Amt Ccy="' + StmtCurr + '">' + StmtAmtTxt + '</Amt>');
        if StmtAmt > 0 then
            WriteLine(OutStream, '        <CdtDbtInd>DRDT</CdtDbtInd>')
        else
            WriteLine(OutStream, '        <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '        <Sts>BOOK2</Sts>');
        WriteLine(OutStream, '        <BookgDt>');
        WriteLine(OutStream, '          <DtTm>' + Format(StmtDate, 0, 9) + 'T13:15:00+01:00</DtTm>');
        WriteLine(OutStream, '        </BookgDt>');
        WriteLine(OutStream, '        <ValDt>');
        WriteLine(OutStream, '          <Dt>' + Format(StmtDate, 0, 9) + '</Dt>');
        WriteLine(OutStream, '        </ValDt>');
        WriteLine(OutStream, '        <AcctSvcrRef>FP-CN_3321d3/0/2</AcctSvcrRef>');
        WriteLine(OutStream, '        <NtryDtls>');
        WriteLine(OutStream, '          <TxDtls>');
        WriteLine(OutStream, '            <Refs>');
        WriteLine(OutStream, '              <EndToEndId>' + LibraryUtility.GenerateGUID() + '</EndToEndId>');
        WriteLine(OutStream, '            </Refs>');
        if InstdAmt > 0 then begin
            WriteLine(OutStream, '            <AmtDtls>');
            WriteLine(OutStream, '              <InstdAmt>');
            WriteLine(OutStream, '                <Amt Ccy="' + InstdAmtCurr + '">' + Format(InstdAmt) + '</Amt>');
            WriteLine(OutStream, '              </InstdAmt>');
            WriteLine(OutStream, '            </AmtDtls>');
        end;
        WriteLine(OutStream, '            <RmtInf>');
        WriteLine(OutStream, '              <Ustrd>Payment of Invoice:' + StmtText + '</Ustrd>');
        WriteLine(OutStream, '            </RmtInf>');
        if StmtRelatedParty <> '' then begin
            WriteLine(OutStream, '            <RltdPties>');
            WriteLine(OutStream, '              <Dbtr>');
            WriteLine(OutStream, '                <Nm>' + StmtRelatedParty + '</Nm>');
            WriteLine(OutStream, '              </Dbtr>');
            WriteLine(OutStream, '            </RltdPties>');
        end;
        WriteLine(OutStream, '          </TxDtls>');
        WriteLine(OutStream, '        </NtryDtls>');
        WriteLine(OutStream, '      </Ntry>');
    end;

    procedure WriteCAMTStmtFooter(var OutStream: OutStream)
    begin
        WriteLine(OutStream, '    </Stmt>');
    end;

    procedure WriteCAMTFooter(var OutStream: OutStream)
    begin
        WriteLine(OutStream, '  </BkToCstmrStmt>');
        WriteLine(OutStream, '</Document>');
    end;

    procedure SetupSourceMock(DataExchDefCode: Code[20]; var TempBlob: Codeunit "Temp Blob")
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        ErmPeSourceTestMock: Codeunit "ERM PE Source Test Mock";
        TempBlobList: Codeunit "Temp Blob List";
    begin
        TempBlobList.Add(TempBlob);
        ErmPeSourceTestMock.SetTempBlobList(TempBlobList);

        DataExchDef.Get(DataExchDefCode);
        DataExchDef."Ext. Data Handling Codeunit" := CODEUNIT::"ERM PE Source Test Mock";
        DataExchDef.Modify();

        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchLineDef.FindFirst();
        DataExchLineDef.Namespace := CopyStr(NamespaceTxt, 1, MaxStrLen(DataExchLineDef.Namespace));
        DataExchLineDef.Modify();
    end;

    local procedure WriteLine(OutStream: OutStream; Text: Text)
    begin
        OutStream.WriteText(Text);
        OutStream.WriteText();
    end;
}

