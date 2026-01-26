codeunit 120541 "Create TCS Rates"
{
    trigger OnRun()
    var
        TaxTypeCode: Code[20];
    begin
        DemoDataSetup.Get();
        TaxTypeCode := 'TCS';
        InsertData(TaxTypeCode, 'A', 'COM', '', '2010-01-01', '1', '0', '5', '0', '0', '0', '0', '0', 'No');
        InsertData(TaxTypeCode, 'A', 'IND', '', '2010-01-01', '1', '0', '5', '0', '0', '0', '0', '0', 'No');
        InsertData(TaxTypeCode, 'A', 'NRI', '', '2010-01-01', '1', '10', '5', '4', '0', '5000000', '0', '0', 'No');
        InsertData(TaxTypeCode, '1H', 'COM', '', '2020-10-01', '0.075', '0', '1', '0', '0', '5000000', '0', '0', 'Yes');

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
        TCSNOC: Text;
        AssesseCode: Text;
        ConcessionalCode: Text;
        EffectiveDate: Text;
        TCS: Text;
        Surcharge: Text;
        NonPANTCS: Text;
        eCess: Text;
        SHECess: Text;
        TCSThresholdAmount: Text;
        SurchargeThresholdAmount: Text;
        ContractAmount: Text;
        CalcOverThreshold: Text)
    var
        TCSValue: Decimal;
        SurchargeValue: Decimal;
        NonPANTCSValue: Decimal;
        eCessValue: Decimal;
        SHECessValue: Decimal;
        TCSThresholdAmountValue: Decimal;
        SurchargeThresholdAmountValue: Decimal;
        ContractAmountValue: Decimal;
        CalcOverThresholdValue: Boolean;
    begin
        Evaluate(TCSValue, TCS);
        Evaluate(SurchargeValue, Surcharge);
        Evaluate(NonPANTCSValue, NonPANTCS);
        Evaluate(eCessValue, eCess);
        Evaluate(SHECessValue, SHECess);
        Evaluate(TCSThresholdAmountValue, TCSThresholdAmount);
        Evaluate(SurchargeThresholdAmountValue, SurchargeThresholdAmount);
        Evaluate(ContractAmountValue, ContractAmount);
        Evaluate(CalcOverThresholdValue, CalcOverThreshold);

        CreateConfigID(TaxTypeCode);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'TCS Nature of Collection'), "Column Type"::"Tax Attributes", TCSNOC, 0D, 0);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'Assessee Code'), "Column Type"::"Tax Attributes", AssesseCode, 0D, 0);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'Concessional Code'), "Column Type"::"Range From", ConcessionalCode, 0D, 0);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'Effective Date'), "Column Type"::"Range From", EffectiveDate, DMY2Date(1, 1, 2010), 0);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'TCS'), "Column Type"::Component, TCS, 0D, TCSValue);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'Surcharge'), "Column Type"::Component, Surcharge, 0D, SurchargeValue);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'Non PAN TCS'), "Column Type"::Component, NonPANTCS, 0D, NonPANTCSValue);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'e Cess'), "Column Type"::Component, eCess, 0D, eCessValue);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'SHE Cess'), "Column Type"::Component, SHECess, 0D, SHECessValue);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'TCS Threshold Amount'), "Column Type"::"Output Information", TCSThresholdAmount, 0D, TCSThresholdAmountValue);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'Surcharge Threshold Amount'), "Column Type"::"Output Information", SurchargeThresholdAmount, 0D, SurchargeThresholdAmountValue);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'Contract Amount'), "Column Type"::"Output Information", ContractAmount, 0D, ContractAmountValue);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'Calc. Over & Above Threshold'), "Column Type"::"Output Information", CalcOverThreshold, 0D, 0);

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
