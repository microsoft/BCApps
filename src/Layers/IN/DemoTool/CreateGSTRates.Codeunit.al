codeunit 120539 "Create GST Rates"
{
    trigger OnRun()
    var
        TaxTypeCode: Code[20];
    begin
        DemoDataSetup.Get();
        TaxTypeCode := 'GST';

        InsertData(TaxTypeCode, '0988001', '0988', '', 'DL', '2010-01-01', '2025-01-01', '0', '0', '18', '0', 'false', 'false');
        InsertData(TaxTypeCode, '0988001', '0988', 'HR', 'DL', '2010-01-01', '2025-01-01', '0', '0', '18', '0', 'false', 'false');
        InsertData(TaxTypeCode, '0988001', '0988', 'DL', 'DL', '2010-01-01', '2025-01-01', '9', '9', '0', '0', 'false', 'false');

        InsertData(TaxTypeCode, '0989001', '0989', '', 'DL', '2010-01-01', '2025-01-01', '0', '0', '18', '0', 'false', 'false');
        InsertData(TaxTypeCode, '0989001', '0989', 'HR', 'DL', '2010-01-01', '2025-01-01', '0', '0', '18', '0', 'false', 'false');
        InsertData(TaxTypeCode, '0989001', '0989', 'DL', 'DL', '2010-01-01', '2025-01-01', '9', '9', '0', '0', 'false', 'false');

        InsertData(TaxTypeCode, '2089001', '2089', '', 'DL', '2010-01-01', '2025-01-01', '0', '0', '18', '0', 'false', 'false');
        InsertData(TaxTypeCode, '2089001', '2089', 'HR', 'DL', '2010-01-01', '2025-01-01', '0', '0', '18', '0', 'false', 'false');
        InsertData(TaxTypeCode, '2089001', '2089', 'DL', 'DL', '2010-01-01', '2025-01-01', '9', '9', '0', '0', 'false', 'false');

        InsertData(TaxTypeCode, '2090001', '2090', '', 'DL', '2010-01-01', '2025-01-01', '0', '0', '18', '0', 'false', 'false');
        InsertData(TaxTypeCode, '2090001', '2090', 'HR', 'DL', '2010-01-01', '2025-01-01', '0', '0', '18', '0', 'false', 'false');
        InsertData(TaxTypeCode, '2090001', '2090', 'DL', 'DL', '2010-01-01', '2025-01-01', '9', '9', '0', '0', 'false', 'false');

        EnableTaxType(TaxTypeCode, true);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        TaxRate: Record "Tax Rate";

    procedure InsertData(
        TaxTypeCode: Code[20];
        ID: Guid;
        ColID: Integer;
        ColType: Enum "Column Type";
        ColValue: Text[100];
        DateValue: Date;
        DateValueTo: Date;
        DecimalValue: Decimal)
    var
        TaxRateValue: Record "Tax Rate Value";
        TaxSetupMatrixMgmt: Codeunit "Tax Setup Matrix Mgmt.";
    begin
        if ColID = 0 then
            exit;
        TaxRateValue.Init();
        TaxRateValue."Tax Type" := TaxTypeCode;
        TaxRateValue."Config ID" := ID;
        TaxRateValue.ID := CreateGuid();
        TaxRateValue."Column ID" := ColID;
        TaxRateValue."Column Type" := ColType;
        TaxRateValue.Value := ColValue;
        TaxRateValue."Decimal Value" := DecimalValue;
        TaxRateValue."Date Value" := DateValue;
        TaxRateValue."Value To" := Format(DateValueTo, 0, 9);
        TaxRateValue."Date Value To" := DateValueTo;
        TaxRateValue.Insert();
        TaxRateValue."Tax Rate ID" := TaxSetupMatrixMgmt.GenerateTaxRateID(ID, TaxTypeCode);
        TaxRateValue.Modify();
    end;

    local procedure CreateConfigID(TaxTypeCode: Code[20])
    begin
        TaxRate.Init();
        TaxRate."Tax Type" := TaxTypeCode;
        TaxRate.Insert(true);
    end;

    local procedure GetTaxColumnID(TaxTypeCode: Code[20]; ColumnName: Text[30]): Integer
    var
        TaxRateColSetup: Record "Tax Rate Column Setup";
    begin
        TaxRateColSetup.SetRange("Tax Type", TaxTypeCode);
        TaxRateColSetup.SetRange("Column Name", ColumnName);
        TaxRateColSetup.FindFirst();
        exit(TaxRateColSetup."Column ID");
    end;

    local procedure InsertData(
        TaxTypeCode: Code[20];
        HSNSAC: Text;
        GSTGroupCode: Text;
        FromState: Text;
        LocationStateCode: Text;
        DateFrom: Text;
        DateTo: Text;
        SGST: Text;
        CGST: Text;
        IGST: Text;
        KFC: Text;
        POSOutOfIndia: Text;
        POSasVendorState: Text)
    var
        SGSTValue: Decimal;
        CGSTValue: Decimal;
        IGSTValue: Decimal;
        KFCValue: Decimal;
        ToDate: Date;
        FromDate: Date;
    begin
        Evaluate(SGSTValue, SGST);
        Evaluate(CGSTValue, CGST);
        Evaluate(IGSTValue, IGST);
        Evaluate(KFCValue, KFC);
        Evaluate(FromDate, DateFrom, 9);
        Evaluate(ToDate, DateTo, 9);

        CreateConfigID(TaxTypeCode);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'GST Group Code'), "Column Type"::"Tax Attributes", GSTGroupCode, 0D, 0D, 0);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'HSN/SAC'), "Column Type"::"Tax Attributes", HSNSAC, 0D, 0D, 0);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'From State'), "Column Type"::Value, FromState, 0D, 0D, 0);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'Location State Code'), "Column Type"::Value, LocationStateCode, 0D, 0D, 0);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'Date'), "Column Type"::"Range From and Range To", DateFrom, FromDate, ToDate, 0);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'SGST'), "Column Type"::Component, SGST, 0D, 0D, SGSTValue);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'CGST'), "Column Type"::Component, CGST, 0D, 0D, CGSTValue);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'IGST'), "Column Type"::Component, IGST, 0D, 0D, IGSTValue);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'KFloodCess'), "Column Type"::Component, KFC, 0D, 0D, KFCValue);
        if POSOutOfIndia = 'false' then
            POSOutOfIndia := 'No'
        else
            POSOutOfIndia := 'Yes';

        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'POS Out Of India'), "Column Type"::"Tax Attributes", POSOutOfIndia, 0D, 0D, 0);
        if POSasVendorState = 'false' then
            POSasVendorState := 'No'
        else
            POSasVendorState := 'Yes';
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'POS as Vendor State'), "Column Type"::"Tax Attributes", POSasVendorState, 0D, 0D, 0);
        UpdateTaxRateId(TaxTypeCode, TaxRate.ID);
    end;

    local procedure UpdateRateIDOnRateValue(ConfigId: Guid; KeyValue: Text[2000])
    var
        TaxRateValue: Record "Tax Rate Value";
    begin
        //This will be used to find exact line of Tax Rate on calculation.
        TaxRateValue.SetRange("Config ID", ConfigId);
        if not TaxRateValue.IsEmpty() then
            TaxRateValue.ModifyAll("Tax Rate ID", KeyValue);
    end;

    local procedure UpdateTaxRateId(TaxType: Code[20]; ConfigId: Guid)
    var
        TaxSetupMatrixMgmt: Codeunit "Tax Setup Matrix Mgmt.";
    begin
        TaxRate.Get(TaxType, ConfigId);
        TaxRate."Tax Setup ID" := TaxSetupMatrixMgmt.GenerateTaxSetupID(ConfigId, TaxType);
        TaxRate."Tax Rate ID" := TaxSetupMatrixMgmt.GenerateTaxRateID(ConfigId, TaxType);
        TaxRate.Modify();
        UpdateRateIDOnRateValue(ConfigId, TaxRate."Tax Rate ID");
    end;

    local procedure EnableTaxType(TaxTypeCode: Code[10]; Enable: Boolean)
    var
        TaxType: Record "Tax Type";
    begin
        if TaxType.Get(TaxTypeCode) then begin
            TaxType.Enabled := Enable;
            TaxType.Modify();
        end;
    end;
}