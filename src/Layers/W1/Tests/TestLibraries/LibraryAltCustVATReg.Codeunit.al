codeunit 131600 "Library - Alt. Cust. VAT Reg."
{
    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";

    procedure CreateAlternativeCustVATReg(var AltCustVATReg: Record "Alt. Cust. VAT Reg."; CustNo: Code[20]);
    var
        CountryCode: Code[10];
        GenBusPostingGroup, VATBusPostingGroup : Code[20];
    begin
        CountryCode := LibraryERM.CreateCountryRegion();
        CreateVATGroups(GenBusPostingGroup, VATBusPostingGroup);
        CreateAlternativeCustVATReg(
            AltCustVATReg, CustNo, CountryCode, LibraryERM.GenerateVATRegistrationNo(CountryCode),
            GenBusPostingGroup, VATBusPostingGroup);
    end;

    procedure CreateAlternativeCustVATReg(var AltCustVATReg: Record "Alt. Cust. VAT Reg."; CustNo: Code[20]; CountryCode: Code[10]);
    var
        GenBusPostingGroup, VATBusPostingGroup : Code[20];
    begin
        CreateVATGroups(GenBusPostingGroup, VATBusPostingGroup);
        CreateAlternativeCustVATReg(
            AltCustVATReg, CustNo, CountryCode, LibraryERM.GenerateVATRegistrationNo(CountryCode),
            GenBusPostingGroup, VATBusPostingGroup);
    end;

    procedure CreateAlternativeCustVATReg(var AltCustVATReg: Record "Alt. Cust. VAT Reg."; CustNo: Code[20]; VATRegistrationNo: Text[20]; GenBusPostingGroup: Code[20]; VATBusPostingGroup: Code[20]);
    begin
        CreateAlternativeCustVATReg(AltCustVATReg, CustNo, LibraryERM.CreateCountryRegion(), VATRegistrationNo, GenBusPostingGroup, VATBusPostingGroup);
    end;

    procedure CreateAlternativeCustVATReg(var AltCustVATReg: Record "Alt. Cust. VAT Reg."; CustNo: Code[20]; CountryCode: Code[10]; VATRegistrationNo: Text[20]; GenBusPostingGroup: Code[20]; VATBusPostingGroup: Code[20]);
    begin
        AltCustVATReg.Validate("Customer No.", CustNo);
        AltCustVATReg.Validate("VAT Country/Region Code", CountryCode);
        AltCustVATReg.Validate("VAT Registration No.", VATRegistrationNo);
        AltCustVATReg.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        AltCustVATReg.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        AltCustVATReg.Insert(true);
    end;

    local procedure CreateVATGroups(var GenBusPostingGroup: Code[20]; var VATBusPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateGeneralPostingSetupInvt(GeneralPostingSetup);
        GeneralPostingSetup.Validate("Sales Credit Memo Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Modify(true);
        LibraryERM.CreateVATPostingSetupWithAccounts(
            VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(10));
        GenBusPostingGroup := GeneralPostingSetup."Gen. Bus. Posting Group";
        VATBusPostingGroup := VATPostingSetup."VAT Bus. Posting Group";
    end;

    procedure UpdateConfirmAltCustVATReg(ConfirmAltCustVATReg: Boolean)
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.SetRange("Notification Id", GetConfirmChangesNotificationId());
        MyNotifications.DeleteAll(true);
        MyNotifications.InsertDefault(GetConfirmChangesNotificationId(), '', '', ConfirmAltCustVATReg);
    end;

    procedure VerifySalesDocAltVATReg(SalesHeader: Record "Sales Header"; DiffVATRegData: Boolean)
    begin
        VerifySalesDocAltVATReg(SalesHeader, DiffVATRegData, DiffVATRegData, DiffVATRegData);
    end;

    procedure VerifySalesDocAltVATReg(SalesHeader: Record "Sales Header"; DiffVATRegNo: Boolean; DiffGenBusPostingGroup: Boolean; DiffVATBusPostingGroup: Boolean)
    begin
        SalesHeader.TestField("Alt. VAT Registration No.", DiffVATRegNo);
        SalesHeader.TestField("Alt. Gen. Bus Posting Group", DiffGenBusPostingGroup);
        SalesHeader.TestField("Alt. VAT Bus Posting Group", DiffVATBusPostingGroup);
    end;

    local procedure GetConfirmChangesNotificationId(): Guid
    begin
        exit('5a911b76-547b-49f4-ba6f-ffc64d75077d');
    end;

}