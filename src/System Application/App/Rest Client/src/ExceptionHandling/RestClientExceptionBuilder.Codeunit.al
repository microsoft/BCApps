// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.RestClient;

codeunit 2362 "Rest Client Exception Builder"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Creates an exception with the specified error code and message. The exception is collectible if the errors are currently being collected.
    /// </summary>
    /// <param name="RestClientException">The error code for the exception.</param>
    /// <param name="ErrorMessage">The message for the exception.</param>
    /// <returns>The exception with the specified error code and message.</returns>
    procedure CreateException(RestClientException: Enum "Rest Client Exception"; ErrorMessage: Text) Exception: ErrorInfo
    begin
        Exception := CreateException(RestClientException, ErrorMessage, IsCollectingErrors());
    end;

    /// <summary>
    /// Creates an exception with the specified error code, message, and collectible flag.
    /// </summary>
    /// <param name="RestClientException">The error code for the exception.</param>
    /// <param name="ErrorMessage">The message for the exception.</param>
    /// <param name="Collectible">Whether the exception is collectible.</param>
    /// <returns>The exception with the specified error code, message, and collectible flag.</returns>
    procedure CreateException(RestClientException: Enum "Rest Client Exception"; ErrorMessage: Text; Collectible: Boolean) Exception: ErrorInfo
    begin
        Exception.Message := ErrorMessage;
        Exception.CustomDimensions.Add('ExceptionCode', Format(RestClientException.AsInteger()));
        Exception.CustomDimensions.Add('ExceptionName', RestClientException.Names.Get(RestClientException.Ordinals.IndexOf(RestClientException.AsInteger())));
        Exception.Collectible := Collectible;
    end;

    /// <summary>
    /// Gets the exception code from the error info.
    /// </summary>
    /// <param name="ErrInfo">The error info of the exception.</param>
    /// <returns>The exception code.</returns>
    procedure GetRestClientException(ErrInfo: ErrorInfo) RestClientException: Enum "Rest Client Exception"
    var
        ExceptionCode: Integer;
    begin
        Evaluate(ExceptionCode, ErrInfo.CustomDimensions.Get('ExceptionCode'));
        RestClientException := Enum::"Rest Client Exception".FromInteger(ExceptionCode);
    end;
}