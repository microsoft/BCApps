codeunit 119084 "Create Cost Object"
{

    trigger OnRun()
    var
        CostAccountMgt: Codeunit "Cost Account Mgt";
    begin
        InsertData(XACCESS, XAccessories, '10', 3, '');
        InsertData(XPAINT, XTradeWithPaint, '20', 0, '');
        InsertData(XFITTINGS, XTradeWithFittings, '20', 0, '');
        InsertData(XACCESSO, XTradeWithAccessories, '20', 0, '');
        InsertData(XTotAccesso, XTotalAccessories, '30', 4, '');

        InsertData(XFURN, XFurnitureDes, '40', 3, '');
        InsertData(XCHAIRS, XSalesOfChairs, '50', 0, '');
        InsertData(XFURNITURE, XSalesOfFurniture, '50', 0, '');
        InsertData(XTotalFurn, XTotalFurniture, '60', 4, '');

        InsertData(XCONSULTING, XConsultingAndWorkIncome, '80', 0, '');

        // Total Amount
        InsertData(XTotal, XTotalCostObject, '99', 2, 'AA..ZZ');  // Amount

        CostAccountMgt.IndentCostObjects();
    end;

    var
        XACCESS: Label 'ACCESS', Comment = 'ACCESS stands for Accessories.';
        XAccessories: Label 'Accessories';
        XPAINT: Label 'PAINT', Comment = 'Paint is a name of Cost Object.';
        XTradeWithPaint: Label 'Trade With Paint';
        XFITTINGS: Label 'FITTINGS', Comment = 'Fittings is a name of Cost Object.';
        XTradeWithFittings: Label 'Trade With Fittings';
        XACCESSO: Label 'ACCESSO', Comment = 'ACCESSO stands for Accessories.';
        XTradeWithAccessories: Label 'Trade With Accessories';
        XTotAccesso: Label 'TotAccesso';
        XTotalAccessories: Label 'Total Accessories';
        XFURN: Label 'FURN', Comment = 'FURN for Furniture.';
        XFURNITURE: Label 'FURNITURE', Comment = 'Furniture is a name of Cost Object.';
        XSalesOfFurniture: Label 'Sales of Furniture';
        XCHAIRS: Label 'CHAIRS', Comment = 'Chairs is a name of Cost Object.';
        XSalesOfChairs: Label 'Sales of Chairs';
        XTotalFurn: Label 'TotalFurn';
        XTotalFurniture: Label 'Total Furniture';
        XCONSULTING: Label 'CONSULTING', Comment = 'Consulting is a name of Cost Object.';
        XConsultingAndWorkIncome: Label 'Consulting and Work Income';
        XTotal: Label 'Total';
        XTotalCostObject: Label 'Total Cost Object';
        XFurnitureDes: Label 'Furniture';

    procedure InsertData(CostObjectCode: Code[20]; CostObjectName: Text[30]; SortingOrder: Code[10]; LineType: Integer; TotalFromTo: Text[30])
    var
        CostObject: Record "Cost Object";
    begin
        CostObject.Init();
        CostObject.Code := CostObjectCode;
        CostObject.Name := CostObjectName;

        CostObject."Sorting Order" := SortingOrder;
        CostObject.Totaling := TotalFromTo;
        CostObject.Validate("Line Type", LineType);
        if CostObject."Line Type" = CostObject."Line Type"::"End-Total" then
            CostObject."Blank Line" := true;

        if not CostObject.Insert() then
            CostObject.Modify();
    end;
}

