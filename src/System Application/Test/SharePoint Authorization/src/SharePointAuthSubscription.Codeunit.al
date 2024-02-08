// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Integration.Sharepoint;

using System.Integration.Sharepoint;
using System.TestLibraries.Utilities;

codeunit 132976 "SharePoint Auth. Subscription"
{
    EventSubscriberInstance = Manual;

    var
        Any: Codeunit Any;
        ShouldFail: Boolean;
        ExpectedError: Text;

#if not CLEAN24
#pragma warning disable AL0432
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SharePoint Authorization Code", 'OnBeforeGetToken', '', false, false)]
#pragma warning restore AL0432
    local procedure OnBeforeGetToken(var IsHandled: Boolean; var IsSuccess: Boolean; var ErrorText: Text; var AccessToken: Text)
    begin
        IsHandled := true;
        IsSuccess := not ShouldFail;
        if IsSuccess then
            AccessToken := Any.AlphanumericText(250)
        else
            ErrorText := ExpectedError;
    end;
#endif
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SharePoint Authorization Code", 'OnBeforeGetSecretToken', '', false, false)]
    local procedure OnBeforeGetSecretToken(var IsHandled: Boolean; var IsSuccess: Boolean; var ErrorText: Text; var AccessToken: SecretText)
    begin
        IsHandled := true;
        IsSuccess := not ShouldFail;
        if IsSuccess then
            AccessToken := Any.AlphanumericText(250)
        else
            ErrorText := ExpectedError;
    end;

    procedure SetParameters(NewShouldFail: Boolean; NewExpectedError: Text)
    begin
        ShouldFail := NewShouldFail;
        ExpectedError := NewExpectedError;
    end;
}