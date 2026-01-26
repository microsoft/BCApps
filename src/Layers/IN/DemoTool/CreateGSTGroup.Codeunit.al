codeunit 120550 "Create GST Group"
{
    trigger OnRun()

    begin
        DemoDataSetup.Get();
        InsertData(
            XGstGrpCode0988, XGSTGrpType::Goods, XGSTPlaceOfSupply::"Bill-to Address", XDesc988, false);
        InsertData(
            XGstGrpCode0989, XGSTGrpType::Goods, XGSTPlaceOfSupply::" ", XDesc989, false);
        InsertData(
            XGstGrpCode2089, XGSTGrpType::Service, XGSTPlaceOfSupply::" ", XDesc2089, false);
        InsertData(
            XGstGrpCode2090, XGSTGrpType::Service, XGSTPlaceOfSupply::" ", XDesc2090, true);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        GstGroup: Record "GST Group";
        XGstGrpCode0988: Label '0988';
        XGstGrpCode0989: Label '0989';
        XGstGrpCode2089: Label '2089';
        XGstGrpCode2090: Label '2090';
        XGSTGrpType: Enum "GST Group Type";
        XGSTPlaceOfSupply: Enum "GST Dependency Type";
        XDesc988: Label '988';
        XDesc989: Label '989';
        XDesc2089: Label '2089';
        XDesc2090: Label '2090';

    procedure InsertData("No.": Code[20]; GSTGrpType: Enum "GST Group Type";
        GSTPlaceOfSupply: Enum "GST Dependency Type"; Descp: Code[250]; ReverseCharge: Boolean)
    begin
        DemoDataSetup.Get();
        GstGroup.Init();
        GstGroup.Validate(Code, "No.");
        GstGroup.Validate("GST Group Type", GSTGrpType);
        GstGroup.Validate("GST Place Of Supply", GSTPlaceOfSupply);
        GstGroup.Validate(Description, Descp);
        GstGroup."Reverse Charge" := ReverseCharge;
        GstGroup.Insert();
    end;
}