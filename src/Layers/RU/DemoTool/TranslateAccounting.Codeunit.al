codeunit 163449 "Translate Accounting"
{

    trigger OnRun()
    begin
    end;

    var
        TestMode: Boolean;

    procedure SetTestMode(NewTestMode: Boolean)
    begin
        TestMode := NewTestMode;
    end;

    procedure ReportCode(ReportCode: Text[30]): Text[30]
    begin
        if (GlobalLanguage <> 1049) and (not TestMode) then
            exit(ReportCode);

        case true of
            ReportCode = 'ACCOUNTING REPORTING':
                exit('üôòâÇïÆàÉæèÇƒ ÄÆùàÆìÄæÆ£');
            ReportCode = 'TAX REPORTING':
                exit('ìÇïÄâÄéÇƒ ÄÆùàÆìÄæÆ£');
            ReportCode = 'CASHFLOW':
                exit('äé.äàì.æÉ.');
            ReportCode = 'GENREPORT':
                exit('ÄüÖÄÆùàÆ');
            ReportCode = 'PROF&LOSS':
                exit('ÅÉêü&ôüøÆ');
            ReportCode = 'BALANCE':
                exit('æÇï£äÄ');
            ReportCode = 'BUDGANALYS':
                exit('ü×äÇìÇïêç');
            ReportCode = 'ACT/BUD':
                exit('öÇèÆ./ü.');
            ReportCode = 'COLUMN':
                exit('æÆÄïüàû');
            ReportCode = 'NETCHANGE':
                exit('ÄüÄÉÄÆ');
            ReportCode = 'TURNOVER':
                exit('ÄüÄÉÇèÆêéø');
            ReportCode = 'STRUCTURE':
                exit('æÆÉôèÆôÉÇ');
            ReportCode = 'CAMPAIGN':
                exit('èÇîÅÇìêƒ');
            ReportCode = 'EXPENCES':
                exit('ÉÇæòÄäø');
            ReportCode = 'DATA':
                exit('äÇììøà');
            ReportCode = 'SHARE':
                exit('äÄïƒ');
            ReportCode = 'HRP REPT':
                exit('çÉÅ ÄÆù');
            ReportCode = 'BUSEXPENS':
                exit('ÄüÖòÄçÉÇæò');
            ReportCode = 'SALESEXPEN':
                exit('ÅÉÄäÇåÉÇæò');
            ReportCode = 'DEFAULT':
                exit('æÆÇìäÇÉÆ');
            ReportCode = 'PERIOD':
                exit('ÅàÉêÄä');
            ReportCode = 'PERIOD_C':
                exit('ÅàÉêÄä_è');
            ReportCode = 'IND CARD':
                exit('êìä èÇÉÆ');
            ReportCode = 'FSI-4':
                exit('öææ-4');
            StrPos(ReportCode, 'FSI-4 T') > 0:
                exit('öææ-4 T' + CopyStr(ReportCode, 8));
            ReportCode = 'RSV-1':
                exit('Éæé-1');
            StrPos(ReportCode, 'RSV-1 T') > 0:
                exit('Éæé-1 Æ' + CopyStr(ReportCode, 8));
            StrPos(ReportCode, 'RSV-1 R') > 0:
                exit('Éæé-1 É' + CopyStr(ReportCode, 8));
            StrPos(ReportCode, 'FORM') > 0:
                exit('öÄÉîÇ' + CopyStr(ReportCode, 5));
            StrPos(ReportCode, 'VAT') > 0:
                exit('ìäæ' + CopyStr(ReportCode, 4));
            StrPos(ReportCode, 'PROFIT') > 0:
                exit('ÅÉêüøï£' + CopyStr(ReportCode, 7));
            StrPos(ReportCode, 'TRANSPORT_AV') > 0:
                exit('ÆÉÇìæÅÄÉÆ_Çé' + CopyStr(ReportCode, 13));
            StrPos(ReportCode, 'TRANSPORT') > 0:
                exit('ÆÉÇìæÅÄÉÆ' + CopyStr(ReportCode, 10));
            StrPos(ReportCode, 'PROPERTY_AV') > 0:
                exit('êîôÖ_Çé' + CopyStr(ReportCode, 12));
            StrPos(ReportCode, 'PROPERTY') > 0:
                exit('êîôÖ' + CopyStr(ReportCode, 9));
            StrPos(ReportCode, 'HEADCOUNT') > 0:
                exit('ùêæïàììÄæÆ£' + CopyStr(ReportCode, 10));
            StrPos(ReportCode, 'FUNDS') > 0:
                exit('öÄìäø' + CopyStr(ReportCode, 6));
            else
                exit(ReportCode);
        end;
    end;

    procedure GroupFilter(GroupCodeFilter: Text[250]): Text[250]
    begin
        if (GlobalLanguage <> 1049) and (not TestMode) then
            exit(GroupCodeFilter);

        ReplaceFilter(GroupCodeFilter, 'ADVPAY', 'ÇéÇìæø');
        ReplaceFilter(GroupCodeFilter, 'SALES', 'ÅÉÄäÇåê');
        ReplaceFilter(GroupCodeFilter, 'PURCHASE', 'ÅÄèôÅèÇ');
        ReplaceFilter(GroupCodeFilter, 'FA', 'Äæ');
        ReplaceFilter(GroupCodeFilter, 'FINISH', 'âÄÆ');
        ReplaceFilter(GroupCodeFilter, 'GOODS', 'ÆÄé');
        ReplaceFilter(GroupCodeFilter, 'MAT', 'îÅç');
        ReplaceFilter(GroupCodeFilter, 'INTASS', 'ìîÇ');
        ReplaceFilter(GroupCodeFilter, 'SERV', 'ôæï');
        ReplaceFilter(GroupCodeFilter, 'CUSTOMS', 'ÆÇî');
        ReplaceFilter(GroupCodeFilter, 'FUTEXP20ST', 'ÉüÅ20èæ');
        ReplaceFilter(GroupCodeFilter, 'FUTEXP20LT', 'ÉüÅ20äæ');
        ReplaceFilter(GroupCodeFilter, 'DATA', 'äÇììøà');

        exit(GroupCodeFilter);
    end;

    procedure ExcelTemplateCode(TemplateCode: Text[250]): Text[250]
    begin
        if (GlobalLanguage <> 1049) and (not TestMode) then
            exit(TemplateCode);

        case true of
            TemplateCode = 'VATSALLEDG':
                exit('ìäæèìÅÉÄä');
            TemplateCode = 'VATSALADDS':
                exit('ìäæèìÅÉÄää');
            TemplateCode = 'VATPURLEDG':
                exit('ìäæèìÅÄè');
            TemplateCode = 'VATPURADDS':
                exit('ìäæèìÅÄèä');
            TemplateCode = 'TAXREG':
                exit('ìÇïÉàâ');
            TemplateCode = 'VATISSJNL':
                exit('åôÉêæéòìäæ');
            else
                exit(TemplateCode);
        end;
    end;

    procedure ReplaceFilter(var GroupFilter: Text[250]; ENUText: Text[30]; RUSText: Text[30]): Text[250]
    var
        Pos: Integer;
    begin
        Pos := StrPos(GroupFilter, ENUText);
        if Pos > 0 then
            GroupFilter :=
              CopyStr(GroupFilter, 1, Pos - 1) +
              RUSText +
              CopyStr(GroupFilter, Pos + StrLen(ENUText));
    end;
}

