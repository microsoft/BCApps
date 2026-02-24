namespace Microsoft.SubscriptionBilling;

using Microsoft.DemoData.Sales;
using Microsoft.DemoTool.Helpers;

codeunit 8116 "Create Sub. Bill. Serv. Obj."
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        CreateServiceObjects();
    end;

    local procedure CreateServiceObjects()
    var
        CreateCustomer: Codeunit "Create Customer";
        ContosoSubscriptionBilling: Codeunit "Contoso Subscription Billing";
        ContosoUtilities: Codeunit "Contoso Utilities";
        CreateSubBillItem: Codeunit "Create Sub. Bill. Item";
        CreateSubBillPackages: Codeunit "Create Sub. Bill. Packages";
        DefaultStartDate: Date;
        CustomStartDate: Date;
    begin
        DefaultStartDate := ContosoUtilities.AdjustDate(19020101D);

        ContosoSubscriptionBilling.InsertServiceObject(SUB100001(), CreateCustomer.DomesticAdatumCorporation(), CreateSubBillItem.SB1100(), DefaultStartDate, 1);
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100001(), DefaultStartDate, CreateSubBillPackages.MonthlySubscription());

        ContosoSubscriptionBilling.InsertServiceObject(SUB100002(), CreateCustomer.DomesticTreyResearch(), CreateSubBillItem.SB1102(), DefaultStartDate, 5);
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100002(), DefaultStartDate, CreateSubBillPackages.MonthlySubscription());

        ContosoSubscriptionBilling.InsertServiceObject(SUB100003(), CreateCustomer.ExportSchoolofArt(), CreateSubBillItem.SB1103(), DefaultStartDate, 1);
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100003(), DefaultStartDate, CreateSubBillPackages.MaintenanceSilver());
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100003(), DefaultStartDate, CreateSubBillPackages.Warranty());

        ContosoSubscriptionBilling.InsertServiceObject(SUB100004(), CreateCustomer.DomesticRelecloud(), CreateSubBillItem.SB1105(), DefaultStartDate, 3);
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100004(), DefaultStartDate, CreateSubBillPackages.UDUsage());

        ContosoSubscriptionBilling.InsertServiceObject(SUB100005(), CreateCustomer.DomesticAdatumCorporation(), CreateSubBillItem.SB1103(), DefaultStartDate, CalcDate('<+1Y>', Today()), 40);
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100005(), DefaultStartDate, CreateSubBillPackages.MaintenanceSilver());
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100005(), DefaultStartDate, CreateSubBillPackages.MaintenanceSilver());

        ContosoSubscriptionBilling.InsertServiceObject(SUB100006(), CreateCustomer.DomesticTreyResearch(), CreateSubBillItem.SB1100(), DefaultStartDate, CalcDate('<+2Y>', Today()), 10);
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100006(), DefaultStartDate, CreateSubBillPackages.MonthlySubscription());

        ContosoSubscriptionBilling.InsertServiceObject(SUB100007(), CreateCustomer.ExportSchoolofArt(), CreateSubBillItem.SB1103(), DefaultStartDate, CalcDate('<+6M>', Today()), 30);
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100007(), DefaultStartDate, CreateSubBillPackages.MaintenanceSilver());
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100007(), DefaultStartDate, CreateSubBillPackages.MaintenanceSilver());

        ContosoSubscriptionBilling.InsertServiceObject(SUB100008(), CreateCustomer.DomesticAdatumCorporation(), CreateSubBillItem.SB1102(), DefaultStartDate, CalcDate('<+18M>', Today()), 2);
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100008(), DefaultStartDate, CreateSubBillPackages.MonthlySubscription());

        ContosoSubscriptionBilling.InsertServiceObject(SUB100009(), CreateCustomer.EUAlpineSkiHouse(), CreateSubBillItem.SB1103(), DefaultStartDate, CalcDate('<+6M>', Today()), 30);
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100009(), DefaultStartDate, CreateSubBillPackages.MaintenanceSilver());
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100009(), DefaultStartDate, CreateSubBillPackages.MaintenanceSilver());

        ContosoSubscriptionBilling.InsertServiceObject(SUB100010(), CreateCustomer.EUAlpineSkiHouse(), CreateSubBillItem.SB1103(), DefaultStartDate, CalcDate('<+18M>', Today()), 40);
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100010(), DefaultStartDate, CreateSubBillPackages.MaintenanceSilver());
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100010(), DefaultStartDate, CreateSubBillPackages.MaintenanceSilver());

        ContosoSubscriptionBilling.InsertServiceObject(SUB100011(), CreateCustomer.ExportSchoolofArt(), CreateSubBillItem.SB1104(), DefaultStartDate, CalcDate('<+1Y>', Today()), 3);
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100011(), DefaultStartDate, CreateSubBillPackages.MonthlySubscription());

        ContosoSubscriptionBilling.InsertServiceObject(SUB100012(), CreateCustomer.EUAlpineSkiHouse(), CreateSubBillItem.SB1104(), DefaultStartDate, CalcDate('<+2Y>', Today()), 2);
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100012(), DefaultStartDate, CreateSubBillPackages.MonthlySubscription());

        ContosoSubscriptionBilling.InsertServiceObject(SUB100013(), CreateCustomer.EUAlpineSkiHouse(), CreateSubBillItem.SB1105(), DefaultStartDate, CalcDate('<+2Y>', Today()), 3);
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100013(), DefaultStartDate, CreateSubBillPackages.MonthlySubscription());

        ContosoSubscriptionBilling.InsertServiceObject(SUB100014(), CreateCustomer.DomesticRelecloud(), CreateSubBillItem.SB1100(), DefaultStartDate, CalcDate('<+3Y>', Today()), 6);
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100014(), DefaultStartDate, CreateSubBillPackages.MonthlySubscription());

        ContosoSubscriptionBilling.InsertServiceObject(SUB100015(), CreateCustomer.DomesticAdatumCorporation(), CreateSubBillItem.SB1102(), DefaultStartDate, CalcDate('<+8M>', Today()), 20);
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100015(), DefaultStartDate, CreateSubBillPackages.UDUsage());
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100015(), DefaultStartDate, CreateSubBillPackages.UDUsage());

        ContosoSubscriptionBilling.InsertServiceObject(SUB100016(), CreateCustomer.DomesticTreyResearch(), CreateSubBillItem.SB1103(), DefaultStartDate, CalcDate('<+12M>', Today()), 5);
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100016(), DefaultStartDate, CreateSubBillPackages.UDUsage());
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100016(), DefaultStartDate, CreateSubBillPackages.UDUsage());

        ContosoSubscriptionBilling.InsertServiceObject(SUB100017(), CreateCustomer.ExportSchoolofArt(), CreateSubBillItem.SB1105(), DefaultStartDate, CalcDate('<+18M>', Today()), 3);
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100017(), DefaultStartDate, CreateSubBillPackages.UDUsage());
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100017(), DefaultStartDate, CreateSubBillPackages.UDUsage());

        ContosoSubscriptionBilling.InsertServiceObject(SUB100018(), CreateCustomer.DomesticRelecloud(), CreateSubBillItem.SB1104(), DefaultStartDate, CalcDate('<+1Y>', Today()), 20);
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100018(), DefaultStartDate, CreateSubBillPackages.UDUsage());
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100018(), DefaultStartDate, CreateSubBillPackages.UDUsage());

        ContosoSubscriptionBilling.InsertServiceObject(SUB100019(), CreateCustomer.EUAlpineSkiHouse(), CreateSubBillItem.SB1104(), DefaultStartDate, CalcDate('<+2Y>', Today()), 19);
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100019(), DefaultStartDate, CreateSubBillPackages.UDUsage());
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100019(), DefaultStartDate, CreateSubBillPackages.UDUsage());

        CustomStartDate := CalcDate('<-24M>', Today());
        ContosoSubscriptionBilling.InsertServiceObject(SUB100020(), CreateCustomer.DomesticAdatumCorporation(), CreateSubBillItem.SB1104(), CustomStartDate, CalcDate('<-18M>', Today()), 10);
        ContosoSubscriptionBilling.InsertServiceCommitments(SUB100020(), CustomStartDate, CreateSubBillPackages.MonthlySubscription());
    end;


    procedure SUB100001(): Code[20]
    begin
        exit('SUB100001');
    end;

    procedure SUB100002(): Code[20]
    begin
        exit('SUB100002');
    end;

    procedure SUB100003(): Code[20]
    begin
        exit('SUB100003');
    end;

    procedure SUB100004(): Code[20]
    begin
        exit('SUB100004');
    end;

    procedure SUB100005(): Code[20]
    begin
        exit('SUB100005');
    end;

    procedure SUB100006(): Code[20]
    begin
        exit('SUB100006');
    end;

    procedure SUB100007(): Code[20]
    begin
        exit('SUB100007');
    end;

    procedure SUB100008(): Code[20]
    begin
        exit('SUB100008');
    end;

    procedure SUB100009(): Code[20]
    begin
        exit('SUB100009');
    end;

    procedure SUB100010(): Code[20]
    begin
        exit('SUB100010');
    end;

    procedure SUB100011(): Code[20]
    begin
        exit('SUB100011');
    end;

    procedure SUB100012(): Code[20]
    begin
        exit('SUB100012');
    end;

    procedure SUB100013(): Code[20]
    begin
        exit('SUB100013');
    end;

    procedure SUB100014(): Code[20]
    begin
        exit('SUB100014');
    end;

    procedure SUB100015(): Code[20]
    begin
        exit('SUB100015');
    end;

    procedure SUB100016(): Code[20]
    begin
        exit('SUB100016');
    end;

    procedure SUB100017(): Code[20]
    begin
        exit('SUB100017');
    end;

    procedure SUB100018(): Code[20]
    begin
        exit('SUB100018');
    end;

    procedure SUB100019(): Code[20]
    begin
        exit('SUB100019');
    end;

    procedure SUB100020(): Code[20]
    begin
        exit('SUB100020');
    end;
}