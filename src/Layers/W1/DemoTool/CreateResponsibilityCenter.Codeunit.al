codeunit 118020 "Create Responsibility Center"
{

    trigger OnRun()
    begin
        Resp.DeleteAll();
        InsertData(XBIRMINGHAM, XCRONUSBirminghamRC, XMainStreet14, CreatePostCode.Convert('GB-B27 4KT'), '+44-161 818192', '+44-161 818100', XAaronNicholls, XBLUE);
        InsertData(XLONDON, XCRONUSLondonRC, XKensingtonStreet22, CreatePostCode.Convert('GB-N12 5XY'), '+44-999 154642', '+44-999 154625', XJackSRichins, '');
        ModifyCust('10000', XBIRMINGHAM);
        ModifyCust('50000', XLONDON);
        ModifyVendor('10000', XLONDON);
        ModifyVendor('20000', XLONDON);
        ModifyVendor('44756404', XBIRMINGHAM);
    end;

    var
        Resp: Record "Responsibility Center";
        CreatePostCode: Codeunit "Create Post Code";
        XBIRMINGHAM: Label 'BIRMINGHAM';
        XCRONUSBirminghamRC: Label 'CRONUS, Birmingham RC.';
        XMainStreet14: Label 'Main Street, 14';
        XAaronNicholls: Label 'Aaron Nicholls';
        XBLUE: Label 'BLUE';
        XLONDON: Label 'LONDON';
        XCRONUSLondonRC: Label 'CRONUS, London RC.';
        XKensingtonStreet22: Label 'Kensington Street, 22';
        XJackSRichins: Label 'Jack S. Richins';

    local procedure InsertData("Code": Code[10]; Name: Text[50]; Address: Text[30]; "Post Code": Code[20]; "Phone No.": Text[30]; "Fax No.": Text[30]; Contact: Text[50]; "Location Code": Code[10])
    var
        CompanyInformation: Record "Company Information";
    begin
        Resp.Init();
        Resp.Validate(Code, Code);
        Resp.Validate(Name, Name);
        Resp.Validate(Address, Address);
        Resp."Post Code" := CreatePostCode.FindPostCode("Post Code");
        Resp.City := CreatePostCode.FindCity("Post Code");
        Resp.Validate("Phone No.", "Phone No.");
        CompanyInformation.Get();
        Resp."Country/Region Code" := CompanyInformation."Country/Region Code";
        Resp.Validate("Fax No.", "Fax No.");
        Resp.Validate(Contact, Contact);
        Resp.Validate("Location Code", "Location Code");
        Resp.Validate(County, CreatePostCode.GetCounty(Resp."Post Code", Resp.City));
        Resp.Insert();
    end;

    local procedure ModifyCust(CustCode: Code[20]; RespCenterCode: Code[10])
    var
        Cust: Record Customer;
    begin
        if Cust.Get(CustCode) then begin
            Cust."Responsibility Center" := RespCenterCode;
            Cust.Modify();
        end;
    end;

    local procedure ModifyVendor(VendorCode: Code[20]; RespCenterCode: Code[10])
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(VendorCode) then begin
            Vendor."Responsibility Center" := RespCenterCode;
            Vendor.Modify();
        end;
    end;
}

