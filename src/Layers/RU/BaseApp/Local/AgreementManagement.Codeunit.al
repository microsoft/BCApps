#pragma warning disable AA0247
codeunit 12421 "Agreement Management"
{

    trigger OnRun()
    begin
    end;

    var
        CustAgrmt: Record "Customer Agreement";
        VendAgrmt: Record "Vendor Agreement";

    [Scope('OnPrem')]
    procedure CreateAgrmtFromCust(Cust: Record Customer; AgrmtNo: Code[20])
    begin
        if not CustAgrmt.Get(Cust."No.", AgrmtNo) then begin
            CustAgrmt.Init();
            CustAgrmt."Customer No." := Cust."No.";
            CustAgrmt."No." := AgrmtNo;
            CustAgrmt."Global Dimension 1 Code" := Cust."Global Dimension 1 Code";
            CustAgrmt."Global Dimension 2 Code" := Cust."Global Dimension 2 Code";
            CustAgrmt."Credit Limit (LCY)" := Cust."Credit Limit (LCY)";
            CustAgrmt."Customer Posting Group" := Cust."Customer Posting Group";
            CustAgrmt."Currency Code" := Cust."Currency Code";
            CustAgrmt."Customer Price Group" := Cust."Customer Price Group";
            CustAgrmt."Language Code" := Cust."Language Code";
            CustAgrmt."Payment Terms Code" := Cust."Payment Terms Code";
            CustAgrmt."Fin. Charge Terms Code" := Cust."Fin. Charge Terms Code";
            CustAgrmt."Salesperson Code" := Cust."Salesperson Code";
            CustAgrmt."Shipment Method Code" := Cust."Shipment Method Code";
            CustAgrmt."Shipping Agent Code" := Cust."Shipping Agent Code";
            CustAgrmt."Customer Disc. Group" := Cust."Customer Disc. Group";
            CustAgrmt.Blocked := Cust.Blocked;
            CustAgrmt."Payment Method Code" := Cust."Payment Method Code";
            CustAgrmt."Location Code" := Cust."Location Code";
            CustAgrmt."Gen. Bus. Posting Group" := Cust."Gen. Bus. Posting Group";
            CustAgrmt."VAT Bus. Posting Group" := Cust."VAT Bus. Posting Group";
            CustAgrmt."Responsibility Center" := Cust."Responsibility Center";
            CustAgrmt."Default Bank Code" := Cust."Default Bank Code";
            CustAgrmt.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateAgrmtFromVend(Vend: Record Vendor; AgrmtNo: Code[20])
    begin
        if not VendAgrmt.Get(Vend."No.", AgrmtNo) then begin
            VendAgrmt.Init();
            VendAgrmt."Vendor No." := Vend."No.";
            VendAgrmt."No." := AgrmtNo;
            VendAgrmt."Global Dimension 1 Code" := Vend."Global Dimension 1 Code";
            VendAgrmt."Global Dimension 2 Code" := Vend."Global Dimension 2 Code";
            VendAgrmt."Vendor Posting Group" := Vend."Vendor Posting Group";
            VendAgrmt."Currency Code" := Vend."Currency Code";
            VendAgrmt."Language Code" := Vend."Language Code";
            VendAgrmt."Payment Terms Code" := Vend."Payment Terms Code";
            VendAgrmt."Purchaser Code" := Vend."Purchaser Code";
            VendAgrmt.Blocked := Vend.Blocked;
            VendAgrmt."Payment Method Code" := Vend."Payment Method Code";
            VendAgrmt."Location Code" := Vend."Location Code";
            VendAgrmt."Gen. Bus. Posting Group" := Vend."Gen. Bus. Posting Group";
            VendAgrmt."VAT Bus. Posting Group" := Vend."VAT Bus. Posting Group";
            VendAgrmt."Responsibility Center" := Vend."Responsibility Center";
            VendAgrmt."Default Bank Code" := Vend."Default Bank Code";
            VendAgrmt.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure GetAgrmtDefaultDimSetID(TableID: Integer; No: Code[20]): Integer
    var
        DimValue: Record "Dimension Value";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DefaultDimension: Record "Default Dimension";
        DimMgt: Codeunit DimensionManagement;
    begin
        DefaultDimension.SetRange("Table ID", TableID);
        DefaultDimension.SetRange("No.", No);
        if DefaultDimension.FindSet() then
            repeat
                DimValue.Get(DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
                TempDimSetEntry."Dimension Code" := DefaultDimension."Dimension Code";
                TempDimSetEntry."Dimension Value Code" := DefaultDimension."Dimension Value Code";
                TempDimSetEntry."Dimension Value ID" := DimValue."Dimension Value ID";
                TempDimSetEntry.Insert();
            until DefaultDimension.Next() = 0;
        exit(DimMgt.GetDimensionSetID(TempDimSetEntry));
    end;
    
    [EventSubscriber(ObjectType::Codeunit, Codeunit::DimensionManagement, 'OnAfterIsDefaultDimTable', '', false, false)]
    local procedure OnAfterIsDefaultDimTable(TableID: Integer; var Result: Boolean)
    begin
        Result := TableID in
            [DATABASE::"Vendor Agreement",
            DATABASE::"Customer Agreement"];
    end;
}

