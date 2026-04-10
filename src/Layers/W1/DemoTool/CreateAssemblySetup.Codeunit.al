codeunit 118870 "Create Assembly Setup"
{

    trigger OnRun()
    begin
        if not AssemblySetup.Get() then
            AssemblySetup.Insert();

        AssemblySetup.Validate("Stockout Warning", true);
        AssemblySetup.Validate("Copy Component Dimensions from", AssemblySetup."Copy Component Dimensions from"::"Item/Resource Card");
        AssemblySetup.Validate("Copy Comments when Posting", true);
        AssemblySetup.Validate("Create Movements Automatically", true);

        CreateNoSeries.InitBaseSeries(AssemblySetup."Assembly Order Nos.", XAORD, XAORDName, '1', XEndingNumber, '', XWarningNumber, 1, Enum::"No. Series Implementation"::Sequence);
        CreateNoSeries.InitBaseSeries(AssemblySetup."Assembly Quote Nos.", XAQUO, XAQuoteName, '1', XEndingNumber, '', XWarningNumber, 1, Enum::"No. Series Implementation"::Sequence);
        CreateNoSeries.InitBaseSeries(AssemblySetup."Blanket Assembly Order Nos.", XABLK, XABLKName, '1', XEndingNumber,
          '', XWarningNumber, 1, Enum::"No. Series Implementation"::Sequence);
        CreateNoSeries.InitBaseSeries(AssemblySetup."Posted Assembly Order Nos.", XAORDPlus, XAORDPlusName, '1', XEndingNumber,
          '', XWarningNumber, 1, Enum::"No. Series Implementation"::Sequence);
        AssemblySetup."Assembly Order Nos." := XAORD;
        AssemblySetup."Assembly Quote Nos." := XAQUO;
        AssemblySetup."Blanket Assembly Order Nos." := XABLK;
        AssemblySetup."Posted Assembly Order Nos." := XAORDPlus;

        AssemblySetup.Modify();
    end;

    var
        AssemblySetup: Record "Assembly Setup";
        CreateNoSeries: Codeunit "Create No. Series";
        XAORD: Label 'A-ORD', Comment = 'A-ORD stands for Assembly-Order';
        XAORDName: Label 'Assembly Orders';
        XAQUO: Label 'A-QUO', Comment = 'A-ORD stands for Assembly-Quote.';
        XAQuoteName: Label 'Assembly Quote';
        XABLK: Label 'A-BLK', Comment = 'A_BLK stands for Assembly-Blanket.';
        XABLKName: Label 'Assembly Blanket Orders';
        XAORDPlus: Label 'A-ORD+';
        XAORDPlusName: Label 'Posted Assembly Orders';
        XEndingNumber: Label 'A01000', Comment = 'A stands for Assembly.';
        XWarningNumber: Label 'A00995', Comment = 'A stands for Assembly.';
}

