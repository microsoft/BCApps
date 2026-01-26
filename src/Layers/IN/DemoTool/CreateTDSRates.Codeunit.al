codeunit 101119 "Create TDS Rates"
{

    trigger OnRun()
    var
        TaxTypeCode: Code[20];
    begin
        DemoDataSetup.Get();
        TaxTypeCode := 'TDS';
        InsertData(TaxTypeCode, 'S', 'IND', '2010-01-01', '', '', '', '', '0.75', '20', '0', '0', '0', '0', '30000', '0');
        InsertData(TaxTypeCode, 'S', 'HUF', '2010-01-01', '', '', '', '', '0.75', '20', '0', '0', '0', '0', '30000', '0');
        InsertData(TaxTypeCode, 'S', 'COM', '2010-01-01', '', '', '', '', '1.5', '20', '0', '0', '0', '0', '30000', '0');
        InsertData(TaxTypeCode, '194J-PF', 'IND', '2010-01-01', '', '', '', '', '7.5', '20', '0', '0', '0', '0', '30000', '0');
        InsertData(TaxTypeCode, '194J-PF', 'COM', '2010-01-01', '', '', '', '', '7.5', '20', '0', '0', '0', '0', '30000', '0');
        InsertData(TaxTypeCode, '194I-LB', 'IND', '2010-01-01', '', '', '', '', '7.6', '20', '0', '0', '0', '0', '240000', '0');
        InsertData(TaxTypeCode, '194I-LB', 'COM', '2010-01-01', '', '', '', '', '7.6', '20', '0', '0', '0', '0', '240000', '0');
        InsertData(TaxTypeCode, '195', 'NRI', '2010-01-01', '', '16', 'A', 'US', '10.4', '20', '0', '0', '0', '0', '0', '0');

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
    end;

    local procedure CreateConfigID(TaxType: Code[20])
    begin
        TaxRate.Init();
        TaxRate."Tax Type" := TaxType;
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
        SectionCode: Text;
        AssesseeCode: Text;
        EffectiveDate: Text;
        ConcessionalCode: Text;
        NatureofRemittance: Text;
        ActApplicable: Text;
        CountryCode: Text;
        TDS: Text;
        NonPANTDS: Text;
        Surcharge: Text;
        eCESS: Text;
        SHECess: Text;
        SurchargeThresholdAmount: Text;
        TDSThresholdAmount: Text;
        PerContractValue: Text)
    var
        TDSValue: Decimal;
        NonPANTDSValue: Decimal;
        SurchargeValue: Decimal;
        eCESSValue: Decimal;
        SHECessValue: Decimal;
        SurchargeThresholdAmountValue: Decimal;
        TDSThresholdAmountValue: Decimal;
        PerContractValueValue: Decimal;
    begin

        Evaluate(TDSValue, TDS);
        Evaluate(NonPANTDSValue, NonPANTDS);
        Evaluate(SurchargeValue, Surcharge);
        Evaluate(eCESSValue, eCESS);
        Evaluate(SHECessValue, SHECess);
        Evaluate(SurchargeThresholdAmountValue, SurchargeThresholdAmount);
        Evaluate(TDSThresholdAmountValue, TDSThresholdAmount);
        Evaluate(PerContractValueValue, PerContractValue);

        CreateConfigID(TaxTypeCode);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'Section Code'), "Column Type"::"Tax Attributes", SectionCode, 0D, 0);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'Assessee Code'), "Column Type"::"Tax Attributes", AssesseeCode, 0D, 0);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'Effective Date'), "Column Type"::"Range From", EffectiveDate, DMY2Date(1, 1, 2010), 0);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'Concessional Code'), "Column Type"::"Tax Attributes", ConcessionalCode, 0D, 0);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'Nature of Remittance'), "Column Type"::"Tax Attributes", NatureofRemittance, 0D, 0);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'Act Applicable'), "Column Type"::"Tax Attributes", ActApplicable, 0D, 0);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'Country Code'), "Column Type"::"Tax Attributes", CountryCode, 0D, 0);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'TDS'), "Column Type"::Component, TDS, 0D, TDSValue);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'Non PAN TDS'), "Column Type"::Component, NonPANTDS, 0D, NonPANTDSValue);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'Surcharge'), "Column Type"::Component, Surcharge, 0D, SurchargeValue);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'eCESS'), "Column Type"::Component, eCESS, 0D, eCESSValue);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'SHE Cess'), "Column Type"::Component, SHECess, 0D, SHECessValue);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'Surcharge Threshold Amount'), "Column Type"::"Output Information", SurchargeThresholdAmount, 0D, SurchargeThresholdAmountValue);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'TDS Threshold Amount'), "Column Type"::"Output Information", TDSThresholdAmount, 0D, TDSThresholdAmountValue);
        InsertData(TaxTypeCode, TaxRate.ID, GetTaxColumnID(TaxTypeCode, 'Per Contract Value'), "Column Type"::"Output Information", PerContractValue, 0D, PerContractValueValue);

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