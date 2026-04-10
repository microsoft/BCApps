// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;

using Microsoft.EServices.EDocument;
tableextension 6412 "ForNAV EDocument" extends "E-Document"
{
    fields
    {
        field(6410; "ForNAV Edoc. ID"; Text[80]) // Needs to have same length as "ForNAV Incoming Doc".ID
        {
            Access = Internal;
            DataClassification = CustomerContent;
            Caption = 'ForNAV Edocument ID';
            ToolTip = 'Specifies the ForNAV E-Document ID.';
        }
    }

    internal procedure DocumentLog() Log: Record "E-Document Integration Log";
    begin
        Log.SetRange(Log."E-Doc. Entry No", Rec."Entry No");
        if Rec.Direction = Rec.Direction::Outgoing then begin
            Log.SetRange(Method, 'POST');
            // Use a dummy label because the URL is mandatory but we don't use it
            Log.SetRange("Request URL", 'https://sendfilepostrequest/');
            if not Log.FindLast() then
                Clear(Log);
        end else begin
            Log.SetRange(Method, 'GET');
            // Use a dummy label because the URL is mandatory but we don't use it
            Log.SetRange("Request URL", 'https://gettargetdocumentrequest/');
            if not Log.FindLast() then
                Clear(Log);
        end;
    end;
}