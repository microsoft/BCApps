// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

using Microsoft.Service.Archive;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;

codeunit 6467 "Serv. Interaction Log Mgt."
{

    [EventSubscriber(ObjectType::Table, Database::"Interaction Log Entry", 'OnBeforeShowDocument', '', false, false)]
    local procedure OnBeforeShowDocument(var InteractionLogEntry: Record "Interaction Log Entry"; var IsHandled: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeaderArchive: Record "Service Header Archive";
    begin
        case InteractionLogEntry."Document Type" of
            InteractionLogEntry."Document Type"::"Serv. Ord. Create":
                begin
                    ServiceHeader.Get(ServiceHeader."Document Type"::Order, InteractionLogEntry."Document No.");
                    Page.Run(Page::"Service Order", ServiceHeader)
                end;
            InteractionLogEntry."Document Type"::"Service Contract":
                begin
                    ServiceContractHeader.Get(ServiceContractHeader."Contract Type"::Contract, InteractionLogEntry."Document No.");
                    Page.Run(Page::"Service Contract", ServiceContractHeader);
                end;
            InteractionLogEntry."Document Type"::"Service Contract Quote":
                begin
                    ServiceContractHeader.Get(ServiceContractHeader."Contract Type"::Quote, InteractionLogEntry."Document No.");
                    Page.Run(Page::"Service Contract Quote", ServiceContractHeader);
                end;
            InteractionLogEntry."Document Type"::"Service Quote":
                if InteractionLogEntry."Version No." <> 0 then begin
                    ServiceHeaderArchive.Get(
                        ServiceHeaderArchive."Document Type"::Quote, InteractionLogEntry."Document No.",
                        InteractionLogEntry."Doc. No. Occurrence", InteractionLogEntry."Version No.");
                    ServiceHeaderArchive.SetRange("Document Type", ServiceHeaderArchive."Document Type"::Quote);
                    ServiceHeaderArchive.SetRange("No.", InteractionLogEntry."Document No.");
                    ServiceHeaderArchive.SetRange("Doc. No. Occurrence", InteractionLogEntry."Doc. No. Occurrence");
                    Page.Run(Page::"Service Quote Archive", ServiceHeaderArchive);
                end else begin
                    ServiceHeader.Get(ServiceHeader."Document Type"::Quote, InteractionLogEntry."Document No.");
                    Page.Run(Page::"Service Quote", ServiceHeader);
                end;
        end;
    end;

}
