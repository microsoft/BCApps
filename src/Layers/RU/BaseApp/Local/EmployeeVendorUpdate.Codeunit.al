#pragma warning disable AA0247
codeunit 12415 "EmployeeVendor-Update"
{

    trigger OnRun()
    begin
    end;

    var
        Vend: Record Vendor;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 No %2 already exists.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure OnInsert(var Employee: Record Employee)
    begin
        if Vend.Get(Employee."No.") then
            Error(Text001, Format(Vend."Vendor Type"), Employee."No.");

        Vend.Init();
        Vend."No." := Employee."No.";
        Vend."Vendor Type" := Vend."Vendor Type"::"Resp. Employee";
        EmployeeToVendor(Employee, Vend);
        Vend.Insert();
    end;

    [Scope('OnPrem')]
    procedure OnModify(var Employee: Record Employee)
    begin
        Vend.SetRange("Employee No.", Employee."No.");
        if Vend.FindSet() then
            repeat
                Vend.TestField("Vendor Type", Vend."Vendor Type"::"Resp. Employee");
                EmployeeToVendor(Employee, Vend);
                Vend.Modify(true);
            until Vend.Next() = 0;
    end;

    local procedure EmployeeToVendor(var Employee: Record Employee; var Vendor: Record Vendor)
    var
        PurchaseSetup: Record "Purchases & Payables Setup";
    begin
        Vendor.Validate(Name, Employee."Short Name");
        Vendor."Country/Region Code" := Employee."Country/Region Code";
        Vendor.Address := Employee.Address;
        Vendor."Address 2" := Employee."Address 2";
        Vendor.City := Employee.City;
        Vendor."Phone No." := Employee."Phone No.";
        Vendor."Fax No." := Employee."Fax No.";
        Vendor."Post Code" := Employee."Post Code";
        Vendor."E-Mail" := Employee."E-Mail";
        Vendor."Employee No." := Employee."No.";
        PurchaseSetup.Get();
        Vendor."Gen. Bus. Posting Group" := PurchaseSetup."Adv. Stmt. Gen.Bus. Posting Gr";
        Vendor."VAT Bus. Posting Group" := PurchaseSetup."Adv. Stmt. VAT Bus. Posting Gr";
        Vendor."Vendor Posting Group" := PurchaseSetup."Adv. Stmt. Vendor Posting Gr.";
    end;

    [Scope('OnPrem')]
    procedure OnRename(OldEmployeeNo: Code[20]; NewEmployeeNo: Code[20])
    begin
        if Vend.Get(OldEmployeeNo) then begin
            Vend.TestField("Vendor Type", Vend."Vendor Type"::"Resp. Employee");
            Vend.Rename(NewEmployeeNo);
        end;
    end;
}

