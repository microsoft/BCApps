// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.eServices.EDocument.Extensions;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Service.Participant;
using Microsoft.Foundation.Company;

/// <summary>
/// A page extension for the Company Information page to show the E-Document service participation.
/// </summary>
pageextension 6165 "E-Doc. Company Information" extends "Company Information"
{
    layout
    {
        addafter(GLN)
        {
            field("E-Document Service Participation Ids"; ParticipantIdCount)
            {
                ApplicationArea = All;
                Caption = 'E-Document Service Participation';
                DrillDown = true;
                Editable = false;
                ToolTip = 'Specifies the company participation for the E-Document services.';
                Visible = EDocumentServiceExists;

                trigger OnDrillDown()
                begin
                    ServiceParticipant.RunServiceParticipantPage(Enum::"E-Document Source Type"::Company, '');
                end;
            }
        }
    }


    var
        ServiceParticipant: Codeunit "Service Participant";
        ParticipantIdCount: Integer;
        EDocumentServiceExists: Boolean;


    trigger OnAfterGetCurrRecord()
    begin
        if TryGetEDocumentServiceParticipation() then;
    end;

    [TryFunction]
    local procedure TryGetEDocumentServiceParticipation()
    var
        EDocumentService: Record "E-Document Service";
    begin
        EDocumentServiceExists := not EDocumentService.IsEmpty();
        ParticipantIdCount := ServiceParticipant.GetParticipantIdCount(Enum::"E-Document Source Type"::Company, '');
    end;

}
