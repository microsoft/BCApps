namespace Microsoft.SubscriptionBilling;

using Microsoft.DemoData.Purchases;

codeunit 8118 "Create Sub. Bill. Vend. Contr."
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        CreateVendorContracts();
    end;

    local procedure CreateVendorContracts()
    var
        CreateVendor: Codeunit "Create Vendor";
        ContosoSubscriptionBilling: Codeunit "Contoso Subscription Billing";
        CreateSubBillContrTypes: Codeunit "Create Sub. Bill. Contr. Types";
        CreateSubBillServObj: Codeunit "Create Sub. Bill. Serv. Obj.";
    begin
        ContosoSubscriptionBilling.InsertVendorContract(VSC100001(), HardwareMaintenanceLbl, CreateVendor.ExportFabrikam(), CreateSubBillContrTypes.MaintenanceCode());
        ContosoSubscriptionBilling.InsertVendorContractLine(VSC100001(), CreateSubBillServObj.SUB100003());

        ContosoSubscriptionBilling.InsertVendorContract(VSC100002(), UsageDataLbl, CreateVendor.DomesticWorldImporter(), CreateSubBillContrTypes.UsageDataCode());
        ContosoSubscriptionBilling.InsertVendorContractLine(VSC100002(), CreateSubBillServObj.SUB100004());

        ContosoSubscriptionBilling.InsertVendorContract(VSC100003(), HardwareMaintenanceLbl, CreateVendor.ExportFabrikam(), CreateSubBillContrTypes.MaintenanceCode());
        ContosoSubscriptionBilling.InsertVendorContractLine(VSC100003(), CreateSubBillServObj.SUB100005());
        ContosoSubscriptionBilling.AddVendorContractLine(VSC100003(), CreateSubBillServObj.SUB100007());
        ContosoSubscriptionBilling.AddVendorContractLine(VSC100003(), CreateSubBillServObj.SUB100009());
        ContosoSubscriptionBilling.AddVendorContractLine(VSC100003(), CreateSubBillServObj.SUB100010());

        ContosoSubscriptionBilling.InsertVendorContract(VSC100004(), UsageDataLbl, CreateVendor.DomesticWorldImporter(), CreateSubBillContrTypes.UsageDataCode());
        ContosoSubscriptionBilling.InsertVendorContractLine(VSC100004(), CreateSubBillServObj.SUB100015());
        ContosoSubscriptionBilling.AddVendorContractLine(VSC100004(), CreateSubBillServObj.SUB100016());
        ContosoSubscriptionBilling.AddVendorContractLine(VSC100004(), CreateSubBillServObj.SUB100017());
        ContosoSubscriptionBilling.AddVendorContractLine(VSC100004(), CreateSubBillServObj.SUB100018());
        ContosoSubscriptionBilling.AddVendorContractLine(VSC100004(), CreateSubBillServObj.SUB100019());
    end;

    var
        HardwareMaintenanceLbl: Label 'Hardware Maintenance', MaxLength = 100;
        UsageDataLbl: Label 'Usage data', MaxLength = 100;

    procedure VSC100001(): Code[20]
    begin
        exit('VSC100001');
    end;

    procedure VSC100002(): Code[20]
    begin
        exit('VSC100002');
    end;

    procedure VSC100003(): Code[20]
    begin
        exit('VSC100003');
    end;

    procedure VSC100004(): Code[20]
    begin
        exit('VSC100004');
    end;
}