codeunit 161388 "Create EN Dimensions Transl."
{

    trigger OnRun()
    begin
        InsertData(XxPURCHASER, XxENU, XPurchaser);
        InsertData(XxSALESPERSON, XxENU, XSalesperson);
        InsertData(XxAREA, XxENU, XArea);
        InsertData(XxSALESCAMPAIGN, XxENU, XSalesCampaign);
        InsertData(XxBUSINESSGROUP, XxENU, XBusinessGroup);
        InsertData(XxCUSTOMERGROUP, XxENU, XCustomerGroup);
        InsertData(XxPROJECT, XxENU, XProject);
        InsertData(XxDEPARTMENT, XxENU, XDepartment);
    end;

    var
        XxPURCHASER: Label 'PURCHASER';
        XxENU: Label 'ENU';
        XPurchaser: Label 'Purchaser';
        XxSALESPERSON: Label 'SALESPERSON';
        XSalesperson: Label 'Salesperson';
        XxAREA: Label 'AREA';
        XArea: Label 'Area';
        XxSALESCAMPAIGN: Label 'SALESCAMPAIGN';
        XSalesCampaign: Label 'Sales Campaign';
        XxBUSINESSGROUP: Label 'BUSINESSGROUP';
        XBusinessGroup: Label 'Business Group';
        XxCUSTOMERGROUP: Label 'CUSTOMERGROUP';
        XCustomerGroup: Label 'Customer Group';
        XxPROJECT: Label 'PROJECT';
        XProject: Label 'Project';
        XxDEPARTMENT: Label 'DEPARTMENT';
        XDepartment: Label 'Department';
        XxITA: Label 'ITA';
        DimensionTranslation: Record "Dimension Translation";

    procedure InsertData("Code": Code[20]; LanguageID: Text[4]; Name: Text[30])
    begin
        DimensionTranslation.Init();
        DimensionTranslation.Code := Code;
        if LanguageID = XxENU then
            DimensionTranslation.Validate("Language ID", 1033);
        if LanguageID = XxITA then
            DimensionTranslation.Validate("Language ID", 1040);
        DimensionTranslation.Validate(Name, Name);
        DimensionTranslation.Insert();
    end;
}

