codeunit 101712 "Create Analysis Line Templates"
{

    trigger OnRun()
    begin
        InsertData(0, XCUSTGROUPS, XCustomersGroupsAll, '', XCUSTOMERS);
        InsertData(0, XCUSTALL, XCustomersAll, '', '');
        InsertData(0, XFURNITALL, XFurnitureTotal, '', '');
        InsertData(0, XMYCUST, XMyCustomers, '', '');
        InsertData(0, XMYITEMS, XMyItemsTotal, '', '');
        InsertData(2, XFURNITALL, XFurnitureTotal, '', '');
        InsertData(2, XMYITEMS, XMyItemsTotal, '', '');
    end;

    var
        AnalysisLineTemplate: Record "Analysis Line Template";
        XCUSTGROUPS: Label 'CUSTGROUPS';
        XCUSTALL: Label 'CUST-ALL';
        XFURNITALL: Label 'FURNIT-ALL';
        XMYCUST: Label 'MY-CUST';
        XMYITEMS: Label 'MY-ITEMS';
        XCustomersGroupsAll: Label 'Customers Groups, All';
        XCustomersAll: Label 'Customers All';
        XFurnitureTotal: Label 'Furniture Total';
        XMyCustomers: Label 'My Customers';
        XMyItemsTotal: Label 'My Items, Total';
        XCUSTOMERS: Label 'CUSTOMERS';

    procedure InsertData(AnalysisArea: Option Sales,Purchase,Inventory; Name: Code[10]; Description: Text[80]; DefaultColumnTemplateName: Code[10]; ItemAnalysisViewCode: Code[10])
    begin
        AnalysisLineTemplate.Init();
        AnalysisLineTemplate.Validate("Analysis Area", AnalysisArea);
        AnalysisLineTemplate.Validate(Name, Name);
        AnalysisLineTemplate.Validate(Description, Description);
        AnalysisLineTemplate.Validate("Default Column Template Name", DefaultColumnTemplateName);
        AnalysisLineTemplate.Validate("Item Analysis View Code", ItemAnalysisViewCode);
        AnalysisLineTemplate.Insert(true);
    end;
}

