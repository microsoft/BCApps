// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Utilities;
using System.Security.User;
using System.Utilities;
using Microsoft.Finance.ReceivablesPayables;

codeunit 5957 "Serv. Posting Selection Mgt."
{
    var
        PostingSelectionManagement: Codeunit "Posting Selection Management";

    procedure ConfirmPostServiceDocument(var ServiceHeaderToPost: Record "Service Header"; var Ship: Boolean; var Consume: Boolean; var Invoice: Boolean; DefaultOption: Integer; WithPrint: Boolean; WithEmail: Boolean; PreviewMode: Boolean) Result: Boolean
    var
        ServiceHeader: Record "Service Header";
        UserSetupManagement: Codeunit "User Setup Management";
        ConfirmManagement: Codeunit "Confirm Management";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        Selection: Integer;
        ShipInvoiceConsumeQst: Label '&Ship,&Invoice,Ship &and Invoice,Ship and &Consume';
        ShipConsumeQst: Label '&Ship,Ship and &Consume';
    begin
        if (ServiceHeaderToPost."Document Type" <> ServiceHeaderToPost."Document Type"::Order) and PreviewMode then
            exit(true);

        if DefaultOption > 4 then
            DefaultOption := 4;
        if DefaultOption <= 0 then
            DefaultOption := 1;

        ServiceHeader.Copy(ServiceHeaderToPost);

        case ServiceHeader."Document Type" of
            ServiceHeader."Document Type"::Order:
                begin
                    UserSetupManagement.GetServiceInvoicePostingPolicy(Ship, Consume, Invoice);
                    case true of
                        Ship and not Consume and Invoice:
                            if not ConfirmManagement.GetResponseOrDefault(PostingSelectionManagement.GetShipInvoiceConfirmationMessage(), true) then
                                exit(false);
                        Ship and not Consume and not Invoice:
                            if not ConfirmManagement.GetResponseOrDefault(PostingSelectionManagement.GetShipConfirmationMessage(), true) then
                                exit(false);
                        Ship and Consume and not Invoice:
                            begin
                                Selection := StrMenu(ShipConsumeQst, 1);
                                if Selection = 0 then
                                    exit(false);
                                Ship := Selection in [1, 2];
                                Consume := Selection in [2];
                            end;
                        else begin
                            Selection := StrMenu(ShipInvoiceConsumeQst, DefaultOption);
                            if Selection = 0 then begin
                                if PreviewMode then
                                    Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());
                                exit(false);
                            end;
                            Ship := Selection in [1, 3, 4];
                            Consume := Selection in [4];
                            Invoice := Selection in [2, 3];
                        end;
                    end;
                end;
            ServiceHeader."Document Type"::Invoice, ServiceHeader."Document Type"::"Credit Memo":
                begin
                    CheckUserCanInvoiceService();

                    if not ConfirmManagement.GetResponseOrDefault(
                            PostingSelectionManagement.GetPostConfirmationMessage(ServiceHeader."Document Type" = ServiceHeader."Document Type"::Invoice, WithPrint, WithEmail), true)
                    then
                        exit(false);
                end;
            else
                if not ConfirmManagement.GetResponseOrDefault(
                        PostingSelectionManagement.GetPostConfirmationMessage(Format(ServiceHeader."Document Type"), WithPrint, WithEmail), true)
                then
                    exit(false);
        end;

        ServiceHeaderToPost.Copy(ServiceHeader);
        exit(true);
    end;

    procedure CheckUserCanInvoiceService()
    var
        UserSetup: Record "User Setup";
        UserSetupManagement: Codeunit "User Setup Management";
        Ship: Boolean;
        Consume: Boolean;
        Invoice: Boolean;
    begin
        UserSetupManagement.GetServiceInvoicePostingPolicy(Ship, Consume, Invoice);
        if Ship and not Invoice then
            Error(
              PostingSelectionManagement.GetPostingInvoiceProhibitedErr(),
              UserSetup.FieldCaption("Service Invoice Posting Policy"), Format("Invoice Posting Policy"::Prohibited),
              UserSetup.TableCaption);
    end;
}
