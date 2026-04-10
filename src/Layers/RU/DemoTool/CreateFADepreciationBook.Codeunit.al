codeunit 101809 "Create FA Depreciation Book"
{

    trigger OnRun()
    begin
        // XAQUISITION
        InsertData(XIA + '001', XAQUISITION, 19021101D, 5, '08-500');
        InsertData(XIA + '002', XAQUISITION, 0D, 0, '08-500');
        InsertData(XIA + '003', XAQUISITION, 19030101D, 5, '08-500');
        InsertData(XFAOB + '001', XAQUISITION, 0D, 0, '99-1010');
        InsertData(XFA000010, XAQUISITION, 0D, 0, '08-400');
        InsertData(XFA000020, XAQUISITION, 0D, 0, '08-400');
        InsertData(XFA000030, XAQUISITION, 0D, 0, '08-400');
        InsertData(XFA000040, XAQUISITION, 0D, 0, '08-400');
        InsertData(XFA000050, XAQUISITION, 0D, 0, '08-400');
        InsertData(XFA000060, XAQUISITION, 0D, 0, '08-400');
        InsertData(XFA000070, XAQUISITION, 0D, 0, '08-400');
        InsertData(XFA000080, XAQUISITION, 0D, 0, '08-400');
        InsertData(XFA000090, XAQUISITION, 0D, 0, '08-400');
        InsertData(XFA + '001', XAQUISITION, 0D, 0, '08-400');
        InsertData(XFA + '002', XAQUISITION, 0D, 0, '08-400');
        InsertData(XFA + '002', XUPGRADING, 0D, 0, '08-400');
        InsertData(XFA + '003', XAQUISITION, 0D, 0, '08-400');
        InsertData(XFA + '004', XAQUISITION, 0D, 0, '08-400');
        InsertData(XFA + '005', XAQUISITION, 0D, 0, '08-400');
        InsertData(XFA + '006', XAQUISITION, 0D, 0, '08-400');
        InsertData(XFA + '007', XAQUISITION, 0D, 0, '08-400');
        InsertData(XFA + '008', XAQUISITION, 0D, 0, '08-400');
        InsertData(XFA + '009', XAQUISITION, 19021101D, 2, '08-400');
        InsertData(XFA + '010', XAQUISITION, 19021101D, 2, '08-400');
        InsertData(XFA + '011', XAQUISITION, 19021101D, 2, '08-400');
        InsertData(XFA + '012', XAQUISITION, 19021101D, 2, '08-400');
        InsertData(XFA + '013', XAQUISITION, 19021201D, 3, '08-400');
        InsertData(XFA + '014', XAQUISITION, 19021201D, 3, '08-400');
        InsertData(XFA + '015', XAQUISITION, 19021201D, 3, '08-400');
        InsertData(XFA + '016', XAQUISITION, 19030101D, 50, '08-310');
        InsertData(XFA + '017', XAQUISITION, 19021101D, 2, '08-400');
        InsertData(XFA + '018', XAQUISITION, 19021101D, 2, '08-400');
        InsertData(XFA + '019', XAQUISITION, 19021101D, 2, '08-400');
        InsertData(XFA + '020', XAQUISITION, 19021101D, 2, '08-400');
        InsertData(XFA + '021', XAQUISITION, 19021101D, 2, '08-400');
        InsertData(XFA + '022', XAQUISITION, 19021101D, 2, '08-400');
        InsertData(XFA + '023', XAQUISITION, 19021101D, 2, '08-400');
        InsertData(XFA + '024', XAQUISITION, 19021101D, 2, '08-400');
        InsertData(XFA + '025', XAQUISITION, 19021101D, 2, '08-400');
        InsertData(XFA + '026', XAQUISITION, 19021101D, 2, '08-400');
        InsertData(XFA + '027', XAQUISITION, 19021101D, 0, '08-320');
        InsertData(XFA + '028', XAQUISITION, 19021101D, 5, '08-400');
        InsertData(XFA + '030', XAQUISITION, 0D, 0, '');

        InsertData(XFA + '027', XCLOSEDOWN, 0D, 0, '01-400');

        InsertData(XFE + '001', XFEACC, 19021006D, 1, '97-130_44');
        //InsertData(XFE+'002',XFEACC,01021903D,1.75,'09-1010');
        InsertData(XFE + '001', XFETAX, 0D, 0, '97-130_44');
        InsertData(XFE + '002', XFETAX, 0D, 0, '');

        InsertData(XIA + '001', XOPERATION, 0D, 5, '04-120_26');
        InsertData(XIA + '002', XOPERATION, 19021201D, 5, '04-110_20');
        InsertData(XIA + '003', XOPERATION, 0D, 5, '04-120_26');
        InsertData(XFA000010, XOPERATION, 19020201D, 5, '01-104_26');
        InsertData(XFA000020, XOPERATION, 19020601D, 5, '01-104_26');
        InsertData(XFA000030, XOPERATION, 19020701D, 5, '01-103_20');
        InsertData(XFA000040, XOPERATION, 19020701D, 5, '01-103_20');
        InsertData(XFA000050, XOPERATION, 0D, 5, '01-103_20');
        InsertData(XFA000060, XOPERATION, 0D, 5, '01-103_20');
        InsertData(XFA000070, XOPERATION, 0D, 3, '01-103_20');
        InsertData(XFA000080, XOPERATION, 19020501D, 7, '01-103_20');
        InsertData(XFA000090, XOPERATION, 0D, 5, '01-103_20');
        InsertData(XFA + '001', XOPERATION, 19021101D, 30.08333333, '01-101_44');
        InsertData(XFA + '002', XOPERATION, 19021101D, 10, '01-102_26');
        InsertData(XFA + '003', XOPERATION, 19021101D, 2, '01-103_91');
        InsertData(XFA + '004', XOPERATION, 19021101D, 2, '01-103_91');
        InsertData(XFA + '005', XOPERATION, 19021101D, 2, '01-103_91');
        InsertData(XFA + '006', XOPERATION, 19021101D, 2, '01-103_91');
        InsertData(XFA + '007', XOPERATION, 19021101D, 2, '01-103_91');
        InsertData(XFA + '008', XOPERATION, 19021101D, 2, '01-103_91');
        InsertData(XFA + '009', XOPERATION, 0D, 2, '01-103_26');
        InsertData(XFA + '010', XOPERATION, 0D, 2, '01-103_26');
        InsertData(XFA + '011', XOPERATION, 0D, 2, '01-103_26');
        InsertData(XFA + '012', XOPERATION, 0D, 2, '01-103_26');
        InsertData(XFA + '013', XOPERATION, 0D, 3, '01-105_26');
        InsertData(XFA + '014', XOPERATION, 0D, 3, '01-105_26');
        InsertData(XFA + '015', XOPERATION, 0D, 3, '01-105_26');
        InsertData(XFA + '016', XOPERATION, 0D, 30.08333333, '01-101_20');
        InsertData(XFA + '017', XOPERATION, 0D, 2, '01-103_26');
        InsertData(XFA + '018', XOPERATION, 0D, 2, '01-103_26');
        InsertData(XFA + '019', XOPERATION, 0D, 2, '01-103_26');
        InsertData(XFA + '020', XOPERATION, 0D, 2, '01-103_26');
        InsertData(XFA + '021', XOPERATION, 0D, 2, '01-103_26');
        InsertData(XFA + '022', XOPERATION, 0D, 2, '01-103_26');
        InsertData(XFA + '023', XOPERATION, 0D, 2, '01-103_26');
        InsertData(XFA + '024', XOPERATION, 0D, 2, '01-103_26');
        InsertData(XFA + '025', XOPERATION, 0D, 2, '01-103_26');
        InsertData(XFA + '026', XOPERATION, 0D, 2, '01-103_26');
        InsertData(XFA + '027', XOPERATION, 19021101D, 3.08333333, '01-103_20');
        InsertData(XFA + '028', XOPERATION, 0D, 5, '01-104_26');
        InsertData(XFA + '029', XOPERATION, 0D, 0, '01-103_26');
        InsertData(XFA + '030', XOPERATION, 0D, 0, '01-103_26');
        InsertData(XFA + '031', XOPERATION, 0D, 0, '01-105_26');
        InsertData(XFA + '032', XOPERATION, 0D, 0, '01-105_26');

        InsertData(XFA + '016', XRENT, 19030101D, 30.08333333, '01-201_90');

        InsertData(XIA + '001', XTAXACC, 19021101D, 5, XTAX + '-' + XIA);
        InsertData(XIA + '002', XTAXACC, 19021201D, 5, XTAX + '-' + XIA);
        InsertData(XIA + '003', XTAXACC, 19030101D, 5, XTAX + '-' + XIA);
        InsertData(XFA000010, XTAXACC, 19020201D, 10, XTAX + '-104');
        InsertData(XFA000020, XTAXACC, 19020601D, 10, XTAX + '-104');
        InsertData(XFA000030, XTAXACC, 0D, 5, XTAX + '-103');
        InsertData(XFA000040, XTAXACC, 0D, 5, XTAX + '-103');
        InsertData(XFA000050, XTAXACC, 0D, 5, XTAX + '-103');
        InsertData(XFA000060, XTAXACC, 0D, 5, XTAX + '-103');
        InsertData(XFA000070, XTAXACC, 0D, 3, XTAX + '-103');
        InsertData(XFA000080, XTAXACC, 0D, 7, XTAX + '-103');
        InsertData(XFA000090, XTAXACC, 0D, 9, XTAX + '-103');
        InsertData(XFA + '001', XTAXACC, 19021101D, 30.08333333, XTAX + '-101');
        InsertData(XFA + '002', XTAXACC, 19021101D, 10, XTAX + '-102');
        InsertData(XFA + '003', XTAXACC, 19021101D, 2, XTAX + '-103');
        InsertData(XFA + '004', XTAXACC, 19021101D, 2, XTAX + '-103');
        InsertData(XFA + '005', XTAXACC, 19021101D, 2, XTAX + '-103');
        InsertData(XFA + '006', XTAXACC, 19021101D, 2, XTAX + '-103');
        InsertData(XFA + '007', XTAXACC, 19021101D, 2, XTAX + '-103');
        InsertData(XFA + '008', XTAXACC, 19021101D, 2, XTAX + '-103');
        InsertData(XFA + '009', XTAXACC, 19021101D, 2, XTAX + '-103');
        InsertData(XFA + '010', XTAXACC, 19021101D, 2, XTAX + '-103');
        InsertData(XFA + '011', XTAXACC, 19021101D, 2, XTAX + '-103');
        InsertData(XFA + '012', XTAXACC, 19021101D, 2, XTAX + '-103');
        InsertData(XFA + '013', XTAXACC, 19021201D, 3, XTAX + '-105');
        InsertData(XFA + '014', XTAXACC, 19021201D, 3, XTAX + '-105');
        InsertData(XFA + '015', XTAXACC, 19021201D, 3, XTAX + '-105');
        InsertData(XFA + '016', XTAXACC, 19030101D, 30.08333333, XTAX + '-101');
        InsertData(XFA + '017', XTAXACC, 19021101D, 2, XTAX + '-103');
        InsertData(XFA + '018', XTAXACC, 19021101D, 2, XTAX + '-103');
        InsertData(XFA + '019', XTAXACC, 19021101D, 2, XTAX + '-103');
        InsertData(XFA + '020', XTAXACC, 19021101D, 2, XTAX + '-103');
        InsertData(XFA + '021', XTAXACC, 19021101D, 2, XTAX + '-103');
        InsertData(XFA + '022', XTAXACC, 19021101D, 2, XTAX + '-103');
        InsertData(XFA + '023', XTAXACC, 19021101D, 2, XTAX + '-103');
        InsertData(XFA + '024', XTAXACC, 19021101D, 2, XTAX + '-103');
        InsertData(XFA + '025', XTAXACC, 19021101D, 2, XTAX + '-103');
        InsertData(XFA + '026', XTAXACC, 19021101D, 2, XTAX + '-103');
        InsertData(XFA + '027', XTAXACC, 19021101D, 3.08333333, XTAX + '-103');
        InsertData(XFA + '028', XTAXACC, 19021101D, 5, XTAX + '-104');
        InsertData(XFA + '029', XTAXACC, 0D, 2, XTAX + '-103');
        InsertData(XFA + '030', XTAXACC, 0D, 2, XTAX + '-103');
        InsertData(XFA + '031', XTAXACC, 0D, 2, XTAX + '-105');
        InsertData(XFA + '032', XTAXACC, 0D, 2, XTAX + '-105');
    end;

    var
        "FA Depreciation Book": Record "FA Depreciation Book";
        CA: Codeunit "Make Adjustments";
        XFA000010: Label 'FA000010';
        XFA000020: Label 'FA000020';
        XFA000030: Label 'FA000030';
        XFA000040: Label 'FA000040';
        XFA000050: Label 'FA000050';
        XFA000060: Label 'FA000060';
        XFA000070: Label 'FA000070';
        XFA000080: Label 'FA000080';
        XFA000090: Label 'FA000090';
        XAQUISITION: Label 'AQUISITION';
        XOPERATION: Label 'OPERATION';
        XTAXACC: Label 'TAXACC';
        XIA: Label 'IA';
        XFAOB: Label 'FAOB';
        XFA: Label 'FA';
        XCLOSEDOWN: Label 'CLOSEDOWN';
        XFEACC: Label 'FEACC';
        XFETAX: Label 'FETAX';
        XFE: Label 'FE';
        XRENT: Label 'RENT';
        XUPGRADING: Label 'UPGRADING';
        XTAX: Label 'TAX';

    procedure InsertData("FA No.": Code[20]; "Depreciation Book Code": Code[10]; "Depreciation Starting Date": Date; "No. of Depreciation Years": Decimal; "FA Posting Group": Code[20])
    begin
        "FA Depreciation Book".Init();
        "FA Depreciation Book"."FA No." := "FA No.";
        "FA Depreciation Book"."Depreciation Book Code" := "Depreciation Book Code";
        "FA Depreciation Book"."Depreciation Starting Date" := CA.AdjustDate("Depreciation Starting Date");
        "FA Depreciation Book".Validate("No. of Depreciation Years", "No. of Depreciation Years");
        "FA Depreciation Book"."No. of Depreciation Months" := Round("No. of Depreciation Years" * 12, 0.00000001);
        "FA Depreciation Book".Validate("FA Posting Group", "FA Posting Group");
        if "FA Depreciation Book"."Depreciation Book Code" = XOPERATION then
            "FA Depreciation Book".Validate("Depreciation Method", "FA Depreciation Book"."Depreciation Method"::"SL-RU");
        if not "FA Depreciation Book".Insert(true) then
            "FA Depreciation Book".Modify();
    end;
}

