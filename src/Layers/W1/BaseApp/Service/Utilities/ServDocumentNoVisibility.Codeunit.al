// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Foundation.NoSeries;
using Microsoft.Service.Setup;

codeunit 6477 "Serv. Document No. Visibility"
{
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        ServiceDocsNoVisible: Dictionary of [Integer, Boolean];
        IsServiceItemNoInitialized: Boolean;
        ServiceItemNoVisible: Boolean;

    procedure ClearState()
    begin
        IsServiceItemNoInitialized := false;
        ServiceItemNoVisible := false;

        Clear(ServiceDocsNoVisible);
    end;

    procedure ServiceDocumentNoIsVisible(DocType: Option Quote,"Order",Invoice,"Credit Memo",Contract; DocNo: Code[20]): Boolean
    var
        NoSeries: Record "No. Series";
        ServiceNoSeriesSetup: Page "Service No. Series Setup";
        DocNoSeries: Code[20];
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceDocumentNoIsVisible(DocType, DocNo, Result, IsHandled);
#if not CLEAN25
        DocumentNoVisibility.RunOnBeforeServiceDocumentNoIsVisible(DocType, DocNo, Result, IsHandled);
#endif
        if IsHandled then
            exit(Result);

        if DocNo <> '' then
            exit(false);

        if ServiceDocsNoVisible.ContainsKey(DocType) then
            exit(ServiceDocsNoVisible.Get(DocType));

        DocNoSeries := DetermineServiceSeriesNo(DocType);
        if not NoSeries.Get(DocNoSeries) then begin
            ServiceNoSeriesSetup.SetFieldsVisibility(DocType);
            ServiceNoSeriesSetup.RunModal();
            DocNoSeries := DetermineServiceSeriesNo(DocType);
        end;

        Result := DocumentNoVisibility.ForceShowNoSeriesForDocNo(DocNoSeries);
        ServiceDocsNoVisible.Add(DocType, Result);

        exit(Result);
    end;

    procedure ServiceItemNoIsVisible(): Boolean
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforeServiceItemNoIsVisible(IsVisible, IsHandled);
#if not CLEAN25
        DocumentNoVisibility.RUnOnBeforeServiceItemNoIsVisible(IsVisible, IsHandled);
#endif
        if IsHandled then
            exit(IsVisible);

        if IsServiceItemNoInitialized then
            exit(ServiceItemNoVisible);
        IsServiceItemNoInitialized := true;

        NoSeriesCode := DetermineServiceItemSeriesNo();
        ServiceItemNoVisible := DocumentNoVisibility.ForceShowNoSeriesForDocNo(NoSeriesCode);
        exit(ServiceItemNoVisible);
    end;

    local procedure DetermineServiceSeriesNo(DocType: Option Quote,"Order",Invoice,"Credit Memo",Contract): Code[20]
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        case DocType of
            DocType::Quote:
                exit(ServiceMgtSetup."Service Quote Nos.");
            DocType::Order:
                exit(ServiceMgtSetup."Service Order Nos.");
            DocType::Invoice:
                exit(ServiceMgtSetup."Service Invoice Nos.");
            DocType::"Credit Memo":
                exit(ServiceMgtSetup."Service Credit Memo Nos.");
            DocType::Contract:
                exit(ServiceMgtSetup."Service Contract Nos.");
        end;
    end;

    local procedure DetermineServiceItemSeriesNo(): Code[20]
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.SetLoadFields("Service Item Nos.");
        ServiceMgtSetup.Get();
        exit(ServiceMgtSetup."Service Item Nos.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceDocumentNoIsVisible(DocType: Option; DocNo: Code[20]; var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceItemNoIsVisible(var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;
}
