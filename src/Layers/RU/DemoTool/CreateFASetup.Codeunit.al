codeunit 101801 "Create FA Setup"
{

    trigger OnRun()
    var
        ExcelTemplate: Record "Excel Template";
    begin
        "FA Setup".Init();

        "Create No. Series".InsertSeriesOnly("FA Setup"."Fixed Asset Nos.", XFA + '-01', XFixedAsset, true, false, false);
        "Create No. Series".InsertSeriesLine("FA Setup"."Fixed Asset Nos.", XFA, 10000, 0D, 1);
        "Create No. Series".InsertSeriesOnly("FA Setup"."Fixed Asset Nos.", XFA + '-02', XIntangiableAssets, true, false, false);
        "Create No. Series".InsertSeriesLine("FA Setup"."Fixed Asset Nos.", XIA, 10000, 0D, 1);
        "Create No. Series".InsertSeriesOnly("FA Setup"."Fixed Asset Nos.", XFA + '-04', XLease, true, false, true);
        "Create No. Series".InsertSeriesLine("FA Setup"."Fixed Asset Nos.", XLA, 10000, 0D, 1);
        "Create No. Series".InsertSeriesOnly("FA Setup"."Fixed Asset Nos.", XFA + '-03', XDeferrals, true, false, true);
        "Create No. Series".InsertSeriesLine("FA Setup"."Fixed Asset Nos.", XFE, 10000, 0D, 1);
        "Create No. Series".InsertSeriesOnly("FA Setup"."Fixed Asset Nos.", XFA + '-08', XFAOnOffBalAccounts, false, false, false);
        "Create No. Series".InsertSeriesLine("FA Setup"."Fixed Asset Nos.", XFAOB, 10000, 19020101D, 1);
        "Create No. Series".InsertRelation(XFA + '-01', XFA + '-02');
        "Create No. Series".InsertRelation(XFA + '-01', XFA + '-03');
        "Create No. Series".InsertRelation(XFA + '-01', XFA + '-04');
        "Create No. Series".InsertRelation(XFA + '-01', XFA + '-08');
        "FA Setup"."Fixed Asset Nos." := XFA + '-01';

        "Create No. Series".InsertSeriesOnly("FA Setup"."Insurance Nos.", XFA + '-09', XInsurance, true, false, true);
        "Create No. Series".InsertSeriesLine("FA Setup"."Insurance Nos.", XFAINS, 10000, 0D, 1);

        "Create No. Series".InsertSeriesOnly("FA Setup"."Writeoff Nos.", XFA + '-14', XWriteOffFA, false, true, false);
        "Create No. Series".InsertSeriesLine("FA Setup"."Writeoff Nos.", XFAW, 10000, 19020101D, 1);
        "Create No. Series".InsertSeriesLine("FA Setup"."Writeoff Nos.", XFAW, 20000, 19030101D, 1);
        "FA Setup"."Posted Release Nos." := XFA + '-14';

        "Create No. Series".InsertSeriesOnly("FA Setup"."Posted Writeoff Nos.", XFA + '-15', XPostedWriteOffFA, false, true, true);
        "Create No. Series".InsertSeriesLine("FA Setup"."Posted Writeoff Nos.", XFAW + '2', 10000, 19020101D, 1);
        "Create No. Series".InsertSeriesLine("FA Setup"."Posted Writeoff Nos.", XFAW + '2', 20000, 19030101D, 1);
        "FA Setup"."Posted Release Nos." := XFA + '-15';

        "Create No. Series".InsertSeriesOnly("FA Setup"."Release Nos.", XFA + '-10', XComSheetFA, false, true, true);
        "Create No. Series".InsertSeriesLine("FA Setup"."Release Nos.", XFAR, 10000, 19020101D, 1);
        "Create No. Series".InsertSeriesLine("FA Setup"."Release Nos.", XFAR, 20000, 19030101D, 1);
        "FA Setup"."Posted Release Nos." := XFA + '-10';

        "Create No. Series".InsertSeriesOnly("FA Setup"."Posted Release Nos.", XFA + '-11', XPostedComSheetFA, true, false, true);
        "Create No. Series".InsertSeriesLine("FA Setup"."Posted Release Nos.", XFAR + '2', 10000, 19020101D, 1);
        "Create No. Series".InsertSeriesLine("FA Setup"."Posted Release Nos.", XFAR + '2', 20000, 19030101D, 1);
        "FA Setup"."Posted Release Nos." := XFA + '-11';

        "Create No. Series".InsertSeriesOnly("FA Setup"."Disposal Nos.", XFA + '-12', XInternalMovementFA, true, false, true);
        "Create No. Series".InsertSeriesLine("FA Setup"."Disposal Nos.", XFAM, 10000, 19020101D, 1);
        "Create No. Series".InsertSeriesLine("FA Setup"."Disposal Nos.", XFAM, 20000, 19030101D, 1);

        "Create No. Series".InsertSeriesOnly("FA Setup"."Posted Disposal Nos.", XFA + '-13', XPostedInternalMovementFA, true, false, true);
        "Create No. Series".InsertSeriesLine("FA Setup"."Posted Disposal Nos.", XFAM + '2', 10000, 19020101D, 1);
        "Create No. Series".InsertSeriesLine("FA Setup"."Posted Disposal Nos.", XFAM + '2', 20000, 19030101D, 1);

        "FA Setup"."Release Depr. Book" := XOPERATION;
        "FA Setup"."Quantitative Depr. Book" := XQUANTITY;
        "FA Setup"."Default Depr. Book" := XAQUISITION;

        "FA Setup"."Insurance Depr. Book" := "FA Setup"."Default Depr. Book";
        "FA Setup"."Future Depr. Book" := XFEACC;
        "FA Setup"."Disposal Depr. Book" := XOPERATION;

        DemoDataSetup.Get();
        if DemoDataSetup."Russian Accounting" then begin
            "FA Setup"."FA-1b Template Code" := XFA1B;
            ExcelTemplate.InsertTemplate(XFA1B, 'FA-1b', 'LocalFiles\FA-1b.xls');
            "FA Setup"."FA-4b Template Code" := XFA4B;
            ExcelTemplate.InsertTemplate(XFA4B, 'FA-4b', 'LocalFiles\FA-4b.xls');
            "FA Setup"."FA-6a Template Code" := XFA6A;
            ExcelTemplate.InsertTemplate(XFA6A, 'FA-6a', 'LocalFiles\FA-6a.xls');
            "FA Setup"."FA-6b Template Code" := XFA6B;
            ExcelTemplate.InsertTemplate(XFA6B, 'FA-6b', 'LocalFiles\FA-6b.xls');
            "FA Setup"."INV-1a Template Code" := XINV1A;
            ExcelTemplate.InsertTemplate(XINV1A, 'INV-1a', 'LocalFiles\INV-1a.xlsx');
            "FA Setup"."INV-11 Template Code" := XINV11;
            ExcelTemplate.InsertTemplate(XINV11, 'INV-11', 'LocalFiles\INV-11.xlsx');

            "FA Setup"."AT Declaration Template Code" := XATDECL;
            ExcelTemplate.InsertTemplate(
              XATDECL, XAssessedTaxDeclaration, 'LocalFiles\AT-Declaration.xlsx');
            "FA Setup"."AT Advance Template Code" := XATADV;
            ExcelTemplate.InsertTemplate(XATADV, XAssessedTaxAdvance, 'LocalFiles\AT-Advance.xlsx');
            "FA Setup".KBK := '18210602010021000110';

            "FA Setup"."INV-1 Template Code" := XINV1;
            ExcelTemplate.InsertTemplate(XINV1, XINV1, 'LocalFiles\INV-1.xlsx');
            "FA Setup"."INV-18 Template Code" := XINV18;
            ExcelTemplate.InsertTemplate(XINV18, XINV18, 'LocalFiles\INV-18.xlsx');
            "FA Setup"."M-2a Template Code" := XM2A;
            ExcelTemplate.InsertTemplate(XM2A, XM2A, 'LocalFiles\M-2A.xlsx');
            "FA Setup"."FA-2 Template Code" := XFA2;
            ExcelTemplate.InsertTemplate(XFA2, XFA2, 'LocalFiles\FA-2.xlsx');
            "FA Setup"."FA-14 Template Code" := XFA14;
            ExcelTemplate.InsertTemplate(XFA14, XFA14, 'LocalFiles\FA-14.xlsx');
            "FA Setup"."FA-3 Template Code" := XFA3;
            ExcelTemplate.InsertTemplate(XFA3, XFA3, 'LocalFiles\FA-3.xlsx');
            "FA Setup"."FA-4 Template Code" := XFA4;
            ExcelTemplate.InsertTemplate(XFA4, XFA4, 'LocalFiles\FA-4.xlsx');
            "FA Setup"."FA-4a Template Code" := XFA4A;
            ExcelTemplate.InsertTemplate(XFA4A, XFA4A, 'LocalFiles\FA-4A.xlsx');
            "FA Setup"."FA-6 Template Code" := XFA6;
            ExcelTemplate.InsertTemplate(XFA6, XFA6, 'LocalFiles\FA-6.xlsx');
            "FA Setup"."FA-15 Template Code" := XFA15;
            ExcelTemplate.InsertTemplate(XFA15, XFA15, 'LocalFiles\FA-15.xlsx');
            "FA Setup"."FA-1 Template Code" := XFA1;
            ExcelTemplate.InsertTemplate(XFA1, XFA1, 'LocalFiles\FA-1.xlsx');
        end;

        if not "FA Setup".Insert(true) then
            "FA Setup".Modify();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        "FA Setup": Record "FA Setup";
        "Create No. Series": Codeunit "Create No. Series";
        XFA: Label 'FA';
        XFixedAsset: Label 'Fixed Asset';
        XInsurance: Label 'Insurance';
        XQUANTITY: Label 'QUANTITY';
        XAQUISITION: Label 'AQUISITION';
        XOPERATION: Label 'OPERATION';
        XFEACC: Label 'FEACC';
        XFAINS: Label 'FAINS';
        XFAW: Label 'FAW';
        XFAR: Label 'FAR';
        XFAM: Label 'FAM';
        XIA: Label 'IA';
        XLA: Label 'LA';
        XFE: Label 'FE';
        XFAOB: Label 'FAOB';
        XFA1B: Label 'FA-1B';
        XFA4B: Label 'FA-4B';
        XFA6A: Label 'FA-6A';
        XFA6B: Label 'FA-6B';
        XINV1A: Label 'INV-1A';
        XINV11: Label 'INV-11';
        XATDECL: Label 'ATDECL';
        XATADV: Label 'ATADV';
        XAssessedTaxDeclaration: Label 'Assessed Tax Declaration';
        XAssessedTaxAdvance: Label 'Assessed Tax Advance';
        XIntangiableAssets: Label 'Intangible assets';
        XLease: Label 'Lease';
        XDeferrals: Label 'Deferrals';
        XFAOnOffBalAccounts: Label 'FA on off-balance accounts';
        XWriteOffFA: Label 'Write-off FA';
        XPostedWriteOffFA: Label 'Posted write-off FA';
        XComSheetFA: Label 'Commissioning sheet of FA';
        XPostedComSheetFA: Label 'Posted commissioning sheet of FA';
        XInternalMovementFA: Label 'Internal movement FA';
        XPostedInternalMovementFA: Label 'Posted internal movement FA';
        XINV1: Label 'INV-1';
        XINV18: Label 'INV-18';
        XM2A: Label 'M-2A';
        XFA2: Label 'FA-2';
        XFA14: Label 'FA-14';
        XFA3: Label 'FA-3';
        XFA4: Label 'FA-4';
        XFA4A: Label 'FA-4A';
        XFA6: Label 'FA-6';
        XFA15: Label 'FA-15';
        XFA1: Label 'FA-1';
	
}
