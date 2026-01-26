codeunit 101801 "Create FA Setup"
{

    trigger OnRun()
    begin
        "FA Setup".Init();
        "Create No. Series".InsertSeries("FA Setup"."Fixed Asset Nos.", XFA, XFixedAsset, XFA10, XFA0999990, XFA000090, '', 10, false, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries("FA Setup"."Insurance Nos.", XFAINS, XInsurance, XFAINS10, XINS0999990, XINS000040, '', 10, Enum::"No. Series Implementation"::Sequence);
        "FA Setup"."Default Depr. Book" := '1-ÚČETNÍ'; // NAVCZ
        "FA Setup"."Insurance Depr. Book" := "FA Setup"."Default Depr. Book";
        // NAVCZ
        "FA Setup"."Tax Depreciation Book CZF" := '2-DAŇOVÁ';
        "FA Setup"."FA Acquisition As Custom 2 CZF" := true;
        // NAVCZ
        if not "FA Setup".Insert(true) then
            "FA Setup".Modify();
    end;

    var
        "FA Setup": Record "FA Setup";
        "Create No. Series": Codeunit "Create No. Series";
        XFA: Label 'FA';
        XFixedAsset: Label 'Fixed Asset';
        XFA10: Label 'FA10';
        XFA0999990: Label 'FA0999990';
        XFA000090: Label 'FA000090';
        XFAINS: Label 'FA-INS';
        XInsurance: Label 'Insurance';
        XFAINS10: Label 'FA-INS10';
        XINS0999990: Label 'INS0999990';
        XINS000040: Label 'INS000040';
}

