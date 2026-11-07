codeunit 101809 "Create FA Depreciation Book"
{

    trigger OnRun()
    begin
        "FA Setup".Get();
        "FA Posting Group" := XCAR;
        InsertData(XFA000010, 19020101D, 5, "FA Posting Group");
        InsertData(XFA000020, 19020501D, 5, "FA Posting Group");
        InsertData(XFA000030, 19020601D, 5, "FA Posting Group");
        "FA Posting Group" := XMACHINERY;
        InsertData(XFA000040, 19020101D, 0, "FA Posting Group");
        InsertData(XFA000050, 19020101D, 10, "FA Posting Group");
        InsertData(XFA000060, 19020201D, 8, "FA Posting Group");
        InsertData(XFA000070, 19020301D, 4, "FA Posting Group");
        InsertData(XFA000080, 19020401D, 8, "FA Posting Group");
        InsertData(XFA000090, 19020201D, 7, XTELEPHONE);
    end;

    var
        "FA Setup": Record "FA Setup";
        "FA Depreciation Book": Record "FA Depreciation Book";
        CA: Codeunit "Make Adjustments";
        "FA Posting Group": Code[20];
        XCAR: Label 'CAR';
        XMACHINERY: Label 'MACHINERY';
        XTELEPHONE: Label 'TELEPHONE';
        XFA000010: Label 'FA000010';
        XFA000020: Label 'FA000020';
        XFA000030: Label 'FA000030';
        XFA000040: Label 'FA000040';
        XFA000050: Label 'FA000050';
        XFA000060: Label 'FA000060';
        XFA000070: Label 'FA000070';
        XFA000080: Label 'FA000080';
        XFA000090: Label 'FA000090';

    procedure InsertData("FA No.": Code[20]; "Depreciation Starting Date": Date; "No. of Depreciation Years": Decimal; "FA Posting Group": Code[20])
    begin
        "FA Depreciation Book"."FA No." := "FA No.";
        "FA Depreciation Book"."Depreciation Book Code" := "FA Setup"."Default Depr. Book";
        "FA Depreciation Book"."Depreciation Starting Date" := CA.AdjustDate("Depreciation Starting Date");
        "FA Depreciation Book".Validate("No. of Depreciation Years", "No. of Depreciation Years");
        "FA Depreciation Book".Validate("FA Posting Group", "FA Posting Group");
        "FA Depreciation Book".Insert(true);
    end;
}

