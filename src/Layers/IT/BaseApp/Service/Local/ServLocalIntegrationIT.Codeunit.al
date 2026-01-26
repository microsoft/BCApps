// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Integration;

using Microsoft.Service.Document;
using Microsoft.Service.Setup;
using Microsoft.Utilities;

codeunit 12109 "Serv. Local Integration IT"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::LocalApplicationManagement, 'OnGetNotifyOnOccurredDateChangeSetup', '', false, false)]
    local procedure OnGetNotifyOnOccurredDateChangeSetup(var NotifyOnOccirDateChange: Boolean; RecRef: RecordRef)
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        case RecRef.Number of
            Database::"Service Header":
                begin
                    ServiceMgtSetup.Get();
                    NotifyOnOccirDateChange := ServiceMgtSetup."Notify On Occur. Date Change";
                end;
        end;

    end;
}
