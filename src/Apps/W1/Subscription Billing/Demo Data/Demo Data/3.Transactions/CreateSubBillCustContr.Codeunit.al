namespace Microsoft.SubscriptionBilling;

using Microsoft.DemoData.Sales;

codeunit 8117 "Create Sub. Bill. Cust. Contr."
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        CreateCustomerContracts();
    end;

    local procedure CreateCustomerContracts()
    var
        CreateCustomer: Codeunit "Create Customer";
        ContosoSubscriptionBilling: Codeunit "Contoso Subscription Billing";
        CreateSubBillContrTypes: Codeunit "Create Sub. Bill. Contr. Types";
        CreateSubBillServObj: Codeunit "Create Sub. Bill. Serv. Obj.";
    begin
        ContosoSubscriptionBilling.InsertCustomerContract(CSC100001(), NewspaperLbl, CreateCustomer.DomesticAdatumCorporation(), CreateSubBillContrTypes.MiscellaneousCode());
        ContosoSubscriptionBilling.InsertCustomerContractLine(CSC100001(), CreateSubBillServObj.SUB100001());

        ContosoSubscriptionBilling.InsertCustomerContract(CSC100002(), SupportLbl, CreateCustomer.DomesticTreyResearch(), CreateSubBillContrTypes.SupportCode());
        ContosoSubscriptionBilling.InsertCustomerContractLine(CSC100002(), CreateSubBillServObj.SUB100002());

        ContosoSubscriptionBilling.InsertCustomerContract(CSC100003(), HardwareMaintenanceLbl, CreateCustomer.ExportSchoolofArt(), CreateSubBillContrTypes.MaintenanceCode());
        ContosoSubscriptionBilling.InsertCustomerContractLine(CSC100003(), CreateSubBillServObj.SUB100003());

        ContosoSubscriptionBilling.InsertCustomerContract(CSC100004(), UsageDataLbl, CreateCustomer.DomesticRelecloud(), CreateSubBillContrTypes.UsageDataCode());
        ContosoSubscriptionBilling.InsertCustomerContractLine(CSC100004(), CreateSubBillServObj.SUB100004());

        ContosoSubscriptionBilling.InsertCustomerContract(CSC100005(), HardwareMaintenanceLbl, CreateCustomer.DomesticAdatumCorporation(), CreateSubBillContrTypes.MaintenanceCode());
        ContosoSubscriptionBilling.InsertCustomerContractLine(CSC100005(), CreateSubBillServObj.SUB100005());

        ContosoSubscriptionBilling.InsertCustomerContract(CSC100006(), NewspaperLbl, CreateCustomer.DomesticTreyResearch(), CreateSubBillContrTypes.MiscellaneousCode());
        ContosoSubscriptionBilling.InsertCustomerContractLine(CSC100006(), CreateSubBillServObj.SUB100006());

        ContosoSubscriptionBilling.InsertCustomerContract(CSC100007(), HardwareMaintenanceLbl, CreateCustomer.ExportSchoolofArt(), CreateSubBillContrTypes.MaintenanceCode());
        ContosoSubscriptionBilling.InsertCustomerContractLine(CSC100007(), CreateSubBillServObj.SUB100007());

        ContosoSubscriptionBilling.InsertCustomerContract(CSC100008(), SupportLbl, CreateCustomer.DomesticAdatumCorporation(), CreateSubBillContrTypes.SupportCode());
        ContosoSubscriptionBilling.InsertCustomerContractLine(CSC100008(), CreateSubBillServObj.SUB100008());

        ContosoSubscriptionBilling.InsertCustomerContract(CSC100009(), HardwareMaintenanceLbl, CreateCustomer.EUAlpineSkiHouse(), CreateSubBillContrTypes.MaintenanceCode());
        ContosoSubscriptionBilling.InsertCustomerContractLine(CSC100009(), CreateSubBillServObj.SUB100009());
        ContosoSubscriptionBilling.InsertCustomerContractLine(CSC100009(), CreateSubBillServObj.SUB100010());

        ContosoSubscriptionBilling.InsertCustomerContract(CSC100010(), NewspaperLbl, CreateCustomer.ExportSchoolofArt(), CreateSubBillContrTypes.MiscellaneousCode());
        ContosoSubscriptionBilling.InsertCustomerContractLine(CSC100010(), CreateSubBillServObj.SUB100011());

        ContosoSubscriptionBilling.InsertCustomerContract(CSC100011(), SupportLbl, CreateCustomer.EUAlpineSkiHouse(), CreateSubBillContrTypes.SupportCode());
        ContosoSubscriptionBilling.InsertCustomerContractLine(CSC100011(), CreateSubBillServObj.SUB100012());

        ContosoSubscriptionBilling.InsertCustomerContract(CSC100012(), SupportLbl, CreateCustomer.EUAlpineSkiHouse(), CreateSubBillContrTypes.SupportCode());
        ContosoSubscriptionBilling.InsertCustomerContractLine(CSC100012(), CreateSubBillServObj.SUB100013());

        ContosoSubscriptionBilling.InsertCustomerContract(CSC100013(), SupportLbl, CreateCustomer.DomesticRelecloud(), CreateSubBillContrTypes.SupportCode());
        ContosoSubscriptionBilling.InsertCustomerContractLine(CSC100013(), CreateSubBillServObj.SUB100014());

        ContosoSubscriptionBilling.InsertCustomerContract(CSC100014(), UsageDataLbl, CreateCustomer.DomesticAdatumCorporation(), CreateSubBillContrTypes.UsageDataCode());
        ContosoSubscriptionBilling.InsertCustomerContractLine(CSC100014(), CreateSubBillServObj.SUB100015());

        ContosoSubscriptionBilling.InsertCustomerContract(CSC100015(), UsageDataLbl, CreateCustomer.DomesticTreyResearch(), CreateSubBillContrTypes.UsageDataCode());
        ContosoSubscriptionBilling.InsertCustomerContractLine(CSC100015(), CreateSubBillServObj.SUB100016());

        ContosoSubscriptionBilling.InsertCustomerContract(CSC100016(), UsageDataLbl, CreateCustomer.ExportSchoolofArt(), CreateSubBillContrTypes.UsageDataCode());
        ContosoSubscriptionBilling.InsertCustomerContractLine(CSC100016(), CreateSubBillServObj.SUB100017());

        ContosoSubscriptionBilling.InsertCustomerContract(CSC100017(), UsageDataLbl, CreateCustomer.DomesticRelecloud(), CreateSubBillContrTypes.UsageDataCode());
        ContosoSubscriptionBilling.InsertCustomerContractLine(CSC100017(), CreateSubBillServObj.SUB100018());

        ContosoSubscriptionBilling.InsertCustomerContract(CSC100018(), UsageDataLbl, CreateCustomer.EUAlpineSkiHouse(), CreateSubBillContrTypes.UsageDataCode());
        ContosoSubscriptionBilling.InsertCustomerContractLine(CSC100018(), CreateSubBillServObj.SUB100019());

        ContosoSubscriptionBilling.InsertCustomerContract(CSC100019(), UsageDataLbl, CreateCustomer.DomesticAdatumCorporation(), CreateSubBillContrTypes.UsageDataCode(), false);
        ContosoSubscriptionBilling.InsertCustomerContractLine(CSC100019(), CreateSubBillServObj.SUB100020());
    end;

    var
        NewspaperLbl: Label 'Newspaper', MaxLength = 100;
        SupportLbl: Label 'Support', MaxLength = 100;
        HardwareMaintenanceLbl: Label 'Hardware Maintenance', MaxLength = 100;
        UsageDataLbl: Label 'Usage data', MaxLength = 100;

    procedure CSC100001(): Code[20]
    begin
        exit('CSC100001');
    end;

    procedure CSC100002(): Code[20]
    begin
        exit('CSC100002');
    end;

    procedure CSC100003(): Code[20]
    begin
        exit('CSC100003');
    end;

    procedure CSC100004(): Code[20]
    begin
        exit('CSC100004');
    end;

    procedure CSC100005(): Code[20]
    begin
        exit('CSC100005');
    end;

    procedure CSC100006(): Code[20]
    begin
        exit('CSC100006');
    end;

    procedure CSC100007(): Code[20]
    begin
        exit('CSC100007');
    end;

    procedure CSC100008(): Code[20]
    begin
        exit('CSC100008');
    end;

    procedure CSC100009(): Code[20]
    begin
        exit('CSC100009');
    end;

    procedure CSC100010(): Code[20]
    begin
        exit('CSC100010');
    end;

    procedure CSC100011(): Code[20]
    begin
        exit('CSC100011');
    end;

    procedure CSC100012(): Code[20]
    begin
        exit('CSC100012');
    end;

    procedure CSC100013(): Code[20]
    begin
        exit('CSC100013');
    end;

    procedure CSC100014(): Code[20]
    begin
        exit('CSC100014');
    end;

    procedure CSC100015(): Code[20]
    begin
        exit('CSC100015');
    end;

    procedure CSC100016(): Code[20]
    begin
        exit('CSC100016');
    end;

    procedure CSC100017(): Code[20]
    begin
        exit('CSC100017');
    end;

    procedure CSC100018(): Code[20]
    begin
        exit('CSC100018');
    end;

    procedure CSC100019(): Code[20]
    begin
        exit('CSC100019');
    end;
}