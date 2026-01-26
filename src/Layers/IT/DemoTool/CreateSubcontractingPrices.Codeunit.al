#if not CLEAN27
codeunit 161352 "Create Subcontracting Prices"
{
    ObsoleteReason = 'Preparation for replacement by Subcontracting app.';
    ObsoleteState = Pending;
    ObsoleteTag = '27.0';

    trigger OnRun()
    begin
        InsertData('500', '70000', '2000', '1', 0D, 0D, 10, XPCS, '');
        InsertData('500', '70000', '2000', '2', 0D, 0D, 20, XPCS, '');
    end;

    var
        XPCS: Label 'PCS';

    procedure InsertData(WorkCenterNo: Code[20]; VendorNo: Code[20]; ItemNo: Code[20]; StdTaskCode: Code[10]; StartDate: Date; EndDate: Date; DirectUnitCost: Decimal; UoMCode: Code[10]; VariantCode: Code[10])
    var
        SubcontractorPrices: Record "Subcontractor Prices";
    begin
        SubcontractorPrices.Init();
        SubcontractorPrices."Work Center No." := WorkCenterNo;
        SubcontractorPrices.Validate("Vendor No.", VendorNo);
        SubcontractorPrices."Item No." := ItemNo;
        SubcontractorPrices."Standard Task Code" := StdTaskCode;
        SubcontractorPrices."Start Date" := StartDate;
        SubcontractorPrices.Validate("End Date", EndDate);
        SubcontractorPrices."Direct Unit Cost" := DirectUnitCost;
        SubcontractorPrices."Unit of Measure Code" := UoMCode;
        SubcontractorPrices."Variant Code" := VariantCode;
        SubcontractorPrices.Insert();
    end;
}
#endif
