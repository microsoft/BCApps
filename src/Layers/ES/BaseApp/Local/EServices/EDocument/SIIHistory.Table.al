// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Sales.Customer;
using System.Telemetry;

table 10750 "SII History"
{
    Caption = 'SII History';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer)
        {
            AutoIncrement = true;
            Caption = 'Id';
            NotBlank = true;
        }
        field(2; "Document State Id"; Integer)
        {
            Caption = 'Document State Id';
            NotBlank = true;
            TableRelation = "SII Doc. Upload State".Id;
        }
        field(3; Status; Enum "SII Document Status")
        {
            Caption = 'Status';
            NotBlank = true;
        }
        field(4; "Request Date"; DateTime)
        {
            Caption = 'Request Date';
            NotBlank = true;
        }
        field(5; "Retries Left"; Integer)
        {
            Caption = 'Retries Left';
        }
        field(6; "Request XML"; BLOB)
        {
            Caption = 'Request XML';
        }
        field(7; "Response XML"; BLOB)
        {
            Caption = 'Response XML';
        }
        field(8; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
        }
        field(9; "Upload Type"; Option)
        {
            Caption = 'Upload Type';
            NotBlank = true;
            OptionCaption = 'Regular,Intracommunity,RetryAccepted,Collection In Cash';
            OptionMembers = Regular,Intracommunity,RetryAccepted,"Collection In Cash";
        }
        field(10; "Is Manual"; Boolean)
        {
            Caption = 'Is Manual';
            NotBlank = true;
        }
        field(11; "Is Accepted With Errors Retry"; Boolean)
        {
            Caption = 'Is Accepted With Errors Retry';
        }
        field(12; "Session Id"; Integer)
        {
            Caption = 'Session Id';
            TableRelation = "SII Session".Id;
        }
        field(40; "Retry Accepted"; Boolean)
        {
            Caption = 'Retry Accepted';
        }
        field(41; "CSV Response"; Text[250])
        {
            Caption = 'CSV Response';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
        key(Key2; Status, "Is Manual")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        FeatureTelemetry.LogUsage('1000HY2', ESSIITok, 'ES SII - Invoice and Credit Memo Types in Sales and Purchase Documents Feature Used');
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ESSIITok: Label 'ES SII - Invoice and Credit Memo Types in Sales and Purchase Documents', Locked = true;
        CommunicationErrorWithRetriesErr: Label '%1. More details may be available in the content of the response. There are %2 automatic retries left before failure.', Comment = '@1 is the error message.@2 is the number or automatic retries before the upload is considered failed.';

    procedure CreateNewRequest(DocUploadId: Integer; UploadType: Option; RetriesLeft: Integer; IsManual: Boolean; IsAcceptedWithErrorRetry: Boolean): Integer
    var
        Customer: Record Customer;
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
    begin
        SIIDocUploadState.Get(DocUploadId);
        if (UploadType in [SIIDocUploadState."Transaction Type"::Regular,
                           SIIDocUploadState."Transaction Type"::"Collection In Cash"]) and
           (SIIDocUploadState.Status = SIIDocUploadState.Status::Accepted) and
           (not IsAcceptedWithErrorRetry)
        then
            exit;

        SIIHistory.Init();
        SIIHistory."Request Date" := CurrentDateTime;
        SIIHistory."Document State Id" := DocUploadId;
        if SIIDocUploadState.Status <> SIIDocUploadState.Status::"Not Supported" then
            SIIHistory.Status := Status::Pending
        else
            SIIHistory.Status := Status::"Not Supported";
        SIIHistory."Retries Left" := RetriesLeft;
        SIIHistory."Upload Type" := UploadType;
        SIIHistory."Is Manual" := IsManual;
        SIIHistory."Retry Accepted" := IsAcceptedWithErrorRetry;
        OnCreateNewRequestOnBeforeInsertSIIHistory(SIIHistory);
        SIIHistory.Insert();

        SIIDocUploadState.Get(DocUploadId);
        if SIIDocUploadState.Status <> SIIDocUploadState.Status::"Not Supported" then
            SIIDocUploadState.Status := SIIDocUploadState.Status::Pending
        else
            SIIDocUploadState.Status := SIIDocUploadState.Status::"Not Supported";
        SIIDocUploadState."Is Manual" := SIIHistory."Is Manual";
        SIIDocUploadState."Transaction Type" := SIIHistory."Upload Type";
        SIIDocUploadState."Retry Accepted" := SIIHistory."Retry Accepted";
        if SIIDocUploadState."Transaction Type" = SIIDocUploadState."Transaction Type"::"Collection In Cash" then begin
            Customer.Get(SIIDocUploadState."CV No.");
            SIIDocUploadState."CV Name" := Customer.Name;
            SIIDocUploadState."Country/Region Code" := Customer."Country/Region Code";
            SIIDocUploadState."VAT Registration No." := Customer."VAT Registration No.";
        end;
        SIIDocUploadState.Modify();

        exit(SIIHistory.Id);
    end;

    [Scope('OnPrem')]
    procedure ProcessResponse()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        SIIDocUploadState.Get("Document State Id");
        BuildDocumentStatus(SIIDocUploadState);

        Modify();
        SIIDocUploadState.Modify();
    end;

    [Scope('OnPrem')]
    procedure ProcessResponseCommunicationError(ErrorMessage: Text[250])
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIJobRetryCommError: Codeunit "SII Job Retry Comm. Error";
    begin
        SIIDocUploadState.Get("Document State Id");

        "Error Message" := ErrorMessage;

        "Retries Left" -= 1;
        if ("Retries Left" > 0) or "Is Manual" then begin
            // Some retries left OR it was a manual retry
            Status := Status::"Communication Error";
            "Error Message" := CopyStr(
                StrSubstNo(CommunicationErrorWithRetriesErr, ErrorMessage, "Retries Left"), 1,
                MaxStrLen("Error Message"));
            SIIJobRetryCommError.ScheduleJobForRetry();
        end else begin
            // We ran out of automatic retries, just set document state to "Failed".
            Status := Status::Failed;
            "Error Message" := CopyStr(ErrorMessage, 1, MaxStrLen("Error Message"));
        end;
        BuildDocumentStatus(SIIDocUploadState);

        Modify();
        SIIDocUploadState.Modify();
    end;

    local procedure BuildDocumentStatus(var SIIDocUploadState: Record "SII Doc. Upload State")
    var
        SIIHistory: Record "SII History";
        RequestToFindType: Option;
    begin
        if (Status = Status::Failed) or
           (Status = Status::"Communication Error") or
           (Status = Status::Incorrect) or
           (Status = Status::"Not Supported")
        then begin
            SIIDocUploadState.Status := Status;
            exit;
        end;
        // We get here with request's status "Accepted" or "Accepted with Errors"

        // There is no need to search for other requests if it's a regural upload.
        if SIIDocUploadState."Transaction Type" in
           [SIIDocUploadState."Transaction Type"::Regular, SIIDocUploadState."Transaction Type"::RetryAccepted,
            SIIDocUploadState."Transaction Type"::"Collection In Cash"]
        then
            SIIDocUploadState.Status := Status
        else begin
            if "Upload Type" = "Upload Type"::Intracommunity then
                RequestToFindType := "Upload Type"::Regular
            else
                RequestToFindType := "Upload Type"::Intracommunity;

            SIIHistory.Ascending(false);
            SIIHistory.SetRange("Document State Id", SIIDocUploadState.Id);
            SIIHistory.SetRange("Upload Type", RequestToFindType);

            SIIHistory.FindFirst();
            if Status = SIIHistory.Status::Accepted then begin
                if SIIHistory.Status = SIIHistory.Status::Accepted then
                    SIIDocUploadState.Status := SIIDocUploadState.Status::Accepted;
                exit;
            end;

            if (SIIHistory.Status = SIIHistory.Status::"Accepted With Errors") or
               (SIIHistory.Status = SIIHistory.Status::Accepted)
            then
                SIIDocUploadState.Status := SIIDocUploadState.Status::"Accepted With Errors";
        end;

        SIIDocUploadState."CSV Response" := Rec."CSV Response";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateNewRequestOnBeforeInsertSIIHistory(var SIIHistory: Record "SII History")
    begin
    end;
}

