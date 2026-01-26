codeunit 101017 "Create TDS Section"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(X194C, X194CContractor, '94C', '');
        InsertData(XS, XSContractorSingletransaction, '94C', '194C');
        InsertData(XC, XCContractorConsolidatedPaymentDuringtheFY, '94C', '194C');
        InsertData(X194J, X194JProfessionalFees, '94J', '');
        InsertData(X194JPF, X194JPFProfessionalFees, '94J', '194J');
        InsertData(X194JTF, X194JTFTechnicalFeeswef01042020, '94J', '194J');
        InsertData(X194JCC, X194JCCPaymenttocallcentreoperatorwef01062017, '94J', '194J');
        InsertData(X194JDF, X194JDFDirectorsfees, '94J', '194J');
        InsertData(X194I, X194IRent, '94I', '');
        InsertData(X194IPM, X194IPMRentPlantMachinery, '94I', '194I');
        InsertData(X194ILB, X194ILBRentLandorbuildingorfurnitureorfitting, '94I', '194I');
        InsertData(X195, X195PayabletoNonResidents, '195', '');
        InsertData(X194A, X194AInterest, '94A', '');
        InsertData(X194ABP, X194ABPInterestonBankandPostOfficedeposits, '94A', '194A');
        InsertData(X194AOT, X194AOTInterestanyother, '94A', '194A');

        CreateTDSPostingSetup(XS, DMY2Date(1, 1, 2010), '5931', '2451');
        CreateTDSPostingSetup(XC, DMY2Date(1, 1, 2010), '5931', '2451');
        CreateTDSPostingSetup(X194JPF, DMY2Date(1, 1, 2010), '5932', '2452');
        CreateTDSPostingSetup(X194JTF, DMY2Date(1, 1, 2010), '5932', '2452');
        CreateTDSPostingSetup(X194JCC, DMY2Date(1, 1, 2010), '5932', '2452');
        CreateTDSPostingSetup(X194JDF, DMY2Date(1, 1, 2010), '5932', '2452');
        CreateTDSPostingSetup(X194IPM, DMY2Date(1, 1, 2010), '5933', '2453');
        CreateTDSPostingSetup(X194ILB, DMY2Date(1, 1, 2010), '5933', '2453');
        CreateTDSPostingSetup(X195, DMY2Date(1, 1, 2010), '5934', '');
        CreateTDSPostingSetup(X194ABP, DMY2Date(1, 1, 2010), '5935', '2454');
        CreateTDSPostingSetup(X194AOT, DMY2Date(1, 1, 2010), '5935', '2454');
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        X194CContractor: Label 'Contractor';
        XSContractorSingletransaction: Label 'Contractor-Single transaction';
        XCContractorConsolidatedPaymentDuringtheFY: Label 'Contractor – Consolidated Payment During the F.Y.';
        X194JProfessionalFees: Label 'Professional Fees';
        X194JPFProfessionalFees: Label 'Professional Fees';
        X194JTFTechnicalFeeswef01042020: Label 'Technical Fees (w.e.f. 01.04.2020)';
        X194JCCPaymenttocallcentreoperatorwef01062017: Label 'Payment to call centre operator (w.e.f. 01.06.2017)';
        X194JDFDirectorsfees: Label 'Director’s fees';
        X194IRent: Label 'Rent';
        X194IPMRentPlantMachinery: Label 'Rent  Plant & Machinery';
        X194ILBRentLandorbuildingorfurnitureorfitting: Label 'Rent  Land or building or furniture or fitting';
        X195PayabletoNonResidents: Label 'Payable to Non Residents';
        X194AInterest: Label 'Interest';
        X194ABPInterestonBankandPostOfficedeposits: Label 'Interest on Bank and Post Office deposits';
        X194AOTInterestanyother: Label 'Interest any other';
        X194C: Label '194C';
        XS: Label 'S';
        XC: Label 'C';
        X194J: Label '194J';
        X194JPF: Label '194J-PF';
        X194JTF: Label '194J-TF';
        X194JCC: Label '194J-CC';
        X194JDF: Label '194J-DF';
        X194I: Label '194I';
        X194IPM: Label '194I-PM';
        X194ILB: Label '194I-LB';
        X195: Label '195';
        X194A: Label '194A';
        X194ABP: Label '194A-BP';
        X194AOT: Label '194A-OT';


    procedure InsertMiniAppData()
    begin
        AddTDSSectionForMini();
    end;

    local procedure AddTDSSectionForMini()
    begin
        DemoDataSetup.Get();
        InsertData(X194C, X194CContractor, '94C', '');
        InsertData(XS, XSContractorSingletransaction, '94C', '194C');
        InsertData(XC, XCContractorConsolidatedPaymentDuringtheFY, '94C', '194C');
        InsertData(X194J, X194JProfessionalFees, '94J', '');
        InsertData(X194JPF, X194JPFProfessionalFees, '94J', '194J');
        InsertData(X194JTF, X194JTFTechnicalFeeswef01042020, '94J', '194J');
        InsertData(X194JCC, X194JCCPaymenttocallcentreoperatorwef01062017, '94J', '194J');
        InsertData(X194JDF, X194JDFDirectorsfees, '94J', '194J');
        InsertData(X194I, X194IRent, '94I', '');
        InsertData(X194IPM, X194IPMRentPlantMachinery, '94I', '194I');
        InsertData(X194ILB, X194ILBRentLandorbuildingorfurnitureorfitting, '94I', '194I');
        InsertData(X195, X195PayabletoNonResidents, '195', '195');
        InsertData(X194A, X194AInterest, '94A', '');
        InsertData(X194ABP, X194ABPInterestonBankandPostOfficedeposits, '94A', '194A');
        InsertData(X194AOT, X194AOTInterestanyother, '94A', '194A');
    end;

    procedure InsertData(Code: Code[20]; Description: Text[100]; eCode: Code[10]; ParentSection: Code[20])
    var
        TDSSection: Record "TDS Section";
    begin
        TDSSection.Init();
        TDSSection.Validate("Code", Code);
        TDSSection.Validate(Description, Description);
        TDSSection.Validate(ecode, eCode);
        TDSSection.Validate("Parent Code", ParentSection);
        TDSSection.Validate("Indentation Level", GetIndentationLevel(ParentSection));
        TDSSection.Insert(true);
    end;

    local procedure GetIndentationLevel(ParentCode: Code[20]): Integer
    var
        TDSSection: Record "TDS Section";
    begin
        if ParentCode = '' then
            exit(0);

        TDSSection.Get(ParentCode);
        exit(TDSSection."Indentation Level" + 1);
    end;

    local procedure CreateTDSPostingSetup(SectionCode: Code[20]; EffectiveDate: Date; TDSAccount: Code[20]; TDSReceivableAcc: Code[20])
    var
        TDSPostingSetup: Record "TDS Posting Setup";
    begin
        TDSPostingSetup.Init();
        TDSPostingSetup.Validate("TDS Section", SectionCode);
        TDSPostingSetup.Validate("Effective Date", EffectiveDate);
        TDSPostingSetup."TDS Account" := TDSAccount;
        TDSPostingSetup."TDS Receivable Account" := TDSReceivableAcc;
        TDSPostingSetup.Insert();
    end;

    procedure CreateAllowedTDSSection(
      CustomerCode: Code[20];
      SectionCode: Code[20];
      ThresholdOverlook: Boolean;
      SurchargeOverlook: Boolean)
    var
        CustomerAllowedSection: Record "Customer Allowed Sections";
    begin
        CustomerAllowedSection.Init();
        CustomerAllowedSection."Customer No" := CustomerCode;
        CustomerAllowedSection."TDS Section" := SectionCode;
        CustomerAllowedSection."Threshold Overlook" := ThresholdOverlook;
        CustomerAllowedSection."Surcharge Overlook" := SurchargeOverlook;
        CustomerAllowedSection.Insert();
    end;

    procedure CreateAllowedVendorTDSSection(
          VendorCode: Code[20];
          SectionCode: Code[20];
          ThresholdOverlook: Boolean;
          SurchargeOverlook: Boolean;
          NRI: Boolean;
          Act: Code[20];
          NOR: Code[10])
    var
        VendorAllowedSection: Record "Allowed Sections";
    begin
        VendorAllowedSection.Init();
        VendorAllowedSection."Vendor No" := VendorCode;
        VendorAllowedSection."TDS Section" := SectionCode;
        VendorAllowedSection."Threshold Overlook" := ThresholdOverlook;
        VendorAllowedSection."Surcharge Overlook" := SurchargeOverlook;
        VendorAllowedSection."Non Resident Payments" := NRI;
        VendorAllowedSection."Nature of Remittance" := NOR;
        VendorAllowedSection."Act Applicable" := Act;
        VendorAllowedSection.Insert();
    end;

    procedure CreateTDSCustomerConcessionalCode(
      CustomerCode: Code[20];
      SectionCode: Code[20];
      ConcessionalCode: Code[20];
      CertificateNo: Code[20])
    var
        TDSCustomerConcenssionalCode: Record "TDS Customer Concessional Code";
    begin
        TDSCustomerConcenssionalCode.Init();
        TDSCustomerConcenssionalCode."Customer No." := CustomerCode;
        TDSCustomerConcenssionalCode."TDS Section Code" := SectionCode;
        TDSCustomerConcenssionalCode."Concessional Code" := ConcessionalCode;
        TDSCustomerConcenssionalCode."Certificate No." := CertificateNo;
        TDSCustomerConcenssionalCode.Insert();
    end;

    procedure CreateTDSVendorConcessionalCode(
      VendorCode: Code[20];
      SectionCode: Code[20];
      ConcessionalCode: Code[20];
      CertificateNo: Code[20])
    var
        TDSVendorConcenssionalCode: Record "TDS Concessional Code";
    begin
        TDSVendorConcenssionalCode.Init();
        TDSVendorConcenssionalCode."Vendor No." := VendorCode;
        TDSVendorConcenssionalCode.Section := SectionCode;
        TDSVendorConcenssionalCode."Concessional Code" := ConcessionalCode;
        TDSVendorConcenssionalCode."Certificate No." := CertificateNo;
        TDSVendorConcenssionalCode.Insert();
    end;
}
