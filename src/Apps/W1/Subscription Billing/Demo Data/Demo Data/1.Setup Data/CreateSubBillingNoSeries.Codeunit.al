namespace Microsoft.SubscriptionBilling;

using Microsoft.DemoTool.Helpers;
using Microsoft.Foundation.NoSeries;

codeunit 8103 "Create Sub. Billing No. Series"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ContosoNoSeries: Codeunit "Contoso No Series";
    begin
        ContosoNoSeries.InsertNoSeries(CustomerContractNoSeries(), CustomerContractNoSeriesDescriptionTok, CustomerContractStartingNoLbl, CustomerContractEndingNoLbl, '', CustomerContractLastUsedNoLbl, 1, Enum::"No. Series Implementation"::Normal, true);
        ContosoNoSeries.InsertNoSeries(VendorContractNoSeries(), VendorContractNoSeriesDescriptionTok, VendorContractStartingNoLbl, VendorContractEndingNoLbl, '', VendorContractLastUsedNoLbl, 1, Enum::"No. Series Implementation"::Normal, true);
        ContosoNoSeries.InsertNoSeries(ServiceObjectNoSeries(), ServiceObjectNoSeriesDescriptionTok, ServiceObjectStartingNoLbl, ServiceObjectEndingNoLbl, '', ServiceObjectLastUsedNoLbl, 1, Enum::"No. Series Implementation"::Normal, true);
    end;

    procedure CustomerContractNoSeries(): Code[20]
    begin
        exit(CustomerContractNoSeriesTok);
    end;

    procedure VendorContractNoSeries(): Code[20]
    begin
        exit(VendorContractNoSeriesTok);
    end;

    procedure ServiceObjectNoSeries(): Code[20]
    begin
        exit(ServiceObjectNoSeriesTok);
    end;

    var
        CustomerContractNoSeriesTok: Label 'CUSTSUBCONTR', MaxLength = 20;
        CustomerContractNoSeriesDescriptionTok: Label 'Customer Subscription Contracts', MaxLength = 100;
        CustomerContractStartingNoLbl: Label 'CSC100001', MaxLength = 20, Locked = true;
        CustomerContractEndingNoLbl: Label 'CSC999999', MaxLength = 20, Locked = true;
        CustomerContractLastUsedNoLbl: Label 'CSC100019', MaxLength = 20, Locked = true;
        VendorContractNoSeriesTok: Label 'VENDSUBCONTR', MaxLength = 20;
        VendorContractNoSeriesDescriptionTok: Label 'Vendor Subscription Contracts', MaxLength = 100;
        VendorContractStartingNoLbl: Label 'VSC100001', MaxLength = 20, Locked = true;
        VendorContractLastUsedNoLbl: Label 'VSC100004', MaxLength = 20, Locked = true;
        VendorContractEndingNoLbl: Label 'VSC999999', MaxLength = 20, Locked = true;
        ServiceObjectNoSeriesTok: Label 'SUBSCRIPTION', MaxLength = 20;
        ServiceObjectNoSeriesDescriptionTok: Label 'Subscriptions', MaxLength = 100;
        ServiceObjectStartingNoLbl: Label 'SUB100001', MaxLength = 20, Locked = true;
        ServiceObjectLastUsedNoLbl: Label 'SUB100020', MaxLength = 20, Locked = true;
        ServiceObjectEndingNoLbl: Label 'SUB999999', MaxLength = 20, Locked = true;
}
