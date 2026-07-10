codeunit 163421 "Create FA Documents"
{

    trigger OnRun()
    begin
        InsertHeader(0, XWOFF + '-001', XCompDisposal, 19021225D, '', '2200100');
        InsertLine(10000, XFA + '017');
        InsertLine(20000, XFA + '018');
        InsertLine(30000, XFA + '019');
        InsertLine(40000, XFA + '020');
        InsertHeader(0, XWOFF + '-002', XFADisposalInclInCC, 19021231D, '', '6101030');
        InsertLine(10000, XFA + '003');
        InsertLine(20000, XFA + '004');
        InsertLine(30000, XFA + '005');
        InsertLine(40000, XFA + '006');
        InsertLine(50000, XFA + '007');
        InsertHeader(0, XWOFF + '-003', XGratCompDisposal, 19021231D, '', '2200100');
        InsertLine(10000, XFA + '008');
        InsertHeader(0, XWOFF + '-004', XFADisposalTelecom, 19030111D, '', '2200100');
        InsertLine(10000, XFA + '012');

        InsertHeader(1, XACTIA + '-001', XCommissioningOfSWBiling, 19021005D, '', '');
        InsertLine(10000, XIA + '001');
        InsertHeader(1, XACTIA + '-002', XCommissioningOfCopyright, 19021130D, '', '');
        InsertLine(10000, XIA + '002');
        InsertHeader(1, XACTIA + '-003', XCommissioningOfIAASSET, 19021220D, '', '');
        InsertLine(10000, XIA + '003');
        InsertHeader(1, XACTFA + '-001', XCommissioningOfBuilding, 19021015D, '', '');
        InsertLine(10000, XFA + '001');
        InsertHeader(1, XACTFA + '-002', XCommissioningOfATS, 19021015D, '', '');
        InsertLine(10000, XFA + '002');
        InsertHeader(1, XACTFA + '-003', XCommissioningOfConveyor, 19021021D, '', '');
        InsertLine(10000, XFA + '027');
        InsertHeader(1, XACTFA + '-004', XCommissioningOfComputer, 19021025D, '', '');
        InsertLine(10000, XFA + '003');
        InsertLine(20000, XFA + '004');
        InsertLine(30000, XFA + '005');
        InsertLine(40000, XFA + '006');
        InsertLine(50000, XFA + '007');
        InsertLine(60000, XFA + '008');
        InsertLine(70000, XFA + '009');
        InsertLine(80000, XFA + '010');
        InsertLine(90000, XFA + '011');
        InsertLine(100000, XFA + '012');
        InsertLine(110000, XFA + '017');
        InsertLine(120000, XFA + '018');
        InsertLine(130000, XFA + '019');
        InsertLine(140000, XFA + '020');
        InsertLine(150000, XFA + '021');
        InsertLine(160000, XFA + '022');
        InsertLine(170000, XFA + '023');
        InsertLine(180000, XFA + '024');
        InsertLine(190000, XFA + '025');
        InsertLine(200000, XFA + '026');
        InsertHeader(1, XACTFA + '-005', XCommissioningOfGAZelle, 19021031D, '', '');
        InsertLine(10000, XFA + '028');
        InsertHeader(1, XACTFA + '-006', XCommissioningOfFurniture, 19021109D, '', '');
        InsertLine(10000, XFA + '013');
        InsertHeader(1, XACTFA + '-007', XCommissioningOfFurniture, 19021109D, '', '');
        InsertLine(10000, XFA + '014');
        InsertHeader(1, XACTFA + '-008', XCommissioningOfFurniture, 19021109D, '', '');
        InsertLine(10000, XFA + '015');
        InsertHeader(1, XACTFA + '-010', XCommissioningOfBuilding, 19021230D, '', '');
        InsertLine(10000, XFA + '016');
        InsertHeader(1, XACTFA + '-011', StrSubstNo(XCommissioningOfFA, '000010'), 19020131D, '', '');
        InsertLine(10000, XFA + '000010');
        InsertHeader(1, XACTFA + '-012', StrSubstNo(XCommissioningOfFA, '000020'), 19020501D, '', '');
        InsertLine(10000, XFA + '000020');
        InsertHeader(1, XACTFA + '-013', StrSubstNo(XCommissioningOfFA, '000030'), 19020601D, '', '');
        InsertLine(10000, XFA + '000030');
        InsertHeader(1, XACTFA + '-014', StrSubstNo(XCommissioningOfFA, '000050'), 19020601D, '', '');
        InsertLine(10000, XFA + '000050');
        InsertHeader(1, XACTFA + '-015', StrSubstNo(XCommissioningOfFA, '000060'), 19020601D, '', '');
        InsertLine(10000, XFA + '000060');
        InsertHeader(1, XACTFA + '-016', StrSubstNo(XCommissioningOfFA, '000070'), 19020601D, '', '');
        InsertLine(10000, XFA + '000070');
        InsertHeader(1, XACTFA + '-017', StrSubstNo(XCommissioningOfFA, '000080'), 19020430D, '', '');
        InsertLine(10000, XFA + '000080');
        InsertHeader(1, XACTFA + '-018', StrSubstNo(XCommissioningOfFA, '000090'), 19020601D, '', '');
        InsertLine(10000, XFA + '000090');

        InsertHeader(2, XACTFA + '-021', XRentedToManufBuilding, 19021231D, '', '8100000');
        InsertLine2(10000, XFA + '016', XOPERATION, XRENT);
        InsertHeader(2, XACTFA + '-022', XTransfToFAPreserve, 19030101D, '', '8100000');
        InsertLine2(10000, XFA + '027', XOPERATION, XCLOSEDOWN);
        InsertHeader(2, XACTFA + '-022', XCommissioningOfAddATSDev, 19021116D, '', '6101010');
        InsertLine2(10000, XFA + '002', XUPGRADING, XOPERATION);
    end;

    var
        FADocHeader: Record "FA Document Header";
        FADocLine: Record "FA Document Line";
        XWOFF: Label 'WOFF';
        XACTIA: Label 'ACTIA';
        XACTFA: Label 'ACTFA';
        XFA: Label 'FA';
        CA: Codeunit "Make Adjustments";
        XIA: Label 'IA';
        XOPERATION: Label 'OPERATION';
        XUPGRADING: Label 'UPGRADING';
        XRENT: Label 'RENT';
        XCLOSEDOWN: Label 'CLOSEDOWN';
        XCompDisposal: Label 'Computer disposal';
        XFADisposalInclInCC: Label 'FA disposal included in CC';
        XGratCompDisposal: Label 'Gratuitous computer disposal';
        XFADisposalTelecom: Label 'FA-012 disposal LLC Telecom';
        XCommissioningOfSWBiling: Label 'Commissioning of SW Biling';
        XCommissioningOfCopyright: Label 'Commissioning of copyright';
        XCommissioningOfIAASSET: Label 'Commissioning of IAASSET-003';
        XCommissioningOfBuilding: Label 'Commissioning of building';
        XCommissioningOfATS: Label 'Commissioning of ATS';
        XCommissioningOfConveyor: Label 'Commissioning of conveyor';
        XCommissioningOfComputer: Label 'Commissioning of computer';
        XCommissioningOfGAZelle: Label 'Commissioning of GAZelle auto';
        XCommissioningOfFurniture: Label 'Commissioning of furniture';
        XCommissioningOfFA: Label 'Commissioning of FA%1';
        XRentedToManufBuilding: Label 'Rented to manufact. building';
        XTransfToFAPreserve: Label 'Transferred to FA preserve';
        XCommissioningOfAddATSDev: Label 'Commissioning of additional ATS devices';

    procedure InsertHeader("Document Type": Integer; "Documetn No.": Code[20]; "Posting Description": Text[50]; "Posting Date": Date; "Shortcut Dimension 1 Code": Code[10]; "Shortcut Dimension 2 Code": Code[10])
    begin
        FADocHeader.Init();
        FADocHeader.Validate("Document Type", "Document Type");
        FADocHeader.Validate("No.", '');
        FADocHeader.Insert(true);
        FADocHeader.Validate("Posting Description", "Posting Description");
        FADocHeader.Validate("Posting Date", CA.AdjustDate("Posting Date"));
        FADocHeader.Validate("Shortcut Dimension 1 Code", "Shortcut Dimension 1 Code");
        FADocHeader.Validate("Shortcut Dimension 2 Code", "Shortcut Dimension 2 Code");
        FADocHeader.Modify();
    end;

    procedure InsertLine("Line No.": Integer; "FA No.": Code[20])
    begin
        FADocLine.Init();
        FADocLine."Document Type" := FADocHeader."Document Type";
        FADocLine."Document No." := FADocHeader."No.";
        FADocLine."Line No." := "Line No.";
        FADocLine.Validate("FA No.", "FA No.");
        FADocLine.Validate(Quantity, 1);
        FADocLine.Insert();
    end;

    procedure InsertLine2("Line No.": Integer; "FA No.": Code[20]; "Depreciation Book": Code[20]; "New Depreciation Book": Code[20])
    begin
        FADocLine.Init();
        FADocLine."Document Type" := FADocHeader."Document Type";
        FADocLine."Document No." := FADocHeader."No.";
        FADocLine."Line No." := "Line No.";
        FADocLine.Validate("FA No.", "FA No.");
        FADocLine.Validate(Quantity, 1);
        FADocLine.Validate("Depreciation Book Code", "Depreciation Book");
        FADocLine.Validate("New Depreciation Book Code", "New Depreciation Book");
        FADocLine.Insert();
    end;
}

